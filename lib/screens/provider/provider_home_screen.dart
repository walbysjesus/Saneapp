import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../features/chat/transaction_chat_page.dart';
import '../../features/generador/solicitud_detalle_page.dart';
import '../../features/provider/provider_profile_status.dart';
import '../../services/commercial_guardrails_service.dart';
import '../../services/commercial_timeline_service.dart';
import '../../services/provider_commercial_reputation_service.dart';
import '../../services/storage_service.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No autenticado.')));
    }

    const profileStatusService = ProviderProfileStatusService();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF163828),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu_rounded),
          tooltip: 'Abrir panel',
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel del proveedor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF163828),
              ),
            ),
            Text(
              'Ventas, operación y caja en una sola vista',
              style: TextStyle(fontSize: 12, color: Color(0xFF5E6B64)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/notificaciones'),
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notificaciones',
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/perfil_proveedor'),
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Perfil',
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: _ProviderDashboardDrawer(onSignOut: () => _signOut(context)),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FBF8), Color(0xFFF1F5F0)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              const Positioned(
                top: -110,
                right: -40,
                child: _GlowOrb(
                  size: 230,
                  colors: [Color(0x3342A06C), Color(0x1142A06C)],
                ),
              ),
              const Positioned(
                top: 180,
                left: -70,
                child: _GlowOrb(
                  size: 190,
                  colors: [Color(0x1A0C4F31), Color(0x000C4F31)],
                ),
              ),
              StreamBuilder<ProviderProfileStatus>(
                stream: profileStatusService.watchCurrentUserStatus(),
                builder: (context, snapshot) {
                  final status =
                      snapshot.data ??
                      const ProviderProfileStatus(
                        isAuthenticated: true,
                        isProfileComplete: false,
                        hasDocuments: false,
                        accountStatus: 'pending_documents',
                        completionPercent: 0,
                      );

                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('providers')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, providerSnapshot) {
                      final providerData = providerSnapshot.data?.data();
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 1080;
                          final leftColumn = [
                            _ProviderHero(
                              status: status,
                              providerData: providerData,
                              user: user,
                            ),
                            const SizedBox(height: 22),
                            const _SectionHeader(
                              title: 'Expedientes premium',
                              subtitle:
                                  'Tu tablero operativo de SLA, caja y próximos pasos por negocio.',
                            ),
                            const SizedBox(height: 12),
                            _PremiumDossierCockpit(userId: user.uid),
                            const SizedBox(height: 22),
                            const _SectionHeader(
                              title: 'Qué atender ahora',
                              subtitle:
                                  'Prioridades accionables para no perder ritmo comercial.',
                            ),
                            const SizedBox(height: 12),
                            _PriorityPanel(
                              userId: user.uid,
                              status: status,
                              providerData: providerData,
                            ),
                            const SizedBox(height: 22),
                            const _SectionHeader(
                              title: 'SLA y reputación',
                              subtitle:
                                  'Señales accionables para no perder adjudicaciones ni ranking premium.',
                            ),
                            const SizedBox(height: 12),
                            _ProviderSlaBoard(userId: user.uid),
                            const SizedBox(height: 12),
                            _ProviderReputationCoach(
                              userId: user.uid,
                              providerData: providerData,
                            ),
                            const SizedBox(height: 22),
                            const _SectionHeader(
                              title: 'Radar comercial',
                              subtitle:
                                  'Lectura rápida de oportunidades, conversión y caja del mes.',
                            ),
                            const SizedBox(height: 12),
                            _MetricsGrid(userId: user.uid),
                            const SizedBox(height: 22),
                            const _SectionHeader(
                              title: 'Oportunidades para ti hoy',
                              subtitle:
                                  'Solicitudes recientes alineadas con tu operación y portafolio.',
                            ),
                            const SizedBox(height: 12),
                            _OpportunityRadar(userId: user.uid),
                            const SizedBox(height: 22),
                            const _SectionHeader(
                              title: 'Cartera recurrente',
                              subtitle:
                                  'Clientes y negocios liberados listos para recompra o reactivación comercial.',
                            ),
                            const SizedBox(height: 12),
                            _RepurchaseAccountsRadar(userId: user.uid),
                            const SizedBox(height: 22),
                            const _SectionHeader(
                              title: 'Acciones clave',
                              subtitle:
                                  'Gestiona tu operación comercial y operativa desde un solo panel.',
                            ),
                            const SizedBox(height: 12),
                            _QuickActions(status: status),
                            const SizedBox(height: 22),
                          ];
                          final rightColumn = [
                            const _SectionHeader(
                              title: 'Soportes y cumplimiento',
                              subtitle:
                                  'Adjunta soportes del proveedor al mismo negocio sin salir del flujo SaneApp.',
                            ),
                            const SizedBox(height: 12),
                            _ProviderSupportCenter(userId: user.uid),
                            const SizedBox(height: 22),
                            const _SectionHeader(
                              title: 'Analítica premium',
                              subtitle:
                                  'Conversión, disputas y foco comercial por categoría y subcategoría.',
                            ),
                            const SizedBox(height: 12),
                            _ProviderPremiumAnalytics(
                              userId: user.uid,
                              providerData: providerData,
                            ),
                            const SizedBox(height: 22),
                            const _SectionHeader(
                              title: 'Últimos movimientos',
                              subtitle:
                                  'Señales recientes del negocio para reaccionar rápido.',
                            ),
                            const SizedBox(height: 12),
                            _RecentActivityPanel(userId: user.uid),
                            const SizedBox(height: 22),
                            const _SectionHeader(
                              title: 'Checklist operativo',
                              subtitle:
                                  'Tu progreso como proveedor dentro del marketplace.',
                            ),
                            const SizedBox(height: 12),
                            _ProviderChecklist(status: status),
                          ];

                          if (!isWide) {
                            return ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                              children: [...leftColumn, ...rightColumn],
                            );
                          }

                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 8,
                                  child: Column(children: leftColumn),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 5,
                                  child: Column(children: rightColumn),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderHero extends StatelessWidget {
  final ProviderProfileStatus status;
  final Map<String, dynamic>? providerData;
  final User user;

  const _ProviderHero({
    required this.status,
    required this.providerData,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final companyName =
        (providerData?['companyName'] as String?)?.trim().isNotEmpty == true
        ? (providerData?['companyName'] as String).trim()
        : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Proveedor SaneApp');
    final accountTone = _accountTone(status.accountStatus);
    final blockers = <String>[
      if (!status.hasDocuments) 'Documentación pendiente',
      if (!status.isProfileComplete) 'Activación de cuenta en proceso',
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3423), Color(0xFF0F5A39), Color(0xFF2D8A59)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220C4F31),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $companyName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Estado de cuenta: ${accountTone.label}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
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
                  '${status.completionPercent}% listo',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            status.detail,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroSignalChip(
                icon: Icons.verified_user_outlined,
                label: accountTone.label,
                color: accountTone.color,
              ),
              _HeroSignalChip(
                icon: Icons.track_changes_outlined,
                label: status.headline,
                color: Colors.white,
                isNeutral: true,
              ),
              for (final blocker in blockers)
                _HeroSignalChip(
                  icon: Icons.priority_high_rounded,
                  label: blocker,
                  color: const Color(0xFFFFE6A6),
                  isNeutral: true,
                ),
            ],
          ),
          const SizedBox(height: 18),
          FutureBuilder<_DashboardSnapshot>(
            future: _loadDashboardSnapshot(user.uid),
            builder: (context, snapshot) {
              final data = snapshot.data;
              final businessItems = [
                _HeroBusinessItem(
                  label: 'Oportunidades nuevas',
                  value: '${data?.newOpportunitiesToday ?? 0}',
                ),
                _HeroBusinessItem(
                  label: 'Cotizaciones pendientes',
                  value: '${data?.pendingQuotes ?? 0}',
                ),
                _HeroBusinessItem(
                  label: 'Pagos por liberar',
                  value: '${data?.paymentsToRelease ?? 0}',
                ),
              ];
              return LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 640;
                  final cardWidth = compact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 20) / 3;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: businessItems
                        .map(
                          (item) => SizedBox(
                            width: cardWidth,
                            child: _HeroBusinessCard(item: item),
                          ),
                        )
                        .toList(),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final primaryButton = FilledButton.icon(
                onPressed: () => Navigator.pushNamed(
                  context,
                  status.canOperate
                      ? '/servicios_disponibles'
                      : '/perfil_proveedor',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0A3423),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.travel_explore_rounded),
                label: Text(
                  status.canOperate
                      ? 'Ver oportunidades de hoy'
                      : 'Completar activación',
                ),
              );
              final secondaryButton = OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/mis_cotizaciones'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.34)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.request_quote_outlined),
                label: const Text('Ver cotizaciones'),
              );

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    primaryButton,
                    const SizedBox(height: 10),
                    secondaryButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: primaryButton),
                  const SizedBox(width: 12),
                  secondaryButton,
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: status.completionPercent / 100,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Nivel operativo ${_accountLevel(status.completionPercent)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _AccountTone _accountTone(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('active') || normalized.contains('approved')) {
      return const _AccountTone('Cuenta habilitada', Color(0xFFA6F4C5));
    }
    if (normalized.contains('offline')) {
      return const _AccountTone('Modo contingencia', Color(0xFFFFD9A6));
    }
    return const _AccountTone('Validación en curso', Color(0xFFFFE6A6));
  }

  String _accountLevel(int completionPercent) {
    if (completionPercent >= 100) {
      return 'premium';
    }
    if (completionPercent >= 70) {
      return 'pro';
    }
    return 'base';
  }
}

class _ProviderDashboardDrawer extends StatelessWidget {
  final VoidCallback onSignOut;

  const _ProviderDashboardDrawer({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Control global',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Atajos operativos, soporte y configuración de la cuenta.',
                    style: TextStyle(color: Color(0xFF66746C), height: 1.35),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerActionTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Perfil del proveedor',
                    route: '/perfil_proveedor',
                  ),
                  _DrawerActionTile(
                    icon: Icons.folder_outlined,
                    label: 'Documentos',
                    route: '/mis_documentos',
                  ),
                  _DrawerActionTile(
                    icon: Icons.travel_explore_outlined,
                    label: 'Oportunidades',
                    route: '/servicios_disponibles',
                  ),
                  _DrawerActionTile(
                    icon: Icons.request_quote_outlined,
                    label: 'Cotizaciones',
                    route: '/mis_cotizaciones',
                  ),
                  _DrawerActionTile(
                    icon: Icons.settings_outlined,
                    label: 'Configuración',
                    route: '/settings',
                  ),
                  _DrawerActionTile(
                    icon: Icons.support_agent_outlined,
                    label: 'Soporte',
                    route: '/support',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _DrawerActionTile({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}

class _HeroSignalChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isNeutral;

  const _HeroSignalChip({
    required this.icon,
    required this.label,
    required this.color,
    this.isNeutral = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isNeutral ? Colors.white.withValues(alpha: 0.1) : color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isNeutral ? Colors.white : const Color(0xFF093120),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isNeutral ? Colors.white : const Color(0xFF093120),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBusinessCard extends StatelessWidget {
  final _HeroBusinessItem item;

  const _HeroBusinessCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _GlowOrb({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _AccountTone {
  final String label;
  final Color color;

  const _AccountTone(this.label, this.color);
}

class _HeroBusinessItem {
  final String label;
  final String value;

  const _HeroBusinessItem({required this.label, required this.value});
}

class _MetricsGrid extends StatelessWidget {
  final String userId;

  const _MetricsGrid({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardSnapshot>(
      future: _loadDashboardSnapshot(userId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final items = [
          _MetricPresentation(
            icon: Icons.request_quote_outlined,
            label: 'Pendientes de respuesta',
            value: '${data?.pendingQuotes ?? 0}',
            hint: 'Cotizaciones en evaluación',
          ),
          _MetricPresentation(
            icon: Icons.bolt_outlined,
            label: 'Oportunidades nuevas hoy',
            value: '${data?.newOpportunitiesToday ?? 0}',
            hint: 'Solicitudes activas recientes',
          ),
          _MetricPresentation(
            icon: Icons.workspace_premium_outlined,
            label: 'Servicio mejor posicionado',
            value: data?.topServiceName ?? 'Sin portafolio activo',
            hint: '${data?.activeServices ?? 0} servicios activos',
            emphasisText: true,
          ),
          _MetricPresentation(
            icon: Icons.trending_up_outlined,
            label: 'Ingresos del mes',
            value: _currency(data?.monthlyRevenue ?? 0),
            hint: _monthDeltaLabel(
              data?.monthlyRevenue ?? 0,
              data?.previousMonthlyRevenue ?? 0,
            ),
          ),
          _MetricPresentation(
            icon: Icons.task_alt_outlined,
            label: 'Tasa de adjudicación',
            value: '${(data?.awardRate ?? 0).round()}%',
            hint:
                '${data?.awardedQuotes ?? 0} adjudicadas de ${data?.totalQuotes ?? 0}',
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 980
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth >= 620
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: cardWidth,
                      child: _MetricCard(item: item),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricPresentation item;

  const _MetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EEE9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D123524),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: const Color(0xFF1A7A4A)),
          ),
          const SizedBox(height: 26),
          Text(
            item.label,
            style: const TextStyle(
              color: Color(0xFF5C6A62),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: item.emphasisText ? 20 : 28,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF74827B), height: 1.25),
          ),
        ],
      ),
    );
  }
}

class _PriorityPanel extends StatelessWidget {
  final String userId;
  final ProviderProfileStatus status;
  final Map<String, dynamic>? providerData;

  const _PriorityPanel({
    required this.userId,
    required this.status,
    required this.providerData,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardSnapshot>(
      future: _loadDashboardSnapshot(userId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final priorities = <_PriorityItem>[
          if (!status.hasDocuments)
            const _PriorityItem(
              icon: Icons.folder_outlined,
              title: 'Completa la carpeta documental',
              detail: 'Sube y valida los soportes para operar sin fricción.',
              route: '/mis_documentos',
              cta: 'Ir a documentos',
            ),
          if ((data?.pendingQuotes ?? 0) > 0)
            _PriorityItem(
              icon: Icons.request_quote_outlined,
              title: 'Responde tus cotizaciones pendientes',
              detail:
                  'Tienes ${data?.pendingQuotes ?? 0} ofertas en evaluación.',
              route: '/mis_cotizaciones',
              cta: 'Revisar ofertas',
            ),
          if ((data?.newOpportunitiesToday ?? 0) > 0)
            _PriorityItem(
              icon: Icons.bolt_outlined,
              title: 'Atiende oportunidades urgentes',
              detail:
                  'Entraron ${data?.newOpportunitiesToday ?? 0} nuevas hoy para tu radar.',
              route: '/servicios_disponibles',
              cta: 'Abrir marketplace',
            ),
          if ((data?.activeServices ?? 0) == 0)
            const _PriorityItem(
              icon: Icons.add_business_outlined,
              title: 'Publica tu primer servicio',
              detail:
                  'Sin portafolio activo pierdes visibilidad y solicitudes dirigidas.',
              route: '/provider-service-create',
              cta: 'Crear servicio',
            )
          else
            _PriorityItem(
              icon: Icons.storefront_outlined,
              title: 'Refuerza tu servicio líder',
              detail:
                  'Mantén visible ${data?.topServiceName ?? 'tu mejor servicio'} con ajustes comerciales.',
              route: '/provider-my-services',
              cta: 'Ver portafolio',
            ),
        ];

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2F22),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: priorities
                .take(4)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PriorityTile(item: item),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _RecentActivityPanel extends StatelessWidget {
  final String userId;

  const _RecentActivityPanel({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ActivityItem>>(
      future: _loadRecentActivity(userId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <_ActivityItem>[];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5ECE7)),
          ),
          child: items.isEmpty
              ? const Text(
                  'Todavía no hay movimientos recientes visibles para esta cuenta.',
                  style: TextStyle(color: Color(0xFF6C7A72), height: 1.45),
                )
              : Column(
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ActivityRow(item: item),
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }
}

class _PremiumDossierCockpit extends StatelessWidget {
  final String userId;

  const _PremiumDossierCockpit({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ProviderDossierItem>>(
      future: _loadProviderDossiers(userId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <_ProviderDossierItem>[];
        if (items.isEmpty) {
          return _EmptyPanel(
            message:
                'Cuando tengas expedientes dirigidos, pagos en custodia o cierres en curso aparecerán aquí con siguiente acción sugerida.',
          );
        }

        return Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProviderDossierCard(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ProviderDossierCard extends StatelessWidget {
  final _ProviderDossierItem item;

  const _ProviderDossierCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2EAE4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F2E20),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
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
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64736C),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StagePill(label: item.stageLabel, color: item.stageColor),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniTag(label: item.categoryLabel),
              _MiniTag(label: item.paymentLabel),
              _MiniTag(label: item.slaLabel),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DashboardMiniMetric(
                  label: 'Valor estimado',
                  value: item.estimatedValue > 0
                      ? _currency(item.estimatedValue)
                      : 'Por definir',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DashboardMiniMetric(
                  label: 'Último evento',
                  value: item.lastEventLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.nextAction,
            style: const TextStyle(
              color: Color(0xFF0C4F31),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        SolicitudDetallePage(solicitudId: item.requestId),
                  ),
                ),
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Abrir expediente'),
              ),
              if (item.openChat)
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TransactionChatPage(
                        requestId: item.requestId,
                        requestTitle: item.title,
                        generatorId: item.generatorId,
                        providerId: item.providerId,
                        generatorLabel: item.generatorLabel,
                        providerLabel: item.providerLabel,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Abrir chat'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderSupportCenter extends StatefulWidget {
  final String userId;

  const _ProviderSupportCenter({required this.userId});

  @override
  State<_ProviderSupportCenter> createState() => _ProviderSupportCenterState();
}

class _ProviderSupportCenterState extends State<_ProviderSupportCenter> {
  final Set<String> _uploadingIds = <String>{};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('billing_records')
          .where('providerId', isEqualTo: widget.userId)
          .where('documentType', isEqualTo: 'provider_support_document')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final pending =
            docs.where((doc) {
              final status = doc.data()['status']?.toString() ?? '';
              return status == 'en_custodia' || status == 'en_disputa';
            }).toList()..sort((a, b) {
              final aDate =
                  _readDate(a.data(), const ['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bDate =
                  _readDate(b.data(), const ['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });

        if (pending.isEmpty) {
          return _EmptyPanel(
            message:
                'No hay soportes pendientes por adjuntar. Cuando un negocio entre en custodia o disputa, SaneApp te lo pedirá aquí.',
          );
        }

        return Column(
          children: pending.take(4).map((doc) {
            final data = doc.data();
            final requestId = data['requestId']?.toString() ?? '';
            final attachmentCount =
                (data['providerSupportAttachments'] as List?)?.length ?? 0;
            final uploading = _uploadingIds.contains(doc.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE4ECE6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['providerName']?.toString() ??
                                'Soporte proveedor',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        _StagePill(
                          label: data['status']?.toString() ?? 'pendiente',
                          color: const Color(0xFFB77C12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data['category'] ?? 'Sin categoría'}${(data['subcategory']?.toString().trim().isNotEmpty ?? false) ? ' · ${data['subcategory']}' : ''}',
                      style: const TextStyle(color: Color(0xFF68766F)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adjuntos cargados: $attachmentCount',
                      style: const TextStyle(color: Color(0xFF68766F)),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: uploading
                              ? null
                              : () => _uploadSupportDocument(
                                  recordId: doc.id,
                                  requestId: requestId,
                                ),
                          icon: uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file_outlined),
                          label: Text(
                            uploading ? 'Subiendo...' : 'Subir soporte',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: requestId.isEmpty
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SolicitudDetallePage(
                                      solicitudId: requestId,
                                    ),
                                  ),
                                ),
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Ver negocio'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _uploadSupportDocument({
    required String recordId,
    required String requestId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (!mounted || result == null || result.files.single.path == null) {
      return;
    }

    setState(() => _uploadingIds.add(recordId));
    try {
      final file = File(result.files.single.path!);
      final url = await StorageService.uploadProviderDocument(
        file,
        widget.userId,
      );
      if (url == null || url.startsWith('ERROR:')) {
        throw Exception(url ?? 'No se pudo subir el documento.');
      }

      await FirebaseFirestore.instance
          .collection('billing_records')
          .doc(recordId)
          .set({
            'providerSupportAttachments': FieldValue.arrayUnion([
              {
                'url': url,
                'fileName': result.files.single.name,
                'uploadedAt': FieldValue.serverTimestamp(),
                'uploadedBy': widget.userId,
              },
            ]),
            'providerSupportLastUploadedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await CommercialTimelineService.recordEvent(
        requestId: requestId,
        eventType: 'provider_support_uploaded',
        title: 'Soporte del proveedor cargado',
        description:
            'El proveedor adjuntó soporte comercial o tributario ligado al mismo negocio.',
        actorId: widget.userId,
        actorRole: 'proveedor',
        metadata: {
          'billingRecordId': recordId,
          'fileName': result.files.single.name,
        },
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Soporte cargado al expediente comercial.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir el soporte: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingIds.remove(recordId));
      }
    }
  }
}

class _ProviderPremiumAnalytics extends StatelessWidget {
  final String userId;
  final Map<String, dynamic>? providerData;

  const _ProviderPremiumAnalytics({
    required this.userId,
    required this.providerData,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProviderAnalyticsSnapshot>(
      future: _loadProviderAnalytics(userId, providerData),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return _EmptyPanel(
            message:
                'Todavía no hay suficiente histórico para calcular analítica premium del proveedor.',
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5ECE7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _DashboardMiniMetric(
                    label: 'Score comercial',
                    value: data.commercialScore,
                  ),
                  _DashboardMiniMetric(label: 'Tier', value: data.tierLabel),
                  _DashboardMiniMetric(
                    label: 'SLA promedio',
                    value: data.slaLabel,
                  ),
                  _DashboardMiniMetric(
                    label: 'Disputas',
                    value: '${data.disputeCount}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Conversión por categoría',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...data.categoryBreakdown
                  .take(4)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AnalyticsRow(item: item),
                    ),
                  ),
              const SizedBox(height: 12),
              const Text(
                'Subcategorías con más adjudicación',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...data.subcategoryBreakdown
                  .take(4)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AnalyticsRow(item: item),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _ProviderSlaBoard extends StatelessWidget {
  final String userId;

  const _ProviderSlaBoard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProviderSlaSnapshot>(
      future: _loadProviderSlaSnapshot(userId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const SizedBox.shrink();
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5ECE7)),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _DashboardMiniMetric(
                label: 'SLA caliente',
                value: '${data.hotQuotes}',
              ),
              _DashboardMiniMetric(
                label: 'Dirigidas sin responder',
                value: '${data.directedPending}',
              ),
              _DashboardMiniMetric(
                label: 'Urgentes abiertas',
                value: '${data.urgentOpen}',
              ),
              _DashboardMiniMetric(
                label: 'Más vieja abierta',
                value: data.oldestOpenLabel,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProviderReputationCoach extends StatelessWidget {
  final String userId;
  final Map<String, dynamic>? providerData;

  const _ProviderReputationCoach({
    required this.userId,
    required this.providerData,
  });

  @override
  Widget build(BuildContext context) {
    final snapshot = ProviderCommercialReputationService.fromProviderData(
      providerData ?? const <String, dynamic>{},
    );
    final notes = <String>[
      'Tier actual: ${snapshot.tierLabel}.',
      'Tiempo de respuesta promedio: ${snapshot.responseLabel}.',
      'Aceptación comercial: ${snapshot.acceptanceRate.toStringAsFixed(0)}%.',
      if (snapshot.policyViolationCount > 0)
        'Hay ${snapshot.policyViolationCount} eventos de política que castigan tu ranking.',
      if (snapshot.disputeCount > 0)
        'Tienes ${snapshot.disputeCount} disputas que afectan confianza y cierre.',
      if (snapshot.completedServices > 0)
        'Servicios completados: ${snapshot.completedServices}. Usa ese histórico para recompra.',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2F22),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score ${snapshot.formattedScore} · ${snapshot.tierLabel}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFFE4F7EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepurchaseAccountsRadar extends StatelessWidget {
  final String userId;

  const _RepurchaseAccountsRadar({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_RepurchaseAccountItem>>(
      future: _loadRepurchaseAccounts(userId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <_RepurchaseAccountItem>[];
        if (items.isEmpty) {
          return _EmptyPanel(
            message:
                'Cuando tengas liberaciones exitosas, aquí aparecerán cuentas listas para recompra y seguimiento.',
          );
        }

        return Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2EAE4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.accountLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.releasedCount} cierres liberados · ${item.lastRequestTitle}',
                                    style: const TextStyle(
                                      color: Color(0xFF68766F),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _currency(item.releasedGmv),
                              style: const TextStyle(
                                color: Color(0xFF0C4F31),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: item.generatorId.isEmpty
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final queued =
                                        await _queueRepurchaseFollowUp(
                                          providerId: userId,
                                          item: item,
                                        );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          queued
                                              ? 'Reactivación enviada a cartera premium para seguimiento.'
                                              : 'No se pudo registrar la reactivación. Intenta de nuevo.',
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.autorenew_rounded),
                            label: const Text('Solicitar reactivación'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final _AnalyticsBreakdown item;

  const _AnalyticsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.awarded} adjudicadas de ${item.total} · ${item.rate.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Color(0xFF6D7B74)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item.revenue > 0 ? _currency(item.revenue) : 'Sin GMV',
            style: const TextStyle(
              color: Color(0xFF0C4F31),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardMiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _DashboardMiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xFF6E7B74))),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String message;

  const _EmptyPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1EADF)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF6B7972), height: 1.45),
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  final String label;
  final Color color;

  const _StagePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OpportunityRadar extends StatelessWidget {
  final String userId;

  const _OpportunityRadar({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('solicitudes')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        final items = docs
            .where((doc) {
              final data = doc.data();
              final preferredProviderId =
                  data['preferredProviderId']?.toString() ?? '';
              final selectedProviderId =
                  data['selectedProveedorId']?.toString() ?? '';
              final status = data['status']?.toString().toLowerCase() ?? '';
              final matchesProvider =
                  preferredProviderId.isEmpty || preferredProviderId == userId;
              final isOpen =
                  selectedProviderId.isEmpty &&
                  !status.contains('cerr') &&
                  !status.contains('cancel') &&
                  !status.contains('final');
              return matchesProvider && isOpen;
            })
            .take(3)
            .map((doc) => _OpportunityPreviewItem.fromDocument(doc))
            .toList();

        if (items.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBF7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE1EADF)),
            ),
            child: const Text(
              'No hay oportunidades nuevas en este momento. Cuando entren solicitudes compatibles aparecerán aquí primero.',
              style: TextStyle(color: Color(0xFF6B7972), height: 1.45),
            ),
          );
        }

        return Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OpportunityPreviewCard(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _PriorityTile extends StatelessWidget {
  final _PriorityItem item;

  const _PriorityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2C96D),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: const Color(0xFF3A2A00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, item.route),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: const Color(0xFFE4F7EB),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(item.cta),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;

  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: item.tint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(item.icon, color: item.tint),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                item.detail,
                style: const TextStyle(color: Color(0xFF6F7D75), height: 1.3),
              ),
              const SizedBox(height: 4),
              Text(
                _relativeTimeLabel(item.createdAt),
                style: const TextStyle(
                  color: Color(0xFF8B9891),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpportunityPreviewCard extends StatelessWidget {
  final _OpportunityPreviewItem item;

  const _OpportunityPreviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E9E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniTag(label: item.urgency),
              _MiniTag(label: item.serviceLabel),
              _MiniTag(label: item.relativeTime),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            item.summary,
            style: const TextStyle(color: Color(0xFF68766F), height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.city.isEmpty ? 'Cobertura por confirmar' : item.city,
                  style: const TextStyle(
                    color: Color(0xFF50615A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                item.estimatedValue > 0
                    ? _currency(item.estimatedValue)
                    : 'Valor por definir',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/servicios_disponibles'),
              icon: const Icon(Icons.travel_explore_outlined),
              label: const Text('Ver oportunidad completa'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;

  const _MiniTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF51635A),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MetricPresentation {
  final IconData icon;
  final String label;
  final String value;
  final String hint;
  final bool emphasisText;

  const _MetricPresentation({
    required this.icon,
    required this.label,
    required this.value,
    required this.hint,
    this.emphasisText = false,
  });
}

class _PriorityItem {
  final IconData icon;
  final String title;
  final String detail;
  final String route;
  final String cta;

  const _PriorityItem({
    required this.icon,
    required this.title,
    required this.detail,
    required this.route,
    required this.cta,
  });
}

class _ActivityItem {
  final IconData icon;
  final String title;
  final String detail;
  final DateTime createdAt;
  final Color tint;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.detail,
    required this.createdAt,
    required this.tint,
  });
}

class _OpportunityPreviewItem {
  final String title;
  final String summary;
  final String city;
  final String urgency;
  final String serviceLabel;
  final double estimatedValue;
  final DateTime createdAt;

  const _OpportunityPreviewItem({
    required this.title,
    required this.summary,
    required this.city,
    required this.urgency,
    required this.serviceLabel,
    required this.estimatedValue,
    required this.createdAt,
  });

  factory _OpportunityPreviewItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _OpportunityPreviewItem(
      title: data['titulo']?.toString() ?? 'Solicitud sin título',
      summary: data['descripcion']?.toString() ?? 'Sin detalle adicional.',
      city: data['city']?.toString() ?? '',
      urgency: data['serviceUrgency']?.toString() ?? 'Programado',
      serviceLabel:
          data['serviceInterest']?.toString() ??
          data['serviceCategory']?.toString() ??
          'General',
      estimatedValue: (data['estimatedValue'] as num?)?.toDouble() ?? 0,
      createdAt: _readDate(data, const ['createdAt']) ?? DateTime.now(),
    );
  }

  String get relativeTime => _relativeTimeLabel(createdAt);
}

class _DashboardSnapshot {
  final int activeServices;
  final int pendingQuotes;
  final int totalQuotes;
  final int awardedQuotes;
  final int newOpportunitiesToday;
  final int paymentsToRelease;
  final double monthlyRevenue;
  final double previousMonthlyRevenue;
  final double awardRate;
  final String? topServiceName;

  const _DashboardSnapshot({
    required this.activeServices,
    required this.pendingQuotes,
    required this.totalQuotes,
    required this.awardedQuotes,
    required this.newOpportunitiesToday,
    required this.paymentsToRelease,
    required this.monthlyRevenue,
    required this.previousMonthlyRevenue,
    required this.awardRate,
    required this.topServiceName,
  });
}

class _ProviderDossierItem {
  final String requestId;
  final String title;
  final String subtitle;
  final String stageLabel;
  final Color stageColor;
  final String paymentLabel;
  final String slaLabel;
  final String categoryLabel;
  final double estimatedValue;
  final String nextAction;
  final String lastEventLabel;
  final bool openChat;
  final String generatorId;
  final String providerId;
  final String generatorLabel;
  final String providerLabel;
  final DateTime updatedAt;

  const _ProviderDossierItem({
    required this.requestId,
    required this.title,
    required this.subtitle,
    required this.stageLabel,
    required this.stageColor,
    required this.paymentLabel,
    required this.slaLabel,
    required this.categoryLabel,
    required this.estimatedValue,
    required this.nextAction,
    required this.lastEventLabel,
    required this.openChat,
    required this.generatorId,
    required this.providerId,
    required this.generatorLabel,
    required this.providerLabel,
    required this.updatedAt,
  });
}

class _ProviderAnalyticsSnapshot {
  final String commercialScore;
  final String tierLabel;
  final String slaLabel;
  final int disputeCount;
  final List<_AnalyticsBreakdown> categoryBreakdown;
  final List<_AnalyticsBreakdown> subcategoryBreakdown;

  const _ProviderAnalyticsSnapshot({
    required this.commercialScore,
    required this.tierLabel,
    required this.slaLabel,
    required this.disputeCount,
    required this.categoryBreakdown,
    required this.subcategoryBreakdown,
  });
}

class _ProviderSlaSnapshot {
  final int hotQuotes;
  final int directedPending;
  final int urgentOpen;
  final String oldestOpenLabel;

  const _ProviderSlaSnapshot({
    required this.hotQuotes,
    required this.directedPending,
    required this.urgentOpen,
    required this.oldestOpenLabel,
  });
}

class _RepurchaseAccountItem {
  final String accountLabel;
  final String generatorId;
  final String lastRequestId;
  final String lastRequestTitle;
  final int releasedCount;
  final double releasedGmv;
  final DateTime lastReleasedAt;

  const _RepurchaseAccountItem({
    required this.accountLabel,
    required this.generatorId,
    required this.lastRequestId,
    required this.lastRequestTitle,
    required this.releasedCount,
    required this.releasedGmv,
    required this.lastReleasedAt,
  });
}

class _AnalyticsBreakdown {
  final String label;
  final int total;
  final int awarded;
  final double revenue;

  const _AnalyticsBreakdown({
    required this.label,
    required this.total,
    required this.awarded,
    required this.revenue,
  });

  double get rate => total == 0 ? 0 : (awarded / total) * 100;
}

Future<_DashboardSnapshot> _loadDashboardSnapshot(String userId) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final todayStart = DateTime(now.year, now.month, now.day);

    final results = await Future.wait([
      firestore
          .collection('provider_services')
          .where('providerId', isEqualTo: userId)
          .get(),
      firestore
          .collection('ofertas')
          .where('proveedorId', isEqualTo: userId)
          .get(),
      firestore
          .collection('payments')
          .where('proveedorId', isEqualTo: userId)
          .get(),
      firestore
          .collection('solicitudes')
          .orderBy('createdAt', descending: true)
          .limit(80)
          .get(),
    ]);

    final serviceDocs = results[0];
    final offerDocs = results[1];
    final paymentDocs = results[2];
    final requestDocs = results[3];

    final services = serviceDocs.docs.map((doc) => doc.data()).toList();
    final activeServices = services
        .where((item) => item['isActive'] != false)
        .length;
    final topService = services
        .where((item) => item['isActive'] != false)
        .fold<Map<String, dynamic>?>(null, (best, item) {
          final bestDate = best == null
              ? DateTime.fromMillisecondsSinceEpoch(0)
              : _readDate(best, const ['updatedAt', 'createdAt']) ??
                    DateTime.fromMillisecondsSinceEpoch(0);
          final itemDate =
              _readDate(item, const ['updatedAt', 'createdAt']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return itemDate.isAfter(bestDate) ? item : best;
        });

    final offers = offerDocs.docs.map((doc) => doc.data()).toList();
    final totalQuotes = offers.length;
    final pendingQuotes = offers
        .where((item) => item['status']?.toString() == 'evaluacion')
        .length;
    final awardedQuotes = offers
        .where((item) => item['status']?.toString() == 'adjudicada')
        .length;
    final awardRate = totalQuotes == 0
        ? 0.0
        : (awardedQuotes / totalQuotes) * 100;

    final payments = paymentDocs.docs.map((doc) => doc.data()).toList();
    var monthlyRevenue = 0.0;
    var previousMonthlyRevenue = 0.0;
    var paymentsToRelease = 0;
    for (final payment in payments) {
      final paymentStatus =
          payment['paymentStatus']?.toString().toLowerCase() ?? '';
      final amount = (payment['monto'] as num?)?.toDouble() ?? 0;
      final date = _readDate(payment, const [
        'releasedAt',
        'paidAt',
        'createdAt',
      ]);
      if (paymentStatus != 'liberado') {
        paymentsToRelease += 1;
      }
      if (paymentStatus == 'liberado' && date != null) {
        if (!date.isBefore(monthStart)) {
          monthlyRevenue += amount;
        } else if (!date.isBefore(previousMonthStart) &&
            date.isBefore(monthStart)) {
          previousMonthlyRevenue += amount;
        }
      }
    }

    final requests = requestDocs.docs.map((doc) => doc.data()).toList();
    final newOpportunitiesToday = requests.where((item) {
      final preferredProviderId = item['preferredProviderId']?.toString() ?? '';
      final selectedProviderId = item['selectedProveedorId']?.toString() ?? '';
      final status = item['status']?.toString().toLowerCase() ?? '';
      final createdAt = _readDate(item, const ['createdAt']);
      final matchesProvider =
          preferredProviderId.isEmpty || preferredProviderId == userId;
      final isOpen =
          selectedProviderId.isEmpty &&
          !status.contains('cerr') &&
          !status.contains('cancel') &&
          !status.contains('final');
      return matchesProvider &&
          isOpen &&
          createdAt != null &&
          !createdAt.isBefore(todayStart);
    }).length;

    return _DashboardSnapshot(
      activeServices: activeServices,
      pendingQuotes: pendingQuotes,
      totalQuotes: totalQuotes,
      awardedQuotes: awardedQuotes,
      newOpportunitiesToday: newOpportunitiesToday,
      paymentsToRelease: paymentsToRelease,
      monthlyRevenue: monthlyRevenue,
      previousMonthlyRevenue: previousMonthlyRevenue,
      awardRate: awardRate,
      topServiceName: topService?['title']?.toString(),
    );
  } catch (_) {
    return const _DashboardSnapshot(
      activeServices: 0,
      pendingQuotes: 0,
      totalQuotes: 0,
      awardedQuotes: 0,
      newOpportunitiesToday: 0,
      paymentsToRelease: 0,
      monthlyRevenue: 0,
      previousMonthlyRevenue: 0,
      awardRate: 0,
      topServiceName: null,
    );
  }
}

Future<List<_ProviderDossierItem>> _loadProviderDossiers(String userId) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final requestResults = await Future.wait([
      firestore
          .collection('solicitudes')
          .where('preferredProviderId', isEqualTo: userId)
          .limit(20)
          .get(),
      firestore
          .collection('solicitudes')
          .where('selectedProveedorId', isEqualTo: userId)
          .limit(20)
          .get(),
      firestore
          .collection('payments')
          .where('proveedorId', isEqualTo: userId)
          .get(),
    ]);

    final directedRequests = requestResults[0];
    final selectedRequests = requestResults[1];
    final paymentQuery = requestResults[2];
    final requestMap = <String, Map<String, dynamic>>{};
    for (final query in [directedRequests, selectedRequests]) {
      for (final doc in query.docs) {
        requestMap[doc.id] = {...doc.data(), 'id': doc.id};
      }
    }
    final payments = {for (final doc in paymentQuery.docs) doc.id: doc.data()};

    final items = requestMap.entries.map((entry) {
      final data = entry.value;
      final payment = payments[entry.key] ?? const <String, dynamic>{};
      final stage =
          data['commercialFlowStage']?.toString() ?? 'open_marketplace';
      final paymentStatus =
          payment['paymentStatus']?.toString() ??
          data['paymentStatus']?.toString() ??
          'sin_pago';
      final createdAt = _readDate(data, const ['createdAt']) ?? DateTime.now();
      final updatedAt =
          _readDate(data, const [
            'commercialFlowUpdatedAt',
            'updatedAt',
            'createdAt',
          ]) ??
          createdAt;
      final serviceCategory =
          data['serviceCategory']?.toString() ??
          data['serviceInterest']?.toString() ??
          'Sin categoría';
      final serviceSubcategory = data['serviceSubcategory']?.toString() ?? '';
      final providerId =
          data['selectedProveedorId']?.toString().isNotEmpty == true
          ? data['selectedProveedorId']!.toString()
          : (data['preferredProviderId']?.toString() ?? userId);
      final providerLabel =
          data['preferredProviderName']?.toString().trim().isNotEmpty == true
          ? data['preferredProviderName']!.toString()
          : 'Proveedor asignado';
      return _ProviderDossierItem(
        requestId: entry.key,
        title: data['titulo']?.toString() ?? 'Expediente comercial',
        subtitle:
            data['descripcion']?.toString() ??
            'Negocio activo dentro de SaneApp.',
        stageLabel: _stageLabel(stage),
        stageColor: _stageColor(stage),
        paymentLabel: _paymentLabel(paymentStatus),
        slaLabel: _slaLabel(createdAt, stage),
        categoryLabel: serviceSubcategory.trim().isNotEmpty
            ? '$serviceCategory · $serviceSubcategory'
            : serviceCategory,
        estimatedValue: (data['estimatedValue'] as num?)?.toDouble() ?? 0,
        nextAction: _nextActionForStage(stage, paymentStatus),
        lastEventLabel: _relativeTimeLabel(updatedAt),
        openChat: stage != 'open_marketplace',
        generatorId: data['generadorId']?.toString() ?? '',
        providerId: providerId,
        generatorLabel: CommercialGuardrailsService.protectedLabelForRole(
          'generador',
          'Generador',
        ),
        providerLabel: providerLabel,
        updatedAt: updatedAt,
      );
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return items.take(4).toList();
  } catch (_) {
    return const <_ProviderDossierItem>[];
  }
}

Future<_ProviderAnalyticsSnapshot> _loadProviderAnalytics(
  String userId,
  Map<String, dynamic>? providerData,
) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore
          .collection('provider_services')
          .where('providerId', isEqualTo: userId)
          .get(),
      firestore
          .collection('ofertas')
          .where('proveedorId', isEqualTo: userId)
          .get(),
      firestore
          .collection('payments')
          .where('proveedorId', isEqualTo: userId)
          .get(),
      firestore.collection('solicitudes').limit(100).get(),
    ]);

    final serviceQuery = results[0];
    final offersQuery = results[1];
    final paymentsQuery = results[2];
    final requestsQuery = results[3];

    final serviceMap = <String, Map<String, dynamic>>{};
    for (final doc in serviceQuery.docs) {
      serviceMap[doc.id] = doc.data();
    }

    final requestMap = <String, Map<String, dynamic>>{};
    for (final doc in requestsQuery.docs) {
      requestMap[doc.id] = doc.data();
    }

    final categoryBuckets = <String, _MutableAnalyticsBucket>{};
    final subcategoryBuckets = <String, _MutableAnalyticsBucket>{};
    for (final doc in offersQuery.docs) {
      final offer = doc.data();
      final requestId = offer['solicitudId']?.toString() ?? '';
      final serviceId = offer['serviceId']?.toString() ?? '';
      final status = offer['status']?.toString() ?? '';
      final request = requestMap[requestId] ?? const <String, dynamic>{};
      final service = serviceMap[serviceId] ?? const <String, dynamic>{};
      final category =
          service['categoryName']?.toString() ??
          request['serviceCategory']?.toString() ??
          request['serviceInterest']?.toString() ??
          'Sin categoría';
      final subcategory =
          service['subcategoryName']?.toString() ??
          request['serviceSubcategory']?.toString() ??
          '';
      categoryBuckets
          .putIfAbsent(category, () => _MutableAnalyticsBucket())
          .register(status == 'adjudicada');
      if (subcategory.trim().isNotEmpty &&
          subcategory != 'Sin subcategoría definida') {
        final key = '$category · $subcategory';
        subcategoryBuckets
            .putIfAbsent(key, () => _MutableAnalyticsBucket())
            .register(status == 'adjudicada');
      }
    }

    for (final doc in paymentsQuery.docs) {
      final payment = doc.data();
      final requestId = payment['solicitudId']?.toString() ?? doc.id;
      final request = requestMap[requestId] ?? const <String, dynamic>{};
      final category =
          request['serviceCategory']?.toString() ??
          request['serviceInterest']?.toString() ??
          'Sin categoría';
      final subcategory = request['serviceSubcategory']?.toString() ?? '';
      final amount = (payment['monto'] as num?)?.toDouble() ?? 0;
      categoryBuckets
              .putIfAbsent(category, () => _MutableAnalyticsBucket())
              .revenue +=
          amount;
      if (subcategory.trim().isNotEmpty &&
          subcategory != 'Sin subcategoría definida') {
        final key = '$category · $subcategory';
        subcategoryBuckets
                .putIfAbsent(key, () => _MutableAnalyticsBucket())
                .revenue +=
            amount;
      }
    }

    final reputationSnapshot =
        ProviderCommercialReputationService.fromProviderData(
          providerData ?? const <String, dynamic>{},
          activeServiceCount: serviceQuery.docs
              .where((doc) => doc.data()['isActive'] != false)
              .length,
        );

    final categoryBreakdown =
        categoryBuckets.entries
            .map(
              (entry) => _AnalyticsBreakdown(
                label: entry.key,
                total: entry.value.total,
                awarded: entry.value.awarded,
                revenue: entry.value.revenue,
              ),
            )
            .toList()
          ..sort((a, b) => b.awarded.compareTo(a.awarded));
    final subcategoryBreakdown =
        subcategoryBuckets.entries
            .map(
              (entry) => _AnalyticsBreakdown(
                label: entry.key,
                total: entry.value.total,
                awarded: entry.value.awarded,
                revenue: entry.value.revenue,
              ),
            )
            .toList()
          ..sort((a, b) => b.awarded.compareTo(a.awarded));

    return _ProviderAnalyticsSnapshot(
      commercialScore: reputationSnapshot.formattedScore,
      tierLabel: reputationSnapshot.tierLabel,
      slaLabel: reputationSnapshot.responseLabel,
      disputeCount: reputationSnapshot.disputeCount,
      categoryBreakdown: categoryBreakdown,
      subcategoryBreakdown: subcategoryBreakdown,
    );
  } catch (_) {
    return const _ProviderAnalyticsSnapshot(
      commercialScore: '0',
      tierLabel: 'Sin datos',
      slaLabel: 'SLA en aprendizaje',
      disputeCount: 0,
      categoryBreakdown: <_AnalyticsBreakdown>[],
      subcategoryBreakdown: <_AnalyticsBreakdown>[],
    );
  }
}

Future<_ProviderSlaSnapshot> _loadProviderSlaSnapshot(String userId) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore
          .collection('ofertas')
          .where('proveedorId', isEqualTo: userId)
          .get(),
      firestore
          .collection('solicitudes')
          .orderBy('createdAt', descending: true)
          .limit(80)
          .get(),
    ]);

    final offers = results[0].docs.map((doc) => doc.data()).toList();
    final requests = results[1].docs.map((doc) => doc.data()).toList();

    final hotQuotes = offers.where((item) {
      final status = item['status']?.toString() ?? '';
      final createdAt = _readDate(item, const ['createdAt']) ?? DateTime.now();
      return status == 'evaluacion' &&
          DateTime.now().difference(createdAt).inHours >= 24;
    }).length;
    final directedPending = requests.where((item) {
      final preferredProviderId = item['preferredProviderId']?.toString() ?? '';
      final stage = item['commercialFlowStage']?.toString() ?? '';
      return preferredProviderId == userId &&
          (stage == 'awaiting_provider_quote' ||
              stage == 'awaiting_provider_response');
    }).length;
    final urgentOpen = requests.where((item) {
      final preferredProviderId = item['preferredProviderId']?.toString() ?? '';
      final urgency = item['serviceUrgency']?.toString().toLowerCase() ?? '';
      final selectedProvider = item['selectedProveedorId']?.toString() ?? '';
      return (preferredProviderId.isEmpty || preferredProviderId == userId) &&
          selectedProvider.isEmpty &&
          urgency.contains('urg');
    }).length;

    DateTime? oldestOpen;
    for (final item in requests) {
      final preferredProviderId = item['preferredProviderId']?.toString() ?? '';
      final selectedProvider = item['selectedProveedorId']?.toString() ?? '';
      final stage = item['commercialFlowStage']?.toString() ?? '';
      if ((preferredProviderId.isEmpty || preferredProviderId == userId) &&
          selectedProvider.isEmpty &&
          (stage == 'awaiting_provider_quote' ||
              stage == 'awaiting_provider_response')) {
        final createdAt = _readDate(item, const ['createdAt']);
        if (createdAt != null &&
            (oldestOpen == null || createdAt.isBefore(oldestOpen))) {
          oldestOpen = createdAt;
        }
      }
    }

    return _ProviderSlaSnapshot(
      hotQuotes: hotQuotes,
      directedPending: directedPending,
      urgentOpen: urgentOpen,
      oldestOpenLabel: oldestOpen == null
          ? 'Sin atraso'
          : _relativeTimeLabel(oldestOpen),
    );
  } catch (_) {
    return const _ProviderSlaSnapshot(
      hotQuotes: 0,
      directedPending: 0,
      urgentOpen: 0,
      oldestOpenLabel: 'Sin atraso',
    );
  }
}

Future<List<_RepurchaseAccountItem>> _loadRepurchaseAccounts(
  String userId,
) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore
          .collection('payments')
          .where('proveedorId', isEqualTo: userId)
          .get(),
      firestore.collection('solicitudes').limit(100).get(),
    ]);

    final requests = {for (final doc in results[1].docs) doc.id: doc.data()};
    final buckets = <String, _RepurchaseMutableBucket>{};
    for (final doc in results[0].docs) {
      final payment = doc.data();
      if (payment['paymentStatus']?.toString() != 'liberado') {
        continue;
      }
      final requestId = payment['solicitudId']?.toString() ?? doc.id;
      final request = requests[requestId] ?? const <String, dynamic>{};
      final generatorId =
          payment['generadorId']?.toString() ??
          request['generadorId']?.toString() ??
          'cliente';
      final bucket = buckets.putIfAbsent(
        generatorId,
        () => _RepurchaseMutableBucket(
          generatorId: generatorId,
          lastRequestTitle: request['titulo']?.toString() ?? 'Negocio liberado',
        ),
      );
      bucket.releasedCount += 1;
      bucket.releasedGmv += (payment['monto'] as num?)?.toDouble() ?? 0;
      bucket.lastRequestId = requestId;
      bucket.lastRequestTitle =
          request['titulo']?.toString() ?? bucket.lastRequestTitle;
      final releasedAt =
          _readDate(payment, const ['releasedAt', 'createdAt']) ??
          DateTime.now();
      if (bucket.lastReleasedAt == null ||
          releasedAt.isAfter(bucket.lastReleasedAt!)) {
        bucket.lastReleasedAt = releasedAt;
      }
    }

    final items =
        buckets.entries
            .map(
              (entry) => _RepurchaseAccountItem(
                accountLabel:
                    'Cuenta ${entry.key.substring(0, entry.key.length.clamp(0, 6))}',
                generatorId: entry.value.generatorId,
                lastRequestId: entry.value.lastRequestId,
                lastRequestTitle: entry.value.lastRequestTitle,
                releasedCount: entry.value.releasedCount,
                releasedGmv: entry.value.releasedGmv,
                lastReleasedAt: entry.value.lastReleasedAt ?? DateTime.now(),
              ),
            )
            .toList()
          ..sort((a, b) => b.lastReleasedAt.compareTo(a.lastReleasedAt));
    return items.take(4).toList();
  } catch (_) {
    return const <_RepurchaseAccountItem>[];
  }
}

Future<bool> _queueRepurchaseFollowUp({
  required String providerId,
  required _RepurchaseAccountItem item,
}) async {
  if (item.generatorId.isEmpty) {
    return false;
  }
  try {
    await FirebaseFirestore.instance
        .collection('provider_repurchase_queue')
        .add({
          'providerId': providerId,
          'generatorId': item.generatorId,
          'requestId': item.lastRequestId,
          'accountLabel': item.accountLabel,
          'lastRequestTitle': item.lastRequestTitle,
          'releasedCount': item.releasedCount,
          'releasedGmv': item.releasedGmv,
          'status': 'pending_follow_up',
          'source': 'provider_dashboard',
          'createdAt': FieldValue.serverTimestamp(),
        });
    if (item.lastRequestId.isNotEmpty) {
      await CommercialTimelineService.recordEvent(
        requestId: item.lastRequestId,
        eventType: 'provider_repurchase_follow_up_requested',
        title: 'Proveedor solicitó reactivación comercial',
        description:
            'Se registró una intención de recompra desde el panel premium para seguimiento del expediente.',
        actorId: providerId,
        actorRole: 'proveedor',
        metadata: {
          'generatorId': item.generatorId,
          'releasedCount': item.releasedCount,
          'releasedGmv': item.releasedGmv,
        },
      );
    }
    return true;
  } catch (_) {
    return false;
  }
}

Future<List<_ActivityItem>> _loadRecentActivity(String userId) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore
          .collection('ofertas')
          .where('proveedorId', isEqualTo: userId)
          .limit(10)
          .get(),
      firestore
          .collection('payments')
          .where('proveedorId', isEqualTo: userId)
          .limit(10)
          .get(),
      firestore
          .collection('solicitudes')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get(),
    ]);

    final offers = results[0].docs.map((doc) {
      final data = doc.data();
      final status = data['status']?.toString() ?? 'evaluacion';
      return _ActivityItem(
        icon: status == 'adjudicada'
            ? Icons.workspace_premium_outlined
            : Icons.request_quote_outlined,
        title: status == 'adjudicada'
            ? 'Cotización adjudicada'
            : 'Cotización enviada o en evaluación',
        detail:
            data['descripcionServicio']?.toString() ??
            'Revisa el estado comercial de esta oferta.',
        createdAt: _readDate(data, const ['createdAt']) ?? DateTime.now(),
        tint: status == 'adjudicada'
            ? const Color(0xFF2D8A59)
            : const Color(0xFF1C6D92),
      );
    }).toList();

    final payments = results[1].docs.map((doc) {
      final data = doc.data();
      final paymentStatus =
          data['paymentStatus']?.toString().toLowerCase() ?? 'pendiente';
      final released = paymentStatus == 'liberado';
      return _ActivityItem(
        icon: released
            ? Icons.payments_outlined
            : Icons.account_balance_wallet_outlined,
        title: released ? 'Pago liberado' : 'Pago en proceso',
        detail: released
            ? 'Se liberó ${_currency((data['monto'] as num?)?.toDouble() ?? 0)} a tu cuenta.'
            : 'Tienes un pago aún por liberar en el flujo operativo.',
        createdAt:
            _readDate(data, const ['releasedAt', 'paidAt', 'createdAt']) ??
            DateTime.now(),
        tint: released ? const Color(0xFF2B8A57) : const Color(0xFFB77C12),
      );
    }).toList();

    final requests = results[2].docs
        .where((doc) {
          final data = doc.data();
          final preferredProviderId =
              data['preferredProviderId']?.toString() ?? '';
          return preferredProviderId.isEmpty || preferredProviderId == userId;
        })
        .map((doc) {
          final data = doc.data();
          final directed =
              (data['preferredProviderId']?.toString().isNotEmpty ?? false);
          return _ActivityItem(
            icon: directed ? Icons.ads_click_outlined : Icons.campaign_outlined,
            title: directed
                ? 'Nueva solicitud dirigida'
                : 'Nueva oportunidad abierta',
            detail:
                data['titulo']?.toString() ??
                'Solicitud reciente en el marketplace.',
            createdAt: _readDate(data, const ['createdAt']) ?? DateTime.now(),
            tint: directed ? const Color(0xFF6F4BC3) : const Color(0xFF0D7C66),
          );
        })
        .toList();

    final all = [...offers, ...payments, ...requests]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all.take(5).toList();
  } catch (_) {
    return const <_ActivityItem>[];
  }
}

DateTime? _readDate(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

String _currency(double value) => '\$${value.toStringAsFixed(0)}';

String _monthDeltaLabel(double current, double previous) {
  if (previous == 0 && current == 0) {
    return 'Sin movimiento mensual aún';
  }
  if (previous == 0) {
    return 'Primer mes con liberaciones';
  }
  final delta = ((current - previous) / previous) * 100;
  final prefix = delta >= 0 ? '+' : '';
  return '$prefix${delta.toStringAsFixed(0)}% vs mes anterior';
}

String _relativeTimeLabel(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) {
    final minutes = diff.inMinutes.clamp(1, 59);
    return 'Hace $minutes min';
  }
  if (diff.inHours < 24) {
    return 'Hace ${diff.inHours} h';
  }
  if (diff.inDays < 7) {
    return 'Hace ${diff.inDays} d';
  }
  return '${date.day}/${date.month}/${date.year}';
}

String _stageLabel(String stage) {
  switch (stage) {
    case 'awaiting_provider_quote':
      return 'Cotización pendiente';
    case 'awaiting_provider_response':
      return 'Respuesta pendiente';
    case 'payment_in_escrow':
      return 'Pago en custodia';
    case 'payment_released':
      return 'Pago liberado';
    case 'payment_under_dispute':
      return 'En disputa';
    case 'awaiting_supervisor_visit_for_provider_quote':
      return 'Visita previa';
    default:
      return 'Marketplace abierto';
  }
}

Color _stageColor(String stage) {
  switch (stage) {
    case 'payment_released':
      return const Color(0xFF1F7A4B);
    case 'payment_in_escrow':
      return const Color(0xFFB77C12);
    case 'payment_under_dispute':
      return const Color(0xFFC24E00);
    case 'awaiting_provider_quote':
    case 'awaiting_provider_response':
      return const Color(0xFF1C6D92);
    default:
      return const Color(0xFF5E6B64);
  }
}

String _paymentLabel(String status) {
  switch (status) {
    case 'liberado':
      return 'Caja liberada';
    case 'en_custodia':
      return 'Caja en custodia';
    case 'en_disputa':
      return 'Caja congelada';
    default:
      return 'Sin pago';
  }
}

String _slaLabel(DateTime createdAt, String stage) {
  if (stage == 'awaiting_provider_quote' ||
      stage == 'awaiting_provider_response') {
    final hours = DateTime.now().difference(createdAt).inHours;
    return hours <= 1 ? 'SLA caliente' : '$hours h abiertas';
  }
  return 'Seguimiento activo';
}

String _nextActionForStage(String stage, String paymentStatus) {
  if (stage == 'awaiting_provider_quote') {
    return 'Siguiente paso: enviar cotización formal y no perder ranking por demora.';
  }
  if (stage == 'awaiting_provider_response') {
    return 'Siguiente paso: responder alcance y disponibilidad desde el expediente.';
  }
  if (stage == 'awaiting_supervisor_visit_for_provider_quote') {
    return 'Siguiente paso: esperar ficha técnica y preparar oferta con mejor precisión.';
  }
  if (paymentStatus == 'en_custodia') {
    return 'Siguiente paso: ejecutar, adjuntar evidencias y preparar soporte para liberación.';
  }
  if (paymentStatus == 'en_disputa') {
    return 'Siguiente paso: consolidar soportes y trazabilidad para defender el caso.';
  }
  if (paymentStatus == 'liberado') {
    return 'Siguiente paso: activar recompra o pedir nueva solicitud al mismo cliente.';
  }
  return 'Siguiente paso: mantener atención comercial y seguimiento del negocio.';
}

class _MutableAnalyticsBucket {
  int total = 0;
  int awarded = 0;
  double revenue = 0;

  void register(bool isAwarded) {
    total += 1;
    if (isAwarded) {
      awarded += 1;
    }
  }
}

class _RepurchaseMutableBucket {
  final String generatorId;
  int releasedCount = 0;
  double releasedGmv = 0;
  DateTime? lastReleasedAt;
  String lastRequestId = '';
  String lastRequestTitle;

  _RepurchaseMutableBucket({
    required this.generatorId,
    required this.lastRequestTitle,
  });
}

class _QuickActions extends StatelessWidget {
  final ProviderProfileStatus status;

  const _QuickActions({required this.status});

  @override
  Widget build(BuildContext context) {
    final primaryAction = status.canOperate
        ? const _ActionItem(
            icon: Icons.travel_explore_rounded,
            label: 'Priorizar oportunidades del día',
            subtitle:
                'Entra directo al marketplace con foco comercial y solicitudes recientes.',
            route: '/servicios_disponibles',
            enabled: true,
          )
        : const _ActionItem(
            icon: Icons.verified_user_outlined,
            label: 'Completar activación operativa',
            subtitle:
                'Termina perfil y documentos para habilitar cotizaciones y servicios.',
            route: '/perfil_proveedor',
            enabled: true,
          );

    final commercial = [
      _ActionItem(
        icon: Icons.add_business,
        label: 'Publicar servicio',
        subtitle: 'Activa una nueva línea comercial.',
        route: '/provider-service-create',
        enabled: status.canOperate,
      ),
      const _ActionItem(
        icon: Icons.request_quote_outlined,
        label: 'Cotizaciones',
        subtitle: 'Responde y sigue adjudicaciones.',
        route: '/mis_cotizaciones',
        enabled: true,
      ),
      const _ActionItem(
        icon: Icons.storefront_outlined,
        label: 'Mis servicios',
        subtitle: 'Gestiona portafolio y visibilidad.',
        route: '/provider-my-services',
        enabled: true,
      ),
    ];

    const operation = [
      _ActionItem(
        icon: Icons.work_history_outlined,
        label: 'Operación',
        subtitle: 'Monitorea servicios en curso.',
        route: '/servicios_en_curso',
        enabled: true,
      ),
      _ActionItem(
        icon: Icons.folder_copy_outlined,
        label: 'Documentos',
        subtitle: 'Asegura cumplimiento operativo.',
        route: '/mis_documentos',
        enabled: true,
      ),
    ];

    const navigation = [
      _ActionItem(
        icon: Icons.home_outlined,
        label: 'Inicio',
        subtitle: 'Vuelve al panel principal del proveedor.',
        route: '/provider_main',
        enabled: true,
      ),
      _ActionItem(
        icon: Icons.assignment_outlined,
        label: 'Mis solicitudes',
        subtitle: 'Consulta el historial y estado de solicitudes.',
        route: '/mis_solicitudes',
        enabled: true,
      ),
      _ActionItem(
        icon: Icons.travel_explore_outlined,
        label: 'Oportunidades',
        subtitle: 'Abre el marketplace de solicitudes activas.',
        route: '/servicios_disponibles',
        enabled: true,
      ),
      _ActionItem(
        icon: Icons.work_history_outlined,
        label: 'Operación',
        subtitle: 'Monitorea servicios en curso y ejecución.',
        route: '/servicios_en_curso',
        enabled: true,
      ),
    ];

    return Column(
      children: [
        _PrimaryActionCard(action: primaryAction),
        const SizedBox(height: 14),
        _ActionCluster(
          title: 'Comercial',
          subtitle: 'Pipeline, portafolio y conversión.',
          actions: commercial,
        ),
        const SizedBox(height: 12),
        _ActionCluster(
          title: 'Operación',
          subtitle: 'Ejecución, soporte y cumplimiento.',
          actions: operation,
        ),
        const SizedBox(height: 12),
        _ActionCluster(
          title: 'Navegación rápida',
          subtitle: 'Accesos directos al flujo principal del proveedor.',
          actions: navigation,
        ),
      ],
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final String route;
  final bool enabled;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
    required this.enabled,
  });
}

class _PrimaryActionCard extends StatelessWidget {
  final _ActionItem action;

  const _PrimaryActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openAction(context, action),
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D3A28), Color(0xFF1F7B4D)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(action.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _ActionCluster extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_ActionItem> actions;

  const _ActionCluster({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5ECE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFF728078))),
          const SizedBox(height: 14),
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActionPill(action: action),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final _ActionItem action;

  const _ActionPill({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openAction(context, action),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: action.enabled
              ? const Color(0xFFF4F8F4)
              : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: action.enabled
                ? const Color(0xFFDCE8DF)
                : const Color(0xFFE6E6E6),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.enabled
                    ? const Color(0xFFE4F3E8)
                    : const Color(0xFFE9E9E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                action.icon,
                color: action.enabled
                    ? const Color(0xFF1F7A4B)
                    : const Color(0xFF909090),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    action.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF728078),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: action.enabled
                  ? const Color(0xFF1F7A4B)
                  : const Color(0xFF9B9B9B),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderChecklist extends StatelessWidget {
  final ProviderProfileStatus status;

  const _ProviderChecklist({required this.status});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ChecklistItem(
        'Perfil básico diligenciado',
        status.completionPercent >= 45,
      ),
      _ChecklistItem(
        'Categorías y alcance definidos',
        status.completionPercent >= 65,
      ),
      _ChecklistItem('Documentos operativos cargados', status.hasDocuments),
      _ChecklistItem(
        'Proveedor habilitado para operar',
        status.isProfileComplete,
      ),
    ];
    final completed = items.where((item) => item.done).length;
    final recommendations = [
      if (!status.hasDocuments) 'Completa documentos para acelerar validación.',
      if (!status.isProfileComplete)
        'Ajusta tu perfil para desbloquear operación total.',
      if (status.hasDocuments && status.isProfileComplete)
        'Mantén actualizado tu portafolio para sostener adjudicaciones.',
    ];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF102F22), Color(0xFF1D6C46)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nivel ${_accountLevelLabel(status.completionPercent)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$completed de ${items.length} hitos completados',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: status.completionPercent / 100,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.done
                        ? const Color(0xFFEAF6EF)
                        : const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.done
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: item.done
                            ? const Color(0xFF2B8A57)
                            : const Color(0xFF929292),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Recomendaciones',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...recommendations.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: Color(0xFF1E7A4B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFF6E7B74),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _accountLevelLabel(int completionPercent) {
    if (completionPercent >= 100) {
      return 'premium';
    }
    if (completionPercent >= 70) {
      return 'pro';
    }
    return 'base';
  }
}

class _ChecklistItem {
  final String label;
  final bool done;

  const _ChecklistItem(this.label, this.done);
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

void _openAction(BuildContext context, _ActionItem action) {
  if (!action.enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Completa tu registro para habilitar esta acción.'),
      ),
    );
    return;
  }
  Navigator.pushNamed(context, action.route);
}
