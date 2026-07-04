import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/role_guard.dart';
import '../../state/app_state.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  final Map<String, String?> _selectedSupervisorByRequest = {};
  final Set<String> _savingRequests = <String>{};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: UserRole.admin,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAF7),
        appBar: AppBar(title: const Text('Asignación de supervisores')),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'supervisor')
              .where('status', isEqualTo: 'active')
              .snapshots(),
          builder: (context, supervisorsSnapshot) {
            if (supervisorsSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final supervisors = (supervisorsSnapshot.data?.docs ?? const [])
                .where(
                  (doc) => doc.data()['supervisorProfileCompleted'] == true,
                )
                .toList();

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('solicitudes')
                  .where('supervisorRequested', isEqualTo: true)
                  .snapshots(),
              builder: (context, requestsSnapshot) {
                if (requestsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs =
                    (requestsSnapshot.data?.docs ?? const []).where((doc) {
                      final status =
                          doc.data()['status']?.toString().toLowerCase() ?? '';
                      return status != 'cancelada' && status != 'completada';
                    }).toList()..sort((a, b) {
                      final aCreated = a.data()['createdAt'];
                      final bCreated = b.data()['createdAt'];
                      final aDate = aCreated is Timestamp
                          ? aCreated.toDate()
                          : DateTime.fromMillisecondsSinceEpoch(0);
                      final bDate = bCreated is Timestamp
                          ? bCreated.toDate()
                          : DateTime.fromMillisecondsSinceEpoch(0);
                      return bDate.compareTo(aDate);
                    });

                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final orderCode = data['supervisorOrderCode']?.toString() ?? '';
                  final title = data['titulo']?.toString() ?? '';
                  return _matchesSearch('$orderCode $title');
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No hay solicitudes con supervisión pendientes de gestionar.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Buscar por orden o solicitud',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...filteredDocs.map((doc) {
                    final data = doc.data();
                    final requestId = doc.id;
                    final assignedSupervisorId = data['supervisorId']
                        ?.toString();
                    final selectedId =
                        _selectedSupervisorByRequest[requestId] ??
                        assignedSupervisorId;
                    final isSaving = _savingRequests.contains(requestId);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFDCE7DF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _Tag(
                                  label: _mapJourney(
                                    data['supervisionJourney']?.toString(),
                                  ),
                                  background: const Color(0xFFE9F3ED),
                                  foreground: const Color(0xFF1E7A4B),
                                ),
                                _Tag(
                                  label: _mapSupervisorStatus(
                                    data['supervisorStatus']?.toString(),
                                  ),
                                  background: const Color(0xFFF2F4F7),
                                  foreground: const Color(0xFF4E5968),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data['titulo']?.toString() ?? 'Solicitud',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['descripcion']?.toString() ?? '',
                              style: const TextStyle(
                                color: Colors.black54,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              label: 'Ciudad',
                              value: data['city']?.toString() ?? '-',
                            ),
                            _InfoRow(
                              label: 'Orden supervisor',
                              value:
                                  data['supervisorOrderCode']?.toString() ??
                                  'Se generará al asignar',
                            ),
                            if ((data['supervisorOrderCode']?.toString() ?? '')
                                .isNotEmpty)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(
                                        text: data['supervisorOrderCode']
                                            .toString(),
                                      ),
                                    );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Numero de orden copiado.',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_outlined),
                                  label: const Text('Copiar orden'),
                                ),
                              ),
                            _InfoRow(
                              label: 'Generador',
                              value: data['contactName']?.toString() ?? '-',
                            ),
                            _InfoRow(
                              label: 'Supervisor actual',
                              value:
                                  data['supervisorName']?.toString() ??
                                  'Sin asignar',
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: selectedId,
                              decoration: const InputDecoration(
                                labelText: 'Supervisor responsable',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Sin asignar'),
                                ),
                                ...supervisors.map((supervisor) {
                                  final supervisorData = supervisor.data();
                                  final name =
                                      supervisorData['fullName']?.toString() ??
                                      supervisorData['companyName']
                                          ?.toString() ??
                                      supervisor.id;
                                  return DropdownMenuItem<String>(
                                    value: supervisor.id,
                                    child: Text(name),
                                  );
                                }),
                              ],
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedSupervisorByRequest[requestId] =
                                            value;
                                      });
                                    },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: isSaving
                                        ? null
                                        : () => _saveAssignment(
                                            requestId: requestId,
                                            requestData: data,
                                            supervisors: supervisors,
                                          ),
                                    icon: isSaving
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.assignment_ind),
                                    label: const Text('Guardar asignación'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        isSaving || assignedSupervisorId == null
                                        ? null
                                        : () => _clearAssignment(requestId),
                                    icon: const Icon(Icons.person_off_outlined),
                                    label: const Text('Liberar'),
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
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveAssignment({
    required String requestId,
    required Map<String, dynamic> requestData,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> supervisors,
  }) async {
    final selectedId = _selectedSupervisorByRequest[requestId];
    setState(() {
      _savingRequests.add(requestId);
    });

    try {
      final selectedSupervisor = supervisors
          .cast<QueryDocumentSnapshot<Map<String, dynamic>>?>()
          .firstWhere((doc) => doc?.id == selectedId, orElse: () => null);
      final supervisorName =
          selectedSupervisor?.data()['fullName']?.toString() ??
          selectedSupervisor?.data()['companyName']?.toString();

      await FirebaseFirestore.instance
          .collection('solicitudes')
          .doc(requestId)
          .set({
            'supervisorId': selectedId,
            'supervisorName': supervisorName,
            'supervisorStatus': selectedId == null
                ? 'pendiente_asignacion'
                : 'asignado',
            'supervisorAssignedAt': selectedId == null
                ? null
                : FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selectedId == null
                ? 'Solicitud marcada nuevamente como pendiente de asignación.'
                : 'Supervisor asignado correctamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingRequests.remove(requestId);
        });
      }
    }
  }

  Future<void> _clearAssignment(String requestId) async {
    setState(() {
      _savingRequests.add(requestId);
      _selectedSupervisorByRequest[requestId] = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('solicitudes')
          .doc(requestId)
          .set({
            'supervisorId': null,
            'supervisorName': null,
            'supervisorStatus': 'pendiente_asignacion',
            'supervisorAssignedAt': null,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supervisor liberado correctamente.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingRequests.remove(requestId);
        });
      }
    }
  }

  bool _matchesSearch(String value) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    return value.toLowerCase().contains(query);
  }

  String _mapJourney(String? value) {
    switch (value) {
      case 'execution_traceability':
        return 'Ejecución y calidad';
      case 'prequote_diagnostic':
      default:
        return 'Preinspección técnica';
    }
  }

  String _mapSupervisorStatus(String? status) {
    switch (status) {
      case 'asignado':
        return 'Asignado';
      case 'en_acompanamiento':
        return 'En acompañamiento';
      case 'verificado':
        return 'Verificado';
      case 'finalizado':
        return 'Finalizado';
      default:
        return 'Pendiente asignación';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Tag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
