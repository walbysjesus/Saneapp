import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:saneapp_pro_nuevo/features/home/home_page.dart';
import 'package:saneapp_pro_nuevo/state/app_state.dart';
import 'package:saneapp_pro_nuevo/models/user_model.dart';

void main() {
  group('Drawer Widget', () {
    testWidgets('Muestra nombre, email y opciones principales', (WidgetTester tester) async {
      final user = UserModel(
        uid: '1',
        email: 'test@email.com',
        fullName: 'Test User',
        photoUrl: null,
        companyName: null,
        role: 'generador',
        verificationStatus: null,
        verifiedAt: null,
        completedServiceIds: const [],
      );
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppState()..setUser(user, UserRole.generador),
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      final menuButton = find.widgetWithIcon(IconButton, Icons.menu);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@email.com'), findsOneWidget);
      expect(find.text('Inicio'), findsWidgets);
      expect(find.text('Crear solicitud'), findsOneWidget);
      expect(find.text('Mis solicitudes'), findsOneWidget);
    });
  });
}


