import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';

import 'state/app_state.dart';
import 'firebase_options.dart';
import 'features/legal/privacy_policy_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/auth/client_profile_screen.dart' as client_profile;
import 'features/home/company_requests_page.dart';
import 'features/home/company_admin_page.dart';
import 'features/home/request_service_page.dart';
import 'features/home/final_disposal_certificates_page.dart';
import 'features/home/explore_services_page.dart';
import 'features/home/emergency_services_page.dart';
import 'features/home/derrame_quimico_page.dart';
import 'features/home/notifications_page.dart';
import 'features/home/profile_page.dart';
import 'features/home/settings_page.dart';
import 'features/home/edit_profile_page.dart';
import 'features/home/verification_page.dart';
import 'features/home/metrics_page.dart';
import 'features/home/support_page.dart';
import 'features/home/request_history_page.dart';
import 'features/home/my_requests_page.dart' as my_requests_page;
import 'features/home/my_requests_pro_page.dart' as my_requests_pro_page;
import 'features/home/categories_pro_page.dart';
import 'features/home/industrial_cleaning_page.dart';
import 'features/home/other_environmental_page.dart';
import 'features/home/certificates_page.dart';
import 'features/home/vactor_equipment_pro_page.dart' as pro_vactor;
import 'features/categories/categories_page_firestore.dart';
import 'features/providers/providers_list_page.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/mis_solicitudes_screen.dart';
import 'ui/screens/quotes_flow_screen.dart';
import 'ui/screens/premium_plans_screen.dart';
import 'ui/screens/help_support_screen.dart';
import 'ui/screens/faq_screen.dart';
import 'ui/screens/contact_support_screen.dart';
import 'ui/screens/live_chat_screen.dart';
import 'core/services/push_notification_service.dart';
import 'l10n/app_localizations.dart';
import 'features/settings/change_password_page.dart';
import 'features/settings/notification_preferences_page.dart';
import 'features/settings/theme_page.dart';
import 'features/settings/account_info_page.dart';
import 'features/settings/delete_account_page.dart';
import 'features/generador/crear_solicitud_page.dart';
import 'features/generador/crear_subasta_page.dart';
import 'features/generador/mis_solicitudes_page.dart';
import 'features/generador/mis_subastas_page.dart';
import 'features/generador/ofertas_recibidas_page.dart';
import 'features/generador/historial_generador_page.dart';
import 'features/generador/pagos_generador_page.dart';
import 'features/generador/perfil_generador_page.dart';
import 'features/generador/supervision_generador_page.dart';
import 'features/provider/servicios_disponibles_page.dart';
import 'features/provider/subastas_activas_page.dart';
import 'features/provider/mis_cotizaciones_page.dart';
import 'features/provider/servicios_en_curso_page.dart';
import 'features/provider/historial_proveedor_page.dart';
import 'features/provider/ingresos_proveedor_page.dart';
import 'features/provider/provider_my_services_page.dart';
import 'features/provider/provider_service_form_page.dart';
import 'features/provider/provider_sell_hub_page.dart';
import 'features/proveedor/provider_profile_setup_screen.dart';
import 'features/proveedor/termina_tu_registro_screen.dart';
import 'features/supervisor/supervisor_profile_setup_screen.dart';
import 'features/supervisor/supervisor_application_status_screen.dart';
import 'features/provider/mis_documentos_page.dart';
import 'features/provider/perfil_proveedor_page.dart';
import 'features/admin/admin_approval_page.dart';
import 'features/admin/admin_dashboard_page.dart';
import 'features/admin/admin_manage_roles_page.dart';
import 'features/admin/admin_requests_page.dart';
import 'features/supervisor/supervisor_dashboard_page.dart';
import 'features/supervisor/supervisor_orders_page.dart';
import 'screens/buyer/buyer_main_screen.dart';
import 'screens/provider/provider_main_screen.dart';

// Widget de utilidades de depuración (solo en modo debug)
// ...existing code...

// ...existing code...

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const _brandGreen = Color(0xFF0C4F31);
const _brandGreenSoft = Color(0xFF1E7A4B);
const _appSurface = Color(0xFFF6FAF7);

void main() async {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError no fatal: ${details.exception}');
  };

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      try {
        await FirebaseAppCheck.instance.activate(
          androidProvider: kDebugMode
              ? AndroidProvider.debug
              : AndroidProvider.playIntegrity,
          appleProvider: kDebugMode
              ? AppleProvider.debug
              : AppleProvider.deviceCheck,
        );
      } catch (error) {
        debugPrint('Firebase App Check no se pudo activar: $error');
      }
      runApp(const MyApp());
    },
    (error, stackTrace) {
      debugPrint('runZonedGuarded capturÃ³: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}

/// ðŸŒ Provider global
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppState())],
      child: Builder(
        builder: (context) {
          final isTest = Platform.environment['FLUTTER_TEST'] == 'true';
          if (!isTest) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(PushNotificationService.initialize(context));
            });
          }
          return const SaneApp();
        },
      ),
    );
  }
}

class SaneApp extends StatefulWidget {
  const SaneApp({super.key});

  @override
  State<SaneApp> createState() => _SaneAppState();
}

class _SaneAppState extends State<SaneApp> with WidgetsBindingObserver {
  Widget? _initialScreen;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadInitialScreen() async {
    // Mostrar pantalla de carga inmediatamente
    setState(() {
      _loading = true;
      _initialScreen = Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_brandGreen),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Cargando SaneApp...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    });

    try {
      final screen = await _getInitialScreen(context);
      if (!mounted) {
        return;
      }
      setState(() {
        _initialScreen = screen;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('No fue posible resolver pantalla inicial: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _initialScreen = const ExploreServicesPage();
        _loading = false;
      });
    }
  }

  Future<Widget> _getInitialScreen(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    final user = appState.currentUser;
    if (!onboardingSeen) {
      return const OnboardingScreen();
    } else if (user == null) {
      return const ExploreServicesPage();
    } else if (user.role == UserRole.proveedor.name) {
      return const ExploreServicesPage();
    } else if (user.role == UserRole.generador.name) {
      if (!user.clientProfileCompleted) {}
      return const BuyerMainScreen();
    } else if (user.role == UserRole.supervisor.name) {
      if ((user.status == 'active' || user.status == 'prequalified') &&
          user.supervisorProfileCompleted) {
        return SupervisorDashboardPage();
      }
      if (user.supervisorProfileCompleted) {
        return const SupervisorApplicationStatusScreen();
      }
      return const SupervisorProfileSetupScreen();
    } else if (user.role == UserRole.admin.name) {
      return const AdminDashboardPage();
    } else {
      return const ExploreServicesPage();
    }
  }

  bool _showDebugTools() {
    var debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    return debug;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    if (_loading || _initialScreen == null) {
      return MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      title: 'SaneApp',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandGreen,
          primary: _brandGreen,
          secondary: _brandGreenSoft,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: _appSurface,
        appBarTheme: const AppBarTheme(
          backgroundColor: _brandGreen,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _brandGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _brandGreen,
            side: const BorderSide(color: _brandGreen),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: appState.locale,
      home: Stack(
        children: [
          _initialScreen!,
          if (_showDebugTools())
            Positioned(right: 16, bottom: 16, child: DebugToolsWidget()),
        ],
      ),
      routes: {
        '/termina-tu-registro': (_) => const TerminaTuRegistroScreen(),
        '/admin-dashboard': (_) => const AdminDashboardPage(),
        '/admin-approval': (_) => const AdminApprovalPage(),
        '/admin-manage-roles': (_) => const AdminManageRolesPage(),
        '/admin-requests': (_) => const AdminRequestsPage(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/emergency-services': (_) => const EmergencyServicesPage(),
        '/derrame-quimico': (_) => const DerrameQuimicoPage(),
        '/privacy': (_) => const PrivacyPolicyPage(),
        '/home_generador': (_) => const BuyerMainScreen(),
        '/buyer_main': (_) => const BuyerMainScreen(),
        '/marketplace': (_) => const ExploreServicesPage(),
        '/categories': (_) => const CategoriesPageGallery(),
        '/providers-list': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final subcategoryId = args?['subcategoryId'] as String? ?? '';
          final subcategoryName = args?['subcategoryName'] as String?;
          final categoryId = args?['categoryId'] as String?;
          final categoryName = args?['categoryName'] as String?;
          return ProvidersListPage(
            subcategoryId: subcategoryId,
            subcategoryName: subcategoryName,
            categoryId: categoryId,
            categoryName: categoryName,
          );
        },
        '/terms': (_) => const TermsAndConditionsPage(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/role-selection': (_) => const RoleSelectionScreen(),
        '/client-profile': (_) => const client_profile.ClientProfileScreen(),
        '/provider-profile-setup': (_) => const ProviderProfileSetupScreen(),
        '/supervisor-profile-setup': (_) =>
            const SupervisorProfileSetupScreen(),
        '/supervisor-application-status': (_) =>
            const SupervisorApplicationStatusScreen(),
        '/company-requests': (_) => const CompanyRequestsPage(),
        '/final-disposal-certificates': (_) =>
            const FinalDisposalCertificatesPage(),
        '/company-admin': (_) => const CompanyAdminPage(),
        '/request-service': (_) => const RequestServicePage(),
        '/explore-services': (_) => const ExploreServicesPage(),
        '/profile': (_) => const ProfilePage(),
        '/settings': (_) => const SettingsPage(),
        '/verification': (_) => const VerificationPage(),
        '/metrics': (_) => const MetricsPage(),
        '/support': (_) => const SupportPage(),
        '/request-history': (_) => const RequestHistoryPage(),
        '/quotes-flow': (_) => const QuotesFlowScreen(),
        '/premium-plans': (_) => const PremiumPlansScreen(),
        '/help-support': (_) => const HelpSupportScreen(),
        '/my-requests': (_) => const MisSolicitudesScreen(),
        '/my-requests-pro': (_) => const my_requests_page.MyRequestsPage(),
        '/my-requests-pro-v2': (_) =>
            const my_requests_pro_page.MyRequestsProPage(),
        '/change-password': (_) => const ChangePasswordPage(),
        '/notification-preferences': (_) => const NotificationPreferencesPage(),
        '/theme': (_) => const ThemePage(),
        '/account-info': (_) => const AccountInfoPage(),
        '/delete-account': (_) => const DeleteAccountPage(),
        '/faq': (_) => const FaqScreen(),
        '/contact-support': (_) => const ContactSupportScreen(),
        '/live-chat': (_) => const LiveChatScreen(),
        '/edit-profile': (_) => const EditProfilePage(),
        '/categories-pro': (_) => const CategoriesProPage(),
        '/industrial-cleaning': (_) => const IndustrialCleaningPage(),
        '/vactor-equipment': (_) => const pro_vactor.VactorEquipmentPage(),
        '/other-environmental': (_) => const OtherEnvironmentalPage(),
        '/certificates': (_) => const CertificatesPage(),
        // Drawer Generador: rutas profesionales
        '/crear_solicitud': (_) => const CrearSolicitudPage(),
        '/crear_subasta': (_) => const CrearSubastaPage(),
        '/mis_solicitudes': (_) => const MisSolicitudesPage(),
        '/mis_subastas': (_) => const MisSubastasPage(),
        '/ofertas_recibidas': (_) => const OfertasRecibidasPage(),
        '/historial_generador': (_) => const HistorialGeneradorPage(),
        '/pagos_generador': (_) => const PagosGeneradorPage(),
        '/perfil_generador': (_) => const PerfilGeneradorPage(),
        '/supervision_generador': (_) => const SupervisionGeneradorPage(),
        // Extras para compatibilidad
        '/notificaciones': (_) => const NotificationsPage(),
        // --- FLUJO PROVEEDOR ---
        '/servicios_disponibles': (_) => const ServiciosDisponiblesPage(),
        '/subastas_activas': (_) => const SubastasActivasPage(),
        '/mis_cotizaciones': (_) => const MisCotizacionesPage(),
        '/servicios_en_curso': (_) => const ServiciosEnCursoPage(),
        '/historial_proveedor': (_) => const HistorialProveedorPage(),
        '/ingresos_proveedor': (_) => const IngresosProveedorPage(),
        '/provider-my-services': (_) => const ProviderMyServicesPage(),
        '/sell-services': (_) => const ProviderSellHubPage(),
        '/provider-service-create': (_) => const ProviderServiceFormPage(),
        '/mis_documentos': (_) => const MisDocumentosPage(),
        '/perfil_proveedor': (_) => const PerfilProveedorPage(),
        // --- SUPERVISOR ---
        '/supervisor-dashboard': (_) => SupervisorDashboardPage(),
        '/supervisor-orders': (_) => const SupervisorOrdersPage(),
        // '/provider_dashboard': (_) => const ProviderDashboardScreen(), // eliminado
        '/provider_main': (_) => ProviderMainScreen(),
      },
    );
  }
}

// ...existing code...

// Widget de utilidades de depuración (solo en modo debug)
class DebugToolsWidget extends StatelessWidget {
  const DebugToolsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'clearPrefs',
          mini: true,
          tooltip: 'Borrar preferencias',
          child: Icon(Icons.delete),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Preferencias borradas')));
          },
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'showLogs',
          mini: true,
          tooltip: 'Mostrar logs',
          child: Icon(Icons.bug_report),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Logs de depuración'),
                content: SingleChildScrollView(child: Text(_getDebugLogs())),
                actions: [
                  TextButton(
                    child: Text('Cerrar'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

String _getDebugLogs() {
  // Reemplaza esto por tu lógica real de logs
  return 'No hay logs disponibles.';
}
