import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../core/services/analytics_service.dart';
import '../../services/provider_commercial_reputation_service.dart';
import '../billing/billing_screen.dart';
import '../provider/models/provider_service_listing.dart';
import '../provider/provider_service_detail_page.dart';
import '../providers/provider_detail_page.dart';

class ExploreServicesPage extends StatefulWidget {
  final String? filter;

  const ExploreServicesPage({super.key, this.filter});

  @override
  State<ExploreServicesPage> createState() => _ExploreServicesPageState();
}

class _ExploreServicesPageState extends State<ExploreServicesPage> {
  static const _brandGreen = Color(0xFF0C4F31);
  static const _brandGreenSoft = Color(0xFF1E7A4B);
  static const _surface = Color(0xFFF6FAF7);
  static const _cardBorder = Color(0xFFDCE7DF);
  static const _savedProvidersKey = 'marketplace_saved_providers';
  static const _savedServicesKey = 'marketplace_saved_services';
  static const _compareProvidersKey = 'marketplace_compare_providers';
  static const _compareServicesKey = 'marketplace_compare_services';

  String _search = '';
  String? _category;
  final bool _onlyEmergency = false;
  final bool _onlyWithLicense = false;
  Set<String> _savedProviderIds = <String>{};
  Set<String> _savedServiceIds = <String>{};
  Set<String> _compareProviderIds = <String>{};
  Set<String> _compareServiceIds = <String>{};

  bool _matchesProviderFilters(Map<String, dynamic> provider) {
    final query = _search.trim().toLowerCase();
    final name = provider['name']?.toString().toLowerCase() ?? '';
    final description = provider['description']?.toString().toLowerCase() ?? '';
    final services =
        (provider['services'] as List?)
            ?.map((item) => item.toString().toLowerCase())
            .toList() ??
        const <String>[];

    if (query.isNotEmpty) {
      final haystack = '$name $description ${services.join(' ')}';
      if (!haystack.contains(query)) {
        return false;
      }
    }

    if (_category != null && _category!.isNotEmpty) {
      final categoryQuery = _category!.toLowerCase();
      final inCategory = services.any(
        (service) => service.contains(categoryQuery),
      );
      if (!inCategory) {
        return false;
      }
    }

    return true;
  }

  Map<String, dynamic> _normalizeProviderDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final categories =
        (data['selectedCategories'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    return {
      'id': doc.id,
      'name': (data['companyName'] as String?)?.trim().isNotEmpty == true
          ? (data['companyName'] as String).trim()
          : 'Proveedor sin nombre',
      'city': (data['operationAddress'] as String?)?.trim() ?? 'Sin ubicación',
      'service': categories.isNotEmpty ? categories.first : 'Sin categoría',
      'services': categories,
      'description':
          (data['serviceArea'] as String?)?.trim() ??
          'Proveedor operativo en servicios ambientales.',
      'logoUrl': (data['logoUrl'] as String?) ?? '',
      'operationPhone': (data['operationPhone'] as String?) ?? '',
      'operationEmail': (data['operationEmail'] as String?) ?? '',
      'profileCompleted': data['profileCompleted'] == true,
      'accountStatus': (data['status'] as String?) ?? 'pending_documents',
      'ratingAverage': (data['ratingAverage'] as num?)?.toDouble() ?? 0,
      'ratingCount': (data['ratingCount'] as num?)?.toInt() ?? 0,
      'avgResponseTimeMinutes':
          (data['avgResponseTimeMinutes'] as num?)?.toDouble() ?? 0,
      'acceptanceRate': (data['acceptanceRate'] as num?)?.toDouble() ?? 0,
      'commercialScore': (data['commercialScore'] as num?)?.toDouble() ?? 0,
      'commercialTier': (data['commercialTier'] as String?) ?? 'D',
      'commercialTierLabel':
          (data['commercialTierLabel'] as String?) ?? 'Por consolidar',
      'completedServices': (data['completedServices'] as num?)?.toInt() ?? 0,
      'rutUrl': (data['rutUrl'] as String?) ?? '',
      'camaraComercioUrl': (data['camaraComercioUrl'] as String?) ?? '',
      'cedulaUrl': (data['cedulaUrl'] as String?) ?? '',
      'certificadoBancarioUrl':
          (data['certificadoBancarioUrl'] as String?) ?? '',
    };
  }

  void _openAuctionFlow() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(
        context,
        '/register',
        arguments: _marketplaceIntentArgs('buy'),
      );
      return;
    }

    _loadCurrentUserData().then((userData) {
      if (!mounted) {
        return;
      }
      final role = userData['role']?.toString();
      if (role == 'generador') {
        if (userData['clientProfileCompleted'] == true) {
          Navigator.pushNamed(
            context,
            '/crear_subasta',
            arguments: {
              'serviceInterest': _category,
              'requestSource': 'service_marketplace',
              'requestTitle': _category != null && _category!.trim().isNotEmpty
                  ? 'Subasta para ${_category!.trim()}'
                  : 'Subasta de servicios ambientales',
              'requestDescription':
                  'Quiero abrir una subasta para comparar múltiples propuestas cuando el alcance del servicio sea amplio, crítico o de alto valor.',
            },
          );
        } else {
          Navigator.pushNamed(context, '/client-profile');
        }
        return;
      }

      Navigator.pushNamed(
        context,
        '/role-selection',
        arguments: _marketplaceIntentArgs('buy'),
      );
    });
  }

  Map<String, String> _marketplaceIntentArgs(String intent) => {
    'marketplaceIntent': intent,
  };

  Future<Map<String, dynamic>> _loadCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const <String, dynamic>{};
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return snapshot.data() ?? const <String, dynamic>{};
  }

  Future<void> _openBuyerFlow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(
        context,
        '/register',
        arguments: _marketplaceIntentArgs('buy'),
      );
      return;
    }

    final userData = await _loadCurrentUserData();
    if (!mounted) {
      return;
    }
    final role = userData['role']?.toString();
    if (role == 'generador') {
      if (userData['clientProfileCompleted'] == true) {
        Navigator.pushNamed(
          context,
          '/crear_solicitud',
          arguments: {
            'serviceInterest': _category,
            'requestSource': 'service_marketplace',
          },
        );
      } else {
        Navigator.pushNamed(context, '/client-profile');
      }
      return;
    }

    Navigator.pushNamed(
      context,
      '/role-selection',
      arguments: _marketplaceIntentArgs('buy'),
    );
  }

  Future<void> _openSellerFlow() async {
    Navigator.pushNamed(context, '/sell-services');
  }

  Future<void> _openWorkspace() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final userData = await _loadCurrentUserData();
    if (!mounted) {
      return;
    }
    final role = userData['role']?.toString();
    if (role == 'proveedor') {
      Navigator.pushNamed(context, '/provider_main');
    } else if (role == 'generador') {
      Navigator.pushNamed(context, '/buyer_main');
    } else {
      Navigator.pushNamed(context, '/role-selection');
    }
  }

  Future<void> _openProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final userData = await _loadCurrentUserData();
    if (!mounted) {
      return;
    }

    final role = userData['role']?.toString();
    if (role == 'proveedor') {
      final profileCompleted = userData['profileCompleted'] == true;
      Navigator.pushNamed(
        context,
        profileCompleted ? '/perfil_proveedor' : '/provider-profile-setup',
      );
      return;
    }

    if (role == 'generador') {
      final profileCompleted = userData['clientProfileCompleted'] == true;
      Navigator.pushNamed(
        context,
        profileCompleted ? '/perfil_generador' : '/client-profile',
      );
      return;
    }

    if (role == 'supervisor') {
      Navigator.pushNamed(context, '/supervisor-profile-setup');
      return;
    }

    Navigator.pushNamed(context, '/profile');
  }

  String _resolveDisplayName(Map<String, dynamic> userData, User user) {
    final candidates = [
      userData['fullName'],
      userData['companyName'],
      user.displayName,
      user.email,
    ];
    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return 'Usuario SaneApp';
  }

  String _resolveEmail(Map<String, dynamic> userData, User user) {
    final candidates = [userData['email'], user.email];
    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return 'Sin correo registrado';
  }

  String _resolveRoleLabel(String? role) {
    switch (role) {
      case 'proveedor':
        return 'Vendedor';
      case 'generador':
        return 'Comprador';
      case 'supervisor':
        return 'Supervisor';
      case 'admin':
        return 'Administrador';
      default:
        return 'Cuenta SaneApp';
    }
  }

  String _buildInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'SA';
    }
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  void _closeDrawerThen(Future<void> Function() action) {
    Navigator.of(context).pop();
    Future<void>.delayed(Duration.zero, () async {
      if (!mounted) {
        return;
      }
      await action();
    });
  }

  Future<String?> _loadCurrentRole() async {
    final data = await _loadCurrentUserData();
    return data['role']?.toString();
  }

  Future<void> _openSupportCenter() async {
    Navigator.pushNamed(context, '/support');
  }

  Future<void> _openNotificationsCenter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    Navigator.pushNamed(context, '/notificaciones');
  }

  Future<void> _openPurchasesHub() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(
        context,
        '/register',
        arguments: _marketplaceIntentArgs('buy'),
      );
      return;
    }

    final role = await _loadCurrentRole();
    if (!mounted) {
      return;
    }
    switch (role) {
      case 'generador':
        Navigator.pushNamed(context, '/mis_solicitudes');
        return;
      case 'proveedor':
        Navigator.pushNamed(context, '/mis_cotizaciones');
        return;
      case 'supervisor':
        Navigator.pushNamed(context, '/supervisor-orders');
        return;
      default:
        Navigator.pushNamed(context, '/request-history');
    }
  }

  Future<void> _openSavedMarketplace() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SavedMarketplacePage(
          providerIds: _savedProviderIds,
          serviceIds: _savedServiceIds,
        ),
      ),
    );
  }

  Future<void> _openFollowedStores() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _MarketplaceProviderDirectoryPage(
          title: 'Tiendas que sigo',
          subtitle:
              'Empresas ambientales que marcaste para seguir y volver a contactar más rápido.',
          providerIds: _savedProviderIds,
        ),
      ),
    );
  }

  Future<void> _openQuestionsHub() async {
    Navigator.pushNamed(context, '/faq');
  }

  Future<void> _openReviewsHub() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _MarketplaceReviewsPage()));
  }

  Future<void> _openHistoryHub() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final role = await _loadCurrentRole();
    if (!mounted) {
      return;
    }
    switch (role) {
      case 'generador':
        Navigator.pushNamed(context, '/historial_generador');
        return;
      case 'proveedor':
        Navigator.pushNamed(context, '/historial_proveedor');
        return;
      case 'supervisor':
        Navigator.pushNamed(context, '/supervisor-orders');
        return;
      default:
        Navigator.pushNamed(context, '/request-history');
    }
  }

  Future<void> _openCouponsHub() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _MarketplaceCouponsPage()));
  }

  Future<void> _openClipsHub() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _MarketplaceClipsPage()));
  }

  Future<void> _openOffersHub() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _MarketplaceFeaturePage(
            title: 'Ofertas',
            subtitle:
                'Para comparar ofertas comerciales, adjudicar proveedores o responder subastas, necesitas entrar con tu cuenta.',
            icon: Icons.local_offer_outlined,
            accentColor: _brandGreen,
            primaryLabel: 'Entrar para ver ofertas',
            onPrimaryTap: () => Navigator.of(context).pushNamed('/login'),
            secondaryLabel: 'Seguir explorando',
            onSecondaryTap: () =>
                Navigator.of(context).pushNamed('/marketplace'),
          ),
        ),
      );
      return;
    }

    final role = await _loadCurrentRole();
    if (!mounted) {
      return;
    }
    switch (role) {
      case 'generador':
        Navigator.pushNamed(context, '/ofertas_recibidas');
        return;
      case 'proveedor':
        Navigator.pushNamed(context, '/subastas_activas');
        return;
      case 'supervisor':
        Navigator.pushNamed(context, '/supervisor-dashboard');
        return;
      default:
        Navigator.pushNamed(context, '/marketplace');
    }
  }

  Future<void> _openOfficialCompanies() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _MarketplaceProviderDirectoryPage(
          title: 'Empresas oficiales',
          subtitle:
              'Directorio de operadores con perfil validado y presencia activa dentro del ecosistema comercial de SaneApp.',
          onlyOfficial: true,
        ),
      ),
    );
  }

  Future<void> _openCategoriesHub() async {
    Navigator.pushNamed(context, '/categories');
  }

  Future<void> _openBillingHub() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    final role = await _loadCurrentRole();
    if (!mounted) {
      return;
    }
    switch (role) {
      case 'generador':
        Navigator.pushNamed(context, '/pagos_generador');
        return;
      case 'proveedor':
        Navigator.pushNamed(context, '/ingresos_proveedor');
        return;
      default:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const BillingScreen()));
    }
  }

  Future<void> _openSettingsHub() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    Navigator.pushNamed(context, '/settings');
  }

  Widget _buildMarketplaceDrawer(bool isAuthenticated) {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_brandGreen, _brandGreenSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: isAuthenticated && user != null
                  ? FutureBuilder<Map<String, dynamic>>(
                      future: _loadCurrentUserData(),
                      builder: (context, snapshot) {
                        final userData =
                            snapshot.data ?? const <String, dynamic>{};
                        final displayName = _resolveDisplayName(userData, user);
                        final email = _resolveEmail(userData, user);
                        final roleLabel = _resolveRoleLabel(
                          userData['role']?.toString(),
                        );
                        final initials = _buildInitials(displayName);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.26,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        roleLabel,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.82,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.84,
                                          ),
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _openProfile();
                              },
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.account_circle_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Mi perfil',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 16,
                                      color: Colors.white.withValues(
                                        alpha: 0.92,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marketplace SaneApp',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Compra, publica y opera servicios ambientales desde una sola entrada.',
                          style: TextStyle(
                            color: Color(0xFFD7EADF),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerMenuTile(
                    icon: Icons.home_outlined,
                    title: 'Inicio',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerMenuTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Ayuda',
                    onTap: () => _closeDrawerThen(_openSupportCenter),
                  ),
                  const Divider(height: 18, thickness: 0.6, color: _cardBorder),
                  const _DrawerSectionLabel(title: 'Mi actividad'),
                  _DrawerMenuTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Mis compras',
                    onTap: () => _closeDrawerThen(_openPurchasesHub),
                  ),
                  _DrawerMenuTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notificaciones',
                    onTap: () => _closeDrawerThen(_openNotificationsCenter),
                  ),
                  _DrawerMenuTile(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Favoritos',
                    onTap: () => _closeDrawerThen(_openSavedMarketplace),
                  ),
                  _DrawerMenuTile(
                    icon: Icons.storefront_outlined,
                    title: 'Tiendas que sigo',
                    onTap: () => _closeDrawerThen(_openFollowedStores),
                  ),
                  _DrawerMenuTile(
                    icon: Icons.question_answer_outlined,
                    title: 'Preguntas',
                    onTap: () => _closeDrawerThen(_openQuestionsHub),
                  ),
                  _DrawerMenuTile(
                    icon: Icons.rate_review_outlined,
                    title: 'Mis opiniones',
                    onTap: () => _closeDrawerThen(_openReviewsHub),
                  ),
                  _DrawerMenuTile(
                    icon: Icons.history_rounded,
                    title: 'Historial',
                    onTap: () => _closeDrawerThen(_openHistoryHub),
                  ),
                  const Divider(height: 18, thickness: 0.6, color: _cardBorder),
                  const _DrawerSectionLabel(title: 'Descubre'),
                  _DrawerMenuTile(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Cupones',
                    onTap: () => _closeDrawerThen(_openCouponsHub),
                  ),
                  _DrawerMenuTile(
                    icon: Icons.local_offer_outlined,
                    title: 'Ofertas',
                    onTap: () => _closeDrawerThen(_openOffersHub),
                  ),
                  _DrawerMenuTile(
                    icon: Icons.verified_user_outlined,
                    title: 'Empresas oficiales',
                    onTap: () => _closeDrawerThen(_openOfficialCompanies),
                  ),
                  _DrawerMenuTile(
                    icon: Icons.grid_view_rounded,
                    title: 'Categorías',
                    onTap: () => _closeDrawerThen(_openCategoriesHub),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: _DrawerHighlightTile(
                      icon: Icons.sell_outlined,
                      title: 'Vender en SaneApp',
                      onTap: () => _closeDrawerThen(_openSellerFlow),
                    ),
                  ),
                  _DrawerMenuTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Facturación',
                    onTap: () => _closeDrawerThen(_openBillingHub),
                  ),
                  _DrawerMenuTile(
                    icon: Icons.settings_outlined,
                    title: 'Configuración',
                    onTap: () => _closeDrawerThen(_openSettingsHub),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: isAuthenticated
                  ? FilledButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) {
                          return;
                        }
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/marketplace',
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Cerrar sesión'),
                    )
                  : FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Ingresar'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMarketplaceMemory();
    if (widget.filter != null && widget.filter!.trim().isNotEmpty) {
      _category = widget.filter!.trim();
    }
  }

  Future<void> _loadMarketplaceMemory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _savedProviderIds =
          (prefs.getStringList(_savedProvidersKey) ?? const <String>[]).toSet();
      _savedServiceIds =
          (prefs.getStringList(_savedServicesKey) ?? const <String>[]).toSet();
      _compareProviderIds =
          (prefs.getStringList(_compareProvidersKey) ?? const <String>[])
              .toSet();
      _compareServiceIds =
          (prefs.getStringList(_compareServicesKey) ?? const <String>[])
              .toSet();
    });
  }

  Future<void> _toggleSavedProvider(String providerId) async {
    final next = Set<String>.from(_savedProviderIds);
    if (!next.add(providerId)) {
      next.remove(providerId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedProvidersKey, next.toList());
    if (!mounted) {
      return;
    }
    setState(() => _savedProviderIds = next);
  }

  Future<void> _toggleSavedService(String serviceId) async {
    final next = Set<String>.from(_savedServiceIds);
    if (!next.add(serviceId)) {
      next.remove(serviceId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedServicesKey, next.toList());
    if (!mounted) {
      return;
    }
    setState(() => _savedServiceIds = next);
  }

  Future<void> _toggleComparedProvider(String providerId) async {
    final next = Set<String>.from(_compareProviderIds);
    if (!next.contains(providerId) && next.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Puedes comparar hasta 3 proveedores a la vez.'),
        ),
      );
      return;
    }
    if (!next.add(providerId)) {
      next.remove(providerId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_compareProvidersKey, next.toList());
    if (!mounted) {
      return;
    }
    setState(() => _compareProviderIds = next);
  }

  Future<void> _toggleComparedService(String serviceId) async {
    final next = Set<String>.from(_compareServiceIds);
    if (!next.contains(serviceId) && next.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Puedes comparar hasta 3 servicios a la vez.'),
        ),
      );
      return;
    }
    if (!next.add(serviceId)) {
      next.remove(serviceId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_compareServicesKey, next.toList());
    if (!mounted) {
      return;
    }
    setState(() => _compareServiceIds = next);
  }

  Future<void> _clearCompared() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_compareProvidersKey);
    await prefs.remove(_compareServicesKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _compareProviderIds = <String>{};
      _compareServiceIds = <String>{};
    });
  }

  void _openCompareSheet({
    required List<Map<String, dynamic>> providers,
    required List<ProviderServiceListing> services,
  }) {
    final pageContext = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6FAF7),
      builder: (context) {
        final selectedProviders = providers
            .where(
              (provider) => _compareProviderIds.contains(
                provider['id']?.toString() ?? '',
              ),
            )
            .toList();
        final selectedServices = services
            .where((service) => _compareServiceIds.contains(service.id))
            .toList();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Comparador comercial',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Revisa en paralelo proveedores y servicios guardados para decidir mejor la ruta comercial.',
                    style: TextStyle(color: Color(0xFF65736C), height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  if (selectedProviders.isNotEmpty) ...[
                    const _SectionTitle(
                      title: 'Proveedores comparados',
                      subtitle:
                          'Señales de confianza, especialidades y acceso rápido a su perfil comercial.',
                    ),
                    const SizedBox(height: 12),
                    ...selectedProviders.map(
                      (provider) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ComparisonTile(
                          title: provider['name']?.toString() ?? 'Proveedor',
                          subtitle:
                              '${provider['city']?.toString() ?? 'Sin ubicación'} · ${((provider['services'] as List?)?.length ?? 0)} especialidades',
                          trailing: provider['profileCompleted'] == true
                              ? 'Validado'
                              : 'En revisión',
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(pageContext).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProviderDetailPage(provider: provider),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (selectedServices.isNotEmpty) ...[
                    const _SectionTitle(
                      title: 'Servicios comparados',
                      subtitle:
                          'Precio base, proveedor, cobertura y tiempo de respuesta en un solo carril.',
                    ),
                    const SizedBox(height: 12),
                    ...selectedServices.map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ComparisonTile(
                          title: service.title,
                          subtitle:
                              '${service.providerName} · ${service.coverage} · ${service.responseTime}',
                          trailing:
                              'Desde ${service.priceFrom.toStringAsFixed(0)}',
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(pageContext).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProviderServiceDetailPage(service: service),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  if (selectedProviders.isEmpty && selectedServices.isEmpty)
                    const _InlineHintCard(
                      text:
                          'Tus elementos comparados no están visibles con los filtros actuales. Ajusta búsqueda, categoría o cobertura para volver a verlos.',
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAuthenticated = currentUser != null;
    return Scaffold(
      backgroundColor: _surface,
      drawer: _buildMarketplaceDrawer(isAuthenticated),
      appBar: AppBar(
        leadingWidth: 116,
        leading: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
            child: TextButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.32)),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_rounded, size: 17),
                  SizedBox(width: 6),
                  Text('Más', style: TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 17),
                ],
              ),
            ),
          ),
        ),
        title: const Text('SANEAPP'),
        centerTitle: true,
        backgroundColor: _brandGreen,
        foregroundColor: Colors.white,
        actions: [
          if (isAuthenticated)
            TextButton(
              onPressed: _openWorkspace,
              child: const Text(
                'Mi espacio',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (!isAuthenticated)
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text(
                'Ingresar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('provider_services')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'No fue posible cargar el marketplace: ${snapshot.error}',
                    ),
                  );
                }

                final services =
                    (snapshot.data?.docs ?? const [])
                        .map(ProviderServiceListing.fromDocument)
                        .where(_matchesFilters)
                        .toList()
                      ..sort(
                        (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(2000))
                            .compareTo(
                              a.updatedAt ?? a.createdAt ?? DateTime(2000),
                            ),
                      );

                if (services.isEmpty) {
                  return const _EmptyMarketplaceState();
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('providers')
                      .snapshots(),
                  builder: (context, providerSnapshot) {
                    final normalizedProviders =
                        (providerSnapshot.data?.docs ?? const [])
                            .map(_normalizeProviderDoc)
                            .where(_matchesProviderFilters)
                            .toList();
                    normalizedProviders.sort((a, b) {
                      final rankA =
                          ProviderCommercialReputationService.rankingIndex(
                            a,
                            activeServiceCount:
                                ((a['services'] as List?) ?? const []).length,
                          );
                      final rankB =
                          ProviderCommercialReputationService.rankingIndex(
                            b,
                            activeServiceCount:
                                ((b['services'] as List?) ?? const []).length,
                          );
                      return rankB.compareTo(rankA);
                    });
                    final providers = normalizedProviders.take(6).toList();
                    final providerById = {
                      for (final provider in normalizedProviders)
                        provider['id']?.toString() ?? '': provider,
                    };
                    services.sort((a, b) {
                      final providerA = providerById[a.providerId];
                      final providerB = providerById[b.providerId];
                      final rankA = providerA == null
                          ? 0.0
                          : ProviderCommercialReputationService.rankingIndex(
                              providerA,
                              activeServiceCount:
                                  ((providerA['services'] as List?) ?? const [])
                                      .length,
                            );
                      final rankB = providerB == null
                          ? 0.0
                          : ProviderCommercialReputationService.rankingIndex(
                              providerB,
                              activeServiceCount:
                                  ((providerB['services'] as List?) ?? const [])
                                      .length,
                            );
                      final rankCompare = rankB.compareTo(rankA);
                      if (rankCompare != 0) {
                        return rankCompare;
                      }
                      final emergencyCompare = b.emergencyAvailability
                          .toString()
                          .compareTo(a.emergencyAvailability.toString());
                      if (emergencyCompare != 0) {
                        return emergencyCompare;
                      }
                      return (b.updatedAt ?? b.createdAt ?? DateTime(2000))
                          .compareTo(
                            a.updatedAt ?? a.createdAt ?? DateTime(2000),
                          );
                    });

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _MarketplaceHero(
                          onCreateAuction: isAuthenticated
                              ? _openAuctionFlow
                              : () => Navigator.pushNamed(
                                  context,
                                  '/register',
                                  arguments: _marketplaceIntentArgs('buy'),
                                ),
                          onFollowUpAction: _openBuyerFlow,
                          followUpLabel: isAuthenticated
                              ? 'Seguir solicitudes'
                              : 'Publicar necesidad',
                          onSellerEntry: _openSellerFlow,
                          category: _category,
                        ),
                        if (!isAuthenticated) ...[
                          const SizedBox(height: 14),
                          const _MarketplaceTrustStrip(),
                        ],
                        if (currentUser != null) ...[
                          const SizedBox(height: 14),
                          _MarketplaceAlertsPulse(
                            userId: currentUser.uid,
                            savedProvidersCount: _savedProviderIds.length,
                            savedServicesCount: _savedServiceIds.length,
                            comparedCount:
                                _compareProviderIds.length +
                                _compareServiceIds.length,
                          ),
                        ],
                        if (_savedProviderIds.isNotEmpty ||
                            _savedServiceIds.isNotEmpty ||
                            _compareProviderIds.isNotEmpty ||
                            _compareServiceIds.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _MarketplaceSaveCompareBar(
                            savedProvidersCount: _savedProviderIds.length,
                            savedServicesCount: _savedServiceIds.length,
                            comparedCount:
                                _compareProviderIds.length +
                                _compareServiceIds.length,
                            onOpenCompare: () => _openCompareSheet(
                              providers: normalizedProviders,
                              services: services,
                            ),
                            onClearCompare: _clearCompared,
                          ),
                        ],
                        const SizedBox(height: 14),
                        _MarketplaceExecutiveDashboard(
                          providers: normalizedProviders,
                          services: services,
                          savedProvidersCount: _savedProviderIds.length,
                          savedServicesCount: _savedServiceIds.length,
                          comparedCount:
                              _compareProviderIds.length +
                              _compareServiceIds.length,
                        ),
                        if (currentUser != null) ...[
                          const SizedBox(height: 14),
                          _RepurchasePlaybook(
                            userId: currentUser.uid,
                            defaultCategory: _category,
                          ),
                        ],
                        const SizedBox(height: 14),
                        _SolutionPaths(category: _category),
                        const SizedBox(height: 14),
                        _LargeScopeBanner(onCreateAuction: _openAuctionFlow),
                        const SizedBox(height: 14),
                        const _SectionTitle(
                          title: 'Proveedores visibles',
                          subtitle:
                              'Ranking inteligente activo: prioriza score comercial, SLA, aceptación y cierres antes de entrar al detalle.',
                        ),
                        const SizedBox(height: 12),
                        if (providers.isEmpty)
                          const _InlineHintCard(
                            text:
                                'Todavía no hay proveedores que coincidan con tus filtros en esta vitrina unificada.',
                          )
                        else
                          ...providers.asMap().entries.map((entry) {
                            final index = entry.key;
                            final provider = entry.value;
                            final providerId = provider['id']?.toString() ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ProviderMarketplaceCard(
                                provider: provider,
                                rankIndex: index,
                                isSaved: _savedProviderIds.contains(providerId),
                                isCompared: _compareProviderIds.contains(
                                  providerId,
                                ),
                                onToggleSaved: () =>
                                    _toggleSavedProvider(providerId),
                                onToggleCompare: () =>
                                    _toggleComparedProvider(providerId),
                              ),
                            );
                          }),
                        const SizedBox(height: 10),
                        const _SectionTitle(
                          title: 'Servicios publicados',
                          subtitle:
                              'Orden inteligente activo: primero ves servicios de proveedores con mejor score comercial y mejor respuesta.',
                        ),
                        const SizedBox(height: 12),
                        ...services.map(
                          (service) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _MarketplaceServiceCard(
                              service: service,
                              isSaved: _savedServiceIds.contains(service.id),
                              isCompared: _compareServiceIds.contains(
                                service.id,
                              ),
                              onToggleSaved: () =>
                                  _toggleSavedService(service.id),
                              onToggleCompare: () =>
                                  _toggleComparedService(service.id),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProviderServiceDetailPage(
                                      service: service,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _MarketplaceBottomDock(
        onHomeTap: () =>
            Navigator.pushReplacementNamed(context, '/marketplace'),
        onBuyTap: _openBuyerFlow,
        onCategoriesTap: _openCategoriesHub,
        onClipsTap: _openClipsHub,
        onSellTap: _openSellerFlow,
      ),
    );
  }

  bool _matchesFilters(ProviderServiceListing service) {
    final query = _search.trim().toLowerCase();
    if (query.isNotEmpty) {
      final combined = [
        service.title,
        service.shortDescription,
        service.categoryName,
        service.subcategoryName,
        service.providerName,
      ].join(' ').toLowerCase();
      if (!combined.contains(query)) {
        return false;
      }
    }

    if (_category != null && _category!.isNotEmpty) {
      final categoryQuery = _category!.toLowerCase();
      final inCategory =
          service.categoryName.toLowerCase().contains(categoryQuery) ||
          service.subcategoryName.toLowerCase().contains(categoryQuery);
      if (!inCategory) {
        return false;
      }
    }

    if (_onlyEmergency && !service.emergencyAvailability) {
      return false;
    }
    if (_onlyWithLicense && !service.requiresLicense) {
      return false;
    }
    return true;
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_brandGreen, _brandGreenSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por servicio, categoría o proveedor',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => setState(() => _search = value),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceServiceCard extends StatelessWidget {
  const _MarketplaceServiceCard({
    required this.service,
    required this.onTap,
    required this.isSaved,
    required this.isCompared,
    required this.onToggleSaved,
    required this.onToggleCompare,
  });

  final ProviderServiceListing service;
  final VoidCallback onTap;
  final bool isSaved;
  final bool isCompared;
  final VoidCallback onToggleSaved;
  final VoidCallback onToggleCompare;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _ExploreServicesPageState._cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                child: service.commercialImageUrl.isNotEmpty
                    ? Image.network(
                        service.commercialImageUrl,
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 190,
                        color: const Color(0xFFEAF3ED),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: _ExploreServicesPageState._brandGreenSoft,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFE8F1EB),
                          backgroundImage: service.providerLogoUrl.isNotEmpty
                              ? NetworkImage(service.providerLogoUrl)
                              : null,
                          child: service.providerLogoUrl.isEmpty
                              ? const Icon(
                                  Icons.business,
                                  color:
                                      _ExploreServicesPageState._brandGreenSoft,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service.providerName,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      service.shortDescription,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(
                          icon: Icons.category_outlined,
                          label: service.categoryName,
                        ),
                        _MetaPill(
                          icon: Icons.tune_outlined,
                          label: service.subcategoryName,
                        ),
                        _MetaPill(
                          icon: Icons.location_on_outlined,
                          label: service.coverage,
                        ),
                        _MetaPill(
                          icon: Icons.schedule_outlined,
                          label: service.responseTime,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Desde ${service.priceFrom.toStringAsFixed(0)} ${service.priceType.toLowerCase()}',
                            style: const TextStyle(
                              color: _ExploreServicesPageState._brandGreen,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onToggleSaved,
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: _ExploreServicesPageState._brandGreen,
                          ),
                          tooltip: isSaved
                              ? 'Quitar de guardados'
                              : 'Guardar servicio',
                        ),
                        ElevatedButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Ver detalle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _ExploreServicesPageState._brandGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: onToggleCompare,
                          icon: Icon(
                            isCompared
                                ? Icons.checklist_rounded
                                : Icons.compare_arrows_rounded,
                          ),
                          label: Text(
                            isCompared ? 'En comparador' : 'Comparar servicio',
                          ),
                        ),
                        if (isSaved)
                          const Chip(
                            label: Text('Guardado'),
                            avatar: Icon(Icons.bookmark_rounded, size: 18),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: _ExploreServicesPageState._brandGreenSoft,
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _EmptyMarketplaceState extends StatelessWidget {
  const _EmptyMarketplaceState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.travel_explore_outlined,
                size: 72,
                color: Color(0xFF1E7A4B),
              ),
              SizedBox(height: 18),
              Text(
                'Aún no hay servicios publicados con esos filtros',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 10),
              Text(
                'Cuando los proveedores publiquen ofertas activas en el marketplace, aparecerán aquí con su imagen comercial, cobertura y precio base.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeScopeBanner extends StatelessWidget {
  final VoidCallback onCreateAuction;

  const _LargeScopeBanner({required this.onCreateAuction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3827), Color(0xFF1E7A4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿El negocio es grande o necesitas comparar varias propuestas?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Usa subasta para proyectos de mayor alcance, con fecha límite, criterios claros y competencia controlada entre proveedores.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onCreateAuction,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _ExploreServicesPageState._brandGreen,
                ),
                icon: const Icon(Icons.gavel_outlined),
                label: const Text('Crear subasta'),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/mis_subastas'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('Ver mis subastas'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketplaceBottomDock extends StatelessWidget {
  const _MarketplaceBottomDock({
    required this.onHomeTap,
    required this.onBuyTap,
    required this.onCategoriesTap,
    required this.onClipsTap,
    required this.onSellTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onBuyTap;
  final VoidCallback onCategoriesTap;
  final VoidCallback onClipsTap;
  final VoidCallback onSellTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: _ExploreServicesPageState._cardBorder.withValues(
                alpha: 0.9,
              ),
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140C4F31),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _MarketplaceDockButton(
                icon: Icons.home_rounded,
                label: 'Inicio',
                onTap: onHomeTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MarketplaceDockButton(
                icon: Icons.shopping_bag_outlined,
                label: 'Comprar',
                onTap: onBuyTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MarketplaceDockButton(
                icon: Icons.grid_view_rounded,
                label: 'Categorías',
                onTap: onCategoriesTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MarketplaceDockButton(
                icon: Icons.play_circle_fill_rounded,
                label: 'Clips',
                isPrimary: true,
                onTap: onClipsTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MarketplaceDockButton(
                icon: Icons.storefront_outlined,
                label: 'Vender',
                onTap: onSellTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceDockButton extends StatelessWidget {
  const _MarketplaceDockButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isPrimary
        ? _ExploreServicesPageState._brandGreen
        : const Color(0xFFF3F7F4);
    final foregroundColor = isPrimary
        ? Colors.white
        : _ExploreServicesPageState._brandGreen;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: foregroundColor),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketplaceHero extends StatelessWidget {
  const _MarketplaceHero({
    required this.onCreateAuction,
    required this.onFollowUpAction,
    required this.followUpLabel,
    required this.onSellerEntry,
    required this.category,
  });

  final VoidCallback onCreateAuction;
  final VoidCallback onFollowUpAction;
  final VoidCallback? onSellerEntry;
  final String followUpLabel;
  final String? category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF092F20), Color(0xFF16623D), Color(0xFF2E8D5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Marketplace SaneApp',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category != null && category!.trim().isNotEmpty
                ? 'Estás explorando oferta para $category. Puedes comparar proveedores, revisar servicios publicados o abrir una subasta si el negocio es grande.'
                : 'Explora una sola vitrina para comparar proveedores, servicios publicados y caminos de contratación asistida.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onCreateAuction,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _ExploreServicesPageState._brandGreen,
                ),
                icon: const Icon(Icons.gavel_outlined),
                label: const Text('Negocio grande: crear subasta'),
              ),
              OutlinedButton.icon(
                onPressed: onFollowUpAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                ),
                icon: const Icon(Icons.assignment_outlined),
                label: Text(followUpLabel),
              ),
              if (onSellerEntry != null)
                OutlinedButton.icon(
                  onPressed: onSellerEntry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  icon: const Icon(Icons.storefront_outlined),
                  label: const Text('Vender en SaneApp'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarketplaceClipsPage extends StatefulWidget {
  const _MarketplaceClipsPage();

  @override
  State<_MarketplaceClipsPage> createState() => _MarketplaceClipsPageState();
}

class _MarketplaceClipsPageState extends State<_MarketplaceClipsPage> {
  Set<String> _savedServiceIds = <String>{};
  Set<String> _followedProviderIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadMarketplaceMemory();
  }

  Map<String, String> _marketplaceIntentArgs(String intent) => {
    'marketplaceIntent': intent,
  };

  Future<Map<String, dynamic>> _loadCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const <String, dynamic>{};
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return snapshot.data() ?? const <String, dynamic>{};
  }

  Future<void> _openBuyerRequestFromClip(ProviderServiceListing service) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(
        context,
        '/register',
        arguments: _marketplaceIntentArgs('buy'),
      );
      return;
    }

    final userData = await _loadCurrentUserData();
    if (!mounted) {
      return;
    }

    final role = userData['role']?.toString();
    if (role == 'generador') {
      if (userData['clientProfileCompleted'] == true) {
        Navigator.pushNamed(
          context,
          '/crear_solicitud',
          arguments: {
            'serviceInterest': service.categoryName,
            'requestSource': 'service_marketplace_clip',
            'requestTitle': 'Solicitud para ${service.title}',
          },
        );
      } else {
        Navigator.pushNamed(context, '/client-profile');
      }
      return;
    }

    Navigator.pushNamed(
      context,
      '/role-selection',
      arguments: _marketplaceIntentArgs('buy'),
    );
  }

  Future<void> _loadMarketplaceMemory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _savedServiceIds =
          (prefs.getStringList(_ExploreServicesPageState._savedServicesKey) ??
                  const <String>[])
              .toSet();
      _followedProviderIds =
          (prefs.getStringList(_ExploreServicesPageState._savedProvidersKey) ??
                  const <String>[])
              .toSet();
    });
  }

  Future<void> _toggleSavedService(ProviderServiceListing service) async {
    final next = Set<String>.from(_savedServiceIds);
    final wasAdded = next.add(service.id);
    if (!wasAdded) {
      next.remove(service.id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _ExploreServicesPageState._savedServicesKey,
      next.toList(),
    );
    if (!mounted) {
      return;
    }
    setState(() => _savedServiceIds = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasAdded
              ? '${service.title} se agregó a guardados.'
              : '${service.title} se quitó de guardados.',
        ),
      ),
    );
  }

  Future<void> _toggleFollowedProvider(ProviderServiceListing service) async {
    final next = Set<String>.from(_followedProviderIds);
    final wasAdded = next.add(service.providerId);
    if (!wasAdded) {
      next.remove(service.providerId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _ExploreServicesPageState._savedProvidersKey,
      next.toList(),
    );
    if (!mounted) {
      return;
    }
    setState(() => _followedProviderIds = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasAdded
              ? 'Ahora sigues a ${service.providerName}.'
              : 'Dejaste de seguir a ${service.providerName}.',
        ),
      ),
    );
  }

  Future<void> _shareClip(ProviderServiceListing service) async {
    AnalyticsService.logEvent(
      'share_marketplace_clip',
      params: {'service_id': service.id, 'provider_id': service.providerId},
    );
    final priceLabel = service.priceFrom > 0
        ? 'Desde ${service.priceFrom.toStringAsFixed(0)}'
        : 'Precio bajo cotización';
    await Share.share(
      '${service.title} · ${service.providerName}\n'
      '${service.shortDescription.trim().isNotEmpty ? service.shortDescription : 'Servicio disponible en el marketplace de SaneApp.'}\n'
      '${service.categoryName} · ${service.coverage} · $priceLabel',
      subject: 'Clip del marketplace: ${service.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Clips del marketplace'),
        backgroundColor: _ExploreServicesPageState._brandGreen,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/sell-services'),
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            label: const Text(
              'Publicar clip',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('provider_services')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No fue posible cargar los clips comerciales: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs =
              snapshot.data?.docs ??
              const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final clips =
              docs
                  .map(ProviderServiceListing.fromDocument)
                  .where((service) => service.isActive)
                  .toList()
                ..sort(
                  (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(2000))
                      .compareTo(a.updatedAt ?? a.createdAt ?? DateTime(2000)),
                );

          if (clips.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _ExploreServicesPageState._cardBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.play_circle_outline_rounded,
                        size: 42,
                        color: _ExploreServicesPageState._brandGreen,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Todavía no hay clips publicados',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Esta sección está pensada para piezas cortas que ayuden a vender mejor: demostraciones, antes y después, pruebas operativas y ofertas rápidas.',
                        style: TextStyle(
                          color: Color(0xFF65736C),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/sell-services'),
                        icon: const Icon(Icons.storefront_outlined),
                        label: const Text('Publicar mi primer clip'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A3222), Color(0xFF15623D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clips que mueven conversión',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Usa este carril para descubrir servicios en formato breve, abrir la ficha comercial y convertir una necesidad en compra o solicitud.',
                      style: TextStyle(color: Color(0xFFD8EADF), height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ClipHeaderChip(label: '${clips.length} clips activos'),
                        _ClipHeaderChip(
                          label:
                              '${clips.where((item) => item.commercialVideoUrl.trim().isNotEmpty).length} con video',
                        ),
                        _ClipHeaderChip(
                          label: '${_savedServiceIds.length} guardados',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: clips.length,
                  itemBuilder: (context, index) {
                    final service = clips[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: _MarketplaceClipCard(
                        key: ValueKey(service.id),
                        service: service,
                        position: index + 1,
                        isSaved: _savedServiceIds.contains(service.id),
                        isFollowingProvider: _followedProviderIds.contains(
                          service.providerId,
                        ),
                        onOpenService: () {
                          AnalyticsService.logEvent(
                            'open_marketplace_clip',
                            params: {
                              'service_id': service.id,
                              'provider_id': service.providerId,
                              'position': index + 1,
                            },
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProviderServiceDetailPage(service: service),
                            ),
                          );
                        },
                        onPrimaryAction: () {
                          _openBuyerRequestFromClip(service);
                        },
                        onToggleSaved: () => _toggleSavedService(service),
                        onToggleProviderFollow: () =>
                            _toggleFollowedProvider(service),
                        onShare: () => _shareClip(service),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MarketplaceClipCard extends StatefulWidget {
  const _MarketplaceClipCard({
    super.key,
    required this.service,
    required this.position,
    required this.isSaved,
    required this.isFollowingProvider,
    required this.onOpenService,
    required this.onPrimaryAction,
    required this.onToggleSaved,
    required this.onToggleProviderFollow,
    required this.onShare,
  });

  final ProviderServiceListing service;
  final int position;
  final bool isSaved;
  final bool isFollowingProvider;
  final VoidCallback onOpenService;
  final VoidCallback onPrimaryAction;
  final VoidCallback onToggleSaved;
  final VoidCallback onToggleProviderFollow;
  final VoidCallback onShare;

  @override
  State<_MarketplaceClipCard> createState() => _MarketplaceClipCardState();
}

class _MarketplaceClipCardState extends State<_MarketplaceClipCard> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _videoFailed = false;
  bool _isMuted = true;

  ProviderServiceListing get service => widget.service;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(covariant _MarketplaceClipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldVideo = oldWidget.service.commercialVideoUrl.trim();
    final nextVideo = widget.service.commercialVideoUrl.trim();
    if (oldWidget.service.id != widget.service.id || oldVideo != nextVideo) {
      _initializeVideo();
    }
  }

  Future<void> _disposeVideoController() async {
    final controller = _videoController;
    _videoController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _initializeVideo() async {
    await _disposeVideoController();
    _videoReady = false;
    _videoFailed = false;
    _isMuted = true;

    final videoUrl = service.commercialVideoUrl.trim();
    if (videoUrl.isEmpty) {
      if (mounted) {
        setState(() {});
      }
      return;
    }

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _videoController = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        return;
      }
      setState(() => _videoReady = true);
    } catch (_) {
      await _disposeVideoController();
      if (!mounted) {
        return;
      }
      setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    final controller = _videoController;
    _videoController = null;
    controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleMute() async {
    final controller = _videoController;
    if (controller == null || !_videoReady) {
      return;
    }
    final nextMuted = !_isMuted;
    await controller.setVolume(nextMuted ? 0 : 1);
    if (!mounted) {
      return;
    }
    setState(() => _isMuted = nextMuted);
  }

  Future<void> _togglePlayback() async {
    final controller = _videoController;
    if (controller == null || !_videoReady) {
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = service.commercialImageUrl.trim();
    final hasImage = imageUrl.isNotEmpty;
    final hasVideo = service.commercialVideoUrl.trim().isNotEmpty;
    final priceLabel = service.priceFrom > 0
        ? 'Desde ${service.priceFrom.toStringAsFixed(0)}'
        : 'Precio bajo cotización';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: widget.onOpenService,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: const Color(0xFF0D241A),
            gradient: (!hasImage && !hasVideo) || _videoFailed
                ? const LinearGradient(
                    colors: [Color(0xFF082519), Color(0xFF17633F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_videoReady && _videoController != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                )
              else if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: const Color(0xFF103724)),
                  ),
                )
              else if (hasVideo && !_videoFailed)
                const Center(
                  child: SizedBox(
                    height: 42,
                    width: 42,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.76),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Text(
                            hasVideo
                                ? 'Clip #${widget.position} · video'
                                : 'Clip #${widget.position}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_videoReady && _videoController != null) ...[
                          _ClipTopAction(
                            icon: _videoController!.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            onTap: _togglePlayback,
                          ),
                          const SizedBox(width: 8),
                          _ClipTopAction(
                            icon: _isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            onTap: _toggleMute,
                          ),
                        ] else
                          const Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                      ],
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ClipInfoChip(label: service.categoryName),
                        _ClipInfoChip(label: service.coverage),
                        _ClipInfoChip(label: service.responseTime),
                        if (service.emergencyAvailability)
                          const _ClipInfoChip(label: 'Emergencia'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      service.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.shortDescription.trim().isNotEmpty
                          ? service.shortDescription
                          : 'Servicio listo para cotización, comparación y cierre dentro del marketplace.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          backgroundImage:
                              service.providerLogoUrl.trim().isNotEmpty
                              ? NetworkImage(service.providerLogoUrl.trim())
                              : null,
                          child: service.providerLogoUrl.trim().isEmpty
                              ? const Icon(
                                  Icons.storefront,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.providerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${service.providerLocation} · $priceLabel',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.76),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ClipActionChip(
                          icon: widget.isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          label: widget.isSaved ? 'Guardado' : 'Guardar',
                          onTap: widget.onToggleSaved,
                        ),
                        _ClipActionChip(
                          icon: widget.isFollowingProvider
                              ? Icons.storefront_rounded
                              : Icons.storefront_outlined,
                          label: widget.isFollowingProvider
                              ? 'Siguiendo'
                              : 'Seguir',
                          onTap: widget.onToggleProviderFollow,
                        ),
                        _ClipActionChip(
                          icon: Icons.share_outlined,
                          label: 'Compartir',
                          onTap: widget.onShare,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onOpenService,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.32),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.remove_red_eye_outlined),
                            label: const Text('Ver ficha'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: widget.onPrimaryAction,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                                  _ExploreServicesPageState._brandGreen,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Comprar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClipTopAction extends StatelessWidget {
  const _ClipTopAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ClipActionChip extends StatelessWidget {
  const _ClipActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClipHeaderChip extends StatelessWidget {
  const _ClipHeaderChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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

class _SolutionPaths extends StatelessWidget {
  const _SolutionPaths({required this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    final categoryLabel = category?.trim().isNotEmpty == true
        ? category!.trim()
        : 'tu operación';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Rutas de compra sugeridas',
          subtitle:
              'El marketplace separa el flujo rápido, el flujo con visita y el negocio grande para no mezclar decisiones operativas.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SolutionPathCard(
              title: 'Compra ágil',
              description:
                  'Ideal cuando ya sabes qué servicio necesitas en $categoryLabel y quieres pasar del clip o la ficha a una solicitud directa.',
              icon: Icons.flash_on_rounded,
              accent: const Color(0xFF0C4F31),
              primaryLabel: 'Crear solicitud',
              onPrimaryTap: () => Navigator.pushNamed(
                context,
                '/crear_solicitud',
                arguments: {
                  'serviceInterest': category,
                  'requestSource': 'marketplace_solution_path_fast',
                },
              ),
            ),
            _SolutionPathCard(
              title: 'Cotización con visita previa',
              description:
                  'Úsala cuando necesitas validar sitio, volúmenes o frecuencia antes de cerrar precio.',
              icon: Icons.assignment_outlined,
              accent: const Color(0xFF896200),
              primaryLabel: 'Ver categorías',
              onPrimaryTap: () =>
                  Navigator.pushNamed(context, '/categories-pro'),
            ),
            _SolutionPathCard(
              title: 'Negocio grande o sensible',
              description:
                  'Escala a subasta si necesitas comparar varios proveedores con trazabilidad y fecha límite.',
              icon: Icons.gavel_outlined,
              accent: const Color(0xFF3657B7),
              primaryLabel: 'Ir a subastas',
              onPrimaryTap: () => Navigator.pushNamed(context, '/mis_subastas'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SolutionPathCard extends StatelessWidget {
  const _SolutionPathCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.primaryLabel,
    required this.onPrimaryTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _ExploreServicesPageState._cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: accent.withValues(alpha: 0.12),
              foregroundColor: accent,
              child: Icon(icon),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Color(0xFF61716A), height: 1.45),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPrimaryTap,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
              ),
              icon: Icon(icon),
              label: Text(primaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

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
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF61716A), height: 1.4),
        ),
      ],
    );
  }
}

class _MarketplaceTrustStrip extends StatelessWidget {
  const _MarketplaceTrustStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _ExploreServicesPageState._cardBorder),
      ),
      child: const Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _TrustBadge(
            icon: Icons.verified_user_outlined,
            label: 'Perfiles verificados',
          ),
          _TrustBadge(icon: Icons.bolt_outlined, label: 'Respuesta priorizada'),
          _TrustBadge(
            icon: Icons.shield_outlined,
            label: 'Cierre con trazabilidad',
          ),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: 18,
        color: _ExploreServicesPageState._brandGreen,
      ),
      label: Text(label),
      side: BorderSide.none,
      backgroundColor: const Color(0xFFF1F6F3),
    );
  }
}

class _ProviderMarketplaceCard extends StatelessWidget {
  const _ProviderMarketplaceCard({
    required this.provider,
    required this.rankIndex,
    required this.isSaved,
    required this.isCompared,
    required this.onToggleSaved,
    required this.onToggleCompare,
  });

  final Map<String, dynamic> provider;
  final int rankIndex;
  final bool isSaved;
  final bool isCompared;
  final VoidCallback onToggleSaved;
  final VoidCallback onToggleCompare;

  @override
  Widget build(BuildContext context) {
    final logoUrl = provider['logoUrl']?.toString() ?? '';
    final services =
        (provider['services'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    final reputation = ProviderCommercialReputationService.fromProviderData(
      provider,
      activeServiceCount: services.length,
    );
    final rankingBadge = ProviderCommercialReputationService.rankingBadge(
      snapshot: reputation,
      index: rankIndex,
    );
    final documentCount = [
      provider['rutUrl'],
      provider['camaraComercioUrl'],
      provider['cedulaUrl'],
      provider['certificadoBancarioUrl'],
    ].where((item) => item?.toString().trim().isNotEmpty == true).length;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          AnalyticsService.logEvent(
            'open_ranked_provider_profile',
            params: {
              'provider_id': provider['id']?.toString() ?? '',
              'rank_index': rankIndex + 1,
            },
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProviderDetailPage(provider: provider),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _ExploreServicesPageState._cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFEAF3ED),
                    backgroundImage: logoUrl.isNotEmpty
                        ? NetworkImage(logoUrl)
                        : null,
                    child: logoUrl.isEmpty
                        ? const Icon(
                            Icons.business,
                            color: _ExploreServicesPageState._brandGreenSoft,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider['name']?.toString() ?? 'Proveedor',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider['city']?.toString() ?? 'Sin ubicación',
                          style: const TextStyle(
                            color: Color(0xFF617068),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: rankIndex == 0
                          ? const Color(0xFFEAF4EC)
                          : const Color(0xFFF4F7F5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#${rankIndex + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: rankIndex == 0
                            ? _ExploreServicesPageState._brandGreen
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: rankIndex == 0
                      ? const Color(0xFFEAF4EC)
                      : const Color(0xFFF4F7F5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  rankingBadge,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: rankIndex == 0
                        ? _ExploreServicesPageState._brandGreen
                        : const Color(0xFF2A3A33),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                provider['description']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF5F6D66), height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaPill(
                    icon: Icons.storefront_outlined,
                    label: '${services.length} especialidades',
                  ),
                  _MetaPill(
                    icon: Icons.folder_outlined,
                    label: '$documentCount soportes base',
                  ),
                  _MetaPill(
                    icon: Icons.verified_user_outlined,
                    label: provider['profileCompleted'] == true
                        ? 'Validado'
                        : 'En revisión',
                  ),
                  _MetaPill(
                    icon: Icons.workspace_premium_outlined,
                    label:
                        'Tier ${reputation.tier} · ${reputation.formattedScore}/100',
                  ),
                  _MetaPill(
                    icon: Icons.bolt_outlined,
                    label: 'SLA ${reputation.responseLabel}',
                  ),
                  if (services.isNotEmpty)
                    _MetaPill(
                      icon: Icons.category_outlined,
                      label: services.first,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProviderDetailPage(provider: provider),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _ExploreServicesPageState._brandGreen,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('Ver perfil comercial'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onToggleCompare,
                    icon: Icon(
                      isCompared
                          ? Icons.checklist_rounded
                          : Icons.compare_arrows_rounded,
                    ),
                    label: Text(
                      isCompared
                          ? 'En comparador del generador'
                          : 'Comparar para este generador',
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: onToggleSaved,
                    icon: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                    tooltip: isSaved
                        ? 'Quitar de guardados'
                        : 'Guardar proveedor',
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

class _MarketplaceAlertsPulse extends StatelessWidget {
  const _MarketplaceAlertsPulse({
    required this.userId,
    required this.savedProvidersCount,
    required this.savedServicesCount,
    required this.comparedCount,
  });

  final String userId;
  final int savedProvidersCount;
  final int savedServicesCount;
  final int comparedCount;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('commercial_chats')
          .where('generatorId', isEqualTo: userId)
          .snapshots(),
      builder: (context, chatsSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('payments')
              .where('generadorId', isEqualTo: userId)
              .snapshots(),
          builder: (context, paymentsSnapshot) {
            if (chatsSnapshot.connectionState == ConnectionState.waiting ||
                paymentsSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            final chats = chatsSnapshot.data?.docs ?? const [];
            final payments = paymentsSnapshot.data?.docs ?? const [];
            final pendingMessages = chats.where((doc) {
              final data = doc.data();
              return (data['lastSenderRole']?.toString() ?? '') ==
                      'proveedor' &&
                  (data['lastMessage']?.toString().trim().isNotEmpty ?? false);
            }).length;
            final custodyPayments = payments.where((doc) {
              final status = doc.data()['paymentStatus']?.toString() ?? '';
              return status == 'en_custodia';
            }).length;
            final disputedPayments = payments.where((doc) {
              final status = doc.data()['paymentStatus']?.toString() ?? '';
              return status == 'en_disputa';
            }).length;

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDDE7E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Radar premium',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mensajes, pagos y oportunidades listas para reactivarse desde el mismo flujo comercial.',
                    style: TextStyle(color: Color(0xFF63736C), height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ExecutiveMetricCard(
                        title: 'Mensajes pendientes',
                        value: '$pendingMessages',
                        hint: 'respuestas comerciales del proveedor',
                        icon: Icons.mark_chat_unread_outlined,
                      ),
                      _ExecutiveMetricCard(
                        title: 'Pagos en custodia',
                        value: '$custodyPayments',
                        hint: 'cierres esperando validación',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      _ExecutiveMetricCard(
                        title: 'Casos en disputa',
                        value: '$disputedPayments',
                        hint: 'negocios con revisión activa',
                        icon: Icons.gpp_maybe_outlined,
                      ),
                      _ExecutiveMetricCard(
                        title: 'Radar guardado',
                        value: '${savedProvidersCount + savedServicesCount}',
                        hint: '$comparedCount comparaciones activas',
                        icon: Icons.bookmark_outline_rounded,
                      ),
                    ],
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

class _MarketplaceExecutiveDashboard extends StatelessWidget {
  const _MarketplaceExecutiveDashboard({
    required this.providers,
    required this.services,
    required this.savedProvidersCount,
    required this.savedServicesCount,
    required this.comparedCount,
  });

  final List<Map<String, dynamic>> providers;
  final List<ProviderServiceListing> services;
  final int savedProvidersCount;
  final int savedServicesCount;
  final int comparedCount;

  @override
  Widget build(BuildContext context) {
    final premiumCount = providers.where((provider) {
      final snapshot = ProviderCommercialReputationService.fromProviderData(
        provider,
        activeServiceCount:
            ((provider['services'] as List?) ?? const []).length,
      );
      return snapshot.tier == 'A' || snapshot.tier == 'B';
    }).length;
    final avgScore = providers.isEmpty
        ? 0.0
        : providers
                  .map(
                    (
                      provider,
                    ) => ProviderCommercialReputationService.rankingIndex(
                      provider,
                      activeServiceCount:
                          ((provider['services'] as List?) ?? const []).length,
                    ),
                  )
                  .reduce((a, b) => a + b) /
              providers.length;
    final fastSlaCount = providers.where((provider) {
      final minutes =
          (provider['avgResponseTimeMinutes'] as num?)?.toDouble() ?? 0;
      return minutes > 0 && minutes <= 180;
    }).length;
    final emergencyServices = services.where((service) {
      return service.emergencyAvailability;
    }).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE7E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard ejecutivo',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Vista rápida del embudo visible: oferta activa, confianza comercial y señales de intención del generador.',
            style: TextStyle(color: Color(0xFF63736C), height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ExecutiveMetricCard(
                title: 'Proveedores visibles',
                value: '${providers.length}',
                hint: '$premiumCount en tier alto',
                icon: Icons.storefront_outlined,
              ),
              _ExecutiveMetricCard(
                title: 'Score promedio',
                value: avgScore.toStringAsFixed(0),
                hint: 'ranking comercial agregado',
                icon: Icons.analytics_outlined,
              ),
              _ExecutiveMetricCard(
                title: 'SLA competitivo',
                value: '$fastSlaCount',
                hint: 'responden en menos de 3 horas',
                icon: Icons.bolt_outlined,
              ),
              _ExecutiveMetricCard(
                title: 'Servicios críticos',
                value: '$emergencyServices',
                hint:
                    '${savedProvidersCount + savedServicesCount} guardados · $comparedCount en comparador',
                icon: Icons.dashboard_customize_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepurchasePlaybook extends StatelessWidget {
  const _RepurchasePlaybook({
    required this.userId,
    required this.defaultCategory,
  });

  final String userId;
  final String? defaultCategory;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('generadorId', isEqualTo: userId)
          .where('paymentStatus', isEqualTo: 'liberado')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final grouped = <String, Map<String, dynamic>>{};
        for (final doc in docs) {
          final data = doc.data();
          final providerId = data['proveedorId']?.toString() ?? '';
          if (providerId.isEmpty) {
            continue;
          }
          final bucket = grouped.putIfAbsent(providerId, () {
            return {
              'providerId': providerId,
              'providerName': data['providerName']?.toString() ?? 'Proveedor',
              'requestTitle': data['requestTitle']?.toString() ?? 'Servicio',
              'count': 0,
              'lastDate': _resolveMarketplaceDate(data),
            };
          });
          bucket['count'] = ((bucket['count'] as int?) ?? 0) + 1;
          final candidateDate = _resolveMarketplaceDate(data);
          final currentDate = bucket['lastDate'] as DateTime;
          if (candidateDate.isAfter(currentDate)) {
            bucket['lastDate'] = candidateDate;
            bucket['requestTitle'] =
                data['requestTitle']?.toString() ?? bucket['requestTitle'];
          }
        }

        final items = grouped.values.toList()
          ..sort((a, b) {
            final countCompare = ((b['count'] as int?) ?? 0).compareTo(
              (a['count'] as int?) ?? 0,
            );
            if (countCompare != 0) {
              return countCompare;
            }
            return (b['lastDate'] as DateTime).compareTo(
              a['lastDate'] as DateTime,
            );
          });

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDDE7E0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recompra y reactivación',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'SaneApp prioriza proveedores con cierres previos liberados para que puedas reactivar compras recurrentes sin volver a empezar desde cero.',
                style: TextStyle(color: Color(0xFF63736C), height: 1.4),
              ),
              const SizedBox(height: 14),
              ...items.take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FBF9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDCE7DF)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['providerName']?.toString() ?? 'Proveedor',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Último cierre: ${item['requestTitle']?.toString() ?? 'Servicio'}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item['count']} cierres liberados · última liberación ${_formatMarketplaceDate(item['lastDate'] as DateTime)}',
                                style: const TextStyle(
                                  color: Color(0xFF63736C),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: () {
                            AnalyticsService.logEvent(
                              'marketplace_repurchase_cta',
                              params: {
                                'provider_id':
                                    item['providerId']?.toString() ?? '',
                              },
                            );
                            Navigator.pushNamed(
                              context,
                              '/crear_solicitud',
                              arguments: {
                                'serviceInterest': defaultCategory,
                                'requestIntent': 'repeat_purchase_request',
                                'requestSource': 'marketplace_repurchase',
                                'preferredProviderId': item['providerId']
                                    ?.toString(),
                                'preferredProviderName': item['providerName']
                                    ?.toString(),
                                'requestTitle':
                                    'Recompra con ${item['providerName']?.toString() ?? 'proveedor'}',
                                'requestDescription':
                                    'Quiero reactivar una compra con ${item['providerName']?.toString() ?? 'este proveedor'} tomando como referencia un cierre previo ya liberado en SaneApp.',
                                'requestNotes':
                                    'Reactivación comercial sugerida por historial de cierres liberados.',
                              },
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                _ExploreServicesPageState._brandGreen,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.replay_outlined),
                          label: const Text('Reactivar'),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _ExecutiveMetricCard extends StatelessWidget {
  const _ExecutiveMetricCard({
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
  });

  final String title;
  final String value;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7E0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _ExploreServicesPageState._brandGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(
                    color: Color(0xFF61736C),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

DateTime _resolveMarketplaceDate(Map<String, dynamic> data) {
  final candidate =
      data['updatedAt'] ??
      data['createdAt'] ??
      data['closedAt'] ??
      data['date'];
  if (candidate is Timestamp) {
    return candidate.toDate();
  }
  if (candidate is DateTime) {
    return candidate;
  }
  if (candidate is int) {
    return DateTime.fromMillisecondsSinceEpoch(candidate);
  }
  if (candidate is String) {
    final parsed = DateTime.tryParse(candidate);
    if (parsed != null) {
      return parsed;
    }
    final asInt = int.tryParse(candidate);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt);
    }
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _formatMarketplaceDate(DateTime date) {
  if (date.millisecondsSinceEpoch == 0) {
    return 'sin fecha';
  }
  return '${date.day}/${date.month}/${date.year}';
}

class _MarketplaceSaveCompareBar extends StatelessWidget {
  const _MarketplaceSaveCompareBar({
    required this.savedProvidersCount,
    required this.savedServicesCount,
    required this.comparedCount,
    required this.onOpenCompare,
    required this.onClearCompare,
  });

  final int savedProvidersCount;
  final int savedServicesCount;
  final int comparedCount;
  final VoidCallback onOpenCompare;
  final Future<void> Function() onClearCompare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _StatusChip(
            icon: Icons.bookmark_rounded,
            label: '$savedProvidersCount proveedores guardados',
          ),
          _StatusChip(
            icon: Icons.inventory_2_outlined,
            label: '$savedServicesCount servicios guardados',
          ),
          _StatusChip(
            icon: Icons.compare_arrows_rounded,
            label: '$comparedCount en el comparador del generador',
          ),
          if (comparedCount > 0)
            FilledButton.icon(
              onPressed: onOpenCompare,
              style: FilledButton.styleFrom(
                backgroundColor: _ExploreServicesPageState._brandGreen,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.dashboard_customize_outlined),
              label: const Text('Abrir comparador del generador'),
            ),
          if (comparedCount > 0)
            TextButton(
              onPressed: onClearCompare,
              child: const Text('Limpiar comparación'),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _ExploreServicesPageState._brandGreen),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _ComparisonTile extends StatelessWidget {
  const _ComparisonTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        tileColor: Colors.white,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEAF3ED),
          child: Icon(Icons.analytics_outlined, color: Color(0xFF0C4F31)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle, style: const TextStyle(height: 1.35)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(trailing, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Abrir', style: TextStyle(color: Colors.black45)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _InlineHintCard extends StatelessWidget {
  final String text;

  const _InlineHintCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E9E2)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF65736C), height: 1.4),
      ),
    );
  }
}

class _SolutionCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _SolutionCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });
}

// ignore: unused_element
class _SolutionCard extends StatelessWidget {
  final _SolutionCardData item;

  const _SolutionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE7E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.accent),
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            item.subtitle,
            style: const TextStyle(color: Color(0xFF65736C), height: 1.38),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF63736C),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _DrawerMenuTile extends StatelessWidget {
  const _DrawerMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: const Color(0xFF2A3A33)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF8A9991),
      ),
      onTap: onTap,
    );
  }
}

class _DrawerHighlightTile extends StatelessWidget {
  const _DrawerHighlightTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF4EC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: _ExploreServicesPageState._brandGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ExploreServicesPageState._brandGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: _ExploreServicesPageState._brandGreen.withValues(
                  alpha: 0.82,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketplaceFeaturePage extends StatelessWidget {
  const _MarketplaceFeaturePage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.primaryLabel,
    required this.onPrimaryTap,
    this.secondaryLabel,
    this.onSecondaryTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String primaryLabel;
  final VoidCallback onPrimaryTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: _ExploreServicesPageState._brandGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor,
                  _ExploreServicesPageState._brandGreenSoft,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 34),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Usa este acceso para seguir el flujo comercial correcto dentro de SaneApp.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF61716A),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onPrimaryTap,
                      icon: Icon(icon),
                      label: Text(primaryLabel),
                    ),
                  ),
                  if (secondaryLabel != null && onSecondaryTap != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onSecondaryTap,
                        child: Text(secondaryLabel!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClipInfoChip extends StatelessWidget {
  const _ClipInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label.trim().isNotEmpty ? label : 'Marketplace',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SavedMarketplacePage extends StatelessWidget {
  const _SavedMarketplacePage({
    required this.providerIds,
    required this.serviceIds,
  });

  final Set<String> providerIds;
  final Set<String> serviceIds;

  Map<String, dynamic> _normalizeProviderDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final categories =
        (data['selectedCategories'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    return {
      'id': doc.id,
      'name': (data['companyName'] as String?)?.trim().isNotEmpty == true
          ? (data['companyName'] as String).trim()
          : 'Proveedor sin nombre',
      'city': (data['operationAddress'] as String?)?.trim() ?? 'Sin ubicación',
      'services': categories,
      'profileCompleted': data['profileCompleted'] == true,
      'logoUrl': (data['logoUrl'] as String?)?.trim() ?? '',
      'photoUrl': (data['photoUrl'] as String?)?.trim() ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Favoritos'),
        backgroundColor: _ExploreServicesPageState._brandGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('providers').snapshots(),
        builder: (context, providersSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('provider_services')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, servicesSnapshot) {
              if (providersSnapshot.connectionState ==
                      ConnectionState.waiting ||
                  servicesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final providers = (providersSnapshot.data?.docs ?? const [])
                  .map(_normalizeProviderDoc)
                  .where(
                    (provider) =>
                        providerIds.contains(provider['id']?.toString() ?? ''),
                  )
                  .toList();
              final services = (servicesSnapshot.data?.docs ?? const [])
                  .map(ProviderServiceListing.fromDocument)
                  .where((service) => serviceIds.contains(service.id))
                  .toList();

              if (providers.isEmpty && services.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Todavía no tienes favoritos guardados en el marketplace.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  const _SectionTitle(
                    title: 'Favoritos del marketplace',
                    subtitle:
                        'Aquí se concentran las empresas y servicios que guardaste para retomar una decisión comercial después.',
                  ),
                  if (providers.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionTitle(
                      title: 'Tiendas que sigues',
                      subtitle:
                          'Empresas a las que decidiste volver para comparar su perfil o solicitar propuesta.',
                    ),
                    const SizedBox(height: 10),
                    ...providers.map(
                      (provider) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            leading: _ProviderIdentityAvatar(
                              provider: provider,
                            ),
                            title: Text(
                              provider['name']?.toString() ?? 'Proveedor',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${provider['city']} · ${((provider['services'] as List?) ?? const []).length} especialidades',
                            ),
                            trailing: provider['profileCompleted'] == true
                                ? const Icon(
                                    Icons.verified_rounded,
                                    color:
                                        _ExploreServicesPageState._brandGreen,
                                  )
                                : null,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProviderDetailPage(provider: provider),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (services.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const _SectionTitle(
                      title: 'Servicios guardados',
                      subtitle:
                          'Atajos para volver a fichas comerciales que ya superaron tu primer filtro de interés.',
                    ),
                    const SizedBox(height: 10),
                    ...services.map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.bookmark_outline_rounded),
                            title: Text(
                              service.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${service.providerName} · ${service.coverage}',
                            ),
                            trailing: Text(
                              'Desde ${service.priceFrom.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProviderServiceDetailPage(
                                    service: service,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

String _buildStaticInitials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'SA';
  }
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length >= 2 ? 2 : 1)
        .toUpperCase();
  }
  return (parts.first[0] + parts[1][0]).toUpperCase();
}

class _MarketplaceCouponsPage extends StatelessWidget {
  const _MarketplaceCouponsPage();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final couponsStream = FirebaseFirestore.instance
        .collection('marketplace_coupons')
        .where('isActive', isEqualTo: true)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: const Text('Cupones'),
        backgroundColor: _ExploreServicesPageState._brandGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: couponsStream,
        builder: (context, couponsSnapshot) {
          if (couponsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final coupons = [...(couponsSnapshot.data?.docs ?? const [])]
            ..sort((a, b) {
              final aData = a.data();
              final bData = b.data();
              final aPriority = (aData['priority'] as num?)?.toInt() ?? 0;
              final bPriority = (bData['priority'] as num?)?.toInt() ?? 0;
              if (aPriority != bPriority) {
                return bPriority.compareTo(aPriority);
              }
              return _resolveCouponDate(
                bData,
                'expiresAt',
              ).compareTo(_resolveCouponDate(aData, 'expiresAt'));
            });

          if (user == null) {
            return _CouponsScaffoldBody(
              coupons: coupons
                  .cast<QueryDocumentSnapshot<Map<String, dynamic>>>(),
              claimsByCouponId: const <String, Map<String, dynamic>>{},
              onClaim: (couponId, data) async {
                Navigator.pushNamed(context, '/login');
              },
              anonymousMode: true,
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('user_coupon_claims')
                .where('userId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, claimsSnapshot) {
              final claimsByCouponId = <String, Map<String, dynamic>>{
                for (final doc in claimsSnapshot.data?.docs ?? const [])
                  doc.data()['couponId']?.toString() ?? '': doc.data(),
              };
              return _CouponsScaffoldBody(
                coupons: coupons
                    .cast<QueryDocumentSnapshot<Map<String, dynamic>>>(),
                claimsByCouponId: claimsByCouponId,
                onClaim: (couponId, data) async {
                  final claimRef = FirebaseFirestore.instance
                      .collection('user_coupon_claims')
                      .doc('${user.uid}_$couponId');

                  final code =
                      (data['code']?.toString().trim().isNotEmpty == true)
                      ? data['code'].toString().trim()
                      : 'SANEAPP';

                  await claimRef.set({
                    'couponId': couponId,
                    'userId': user.uid,
                    'code': code,
                    'title': data['title']?.toString().trim(),
                    'discountLabel': data['discountLabel']?.toString().trim(),
                    'claimStatus': 'active',
                    'claimedAt': FieldValue.serverTimestamp(),
                    'expiresAt': data['expiresAt'],
                  }, SetOptions(merge: true));

                  if (!context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cupón $code guardado en tu cuenta.'),
                    ),
                  );
                },
                anonymousMode: false,
              );
            },
          );
        },
      ),
    );
  }
}

class _CouponsScaffoldBody extends StatelessWidget {
  const _CouponsScaffoldBody({
    required this.coupons,
    required this.claimsByCouponId,
    required this.onClaim,
    required this.anonymousMode,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> coupons;
  final Map<String, Map<String, dynamic>> claimsByCouponId;
  final Future<void> Function(String couponId, Map<String, dynamic> data)
  onClaim;
  final bool anonymousMode;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                _ExploreServicesPageState._brandGreen,
                _ExploreServicesPageState._brandGreenSoft,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(height: 14),
              const Text(
                'Beneficios activos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                anonymousMode
                    ? 'Puedes explorar campañas activas. Para reclamar un cupón y dejarlo ligado a tu cuenta, entra cuando lo necesites.'
                    : 'Tus cupones se guardan en Firestore para que puedas reutilizarlos en el flujo comercial y financiero de SaneApp.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (coupons.isEmpty)
          const _InlineHintCard(
            text:
                'Aún no hay campañas activas en el marketplace. Cuando el equipo comercial cargue beneficios, aparecerán aquí.',
          )
        else
          ...coupons.map((doc) {
            final data = doc.data();
            final claim = claimsByCouponId[doc.id];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CouponCard(
                couponId: doc.id,
                data: data,
                claim: claim,
                anonymousMode: anonymousMode,
                onClaim: onClaim,
              ),
            );
          }),
      ],
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.couponId,
    required this.data,
    required this.claim,
    required this.anonymousMode,
    required this.onClaim,
  });

  final String couponId;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? claim;
  final bool anonymousMode;
  final Future<void> Function(String couponId, Map<String, dynamic> data)
  onClaim;

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString().trim().isNotEmpty == true
        ? data['title'].toString().trim()
        : 'Campaña comercial';
    final description =
        data['description']?.toString().trim().isNotEmpty == true
        ? data['description'].toString().trim()
        : 'Beneficio disponible para operaciones activas dentro de SaneApp.';
    final code = data['code']?.toString().trim().toUpperCase() ?? 'SANEAPP';
    final discountLabel =
        data['discountLabel']?.toString().trim().isNotEmpty == true
        ? data['discountLabel'].toString().trim()
        : 'Beneficio comercial';
    final audience = data['audienceLabel']?.toString().trim().isNotEmpty == true
        ? data['audienceLabel'].toString().trim()
        : 'Marketplace';
    final expiresAt = _resolveCouponDate(data, 'expiresAt');
    final isClaimed = claim != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4EC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    discountLabel,
                    style: const TextStyle(
                      color: _ExploreServicesPageState._brandGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                _CouponStatusChip(
                  label: isClaimed ? 'Guardado' : 'Disponible',
                  tone: isClaimed
                      ? const Color(0xFF1565C0)
                      : _ExploreServicesPageState._brandGreen,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(color: Color(0xFF63736C), height: 1.45),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Código $code',
                ),
                _StatusChip(icon: Icons.groups_outlined, label: audience),
                _StatusChip(
                  icon: Icons.schedule_outlined,
                  label: 'Vence ${_formatMarketplaceDate(expiresAt)}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isClaimed ? null : () => onClaim(couponId, data),
                icon: Icon(
                  anonymousMode
                      ? Icons.login_rounded
                      : isClaimed
                      ? Icons.check_circle_outline_rounded
                      : Icons.add_card_rounded,
                ),
                label: Text(
                  anonymousMode
                      ? 'Entrar para reclamar'
                      : isClaimed
                      ? 'Cupón guardado'
                      : 'Guardar en mi cuenta',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Código $code copiado.')),
                  );
                },
                icon: const Icon(Icons.copy_all_rounded),
                label: const Text('Copiar código'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponStatusChip extends StatelessWidget {
  const _CouponStatusChip({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: tone, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MarketplaceReviewsPage extends StatelessWidget {
  const _MarketplaceReviewsPage();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis opiniones'),
          backgroundColor: _ExploreServicesPageState._brandGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('No autenticado.')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FAF7),
        appBar: AppBar(
          title: const Text('Mis opiniones'),
          backgroundColor: _ExploreServicesPageState._brandGreen,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Emitidas'),
              Tab(text: 'Recibidas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MarketplaceRatingsTab(
              query: FirebaseFirestore.instance
                  .collection('ratings')
                  .where('fromUserId', isEqualTo: user.uid)
                  .snapshots(),
              emptyMessage:
                  'Aún no has dejado opiniones registradas en cierres comerciales.',
              summaryLabel: 'Opiniones emitidas',
              accentColor: const Color(0xFF8A5E00),
              peerField: 'toUserId',
              reviewPerspective: _ReviewPerspective.sent,
            ),
            _MarketplaceRatingsTab(
              query: FirebaseFirestore.instance
                  .collection('ratings')
                  .where('toUserId', isEqualTo: user.uid)
                  .snapshots(),
              emptyMessage:
                  'Todavía no recibes opiniones visibles en este módulo.',
              summaryLabel: 'Opiniones recibidas',
              accentColor: _ExploreServicesPageState._brandGreenSoft,
              peerField: 'fromUserId',
              reviewPerspective: _ReviewPerspective.received,
            ),
          ],
        ),
      ),
    );
  }
}

enum _ReviewPerspective { sent, received }

class _MarketplaceRatingsTab extends StatefulWidget {
  const _MarketplaceRatingsTab({
    required this.query,
    required this.emptyMessage,
    required this.summaryLabel,
    required this.accentColor,
    required this.peerField,
    required this.reviewPerspective,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> query;
  final String emptyMessage;
  final String summaryLabel;
  final Color accentColor;
  final String peerField;
  final _ReviewPerspective reviewPerspective;

  @override
  State<_MarketplaceRatingsTab> createState() => _MarketplaceRatingsTabState();
}

class _MarketplaceRatingsTabState extends State<_MarketplaceRatingsTab> {
  int _minimumStars = 0;
  String _roleFilter = 'todos';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.query,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = [...(snapshot.data?.docs ?? const [])]
          ..sort(
            (a, b) => _resolveCouponDate(
              b.data(),
              'createdAt',
            ).compareTo(_resolveCouponDate(a.data(), 'createdAt')),
          );

        final filteredDocs = docs.where((doc) {
          final data = doc.data();
          final stars = (data['stars'] as num?)?.toInt() ?? 0;
          final role = data['role']?.toString().trim().toLowerCase() ?? '';
          final matchesStars = stars >= _minimumStars;
          final matchesRole = _roleFilter == 'todos' || role == _roleFilter;
          return matchesStars && matchesRole;
        }).toList();

        final average = filteredDocs.isEmpty
            ? 0.0
            : filteredDocs
                      .map(
                        (doc) => (doc.data()['stars'] as num?)?.toDouble() ?? 0,
                      )
                      .reduce((a, b) => a + b) /
                  filteredDocs.length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFDDE7E0)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ReviewStatCard(
                    title: widget.summaryLabel,
                    value: '${filteredDocs.length}',
                    hint: 'registros persistidos en Firestore',
                    accentColor: widget.accentColor,
                    icon: Icons.rate_review_outlined,
                  ),
                  _ReviewStatCard(
                    title: 'Promedio',
                    value: average.toStringAsFixed(1),
                    hint: 'estrellas consolidadas',
                    accentColor: const Color(0xFFB77900),
                    icon: Icons.star_outline_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFDDE7E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrar opiniones',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _roleFilter,
                    decoration: const InputDecoration(
                      labelText: 'Rol comercial',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'todos', child: Text('Todos')),
                      DropdownMenuItem(
                        value: 'client_to_provider',
                        child: Text('Cliente a proveedor'),
                      ),
                      DropdownMenuItem(
                        value: 'provider_to_client',
                        child: Text('Proveedor a cliente'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _roleFilter = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [0, 3, 4, 5].map((stars) {
                      final selected = _minimumStars == stars;
                      return ChoiceChip(
                        label: Text(stars == 0 ? 'Todas' : '$stars+ estrellas'),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _minimumStars = stars),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (filteredDocs.isEmpty)
              _InlineHintCard(text: widget.emptyMessage)
            else
              ...filteredDocs.map(
                (doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReviewTile(
                    data: doc.data(),
                    peerField: widget.peerField,
                    reviewPerspective: widget.reviewPerspective,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReviewStatCard extends StatelessWidget {
  const _ReviewStatCard({
    required this.title,
    required this.value,
    required this.hint,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final String value;
  final String hint;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(color: Color(0xFF63736C), height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.data,
    required this.peerField,
    required this.reviewPerspective,
  });

  final Map<String, dynamic> data;
  final String peerField;
  final _ReviewPerspective reviewPerspective;

  @override
  Widget build(BuildContext context) {
    final stars = (data['stars'] as num?)?.toInt() ?? 0;
    final comment = data['comment']?.toString().trim() ?? '';
    final serviceId = data['serviceId']?.toString().trim();
    final peerUserId = data[peerField]?.toString().trim() ?? '';
    final date = _resolveCouponDate(data, 'createdAt');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: peerUserId.isEmpty
                        ? null
                        : FirebaseFirestore.instance
                              .collection('users')
                              .doc(peerUserId)
                              .get(),
                    builder: (context, snapshot) {
                      final peerData = snapshot.data?.data();
                      final peerName =
                          peerData?['fullName']?.toString().trim().isNotEmpty ==
                              true
                          ? peerData!['fullName'].toString().trim()
                          : peerData?['companyName']
                                    ?.toString()
                                    .trim()
                                    .isNotEmpty ==
                                true
                          ? peerData!['companyName'].toString().trim()
                          : 'Usuario relacionado';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewPerspective == _ReviewPerspective.sent
                                ? 'Opinión sobre $peerName'
                                : 'Opinión de $peerName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            serviceId?.isNotEmpty == true
                                ? 'Servicio $serviceId · ${_formatMarketplaceDate(date)}'
                                : _formatMarketplaceDate(date),
                            style: const TextStyle(color: Color(0xFF63736C)),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6DD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFFB77900),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$stars/5',
                        style: const TextStyle(
                          color: Color(0xFF8A5E00),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              comment.isEmpty ? 'Sin comentario adicional.' : comment,
              style: const TextStyle(color: Color(0xFF2A3A33), height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceProviderDirectoryPage extends StatelessWidget {
  const _MarketplaceProviderDirectoryPage({
    required this.title,
    required this.subtitle,
    this.providerIds,
    this.onlyOfficial = false,
  });

  final String title;
  final String subtitle;
  final Set<String>? providerIds;
  final bool onlyOfficial;

  Map<String, dynamic> _normalizeProviderDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final categories =
        (data['selectedCategories'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        const <String>[];
    return {
      'id': doc.id,
      'name': (data['companyName'] as String?)?.trim().isNotEmpty == true
          ? (data['companyName'] as String).trim()
          : 'Proveedor sin nombre',
      'city': (data['operationAddress'] as String?)?.trim() ?? 'Sin ubicación',
      'services': categories,
      'description':
          (data['serviceArea'] as String?)?.trim() ??
          'Operador ambiental activo.',
      'profileCompleted': data['profileCompleted'] == true,
      'ratingAverage': (data['ratingAverage'] as num?)?.toDouble() ?? 0,
      'commercialScore': (data['commercialScore'] as num?)?.toDouble() ?? 0,
      'logoUrl': (data['logoUrl'] as String?)?.trim() ?? '',
      'photoUrl': (data['photoUrl'] as String?)?.trim() ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: _ExploreServicesPageState._brandGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('providers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items =
              (snapshot.data?.docs ?? const [])
                  .map(_normalizeProviderDoc)
                  .where((provider) {
                    final id = provider['id']?.toString() ?? '';
                    if (providerIds != null && !providerIds!.contains(id)) {
                      return false;
                    }
                    if (onlyOfficial && provider['profileCompleted'] != true) {
                      return false;
                    }
                    return true;
                  })
                  .toList()
                ..sort((a, b) {
                  final scoreA = (a['commercialScore'] as double?) ?? 0;
                  final scoreB = (b['commercialScore'] as double?) ?? 0;
                  return scoreB.compareTo(scoreA);
                });

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  onlyOfficial
                      ? 'Aún no hay empresas oficiales visibles en este directorio.'
                      : 'Todavía no sigues empresas desde el marketplace.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              _SectionTitle(title: title, subtitle: subtitle),
              const SizedBox(height: 12),
              ...items.map(
                (provider) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: _ProviderIdentityAvatar(provider: provider),
                      title: Text(
                        provider['name']?.toString() ?? 'Proveedor',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${provider['city']} · ${((provider['services'] as List?) ?? const []).length} especialidades',
                          style: const TextStyle(height: 1.4),
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (provider['profileCompleted'] == true)
                            const Icon(
                              Icons.verified_rounded,
                              color: _ExploreServicesPageState._brandGreen,
                            ),
                          Text(
                            ((provider['ratingAverage'] as double?) ?? 0)
                                .toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProviderDetailPage(provider: provider),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProviderIdentityAvatar extends StatelessWidget {
  const _ProviderIdentityAvatar({required this.provider});

  final Map<String, dynamic> provider;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (provider['logoUrl']?.toString().trim().isNotEmpty == true)
        ? provider['logoUrl'].toString().trim()
        : provider['photoUrl']?.toString().trim() ?? '';

    return CircleAvatar(
      radius: 23,
      backgroundColor: const Color(0xFFEAF4EC),
      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      child: imageUrl.isEmpty
          ? Text(
              _buildStaticInitials(provider['name']?.toString() ?? ''),
              style: const TextStyle(
                color: _ExploreServicesPageState._brandGreen,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

DateTime _resolveCouponDate(Map<String, dynamic> data, String field) {
  final candidates = [data[field], data['updatedAt'], data['createdAt']];
  for (final candidate in candidates) {
    if (candidate is Timestamp) {
      return candidate.toDate();
    }
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
