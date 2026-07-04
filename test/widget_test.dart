// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/mocks/mock_firebase_analytics.dart';
import 'package:saneapp_pro_nuevo/core/services/analytics_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:saneapp_pro_nuevo/firebase_options.dart';

void main() {
  testWidgets('Test básico runner', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('Runner OK')));
    expect(find.text('Runner OK'), findsOneWidget);
  });
  setUpAll(() async {
    // Mock de Firebase para evitar errores de no-app
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {}
    AnalyticsService.setAnalyticsInstance(MockFirebaseAnalytics());
  });

  // TEST DE CONTROL: verifica que el framework de test funciona
  test('control: framework de test activo', () {
    expect(1 + 1, equals(2));
  });
}

