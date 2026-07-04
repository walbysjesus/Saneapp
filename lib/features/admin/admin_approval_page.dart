import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _brandGreen = Color(0xFF0C4F31);
const _brandGreenSoft = Color(0xFF1E7A4B);
const _surface = Color(0xFFF6FAF7);
const _cardBorder = Color(0xFFDCE7DF);
const _warningColor = Color(0xFFC27A00);
const _dangerColor = Color(0xFFB83A2F);

enum _SupervisorReviewFilter {
  pendingReview,
  approved,
  rejected,
}

class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({super.key});

  @override
  State<AdminApprovalPage> createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final Set<String> _processingIds = <String>{};
  _SupervisorReviewFilter _selectedFilter =
      _SupervisorReviewFilter.pendingReview;

  Future<bool> _isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['role'] == 'admin';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _supervisorsByFilter() {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .where('role', isEqualTo: 'supervisor');

    switch (_selectedFilter) {
      case _SupervisorReviewFilter.pendingReview:
        query = query.where(
          'status',
          whereIn: const ['pending_review', 'prequalified', 'requires_review'],
        );
        break;
      case _SupervisorReviewFilter.approved:
        query = query.where('status', isEqualTo: 'active');
        break;
      case _SupervisorReviewFilter.rejected:
        query = query.where('status', isEqualTo: 'rejected');
        break;
    }

    return query.snapshots();
  }

  String get _filterHeadline {
    return switch (_selectedFilter) {
      _SupervisorReviewFilter.pendingReview =>
        'Validación operativa de supervisores',
      _SupervisorReviewFilter.approved => 'Supervisores aprobados',
      _SupervisorReviewFilter.rejected => 'Supervisores rechazados',
    };
  }

  String get _filterDescription {
    return switch (_selectedFilter) {
      _SupervisorReviewFilter.pendingReview =>
        'Esta bandeja revisa postulaciones reales en Firebase con estado pending_review, prequalified o requires_review y permite activar o rechazar supervisores.',
      _SupervisorReviewFilter.approved =>
        'Aquí se muestran los supervisores ya activados por el equipo administrativo.',
      _SupervisorReviewFilter.rejected =>
        'Aquí se muestran las postulaciones rechazadas para seguimiento o nueva validación.',
    };
  }

  String get _filterCounterLabel {
    return switch (_selectedFilter) {
      _SupervisorReviewFilter.pendingReview => 'pendientes por revisar',
      _SupervisorReviewFilter.approved => 'supervisores aprobados',
      _SupervisorReviewFilter.rejected => 'supervisores rechazados',
    };
  }

  bool get _showsDecisionActions {
    return _selectedFilter == _SupervisorReviewFilter.pendingReview;
  }

  Future<void> _approveSupervisor({
    required String userId,
    required String? fullName,
    required String email,
  }) async {
    final admin = _auth.currentUser;
    if (admin == null) {
      return;
    }

    final shouldApprove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aprobar supervisor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmar aprobación de ${fullName?.trim().isNotEmpty == true ? fullName : 'Supervisor sin nombre'}.',
            ),
            const SizedBox(height: 12),
            Text('Correo: $email'),
            const SizedBox(height: 8),
            SelectableText(
              'UID: $userId',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _brandGreen),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (shouldApprove != true) {
      return;
    }

    setState(() {
      _processingIds.add(userId);
    });

    try {
      await _firestore.collection('users').doc(userId).set({
        'status': 'active',
        'supervisorReviewedAt': FieldValue.serverTimestamp(),
        'supervisorReviewedBy': admin.uid,
        'supervisorDecision': 'approved',
        'supervisorRejectionReason': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Supervisor ${fullName?.trim().isNotEmpty == true ? fullName : userId} aprobado correctamente para UID $userId.',
          ),
          backgroundColor: _brandGreenSoft,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(userId);
        });
      }
    }
  }

  Future<void> _rejectSupervisor({
    required String userId,
    required String? fullName,
  }) async {
    final admin = _auth.currentUser;
    if (admin == null) {
      return;
    }

    final reasonController = TextEditingController();
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rechazar postulación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrarás la postulación de ${fullName?.trim().isNotEmpty == true ? fullName : userId} como rechazada.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo de rechazo',
                hintText: 'Describe ajustes o faltantes para la resubmisión.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _dangerColor),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    final rejectionReason = reasonController.text.trim();
    reasonController.dispose();

    if (shouldReject != true) {
      return;
    }

    setState(() {
      _processingIds.add(userId);
    });

    try {
      await _firestore.collection('users').doc(userId).set({
        'status': 'rejected',
        'supervisorReviewedAt': FieldValue.serverTimestamp(),
        'supervisorReviewedBy': admin.uid,
        'supervisorDecision': 'rejected',
        'supervisorRejectionReason': rejectionReason,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Supervisor ${fullName?.trim().isNotEmpty == true ? fullName : userId} rechazado para UID $userId.',
          ),
          backgroundColor: _dangerColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(userId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.data!) {
          return Scaffold(
            backgroundColor: _surface,
            appBar: AppBar(
              title: const Text('Aprobación de supervisores'),
              backgroundColor: _brandGreen,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('Acceso restringido')),
          );
        }

        return Scaffold(
          backgroundColor: _surface,
          appBar: AppBar(
            title: const Text('Aprobación de supervisores'),
            backgroundColor: _brandGreen,
            foregroundColor: Colors.white,
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _supervisorsByFilter(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? const [];

              if (snapshot.hasError) {
                return const Center(
                  child: Text('No fue posible cargar las postulaciones.'),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [_brandGreen, _brandGreenSoft],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _filterHeadline,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _filterDescription,
                          style: TextStyle(color: Colors.white70, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FilterChip(
                              label: 'Pendientes',
                              selected: _selectedFilter ==
                                  _SupervisorReviewFilter.pendingReview,
                              onTap: () {
                                setState(() {
                                  _selectedFilter =
                                      _SupervisorReviewFilter.pendingReview;
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'Aprobados',
                              selected: _selectedFilter ==
                                  _SupervisorReviewFilter.approved,
                              onTap: () {
                                setState(() {
                                  _selectedFilter =
                                      _SupervisorReviewFilter.approved;
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'Rechazados',
                              selected: _selectedFilter ==
                                  _SupervisorReviewFilter.rejected,
                              onTap: () {
                                setState(() {
                                  _selectedFilter =
                                      _SupervisorReviewFilter.rejected;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${docs.length} $_filterCounterLabel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (docs.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _emptyStateTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _emptyStateDescription,
                            style: TextStyle(color: Colors.black54, height: 1.4),
                          ),
                        ],
                      ),
                    )
                  else
                    ...docs.map((doc) {
                      final data = doc.data();
                      final userId = doc.id;
                      final fullName = data['fullName'] as String?;
                      final email = data['email'] as String? ?? 'Sin correo';
                      final city = data['city'] as String? ?? 'Sin ciudad';
                      final status = data['status'] as String?;
                      final score =
                          (data['supervisorAssessmentScore'] as num?)?.toInt();
                      final approvedAssessment =
                          data['supervisorAssessmentPassed'] == true;
                        final reviewedAt = data['supervisorReviewedAt'];
                        final rejectionReason =
                          data['supervisorRejectionReason'] as String?;
                      final processing = _processingIds.contains(userId);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: _brandGreenSoft.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.verified_user_outlined,
                                      color: _brandGreenSoft,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fullName?.trim().isNotEmpty == true
                                              ? fullName!
                                              : 'Supervisor sin nombre',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          email,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _StatusPill(
                                    label: _statusLabel(status),
                                    color: _statusColor(status),
                                  ),
                                  _StatusPill(
                                    label: 'Ciudad: $city',
                                    color: _brandGreenSoft,
                                  ),
                                  if (score != null)
                                    _StatusPill(
                                      label:
                                          'Puntaje: $score/100 ${approvedAssessment ? 'aprobado' : 'pendiente'}',
                                      color: approvedAssessment
                                          ? _brandGreenSoft
                                          : _warningColor,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4F1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _cardBorder),
                                ),
                                child: SelectableText(
                                  'UID: $userId\nEstado en Firestore: ${status ?? 'sin estado'}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (reviewedAt is Timestamp) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Última revisión: ${_formatTimestamp(reviewedAt)}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (_selectedFilter ==
                                      _SupervisorReviewFilter.rejected &&
                                  rejectionReason != null &&
                                  rejectionReason.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _dangerColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    'Motivo: $rejectionReason',
                                    style: const TextStyle(
                                      color: _dangerColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              if (_showsDecisionActions)
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: processing
                                            ? null
                                            : () => _rejectSupervisor(
                                                  userId: userId,
                                                  fullName: fullName,
                                                ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _dangerColor,
                                          side: const BorderSide(
                                            color: _dangerColor,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        icon: const Icon(Icons.close_rounded),
                                        label: const Text('Rechazar'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: processing
                                            ? null
                                            : () => _approveSupervisor(
                                                  userId: userId,
                                                  fullName: fullName,
                                                email: email,
                                                ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _brandGreen,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        icon: processing
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.check_rounded),
                                        label: Text(
                                          processing ? 'Procesando...' : 'Aprobar',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String get _emptyStateTitle {
    return switch (_selectedFilter) {
      _SupervisorReviewFilter.pendingReview =>
        'No hay supervisores pendientes',
      _SupervisorReviewFilter.approved => 'No hay supervisores aprobados',
      _SupervisorReviewFilter.rejected => 'No hay supervisores rechazados',
    };
  }

  String get _emptyStateDescription {
    return switch (_selectedFilter) {
      _SupervisorReviewFilter.pendingReview =>
        'Cuando un supervisor complete su inscripción, aparecerá aquí para validación administrativa.',
      _SupervisorReviewFilter.approved =>
        'Los supervisores activados por el equipo administrativo aparecerán aquí.',
      _SupervisorReviewFilter.rejected =>
        'Las postulaciones rechazadas quedarán listadas aquí con su motivo de revisión.',
    };
  }

  String _formatTimestamp(Timestamp timestamp) {
    final reviewedDate = timestamp.toDate();
    final day = reviewedDate.day.toString().padLeft(2, '0');
    final month = reviewedDate.month.toString().padLeft(2, '0');
    final year = reviewedDate.year;
    final hour = reviewedDate.hour.toString().padLeft(2, '0');
    final minute = reviewedDate.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'prequalified':
        return 'Precalificado';
      case 'requires_review':
        return 'Requiere revisión';
      case 'rejected':
        return 'Rechazado';
      case 'pending_review':
      default:
        return 'En revisión';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return _brandGreenSoft;
      case 'prequalified':
        return const Color(0xFF2C6E49);
      case 'requires_review':
        return _warningColor;
      case 'rejected':
        return _dangerColor;
      case 'pending_review':
      default:
        return _warningColor;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

