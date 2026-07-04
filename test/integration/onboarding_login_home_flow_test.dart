import 'package:flutter_test/flutter_test.dart';
import 'package:saneapp_pro_nuevo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:saneapp_pro_nuevo/models/user_model.dart';
import 'package:saneapp_pro_nuevo/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:saneapp_pro_nuevo/ui/screens/onboarding_screen.dart';
import 'package:saneapp_pro_nuevo/features/home/explore_services_page.dart';
import 'package:saneapp_pro_nuevo/screens/buyer/buyer_main_screen.dart';
import 'package:saneapp_pro_nuevo/features/supervisor/supervisor_profile_setup_screen.dart';
import 'package:saneapp_pro_nuevo/features/supervisor/supervisor_application_status_screen.dart';
import 'package:saneapp_pro_nuevo/features/supervisor/supervisor_dashboard_page.dart';

import 'test_bootstrap.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 40; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ensureFirebaseInitializedForTests();
  });

  group('Flujo de onboarding/login/home', () {
    testWidgets('Muestra onboarding si no se ha visto', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': false});
      await tester.pumpWidget(const MyApp());
      await tester.binding.setLocale('es', 'ES');
      await _pumpApp(tester);
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('Muestra login si onboarding visto y no hay usuario', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      await tester.pumpWidget(const MyApp());
      await tester.binding.setLocale('es', 'ES');
      await _pumpApp(tester);
      expect(find.byType(ExploreServicesPage), findsOneWidget);
    });

    testWidgets('Muestra home si usuario autenticado', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      final appState = AppState();
      appState.setUser(
        UserModel(
          uid: 'test',
          email: 'test@saneapp.com',
          fullName: 'Test User',
          photoUrl: null,
          companyName: null,
          role: 'generador',
          city: null,
          clientProfileCompleted: true,
          verificationStatus: null,
          verifiedAt: null,
          completedServiceIds: const [],
          ofreceEmergencias24h: false,
        ),
        UserRole.generador,
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider<AppState>.value(value: appState)],
          child: const SaneApp(),
        ),
      );
      await tester.binding.setLocale('es', 'ES');
      await _pumpApp(tester);
      expect(find.byType(BuyerMainScreen), findsOneWidget);
    });

    testWidgets('Generador incompleto ve onboarding de cliente', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      final appState = AppState();
      appState.setUser(
        UserModel(
          uid: 'generator-incomplete',
          email: 'cliente@saneapp.com',
          fullName: 'Cliente Nuevo',
          role: 'generador',
          entityType: 'empresa',
          clientType: 'empresa',
          clientProfileCompleted: false,
        ),
        UserRole.generador,
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider<AppState>.value(value: appState)],
          child: const SaneApp(),
        ),
      );
      await tester.binding.setLocale('es', 'ES');
      await _pumpApp(tester);
      expect(find.byType(BuyerMainScreen), findsOneWidget);
    });

    testWidgets('Supervisor incompleto ve setup operativo', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      final appState = AppState();
      appState.setUser(
        UserModel(
          uid: 'supervisor-incomplete',
          email: 'supervisor@saneapp.com',
          fullName: 'Supervisor Incompleto',
          role: 'supervisor',
          status: 'pending_review',
          supervisorProfileCompleted: false,
        ),
        UserRole.supervisor,
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider<AppState>.value(value: appState)],
          child: const SaneApp(),
        ),
      );
      await tester.binding.setLocale('es', 'ES');
      await _pumpApp(tester);
      expect(find.byType(SupervisorProfileSetupScreen), findsOneWidget);
    });

    testWidgets('Supervisor en revisión ve estado de postulación', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      final appState = AppState();
      appState.setUser(
        UserModel(
          uid: 'supervisor-review',
          email: 'supervisor.review@saneapp.com',
          fullName: 'Supervisor Revision',
          role: 'supervisor',
          status: 'pending_review',
          supervisorProfileCompleted: true,
          supervisorAssessmentPassed: true,
          supervisorAssessmentScore: 80,
        ),
        UserRole.supervisor,
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider<AppState>.value(value: appState)],
          child: const SaneApp(),
        ),
      );
      await tester.binding.setLocale('es', 'ES');
      await _pumpApp(tester);
      expect(find.byType(SupervisorApplicationStatusScreen), findsOneWidget);
    });

    testWidgets('Supervisor activo entra al panel operativo', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'onboarding_seen': true});
      final appState = AppState();
      appState.setUser(
        UserModel(
          uid: 'supervisor-active',
          email: 'supervisor.active@saneapp.com',
          fullName: 'Supervisor Activo',
          role: 'supervisor',
          status: 'active',
          supervisorProfileCompleted: true,
          supervisorAssessmentPassed: true,
          supervisorAssessmentScore: 100,
        ),
        UserRole.supervisor,
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider<AppState>.value(value: appState)],
          child: const SaneApp(),
        ),
      );
      await tester.binding.setLocale('es', 'ES');
      await _pumpApp(tester);
      expect(find.byType(SupervisorDashboardPage), findsOneWidget);
    });
  });
}
