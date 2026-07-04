import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saneapp_pro_nuevo/features/auth/register_screen.dart';
import 'package:saneapp_pro_nuevo/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:saneapp_pro_nuevo/firebase_options.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (_) {}
  });

  testWidgets('Registro muestra validaciones y feedback', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RegisterScreen(),
      ),
    );

    // Verifica que el botÃ³n de registro estÃ© presente
    final registerButton = find.widgetWithText(ElevatedButton, 'Registrarme');
    expect(registerButton, findsOneWidget);
    await tester.scrollUntilVisible(
      registerButton,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Intenta registrar sin datos
    final registerWidget = tester.widget<ElevatedButton>(registerButton);
    registerWidget.onPressed!.call();
    await tester.pump();
    expect(find.text('El nombre completo es obligatorio'), findsOneWidget);
    expect(find.text('El email es obligatorio'), findsOneWidget);

    // Ingresa email invÃ¡lido
    await tester.enterText(find.byType(TextFormField).at(1), 'correo@mal');
    await tester.scrollUntilVisible(
      registerButton,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    tester.widget<ElevatedButton>(registerButton).onPressed!.call();
    await tester.pump();
    expect(find.textContaining('inv'), findsWidgets);
  });
}


