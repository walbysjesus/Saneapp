import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/role_guard.dart';
import '../../state/app_state.dart';
import 'supervisor_acta_page.dart';
import 'supervisor_supervision_workbench_page.dart';

class SupervisorDashboardPage extends StatelessWidget {
  const SupervisorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      requiredRole: UserRole.supervisor,
      child: _SupervisorDashboardContent(),
    );
  }
}

class _SupervisorDashboardContent extends StatelessWidget {
  const _SupervisorDashboardContent();

  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);
  static const _brandSand = Color(0xFFF4F7F2);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final firebaseReady = Firebase.apps.isNotEmpty;
    final firebaseUser = firebaseReady
        ? FirebaseAuth.instance.currentUser
        : null;
    final fallbackUser = appState.currentUser;
    final userId = firebaseUser?.uid ?? fallbackUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }

    if (!firebaseReady) {
      final status = fallbackUser?.status ?? 'pending_review';
      final profileCompleted = fallbackUser?.supervisorProfileCompleted == true;
      final canAccess = status == 'active' || status == 'prequalified';
      if (!canAccess || !profileCompleted) {
        return _LockedSupervisorView(profileCompleted: profileCompleted);
      }
      return const Scaffold(
        backgroundColor: _brandSand,
        body: SafeArea(
          child: Center(child: Text('No tienes servicios asignados.')),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final userData = userSnapshot.data?.data() ?? <String, dynamic>{};
        final status = userData['status'] as String? ?? 'pending_review';
        final profileCompleted = userData['supervisorProfileCompleted'] == true;
        final canAccess = status == 'active' || status == 'prequalified';
        if (!canAccess || !profileCompleted) {
          return _LockedSupervisorView(profileCompleted: profileCompleted);
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('solicitudes')
              .where('supervisorId', isEqualTo: userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final solicitudes = snapshot.data?.docs ?? const [];
            final metrics = _SupervisorMetrics.fromSolicitudes(solicitudes);

            return Scaffold(
              backgroundColor: _brandSand,
              drawer: _SupervisorDrawer(
                userName:
                    userData['fullName']?.toString() ?? 'Supervisor SaneApp',
                userEmail:
                    firebaseUser?.email ?? fallbackUser?.email ?? 'Sin correo',
              ),
              appBar: AppBar(
                backgroundColor: _brandGreen,
                foregroundColor: Colors.white,
                title: const Text('Panel de Supervisión'),
                actions: [
                  IconButton(
                    tooltip: 'Soporte operativo',
                    onPressed: () => Navigator.of(context).pushNamed('/support'),
                    icon: const Icon(Icons.support_agent_outlined),
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  _SupervisorHero(
                    name:
                        userData['fullName']?.toString() ??
                        'Supervisor SaneApp',
                    status: status,
                    metrics: metrics,
                  ),
                  const SizedBox(height: 18),
                  _SupervisorMetricsGrid(metrics: metrics),
                  const SizedBox(height: 22),
                  _AgendaSummaryCard(solicitudes: solicitudes),
                  const SizedBox(height: 22),
                  const _SectionHeader(
                    title: 'Frente operativo',
                    subtitle:
                        'Atajos para ejecutar verificaciones, actas y acompañamiento técnico.',
                  ),
                  const SizedBox(height: 12),
                  _SupervisorQuickActions(
                    solicitudes: solicitudes,
                  ),
                  const SizedBox(height: 22),
                  const _SectionHeader(
                    title: 'Prioridades del día',
                    subtitle:
                        'Servicios que requieren intervención, documentación o cierre.',
                  ),
                  const SizedBox(height: 12),
                  _PriorityStrip(metrics: metrics),
                  const SizedBox(height: 22),
                  _OperationalOrdersSection(solicitudes: solicitudes),
                  const SizedBox(height: 22),
                  const _SectionHeader(
                    title: 'Servicios asignados',
                    subtitle:
                        'Vista operativa con estado, documentación y próximos pasos.',
                  ),
                  const SizedBox(height: 12),
                  if (solicitudes.isEmpty)
                    const _EmptyAssignmentsCard()
                  else
                    ...solicitudes.map(
                      (doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _SupervisorAssignmentCard(solicitud: doc),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SupervisorDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;

  const _SupervisorDrawer({
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: _SupervisorDashboardContent._brandGreen,
            ),
            accountName: Text(userName),
            accountEmail: Text(userEmail),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.shield_outlined, color: Colors.white, size: 30),
            ),
          ),
          _DrawerTile(
            icon: Icons.dashboard_customize_outlined,
            label: 'Panel operativo',
            onTap: () => Navigator.of(context).pop(),
          ),
          _DrawerTile(
            icon: Icons.assignment_turned_in_outlined,
            label: 'Órdenes operativas',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/supervisor-orders');
            },
          ),
          _DrawerTile(
            icon: Icons.assignment_outlined,
            label: 'Soporte operativo',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/support');
            },
          ),
          _DrawerTile(
            icon: Icons.settings_outlined,
            label: 'Configuración',
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/settings');
            },
          ),
          const Spacer(),
          _DrawerTile(
            icon: Icons.logout,
            label: 'Cerrar sesión',
            danger: true,
            onTap: () async {
              Navigator.of(context).pop();
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) {
                return;
              }
              context.read<AppState>().clearUser();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFB83A2F) : Colors.black87;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}

class _AgendaSummaryCard extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> solicitudes;

  const _AgendaSummaryCard({required this.solicitudes});

  @override
  Widget build(BuildContext context) {
    final total = solicitudes.length;
    final initial = solicitudes.where((doc) {
      final status = doc.data()['supervisorStatus']?.toString() ??
          'pendiente_verificacion';
      return status == 'pendiente_verificacion';
    }).length;
    final accompaniment = solicitudes.where((doc) {
      final status = doc.data()['supervisorStatus']?.toString() ?? '';
      return status == 'en_acompanamiento';
    }).length;
    final closures = solicitudes.where((doc) {
      final status = doc.data()['supervisorStatus']?.toString() ?? '';
      return status == 'verificado' || status == 'en_acompanamiento';
    }).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agenda operativa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Prioriza visitas iniciales, acompañamientos en campo y cierres con acta final desde una sola vista.',
            style: TextStyle(color: Colors.black54, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AgendaPill(label: '$total órdenes totales'),
              _AgendaPill(label: '$initial verificaciones iniciales'),
              _AgendaPill(label: '$accompaniment en acompañamiento'),
              _AgendaPill(label: '$closures listas para cierre'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AgendaPill extends StatelessWidget {
  final String label;

  const _AgendaPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _SupervisorDashboardContent._brandGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OperationalOrdersSection extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> solicitudes;

  const _OperationalOrdersSection({required this.solicitudes});

  @override
  Widget build(BuildContext context) {
    if (solicitudes.isEmpty) {
      return const SizedBox.shrink();
    }

    final orders = solicitudes.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Órdenes operativas',
          subtitle:
              'Bandeja resumida con el tipo de frente, prioridad operativa y estado de supervisión.',
        ),
        const SizedBox(height: 12),
        ...orders.map((doc) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OperationalOrderTile(solicitud: doc),
            )),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/supervisor-orders'),
            icon: const Icon(Icons.open_in_new_outlined),
            label: const Text('Ver bandeja completa'),
          ),
        ),
      ],
    );
  }
}

class _OperationalOrderTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> solicitud;

  const _OperationalOrderTile({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final data = solicitud.data();
    final title = data['titulo']?.toString() ?? data['service']?.toString() ?? 'Servicio ambiental';
    final city = data['city']?.toString() ?? data['ubicacion']?.toString() ?? 'Sin ciudad';
    final generator = data['generadorNombre']?.toString() ?? 'Generador pendiente';
    final orderType = _orderTypeLabel(data);
    final priority = _priorityLabel(data);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text('Generador: $generator', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(icon: Icons.route_outlined, label: orderType),
              _InfoPill(icon: Icons.place_outlined, label: city),
              _InfoPill(icon: Icons.priority_high_outlined, label: priority),
            ],
          ),
        ],
      ),
    );
  }

  String _orderTypeLabel(Map<String, dynamic> data) {
    final status = data['supervisorStatus']?.toString() ?? 'pendiente_verificacion';
    if (status == 'pendiente_verificacion') {
      return 'Verificación inicial';
    }
    if (status == 'en_acompanamiento') {
      return 'Acompañamiento en ejecución';
    }
    if (status == 'verificado') {
      return 'Cierre documental';
    }
    return 'Seguimiento operativo';
  }

  String _priorityLabel(Map<String, dynamic> data) {
    final urgency = data['serviceUrgency']?.toString().toLowerCase() ?? '';
    if (urgency.contains('alta') || urgency.contains('urgente')) {
      return 'Alta';
    }
    if (urgency.contains('media')) {
      return 'Media';
    }
    return 'Operativa';
  }
}

class _SupervisorHero extends StatelessWidget {
  final String name;
  final String status;
  final _SupervisorMetrics metrics;

  const _SupervisorHero({
    required this.name,
    required this.status,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final statusLabel = status == 'active' ? 'Operativo' : 'En revisión';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            _SupervisorDashboardContent._brandGreen,
            _SupervisorDashboardContent._brandGreenSoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              _HeroPill(label: statusLabel),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coordina verificaciones, soportes técnicos y cierres documentales desde un frente único.',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(label: '${metrics.assigned} asignaciones'),
              _HeroPill(label: '${metrics.pendingVerification} por verificar'),
              _HeroPill(label: '${metrics.workbenchReady} con soporte técnico'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupervisorMetricsGrid extends StatelessWidget {
  final _SupervisorMetrics metrics;

  const _SupervisorMetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.18,
      children: [
        _MetricTile(
          icon: Icons.assignment_outlined,
          label: 'Asignadas',
          value: '${metrics.assigned}',
        ),
        _MetricTile(
          icon: Icons.rule_folder_outlined,
          label: 'Actas pendientes',
          value: '${metrics.pendingActa}',
          accentColor: const Color(0xFFC24E00),
        ),
        _MetricTile(
          icon: Icons.handshake_outlined,
          label: 'Acompañamiento',
          value: '${metrics.inAccompaniment}',
        ),
        _MetricTile(
          icon: Icons.task_alt_outlined,
          label: 'Cierres listos',
          value: '${metrics.readyToClose}',
          accentColor: const Color(0xFF3B6EA5),
        ),
      ],
    );
  }
}

class _SupervisorQuickActions extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> solicitudes;

  const _SupervisorQuickActions({required this.solicitudes});

  bool get hasAssignments => solicitudes.isNotEmpty;

  QueryDocumentSnapshot<Map<String, dynamic>>? _findFirstByStatuses(
    List<String> statuses,
  ) {
    for (final solicitud in solicitudes) {
      final status =
          solicitud.data()['supervisorStatus']?.toString() ??
          'pendiente_verificacion';
      if (statuses.contains(status)) {
        return solicitud;
      }
    }
    return solicitudes.isNotEmpty ? solicitudes.first : null;
  }

  void _openInitialVerification(BuildContext context) {
    final target = _findFirstByStatuses(const ['pendiente_verificacion']);
    if (target == null) {
      _showNoAssignmentMessage(context, 'No tienes verificaciones iniciales disponibles.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupervisorActaPage(
          solicitudId: target.id,
          esActaFinal: false,
        ),
      ),
    );
  }

  void _openWorkbench(BuildContext context) {
    final target = _findFirstByStatuses(const [
      'pendiente_verificacion',
      'verificado',
      'en_acompanamiento',
    ]);
    if (target == null) {
      _showNoAssignmentMessage(context, 'No tienes servicios listos para gestionar soporte.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupervisorSupervisionWorkbenchPage(
          solicitudId: target.id,
        ),
      ),
    );
  }

  void _openFinalActa(BuildContext context) {
    final target = _findFirstByStatuses(const ['en_acompanamiento']);
    if (target == null) {
      _showNoAssignmentMessage(context, 'No tienes servicios en acompañamiento listos para acta final.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupervisorActaPage(
          solicitudId: target.id,
          esActaFinal: true,
        ),
      ),
    );
  }

  void _showNoAssignmentMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        icon: Icons.fact_check_outlined,
        title: 'Verificaciones',
        subtitle:
            'Abre tus servicios por verificar y ejecuta la visita inicial.',
        enabled: hasAssignments,
        onTap: () => _openInitialVerification(context),
      ),
      _QuickActionData(
        icon: Icons.edit_note_outlined,
        title: 'Workbench técnico',
        subtitle: 'Gestiona ficha técnica, evaluación y evidencias.',
        enabled: hasAssignments,
        onTap: () => _openWorkbench(context),
      ),
      _QuickActionData(
        icon: Icons.assignment_turned_in_outlined,
        title: 'Actas finales',
        subtitle: 'Documenta cierres y deja trazabilidad completa.',
        enabled: hasAssignments,
        onTap: () => _openFinalActa(context),
      ),
      _QuickActionData(
        icon: Icons.support_agent_outlined,
        title: 'Soporte operativo',
        subtitle: 'Eleva incidencias o coordina ayuda interna.',
        enabled: true,
        onTap: () => Navigator.of(context).pushNamed('/support'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: action.enabled ? action.onTap : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFDCE7DF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    action.icon,
                    color: action.enabled
                        ? _SupervisorDashboardContent._brandGreenSoft
                        : Colors.black26,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    action.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      action.subtitle,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PriorityStrip extends StatelessWidget {
  final _SupervisorMetrics metrics;

  const _PriorityStrip({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = [
      _PriorityData(
        label: 'Verificaciones iniciales',
        value: '${metrics.pendingVerification}',
        accentColor: const Color(0xFFC24E00),
      ),
      _PriorityData(
        label: 'Soportes por completar',
        value: '${metrics.missingWorkbench}',
        accentColor: _SupervisorDashboardContent._brandGreenSoft,
      ),
      _PriorityData(
        label: 'Listas para cierre',
        value: '${metrics.readyToClose}',
        accentColor: const Color(0xFF3B6EA5),
      ),
    ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: item == items.last ? 0 : 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFDCE7DF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: item.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SupervisorAssignmentCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> solicitud;

  const _SupervisorAssignmentCard({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    final data = solicitud.data();
    final tipoServicio = data['service']?.toString() ?? '-';
    final ubicacion = data['ubicacion']?.toString() ?? '-';
    final generador = data['generadorNombre']?.toString() ?? '-';
    final orderCode = data['supervisorOrderCode']?.toString();
    final supervisorStatus =
        data['supervisorStatus']?.toString() ?? 'pendiente_verificacion';
    final fechaProgramada = data['fecha']?.toString() ?? '-';
    final hasTechnicalSheet =
        data['technicalSurveySheet'] is Map ||
        data['prequoteTechnicalSurveyRequired'] == true;
    final hasQualityEvaluation =
        data['providerQualityEvaluation'] is Map ||
        data['providerQualityEvaluationRequired'] == true;
    final cardState = _AssignmentState.fromRaw(supervisorStatus);

    VoidCallback? primaryAction;
    String primaryLabel = '';

    if (supervisorStatus == 'pendiente_verificacion') {
      primaryLabel = 'Realizar verificación inicial';
      primaryAction = () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SupervisorActaPage(
              solicitudId: solicitud.id,
              esActaFinal: false,
            ),
          ),
        );
      };
    } else if (supervisorStatus == 'verificado') {
      primaryLabel = 'Iniciar acompañamiento';
      primaryAction = () =>
          _cambiarEstado(context, solicitud.id, 'en_acompanamiento');
    } else if (supervisorStatus == 'en_acompanamiento') {
      primaryLabel = 'Finalizar supervisión';
      primaryAction = () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SupervisorActaPage(
              solicitudId: solicitud.id,
              esActaFinal: true,
            ),
          ),
        );
      };
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipoServicio,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (orderCode != null && orderCode.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Orden: $orderCode',
                              style: const TextStyle(
                                color: Color(0xFF0C4F31),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copiar numero de orden',
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: orderCode),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Numero de orden copiado.'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.copy_outlined, size: 18),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Generador: $generador',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              _StatusBadge(state: cardState),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(icon: Icons.location_on_outlined, label: ubicacion),
              _InfoPill(
                icon: Icons.calendar_today_outlined,
                label: fechaProgramada,
              ),
              if (orderCode != null && orderCode.isNotEmpty)
                _InfoPill(
                  icon: Icons.tag_outlined,
                  label: orderCode,
                ),
              _InfoPill(
                icon: Icons.inventory_2_outlined,
                label: hasTechnicalSheet || hasQualityEvaluation
                    ? 'Soporte habilitado'
                    : 'Sin soporte cargado',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBF9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                _TimelineRow(
                  label: 'Verificación inicial',
                  done: supervisorStatus != 'pendiente_verificacion',
                ),
                _TimelineRow(
                  label: 'Soporte técnico',
                  done: hasTechnicalSheet || hasQualityEvaluation,
                ),
                _TimelineRow(
                  label: 'Cierre y acta final',
                  done: supervisorStatus == 'finalizado',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (primaryAction != null)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _SupervisorDashboardContent._brandGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: primaryAction,
                    child: Text(primaryLabel),
                  ),
                ),
              if (primaryAction != null) const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _SupervisorDashboardContent._brandGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFBFD7C7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SupervisorSupervisionWorkbenchPage(
                          solicitudId: solicitud.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note_outlined),
                  label: const Text('Gestionar soporte'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarEstado(
    BuildContext context,
    String solicitudId,
    String nuevoEstado,
  ) async {
    await FirebaseFirestore.instance
        .collection('solicitudes')
        .doc(solicitudId)
        .update({
          'supervisorStatus': nuevoEstado,
          'supervisorStatusUpdatedAt': FieldValue.serverTimestamp(),
        });
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Estado actualizado.')));
    }
  }
}

class _LockedSupervisorView extends StatelessWidget {
  final bool profileCompleted;

  const _LockedSupervisorView({required this.profileCompleted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SupervisorDashboardContent._brandSand,
      appBar: AppBar(
        backgroundColor: _SupervisorDashboardContent._brandGreen,
        foregroundColor: Colors.white,
        title: const Text('Panel de Supervisión'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFDCE7DF)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_clock,
                    size: 42,
                    color: Color(0xFFC24E00),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tu acceso operativo aún no está habilitado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Debes completar tu postulación y quedar aprobado por SaneApp antes de operar como supervisor.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _SupervisorDashboardContent._brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      profileCompleted
                          ? '/supervisor-application-status'
                          : '/supervisor-profile-setup',
                    );
                  },
                  child: Text(
                    profileCompleted
                        ? 'Ver estado de postulación'
                        : 'Completar postulación',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor = _SupervisorDashboardContent._brandGreenSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _EmptyAssignmentsCard extends StatelessWidget {
  const _EmptyAssignmentsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: const Column(
        children: [
          Icon(Icons.assignment_late_outlined, size: 42, color: Colors.black38),
          SizedBox(height: 12),
          Text(
            'No tienes servicios asignados.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Cuando recibas una nueva asignación, aparecerá aquí con sus prioridades y soportes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _AssignmentState state;

  const _StatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: state.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        state.label,
        style: TextStyle(color: state.foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final bool done;

  const _TimelineRow({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done
                ? _SupervisorDashboardContent._brandGreenSoft
                : Colors.black38,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });
}

class _PriorityData {
  final String label;
  final String value;
  final Color accentColor;

  const _PriorityData({
    required this.label,
    required this.value,
    required this.accentColor,
  });
}

class _SupervisorMetrics {
  final int assigned;
  final int pendingVerification;
  final int inAccompaniment;
  final int pendingActa;
  final int readyToClose;
  final int workbenchReady;
  final int missingWorkbench;

  const _SupervisorMetrics({
    required this.assigned,
    required this.pendingVerification,
    required this.inAccompaniment,
    required this.pendingActa,
    required this.readyToClose,
    required this.workbenchReady,
    required this.missingWorkbench,
  });

  factory _SupervisorMetrics.fromSolicitudes(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> solicitudes,
  ) {
    var pendingVerification = 0;
    var inAccompaniment = 0;
    var pendingActa = 0;
    var readyToClose = 0;
    var workbenchReady = 0;
    var missingWorkbench = 0;

    for (final doc in solicitudes) {
      final data = doc.data();
      final status =
          data['supervisorStatus']?.toString() ?? 'pendiente_verificacion';
      final hasTechnicalSheet =
          data['technicalSurveySheet'] is Map ||
          data['prequoteTechnicalSurveyRequired'] == true;
      final hasQualityEvaluation =
          data['providerQualityEvaluation'] is Map ||
          data['providerQualityEvaluationRequired'] == true;
      final hasWorkbench = hasTechnicalSheet || hasQualityEvaluation;

      if (status == 'pendiente_verificacion') {
        pendingVerification++;
        pendingActa++;
      }
      if (status == 'en_acompanamiento') {
        inAccompaniment++;
        pendingActa++;
      }
      if (status == 'verificado' || status == 'en_acompanamiento') {
        readyToClose++;
      }
      if (hasWorkbench) {
        workbenchReady++;
      } else {
        missingWorkbench++;
      }
    }

    return _SupervisorMetrics(
      assigned: solicitudes.length,
      pendingVerification: pendingVerification,
      inAccompaniment: inAccompaniment,
      pendingActa: pendingActa,
      readyToClose: readyToClose,
      workbenchReady: workbenchReady,
      missingWorkbench: missingWorkbench,
    );
  }
}

class _AssignmentState {
  final String label;
  final Color foreground;
  final Color background;

  const _AssignmentState({
    required this.label,
    required this.foreground,
    required this.background,
  });

  factory _AssignmentState.fromRaw(String raw) {
    switch (raw) {
      case 'verificado':
        return const _AssignmentState(
          label: 'Verificado',
          foreground: Color(0xFF1D6B45),
          background: Color(0xFFE7F4EB),
        );
      case 'en_acompanamiento':
        return const _AssignmentState(
          label: 'En acompañamiento',
          foreground: Color(0xFF3B6EA5),
          background: Color(0xFFEAF1FB),
        );
      case 'finalizado':
        return const _AssignmentState(
          label: 'Finalizado',
          foreground: Color(0xFF1D6B45),
          background: Color(0xFFE7F4EB),
        );
      default:
        return const _AssignmentState(
          label: 'Pendiente verificación',
          foreground: Color(0xFFC24E00),
          background: Color(0xFFFFF1E6),
        );
    }
  }
}
