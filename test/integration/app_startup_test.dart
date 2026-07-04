import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saneapp_pro_nuevo/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ensureFirebaseInitializedForTests();
  });

  testWidgets('Test de inicio: detectar pantalla paralizada', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    // Espera hasta que desaparezca el CircularProgressIndicator
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // Verifica que la pantalla principal no estÃ¡ en blanco
    final homeFinder = find.byType(Scaffold);
    final spinnerFinder = find.byType(CircularProgressIndicator);

    expect(
      homeFinder,
      findsWidgets,
      reason: 'La pantalla principal debe estar visible',
    );
    expect(
      spinnerFinder,
      findsNothing,
      reason: 'No debe haber un spinner indefinido',
    );

    // Verifica que no hay errores visibles
    expect(find.textContaining('Error'), findsNothing);
    expect(find.textContaining('cerrar app'), findsNothing);
    expect(find.textContaining('esperar'), findsNothing);
  });
}
