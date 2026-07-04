import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:saneapp_pro_nuevo/features/admin/admin_approval_page.dart';

void main() {
  setUpAll(() async {
    // Inicializa Firebase para tests
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    // Puedes usar Firebase.initializeApp() si tienes firebase_options.dart
    await Firebase.initializeApp();
    // Si usas mocks, puedes inicializar aquÃ­
    // FirebaseAuth.instance = MockFirebaseAuth();
  });
  group('AdminApprovalPage', () {
    testWidgets('Muestra acceso restringido si no es admin', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AdminApprovalPage()));
      await tester.pumpAndSettle();
      expect(find.text('Acceso restringido'), findsOneWidget);
    });

    testWidgets('Muestra loading mientras carga', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AdminApprovalPage()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // Nota: Para pruebas con Firestore y Auth, se recomienda usar mocks o Firebase Test SDK
  });
}

