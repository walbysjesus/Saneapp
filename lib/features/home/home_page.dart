import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saneapp_pro_nuevo/state/app_state.dart';
import 'package:saneapp_pro_nuevo/core/services/analytics_service.dart';

import '../../core/utils/adaptive_image_provider.dart';
import '../../models/user_model.dart';
import '../generador/solicitud_detalle_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreen('HomeScreen');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = context.read<AppState>();
      final user = appState.currentUser;
      if (user?.role == 'generador' && user?.clientProfileCompleted == true) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/buyer_main');
        }
        return;
      }
      if (user?.role == 'proveedor') {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/marketplace');
        }
        return;
      }
      if (Firebase.apps.isEmpty) {
        return;
      }
      if (user?.role == 'generador' || user?.role == 'proveedor') {
        // Consultar Firestore para saber si el perfil estÃ¡ completo
        final uid = user?.uid;
        if (uid != null) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          final data = doc.data();
          if (user?.role == 'generador' &&
              data != null &&
              data['clientProfileCompleted'] != true) {
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: const Text('Â¡Completa tu perfil para continuar!'),
                  content: const Text(
                    'Para poder usar SaneApp y publicar solicitudes, primero debes completar tu perfil operativo. Esto nos permite ofrecerte los mejores proveedores y servicios a tu medida.',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(
                          context,
                        ).pushReplacementNamed('/client-profile');
                      },
                      child: const Text('Completar perfil'),
                    ),
                  ],
                ),
              );
            }
          }
          // Control de acceso para proveedor
          if (user?.role == 'proveedor' &&
              data != null &&
              data['profileCompleted'] != true) {
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => AlertDialog(
                  title: const Text('Â¡Completa tu perfil de proveedor!'),
                  content: const Text(
                    'Para poder usar SaneApp como proveedor y acceder a solicitudes, primero debes completar tu registro profesional.',
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(
                          context,
                        ).pushReplacementNamed('/provider-profile-setup');
                      },
                      child: const Text('Completar registro'),
                    ),
                  ],
                ),
              );
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final user = appState.currentUser;
    final hasFirebase = Firebase.apps.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color drawerBg = isDark ? const Color(0xFF212121) : const Color(0xFFF3F8F4);
    Color headerBg = _brandGreen;
    final Color headerText = Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: _brandGreen,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Center(
          child: Text(
            'SaneApp',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            tooltip: 'Notificaciones',
            onPressed: () async {
              final nav = Navigator.of(context);
              try {
                await nav.pushNamed('/notificaciones');
              } catch (e) {
                if (!mounted) return;
              }
            },
          ),
        ],
      ),
      drawer: _OperationalDrawer(
        user: user,
        hasFirebase: hasFirebase,
        drawerBg: drawerBg,
        headerBg: headerBg,
        headerText: headerText,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          _GeneratorHero(
            userName: user?.companyName ?? user?.fullName ?? 'Cliente SaneApp',
            city: user?.city,
            entityType: user?.entityType,
          ),
          const SizedBox(height: 18),
          hasFirebase
              ? StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('solicitudes')
                      .where('generadorId', isEqualTo: user?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? const [];
                    final activeCount = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == 'activa';
                    }).length;
                    final emergencyCount = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['type'] == 'emergency';
                    }).length;
                    final withSupervisor = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['supervisorRequested'] == true;
                    }).length;
                    return Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'Solicitudes activas',
                            value: '$activeCount',
                            icon: Icons.assignment_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: 'Emergencias',
                            value: '$emergencyCount',
                            icon: Icons.warning_amber_rounded,
                            accentColor: const Color(0xFFC24E00),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: 'Con supervisión',
                            value: '$withSupervisor',
                            icon: Icons.verified_user_outlined,
                          ),
                        ),
                      ],
                    );
                  },
                )
              : const Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Solicitudes activas',
                        value: '0',
                        icon: Icons.assignment_outlined,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Emergencias',
                        value: '0',
                        icon: Icons.warning_amber_rounded,
                        accentColor: Color(0xFFC24E00),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Con supervisión',
                        value: '0',
                        icon: Icons.verified_user_outlined,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 18),
          const _SectionHeader(
            title: 'Acciones rápidas',
            subtitle:
                'Publica solicitudes, activa emergencias o coordina supervisión en segundos.',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 560 ? 1 : 2;
              return GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 168,
                ),
                children: [
                  _QuickActionCard(
                    title: 'Nueva solicitud',
                    subtitle: 'Flujo operativo estándar con perfil precargado.',
                    icon: Icons.add_task,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/crear_solicitud'),
                  ),
                  _QuickActionCard(
                    title: 'Emergencia 24/7',
                    subtitle:
                        'Activa atención prioritaria para incidentes críticos.',
                    icon: Icons.crisis_alert_outlined,
                    accentColor: const Color(0xFFC24E00),
                    onTap: () =>
                        Navigator.of(context).pushNamed('/emergency-services'),
                  ),
                  _QuickActionCard(
                    title: 'Supervisión',
                    subtitle:
                        'Solicita verificación técnica o acompañamiento completo para tus servicios.',
                    icon: Icons.verified_user_outlined,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed('/supervision_generador'),
                  ),
                  _QuickActionCard(
                    title: 'Mis solicitudes',
                    subtitle:
                        'Haz seguimiento de estado, ofertas y servicios activos.',
                    icon: Icons.inventory_2_outlined,
                    onTap: () =>
                        Navigator.of(context).pushNamed('/mis_solicitudes'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const _SectionHeader(
            title: 'Categorías del marketplace',
            subtitle:
                'Explora líneas ambientales y entra más rápido a la categoría correcta para tu próxima solicitud.',
          ),
          const SizedBox(height: 12),
          _CategoriesSpotlightCard(
            onBrowse: () => Navigator.of(context).pushNamed('/categories-pro'),
            onCreateRequest: () =>
                Navigator.of(context).pushNamed('/crear_solicitud'),
          ),
          const SizedBox(height: 18),
          const _SectionHeader(
            title: 'Tu demanda prioritaria',
            subtitle:
                'Servicios configurados desde tu perfil cliente para crear solicitudes más rápido.',
          ),
          const SizedBox(height: 12),
          _ClientDemandCard(userId: hasFirebase ? user?.uid : null),
          const SizedBox(height: 18),
          const _SectionHeader(
            title: 'Actividad recie y soportente',
            subtitle:
                'Visualiza tus publicaciones más recientes como si fuera un panel de marketplace.',
          ),
          const SizedBox(height: 12),
          _RecentRequestsPanel(userId: hasFirebase ? user?.uid : null),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            label: 'Categorías',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined),
            label: 'Supervisión',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/home_generador');
            return;
          }
          if (index == 1) {
            Navigator.of(context).pushNamed('/categories-pro');
            return;
          }
          if (index == 2) {
            Navigator.of(
              context,
            ).pushReplacementNamed('/supervision_generador');
          }
        },
      ),
    );
  }
}

class _GeneratorHero extends StatelessWidget {
  final String userName;
  final String? city;
  final String? entityType;

  const _GeneratorHero({
    required this.userName,
    required this.city,
    required this.entityType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            _HomeScreenState._brandGreen,
            _HomeScreenState._brandGreenSoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu panel comprador está listo para cotizar, comparar y activar servicios ambientales con mejor trazabilidad.',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                label: city?.isNotEmpty == true ? city! : 'Sin ciudad base',
              ),
              _HeroPill(
                label: entityType == 'empresa'
                    ? 'Cliente empresa'
                    : 'Cliente persona',
              ),
              const _HeroPill(label: 'Marketplace operativo'),
            ],
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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor = _HomeScreenState._brandGreenSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8E5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accentColor = _HomeScreenState._brandGreenSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDCE7DF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accentColor),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesSpotlightCard extends StatelessWidget {
  final VoidCallback onBrowse;
  final VoidCallback onCreateRequest;

  const _CategoriesSpotlightCard({
    required this.onBrowse,
    required this.onCreateRequest,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        final categories = snapshot.data?.docs ?? const [];
        final categoryLabels = categories
            .map((doc) {
              final name = doc.data()['name']?.toString().trim();
              return (name != null && name.isNotEmpty) ? name : doc.id;
            })
            .take(3)
            .toList(growable: false);

        final spotlightLabels = categoryLabels.isEmpty
            ? const [
                'Limpieza industrial',
                'Vactor y succión',
                'Gestión ambiental',
              ]
            : categoryLabels;

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
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      color: _HomeScreenState._brandGreenSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Descubre categorías activas',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Navega el catálogo ambiental y entra al flujo correcto sin perder tiempo.',
                          style: TextStyle(color: Colors.black54, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: spotlightLabels
                    .map((label) => _CategoryPill(label: label))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onBrowse,
                      style: FilledButton.styleFrom(
                        backgroundColor: _HomeScreenState._brandGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.grid_view_rounded),
                      label: const Text('Ver categorías'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onCreateRequest,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEAF5EE),
                        foregroundColor: _HomeScreenState._brandGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_task_outlined),
                      label: const Text('Crear solicitud'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;

  const _CategoryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _HomeScreenState._brandGreen,
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

class _OperationalDrawer extends StatefulWidget {
  final UserModel? user;
  final bool hasFirebase;
  final Color drawerBg;
  final Color headerBg;
  final Color headerText;

  const _OperationalDrawer({
    required this.user,
    required this.hasFirebase,
    required this.drawerBg,
    required this.headerBg,
    required this.headerText,
  });

  @override
  State<_OperationalDrawer> createState() => _OperationalDrawerState();
}

class _OperationalDrawerState extends State<_OperationalDrawer> {
  static const _favoritesKey = 'generador_drawer_favorites';
  static const _usageKey = 'generador_drawer_route_usage';
  final TextEditingController _searchController = TextEditingController();
  Set<String> _favoriteRoutes = <String>{};
  Map<String, int> _routeUsage = <String, int>{};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _searchController.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? const <String>[];
    final usageRaw = prefs.getString(_usageKey);
    final decoded = usageRaw == null
        ? const <String, dynamic>{}
        : jsonDecode(usageRaw) as Map<String, dynamic>;
    if (!mounted) {
      return;
    }
    setState(() {
      _favoriteRoutes = favorites.toSet();
      _routeUsage = decoded.map(
        (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
      );
    });
  }

  Future<void> _toggleFavorite(String route) async {
    final updated = Set<String>.from(_favoriteRoutes);
    if (updated.contains(route)) {
      updated.remove(route);
    } else {
      updated.add(route);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, updated.toList());
    if (!mounted) {
      return;
    }
    setState(() {
      _favoriteRoutes = updated;
    });
  }

  Future<void> _registerRouteUsage(String route) async {
    final updated = Map<String, int>.from(_routeUsage);
    updated.update(route, (value) => value + 1, ifAbsent: () => 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usageKey, jsonEncode(updated));
    if (!mounted) {
      return;
    }
    setState(() {
      _routeUsage = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.hasFirebase ? widget.user?.uid : null;
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    if (userId == null) {
      return Drawer(
        backgroundColor: const Color(0xFFF3F8F4),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _DrawerHeaderCard(
              user: widget.user,
              headerBg: widget.headerBg,
              headerText: widget.headerText,
              totalRequests: 0,
              activeRequests: 0,
              supervisedRequests: 0,
              emergencyRequests: 0,
              pendingOffers: 0,
              pendingPayments: 0,
              unreadOffers: 0,
            ),
          ],
        ),
      );
    }

    return Drawer(
      backgroundColor: const Color(0xFFF3F8F4),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes')
            .where('generadorId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? const [];
          final totalRequests = docs.length;
          final activeRequests = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status']?.toString().toLowerCase() ?? '';
            return status == 'activa' ||
                status == 'pago_confirmado' ||
                status == 'en_ejecucion';
          }).length;
          final supervisedRequests = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['supervisorRequested'] == true;
          }).length;
          final emergencyRequests = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['type'] == 'emergency';
          }).length;
          final requestIds = docs.map((doc) => doc.id).toList(growable: false);

          return FutureBuilder<_DrawerOfferStats>(
            future: _loadOfferStats(requestIds),
            builder: (context, offersSnapshot) {
              final offerStats =
                  offersSnapshot.data ?? const _DrawerOfferStats();
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payments')
                    .where('generadorId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, paymentsSnapshot) {
                  final paymentDocs = paymentsSnapshot.data?.docs ?? const [];
                  final pendingPayments = paymentDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status =
                        data['paymentStatus']?.toString().toLowerCase() ?? '';
                    return status != 'paid' && status != 'pagado';
                  }).length;

                  final pendingTasks = _buildPendingTasks(
                    profileCompleted:
                        widget.user?.clientProfileCompleted == true,
                    activeRequests: activeRequests,
                    supervisedRequests: supervisedRequests,
                    emergencyRequests: emergencyRequests,
                    pendingOffers: offerStats.pendingDecisionCount,
                    pendingPayments: pendingPayments,
                  );

                  final allItems = _buildMenuItems(
                    context: context,
                    activeRequests: activeRequests,
                    supervisedRequests: supervisedRequests,
                    emergencyRequests: emergencyRequests,
                    pendingOffers: offerStats.pendingDecisionCount,
                    pendingPayments: pendingPayments,
                    offersWaitingReview: offerStats.unreadOffersCount,
                  );
                  final orderedGroups = _sortGroups(
                    items: allItems,
                    user: widget.user,
                    pendingTasksCount: pendingTasks.length,
                    pendingOffers: offerStats.pendingDecisionCount,
                  );
                  final favoriteItems = allItems
                      .where((item) => _favoriteRoutes.contains(item.route))
                      .toList();
                  final filteredItems = _filterItems(allItems);

                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _DrawerHeaderCard(
                        user: widget.user,
                        headerBg: widget.headerBg,
                        headerText: widget.headerText,
                        totalRequests: totalRequests,
                        activeRequests: activeRequests,
                        supervisedRequests: supervisedRequests,
                        emergencyRequests: emergencyRequests,
                        pendingOffers: offerStats.pendingDecisionCount,
                        pendingPayments: pendingPayments,
                        unreadOffers: offerStats.unreadOffersCount,
                      ),
                      _DrawerSearchField(controller: _searchController),
                      if (widget.user?.clientProfileCompleted != true)
                        _DrawerActionBanner(
                          title: 'Completa tu perfil operativo',
                          subtitle:
                              'Te ayudará a publicar más rápido y a recibir proveedores mejor alineados.',
                          buttonLabel: 'Completar ahora',
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed('/perfil_generador'),
                        ),
                      if (pendingTasks.isNotEmpty)
                        _DrawerPendingTasks(tasks: pendingTasks),
                      if (favoriteItems.isNotEmpty)
                        _DrawerMenuGroup(
                          title: 'Favoritos',
                          subtitle:
                              'Tus accesos fijados para entrar más rápido.',
                          items: _filterItems(favoriteItems),
                          currentRoute: currentRoute,
                          favoriteRoutes: _favoriteRoutes,
                          onToggleFavorite: _toggleFavorite,
                          onNavigate: _openMenuItem,
                        ),
                      ...orderedGroups.map((group) {
                        return _DrawerMenuGroup(
                          title: group.title,
                          subtitle: group.subtitle,
                          items: filteredItems
                              .where((item) => item.group == group.key)
                              .toList(),
                          currentRoute: currentRoute,
                          favoriteRoutes: _favoriteRoutes,
                          onToggleFavorite: _toggleFavorite,
                          onNavigate: _openMenuItem,
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<_DrawerOfferStats> _loadOfferStats(List<String> requestIds) async {
    if (requestIds.isEmpty) {
      return const _DrawerOfferStats();
    }
    final batches = <List<String>>[];
    for (var index = 0; index < requestIds.length; index += 30) {
      final end = (index + 30 < requestIds.length)
          ? index + 30
          : requestIds.length;
      batches.add(requestIds.sublist(index, end));
    }

    var totalOffers = 0;
    var pendingDecisionCount = 0;

    for (final batch in batches) {
      final snapshot = await FirebaseFirestore.instance
          .collection('ofertas')
          .where('solicitudId', whereIn: batch)
          .get();
      totalOffers += snapshot.docs.length;
      final grouped = <String, int>{};
      for (final doc in snapshot.docs) {
        final solicitudId = doc.data()['solicitudId']?.toString();
        if (solicitudId == null || solicitudId.isEmpty) {
          continue;
        }
        grouped.update(solicitudId, (value) => value + 1, ifAbsent: () => 1);
      }
      pendingDecisionCount += grouped.length;
    }

    return _DrawerOfferStats(
      unreadOffersCount: totalOffers,
      pendingDecisionCount: pendingDecisionCount,
    );
  }

  Future<void> _openMenuItem(_DrawerMenuItemData item) async {
    await _registerRouteUsage(item.route);
    item.onTap();
  }

  List<_DrawerPendingTaskData> _buildPendingTasks({
    required bool profileCompleted,
    required int activeRequests,
    required int supervisedRequests,
    required int emergencyRequests,
    required int pendingOffers,
    required int pendingPayments,
  }) {
    final tasks = <_DrawerPendingTaskData>[];
    if (!profileCompleted) {
      tasks.add(
        _DrawerPendingTaskData(
          title: 'Completar perfil cliente',
          subtitle: 'Configura datos operativos e intereses prioritarios.',
          route: '/perfil_generador',
          accentColor: const Color(0xFFC24E00),
        ),
      );
    }
    if (pendingOffers > 0) {
      tasks.add(
        _DrawerPendingTaskData(
          title: 'Revisar ofertas pendientes',
          subtitle: '$pendingOffers publicación(es) aún sin adjudicar.',
          route: '/ofertas_recibidas',
          accentColor: _HomeScreenState._brandGreenSoft,
        ),
      );
    }
    if (pendingPayments > 0) {
      tasks.add(
        _DrawerPendingTaskData(
          title: 'Validar pagos',
          subtitle: '$pendingPayments pago(s) con estado pendiente.',
          route: '/pagos_generador',
          accentColor: const Color(0xFF3B6EA5),
        ),
      );
    }
    if (supervisedRequests > 0) {
      tasks.add(
        _DrawerPendingTaskData(
          title: 'Monitorear supervisión',
          subtitle: '$supervisedRequests servicio(s) con trazabilidad activa.',
          route: '/supervision_generador',
          accentColor: _HomeScreenState._brandGreen,
        ),
      );
    }
    if (emergencyRequests > 0) {
      tasks.add(
        _DrawerPendingTaskData(
          title: 'Seguir emergencias abiertas',
          subtitle: '$emergencyRequests caso(s) con prioridad operativa.',
          route: '/mis_solicitudes',
          accentColor: const Color(0xFFC24E00),
        ),
      );
    }
    if (tasks.isEmpty && activeRequests > 0) {
      tasks.add(
        _DrawerPendingTaskData(
          title: 'Revisar solicitudes activas',
          subtitle: '$activeRequests solicitud(es) actualmente en operación.',
          route: '/mis_solicitudes',
          accentColor: _HomeScreenState._brandGreenSoft,
        ),
      );
    }
    return tasks;
  }

  List<_DrawerMenuItemData> _buildMenuItems({
    required BuildContext context,
    required int activeRequests,
    required int supervisedRequests,
    required int emergencyRequests,
    required int pendingOffers,
    required int pendingPayments,
    required int offersWaitingReview,
  }) {
    return [
      _DrawerMenuItemData(
        route: '/home_generador',
        group: 'operacion',
        icon: Icons.home_outlined,
        title: 'Inicio',
        subtitle: 'Resumen del marketplace y actividad reciente.',
        onTap: () =>
            Navigator.of(context).pushReplacementNamed('/home_generador'),
      ),
      _DrawerMenuItemData(
        route: '/crear_solicitud',
        group: 'operacion',
        icon: Icons.add_task_outlined,
        title: 'Crear solicitud',
        subtitle: 'Publica un requerimiento estándar.',
        onTap: () => Navigator.of(context).pushNamed('/crear_solicitud'),
      ),
      _DrawerMenuItemData(
        route: '/mis_solicitudes',
        group: 'operacion',
        icon: Icons.assignment_outlined,
        title: 'Mis solicitudes',
        subtitle: 'Sigue estados, ofertas y cierres.',
        badge: activeRequests > 0 ? '$activeRequests activas' : null,
        onTap: () => Navigator.of(context).pushNamed('/mis_solicitudes'),
      ),
      _DrawerMenuItemData(
        route: '/supervision_generador',
        group: 'operacion',
        icon: Icons.verified_user_outlined,
        title: 'Supervisión',
        subtitle: 'Control técnico y trazabilidad de servicios.',
        badge: supervisedRequests > 0
            ? '$supervisedRequests en seguimiento'
            : null,
        onTap: () => Navigator.of(context).pushNamed('/supervision_generador'),
      ),
      _DrawerMenuItemData(
        route: '/emergency-services',
        group: 'operacion',
        icon: Icons.crisis_alert_outlined,
        title: 'Emergencias',
        subtitle: 'Atención prioritaria 24/7.',
        badge: emergencyRequests > 0 ? '$emergencyRequests abiertas' : null,
        accentColor: const Color(0xFFC24E00),
        onTap: () => Navigator.of(context).pushNamed('/emergency-services'),
      ),
      _DrawerMenuItemData(
        route: '/crear_subasta',
        group: 'mercado',
        icon: Icons.gavel_outlined,
        title: 'Crear subasta',
        subtitle: 'Publica una necesidad con lógica competitiva.',
        onTap: () => Navigator.of(context).pushNamed('/crear_subasta'),
      ),
      _DrawerMenuItemData(
        route: '/mis_subastas',
        group: 'mercado',
        icon: Icons.local_offer_outlined,
        title: 'Mis subastas',
        subtitle: 'Gestiona adjudicación y evolución.',
        onTap: () => Navigator.of(context).pushNamed('/mis_subastas'),
      ),
      _DrawerMenuItemData(
        route: '/ofertas_recibidas',
        group: 'mercado',
        icon: Icons.inbox_outlined,
        title: 'Ofertas recibidas',
        subtitle: 'Compara precio, tiempos y garantías.',
        badge: offersWaitingReview > 0
            ? '$offersWaitingReview oferta(s)'
            : (pendingOffers > 0 ? '$pendingOffers por decidir' : null),
        onTap: () => Navigator.of(context).pushNamed('/ofertas_recibidas'),
      ),
      _DrawerMenuItemData(
        route: '/historial_generador',
        group: 'mercado',
        icon: Icons.history_outlined,
        title: 'Historial',
        subtitle: 'Servicios finalizados y cierres.',
        onTap: () => Navigator.of(context).pushNamed('/historial_generador'),
      ),
      _DrawerMenuItemData(
        route: '/perfil_generador',
        group: 'cuenta',
        icon: Icons.account_circle_outlined,
        title: 'Perfil cliente',
        subtitle: 'Datos operativos y preferencias de demanda.',
        badge: widget.user?.clientProfileCompleted == true
            ? 'Perfil completo'
            : 'Completar perfil',
        onTap: () => Navigator.of(context).pushNamed('/perfil_generador'),
      ),
      _DrawerMenuItemData(
        route: '/pagos_generador',
        group: 'cuenta',
        icon: Icons.payments_outlined,
        title: 'Pagos y facturación',
        subtitle: 'Revisa cobros y trazabilidad financiera.',
        badge: pendingPayments > 0 ? '$pendingPayments pendientes' : null,
        onTap: () => Navigator.of(context).pushNamed('/pagos_generador'),
      ),
      _DrawerMenuItemData(
        route: '/notificaciones',
        group: 'cuenta',
        icon: Icons.notifications_outlined,
        title: 'Notificaciones',
        subtitle: 'Eventos, alertas y novedades del servicio.',
        onTap: () => Navigator.of(context).pushNamed('/notificaciones'),
      ),
      _DrawerMenuItemData(
        route: '/metrics',
        group: 'insights',
        icon: Icons.query_stats_outlined,
        title: 'Métricas',
        subtitle: 'Consulta indicadores y actividad general.',
        onTap: () => Navigator.of(context).pushNamed('/metrics'),
      ),
      _DrawerMenuItemData(
        route: '/support',
        group: 'insights',
        icon: Icons.support_agent_outlined,
        title: 'Centro de soporte',
        subtitle: 'Canales de ayuda y acompañamiento.',
        badge: '24/7',
        onTap: () => Navigator.of(context).pushNamed('/support'),
      ),
      _DrawerMenuItemData(
        route: '/live-chat',
        group: 'insights',
        icon: Icons.live_help_outlined,
        title: 'Chat en vivo',
        subtitle: 'Habla con soporte cuando necesites ayuda inmediata.',
        onTap: () => Navigator.of(context).pushNamed('/live-chat'),
      ),
      _DrawerMenuItemData(
        route: '/settings',
        group: 'insights',
        icon: Icons.settings_outlined,
        title: 'Configuración',
        subtitle: 'Preferencias y ajustes de la cuenta.',
        onTap: () => Navigator.of(context).pushNamed('/settings'),
      ),
      _DrawerMenuItemData(
        route: '/logout',
        group: 'cuenta',
        icon: Icons.logout,
        title: 'Cerrar sesión',
        subtitle: 'Salir del panel cliente actual.',
        accentColor: const Color(0xFFC24E00),
        onTap: () async {
          await FirebaseAuth.instance.signOut();
          if (!context.mounted) {
            return;
          }
          context.read<AppState>().clearUser();
          Navigator.of(context).pushReplacementNamed('/login');
        },
      ),
    ];
  }

  List<_DrawerMenuItemData> _filterItems(List<_DrawerMenuItemData> items) {
    if (_searchQuery.isEmpty) {
      return items;
    }
    return items.where((item) {
      final text = '${item.title} ${item.subtitle}'.toLowerCase();
      return text.contains(_searchQuery);
    }).toList();
  }

  List<_DrawerGroupData> _sortGroups({
    required List<_DrawerMenuItemData> items,
    required UserModel? user,
    required int pendingTasksCount,
    required int pendingOffers,
  }) {
    final baseGroups = [
      const _DrawerGroupData(
        key: 'operacion',
        title: 'Operación diaria',
        subtitle: 'Lo que más usas para publicar y operar.',
      ),
      const _DrawerGroupData(
        key: 'mercado',
        title: 'Mercado y seguimiento',
        subtitle: 'Comparación, subastas y trazabilidad comercial.',
      ),
      const _DrawerGroupData(
        key: 'cuenta',
        title: 'Cuenta y administración',
        subtitle: 'Perfil, pagos y configuración de la cuenta.',
      ),
      const _DrawerGroupData(
        key: 'insights',
        title: 'Insights y soporte',
        subtitle: 'Monitoreo, ayuda y configuración de la cuenta.',
      ),
    ];

    final stageBias = <String, int>{
      'operacion': pendingTasksCount > 0 ? 120 : 70,
      'mercado': pendingOffers > 0 ? 110 : 65,
      'cuenta': user?.clientProfileCompleted == true ? 50 : 130,
      'insights': 40,
    };

    final usageByGroup = <String, int>{};
    for (final item in items) {
      usageByGroup.update(
        item.group,
        (value) => value + (_routeUsage[item.route] ?? 0),
        ifAbsent: () => _routeUsage[item.route] ?? 0,
      );
    }

    final sorted = [...baseGroups]
      ..sort((a, b) {
        final scoreA = (stageBias[a.key] ?? 0) + (usageByGroup[a.key] ?? 0);
        final scoreB = (stageBias[b.key] ?? 0) + (usageByGroup[b.key] ?? 0);
        return scoreB.compareTo(scoreA);
      });
    return sorted;
  }
}

class _DrawerHeaderCard extends StatelessWidget {
  final UserModel? user;
  final Color headerBg;
  final Color headerText;
  final int totalRequests;
  final int activeRequests;
  final int supervisedRequests;
  final int emergencyRequests;
  final int pendingOffers;
  final int pendingPayments;
  final int unreadOffers;

  const _DrawerHeaderCard({
    required this.user,
    required this.headerBg,
    required this.headerText,
    required this.totalRequests,
    required this.activeRequests,
    required this.supervisedRequests,
    required this.emergencyRequests,
    required this.pendingOffers,
    required this.pendingPayments,
    required this.unreadOffers,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        user?.companyName ?? user?.fullName ?? 'Cliente SaneApp';
    final roleLabel = user?.entityType == 'empresa'
        ? 'Cliente empresa'
        : 'Cliente persona';
    final avatarImage = resolveAdaptiveImageProvider(user?.photoUrl);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [headerBg, _HomeScreenState._brandGreenSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140C4F31),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 36, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushNamed('/perfil_generador'),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      avatarImage ??
                      const AssetImage('assets/images/logo_saneapp.png'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: headerText,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: headerText.withValues(alpha: 0.82),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DrawerHeaderPill(label: roleLabel),
                        if ((user?.city ?? '').isNotEmpty)
                          _DrawerHeaderPill(label: user!.city!),
                        _DrawerHeaderPill(
                          label: user?.clientProfileCompleted == true
                              ? 'Perfil operativo completo'
                              : 'Perfil pendiente',
                        ),
                        _DrawerHeaderPill(
                          label: user?.verified == true
                              ? 'Verificado'
                              : 'Pendiente validación',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estado operativo',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DrawerSummaryMetric(
                        label: 'Publicadas',
                        value: '$totalRequests',
                      ),
                    ),
                    Expanded(
                      child: _DrawerSummaryMetric(
                        label: 'Activas',
                        value: '$activeRequests',
                      ),
                    ),
                    Expanded(
                      child: _DrawerSummaryMetric(
                        label: 'Supervisión',
                        value: '$supervisedRequests',
                      ),
                    ),
                    Expanded(
                      child: _DrawerSummaryMetric(
                        label: 'Cobros',
                        value: '$pendingPayments',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HealthChip(
                      label: unreadOffers > 0
                          ? '$unreadOffers oferta(s) recibidas'
                          : 'Ofertas al día',
                    ),
                    _HealthChip(
                      label: pendingOffers > 0
                          ? '$pendingOffers solicitud(es) por decidir'
                          : 'Ofertas al día',
                    ),
                    _HealthChip(
                      label: emergencyRequests > 0
                          ? '$emergencyRequests emergencia(s) abiertas'
                          : 'Sin urgencias críticas',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerHeaderPill extends StatelessWidget {
  final String label;

  const _DrawerHeaderPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DrawerSummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _DrawerSummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

class _DrawerSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DrawerSectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF163826),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF5F7264), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DrawerActionBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _DrawerActionBanner({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5EC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF2D1B0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_late_outlined, color: Color(0xFFC24E00)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Acción requerida',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFC24E00),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFE3C7),
                foregroundColor: const Color(0xFFC24E00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_outlined),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSearchField extends StatelessWidget {
  final TextEditingController controller;

  const _DrawerSearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Buscar módulos, acciones o soporte',
          prefixIcon: const Icon(
            Icons.search_outlined,
            color: _HomeScreenState._brandGreenSoft,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FBF9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDCE7DF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDCE7DF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: _HomeScreenState._brandGreenSoft,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerPendingTasks extends StatelessWidget {
  final List<_DrawerPendingTaskData> tasks;

  const _DrawerPendingTasks({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE7DF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pendientes de hoy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Atajos directos para lo que requiere atención inmediata.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ...tasks.map((task) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: const Color(0xFFF8FBF9),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.of(context).pushNamed(task.route),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: task.accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  task.subtitle,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DrawerMenuGroup extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_DrawerMenuItemData> items;
  final String currentRoute;
  final Set<String> favoriteRoutes;
  final ValueChanged<String> onToggleFavorite;
  final ValueChanged<_DrawerMenuItemData> onNavigate;

  const _DrawerMenuGroup({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.currentRoute,
    required this.favoriteRoutes,
    required this.onToggleFavorite,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDCE7DF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x080C4F31),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            _DrawerSectionTitle(title: title, subtitle: subtitle),
            const Divider(height: 1, color: Color(0xFFE6EEE8)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DrawerNavTile(
                          icon: item.icon,
                          title: item.title,
                          subtitle: item.subtitle,
                          badge: item.badge,
                          accentColor: item.accentColor,
                          onTap: () => onNavigate(item),
                          isFavorite: favoriteRoutes.contains(item.route),
                          isActive: currentRoute == item.route,
                          onToggleFavorite: item.route == '/logout'
                              ? null
                              : () => onToggleFavorite(item.route),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthChip extends StatelessWidget {
  final String label;

  const _HealthChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isFavorite;
  final bool isActive;
  final VoidCallback? onToggleFavorite;

  const _DrawerNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.accentColor = _HomeScreenState._brandGreenSoft,
    this.isFavorite = false,
    this.isActive = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? const Color(0xFFEAF5EE) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? accentColor.withValues(alpha: 0.34)
                  : const Color(0xFFDCE7DF),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080C4F31),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isActive ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isActive
                            ? const Color(0xFF163826)
                            : Colors.black87,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5F7264),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onToggleFavorite != null)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: isFavorite
                            ? 'Quitar favorito'
                            : 'Agregar a favoritos',
                        onPressed: onToggleFavorite,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          color: isFavorite
                              ? const Color(0xFFC24E00)
                              : const Color(0xFF8B9A90),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 24, height: 24),
                  const SizedBox(height: 4),
                  Icon(
                    isActive ? Icons.arrow_forward : Icons.chevron_right,
                    size: 20,
                    color: isActive ? accentColor : const Color(0xFF8B9A90),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerPendingTaskData {
  final String title;
  final String subtitle;
  final String route;
  final Color accentColor;

  const _DrawerPendingTaskData({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.accentColor,
  });
}

class _DrawerMenuItemData {
  final String route;
  final String group;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final Color accentColor;
  final VoidCallback onTap;

  const _DrawerMenuItemData({
    required this.route,
    required this.group,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.accentColor = _HomeScreenState._brandGreenSoft,
  });
}

class _DrawerGroupData {
  final String key;
  final String title;
  final String subtitle;

  const _DrawerGroupData({
    required this.key,
    required this.title,
    required this.subtitle,
  });
}

class _DrawerOfferStats {
  final int unreadOffersCount;
  final int pendingDecisionCount;

  const _DrawerOfferStats({
    this.unreadOffersCount = 0,
    this.pendingDecisionCount = 0,
  });
}

class _ClientDemandCard extends StatelessWidget {
  final String? userId;

  const _ClientDemandCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId == null || Firebase.apps.isEmpty) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final interests =
            (data['serviceInterests'] as List?)?.cast<String>() ??
            const <String>[];
        final urgency =
            data['serviceUrgency'] as String? ?? 'Sin urgencia definida';
        final frequency =
            data['contractFrequency'] as String? ?? 'Sin frecuencia definida';
        return Container(
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
                children: interests.isEmpty
                    ? const [
                        Chip(label: Text('Completa intereses en tu perfil')),
                      ]
                    : interests
                          .take(5)
                          .map((item) => Chip(label: Text(item)))
                          .toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('Urgencia habitual: $urgency')),
                  Expanded(child: Text('Frecuencia: $frequency')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentRequestsPanel extends StatelessWidget {
  final String? userId;

  const _RecentRequestsPanel({required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId == null || Firebase.apps.isEmpty) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('solicitudes')
          .where('generadorId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDCE7DF)),
            ),
            child: const Text(
              'Aún no tienes publicaciones. Empieza con una solicitud o activa una emergencia.',
            ),
          );
        }
        final recent = [...docs]
          ..sort((a, b) {
            final aCreated = (a.data() as Map<String, dynamic>)['createdAt'];
            final bCreated = (b.data() as Map<String, dynamic>)['createdAt'];
            final aTimestamp = aCreated is Timestamp
                ? aCreated
                : Timestamp.fromMillisecondsSinceEpoch(0);
            final bTimestamp = bCreated is Timestamp
                ? bCreated
                : Timestamp.fromMillisecondsSinceEpoch(0);
            return bTimestamp.compareTo(aTimestamp);
          });

        return Column(
          children: recent.take(3).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return RecentRequestPreviewCard(requestId: doc.id, data: data);
          }).toList(),
        );
      },
    );
  }
}

class RecentRequestPreviewCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;

  const RecentRequestPreviewCard({
    super.key,
    required this.requestId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isEmergency = data['type'] == 'emergency';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: requestId.isEmpty
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SolicitudDetallePage(solicitudId: requestId),
                    ),
                  );
                },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFDCE7DF)),
            ),
            child: Row(
              children: [
                Icon(
                  isEmergency
                      ? Icons.warning_amber_rounded
                      : Icons.assignment_turned_in_outlined,
                  color: isEmergency
                      ? const Color(0xFFC24E00)
                      : _HomeScreenState._brandGreenSoft,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['titulo']?.toString() ?? 'Solicitud',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${data['serviceInterest'] ?? 'Sin categoría'} • ${data['status'] ?? 'Sin estado'}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
