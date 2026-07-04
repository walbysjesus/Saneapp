import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../state/app_state.dart';

const _brandGreen = Color(0xFF0C4F31);
const _surface = Color(0xFFF6FAF7);

class SupervisorApplicationStatusScreen extends StatefulWidget {
  const SupervisorApplicationStatusScreen({super.key});

  @override
  State<SupervisorApplicationStatusScreen> createState() =>
      _SupervisorApplicationStatusScreenState();
}

class _SupervisorApplicationStatusScreenState
    extends State<SupervisorApplicationStatusScreen> {
  int _refreshTick = 0;
  bool _refreshing = false;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  void _syncAppState(
    AppState appState,
    Map<String, dynamic> data, {
    required String uid,
    required String email,
  }) {
    final previous = appState.currentUser;
    final roleStr = data['role'] as String? ?? previous?.role ?? 'supervisor';
    final role = roleFromString(roleStr) ?? appState.role ?? UserRole.supervisor;
    final nextUser = UserModel(
      uid: uid,
      email: email,
      fullName: data['fullName'] as String? ?? previous?.fullName,
      photoUrl: data['photoUrl'] as String? ?? previous?.photoUrl,
      companyName: data['companyName'] as String? ?? previous?.companyName,
      role: roleStr,
      city: data['city'] as String? ?? previous?.city,
      entityType: data['entityType'] as String? ?? previous?.entityType,
      clientType: data['clientType'] as String? ?? previous?.clientType,
      status: data['status'] as String? ?? previous?.status,
      clientProfileCompleted:
          data['clientProfileCompleted'] as bool? ??
          previous?.clientProfileCompleted ??
          false,
      supervisorProfileCompleted:
          data['supervisorProfileCompleted'] as bool? ??
          previous?.supervisorProfileCompleted ??
          false,
      supervisorAssessmentPassed:
          data['supervisorAssessmentPassed'] as bool? ??
          previous?.supervisorAssessmentPassed ??
          false,
      supervisorAssessmentScore:
          (data['supervisorAssessmentScore'] as num?)?.toInt() ??
          previous?.supervisorAssessmentScore,
      verificationStatus: previous?.verificationStatus,
      verifiedAt: previous?.verifiedAt,
      completedServiceIds: previous?.completedServiceIds ?? const [],
      ofreceEmergencias24h:
          data['ofreceEmergencias24h'] as bool? ?? previous?.ofreceEmergencias24h,
    );

    final changed = previous == null ||
        previous.uid != nextUser.uid ||
        previous.email != nextUser.email ||
        previous.status != nextUser.status ||
        previous.role != nextUser.role ||
        previous.supervisorProfileCompleted !=
            nextUser.supervisorProfileCompleted ||
        previous.supervisorAssessmentPassed !=
            nextUser.supervisorAssessmentPassed ||
        previous.supervisorAssessmentScore !=
            nextUser.supervisorAssessmentScore;

    if (changed) {
      appState.setUser(nextUser, role);
    }
  }

  Future<Map<String, dynamic>> _loadUserFromServer(
    AppState appState, {
    bool forceServer = false,
  }) async {
    if (_firebaseReady) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Usuario no autenticado');
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(GetOptions(
            source: forceServer ? Source.server : Source.serverAndCache,
          ));
      final data = snapshot.data() ?? <String, dynamic>{};
      _syncAppState(
        appState,
        data,
        uid: user.uid,
        email: user.email ?? appState.currentUser?.email ?? '',
      );
      return data;
    }

    final currentUser = appState.currentUser;
    if (currentUser == null) {
      throw StateError('Usuario no autenticado');
    }

    return _fallbackUserData(appState);
  }

  Map<String, dynamic> _fallbackUserData(AppState appState) {
    final currentUser = appState.currentUser;
    if (currentUser == null) {
      return <String, dynamic>{};
    }

    return <String, dynamic>{
      'status': currentUser.status,
      'supervisorProfileCompleted': currentUser.supervisorProfileCompleted,
      'supervisorAssessmentPassed': currentUser.supervisorAssessmentPassed,
      'supervisorAssessmentScore': currentUser.supervisorAssessmentScore,
    };
  }

  Future<void> _refreshStatus(AppState appState) async {
    setState(() {
      _refreshing = true;
    });

    try {
      final data = await _loadUserFromServer(appState, forceServer: true);
      if (!mounted) {
        return;
      }
      setState(() {
        _refreshTick++;
      });
      final status = data['status'] as String? ?? 'pending_review';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_buildRefreshMessage(status))),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible consultar el estado. Revisa tu conexión con Firebase.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  String _buildRefreshMessage(String status) {
    switch (status) {
      case 'active':
        return 'Estado actualizado desde servidor: aprobado.';
      case 'prequalified':
        return 'Estado actualizado desde servidor: perfil precalificado. Entrando al panel.';
      case 'requires_review':
        return 'Estado actualizado desde servidor: requiere validación adicional.';
      case 'rejected':
        return 'Estado actualizado desde servidor: rechazado.';
      case 'pending_review':
        return 'El servidor sigue reportando pending_review para este UID.';
      default:
        return 'Estado actualizado desde servidor: $status.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Estado de tu postulación'),
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
      ),
      body: _firebaseReady
          ? _LiveStatusView(
              appState: appState,
              onData: (data, uid, email) => _syncAppState(
                appState,
                data,
                uid: uid,
                email: email,
              ),
              refreshTick: _refreshTick,
              onRefresh: () => _refreshStatus(appState),
              refreshing: _refreshing,
            )
          : _FallbackStatusView(
              data: _fallbackUserData(appState),
              onRefresh: () => _refreshStatus(appState),
              refreshing: _refreshing,
            ),
    );
  }
}

class _LiveStatusView extends StatelessWidget {
  const _LiveStatusView({
    required this.appState,
    required this.onData,
    required this.refreshTick,
    required this.onRefresh,
    required this.refreshing,
  });

  final AppState appState;
  final void Function(Map<String, dynamic> data, String uid, String email) onData;
  final int refreshTick;
  final Future<void> Function() onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _StatusScaffold(
        icon: Icons.error_outline,
        title: 'No se pudo cargar tu solicitud',
        message: 'Usuario no autenticado.',
        actions: [
          _StatusAction(label: 'Actualizar estado', onPressed: onRefresh),
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      key: ValueKey('supervisor-status-$refreshTick'),
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _StatusScaffold(
            icon: Icons.cloud_off_outlined,
            title: 'Sin conexión con la plataforma',
            message:
                'No fue posible consultar tu estado en tiempo real. Verifica tu conexión y vuelve a intentarlo.',
            actions: [
              _StatusAction(label: 'Actualizar estado', onPressed: onRefresh),
            ],
          );
        }

        final data = snapshot.data?.data() ?? <String, dynamic>{};
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          onData(data, user.uid, user.email ?? appState.currentUser?.email ?? '');
        });
        return _SupervisorStatusContent(
          data: data,
          userId: user.uid,
          sourceLabel: snapshot.data?.metadata.isFromCache == true
              ? 'cache'
              : 'server',
          onRefresh: onRefresh,
          refreshing: refreshing,
        );
      },
    );
  }
}

class _FallbackStatusView extends StatelessWidget {
  const _FallbackStatusView({
    required this.data,
    required this.onRefresh,
    required this.refreshing,
  });

  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    return _SupervisorStatusContent(
      data: data,
      userId: context.read<AppState>().currentUser?.uid ?? 'sin_uid',
      sourceLabel: 'local',
      onRefresh: onRefresh,
      refreshing: refreshing,
    );
  }
}

class _SupervisorStatusContent extends StatelessWidget {
  const _SupervisorStatusContent({
    required this.data,
    required this.userId,
    required this.sourceLabel,
    required this.onRefresh,
    required this.refreshing,
  });

  final Map<String, dynamic> data;
  final String userId;
  final String sourceLabel;
  final Future<void> Function() onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending_review';
    final completed = data['supervisorProfileCompleted'] == true;
    final passed = data['supervisorAssessmentPassed'] == true;
    final score = (data['supervisorAssessmentScore'] as num?)?.toInt();
    final eligibilityScore =
      (data['supervisorEligibilityScore'] as num?)?.toInt();
    final passedChecks =
      (data['supervisorEligibilityPassedChecks'] as num?)?.toInt();
    final totalChecks =
      (data['supervisorEligibilityTotalChecks'] as num?)?.toInt();
    final eligibilitySummary = data['supervisorEligibilitySummary'] as String?;
    final eligibilityReasons =
      (data['supervisorEligibilityReasons'] as List?)
        ?.whereType<String>()
        .toList() ??
      const <String>[];
    final rejectionReason = data['supervisorRejectionReason'] as String?;
    final reviewedAt = data['supervisorReviewedAt'];

    if (!completed) {
      return _StatusScaffold(
        icon: Icons.assignment_late_outlined,
        title: 'Tu perfil operativo está incompleto',
        message:
            'Completa tus datos, certificaciones y evaluación técnica antes de pasar a revisión.',
        diagnostics: _buildDiagnostics(status, completed, sourceLabel),
        actions: [
          _StatusAction(
            label: 'Completar perfil',
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              '/supervisor-profile-setup',
            ),
          ),
          _StatusAction(label: 'Actualizar estado', onPressed: onRefresh),
        ],
      );
    }

    if (status == 'active' || status == 'prequalified') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/supervisor-dashboard');
      });
      return const Center(child: CircularProgressIndicator());
    }

    final title = switch (status) {
      'rejected' => 'Tu postulación requiere ajustes',
      'prequalified' => 'Tu perfil quedó precalificado',
      'requires_review' => 'Tu perfil requiere validación adicional',
      _ => 'Tu postulación está en revisión',
    };
    final message = switch (status) {
      'rejected' =>
        'El equipo de operaciones encontró observaciones. Revisa tu información y vuelve a enviarla.',
      'prequalified' =>
        'Tu postulación superó el filtro automático con criterios objetivos de formación, experiencia, disponibilidad y evaluación técnica.',
      'requires_review' =>
        'Tu postulación fue recibida, pero no cumplió todos los criterios automáticos. Revisa los puntos señalados antes de volver a enviarla.',
      _ =>
        'Ya recibimos tu perfil operativo. El sistema validará tu experiencia, formación, evaluación y disponibilidad antes de habilitar el panel operativo.',
    };

    return _StatusScaffold(
      icon: _statusIcon(status),
      title: title,
      message: message,
      score: score,
      passed: passed,
      eligibilityScore: eligibilityScore,
      passedChecks: passedChecks,
      totalChecks: totalChecks,
      eligibilitySummary: eligibilitySummary,
      eligibilityReasons: eligibilityReasons,
      rejectionReason: rejectionReason,
      reviewedAt: reviewedAt is Timestamp ? reviewedAt : null,
      warningMessage: status == 'pending_review' && sourceLabel == 'server'
          ? 'Firebase aún tiene esta postulación en pending_review para el UID mostrado abajo. Esto indica que todavía no existe una clasificación automática persistida para este registro.'
          : status == 'requires_review' && eligibilityReasons.isNotEmpty
          ? 'Corrige los criterios observados y vuelve a enviar tu perfil para recalcular la evaluación automática.'
          : null,
      diagnostics: _buildDiagnostics(status, completed, sourceLabel),
      refreshing: refreshing,
      actions: [
        if (status == 'rejected')
          _StatusAction(
            label: 'Corregir perfil',
            onPressed: () => Navigator.pushReplacementNamed(
              context,
              '/supervisor-profile-setup',
            ),
          ),
        _StatusAction(label: 'Actualizar estado', onPressed: onRefresh),
      ],
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'rejected':
        return Icons.cancel_outlined;
      case 'prequalified':
        return Icons.verified_outlined;
      case 'requires_review':
        return Icons.rule_folder_outlined;
      default:
        return Icons.hourglass_top;
    }
  }

  String _buildDiagnostics(String status, bool completed, String sourceLabel) {
    return 'UID: $userId\nEstado leído: $status\nPerfil completo: ${completed ? 'sí' : 'no'}\nOrigen: $sourceLabel';
  }
}

class _StatusScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final int? score;
  final bool? passed;
  final int? eligibilityScore;
  final int? passedChecks;
  final int? totalChecks;
  final String? eligibilitySummary;
  final List<String> eligibilityReasons;
  final String? rejectionReason;
  final Timestamp? reviewedAt;
  final String? warningMessage;
  final String? diagnostics;
  final bool refreshing;
  final List<_StatusAction> actions;

  const _StatusScaffold({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    this.score,
    this.passed,
    this.eligibilityScore,
    this.passedChecks,
    this.totalChecks,
    this.eligibilitySummary,
    this.eligibilityReasons = const <String>[],
    this.rejectionReason,
    this.reviewedAt,
    this.warningMessage,
    this.diagnostics,
    this.refreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 56, color: _brandGreen),
                              const Spacer(),
                              if (refreshing)
                                const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(message),
                          if (score != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Puntaje técnico: $score/100 ${passed == true ? '(aprobado)' : '(pendiente)'}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                          if (eligibilityScore != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Resultado automático: $eligibilityScore/100 ${passedChecks != null && totalChecks != null ? '($passedChecks/$totalChecks criterios)' : ''}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                          if (eligibilitySummary != null && eligibilitySummary!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6F1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFD5E5DA)),
                              ),
                              child: Text(
                                eligibilitySummary!,
                                style: const TextStyle(
                                  color: Color(0xFF234B33),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (eligibilityReasons.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F4EC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE8D8B6)),
                              ),
                              child: Text(
                                'Criterios pendientes:\n${eligibilityReasons.map((reason) => '• $reason').join('\n')}',
                                style: const TextStyle(
                                  color: Color(0xFF6B5120),
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                          if (reviewedAt != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Última revisión: ${_formatTimestamp(reviewedAt!)}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ],
                          if (rejectionReason != null && rejectionReason!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDECE9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'Observación del equipo: $rejectionReason',
                                style: const TextStyle(
                                  color: Color(0xFFB83A2F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (warningMessage != null && warningMessage!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7E6),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFF0D28B)),
                              ),
                              child: Text(
                                warningMessage!,
                                style: const TextStyle(
                                  color: Color(0xFF8A5A00),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (diagnostics != null && diagnostics!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4F1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFD7E3DB)),
                              ),
                              child: Text(
                                diagnostics!,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: actions
                                .map(
                                  (action) => ElevatedButton(
                                    onPressed: action.onPressed,
                                    child: Text(action.label),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _StatusAction {
  final String label;
  final Future<void> Function() onPressed;

  const _StatusAction({required this.label, required this.onPressed});
}
