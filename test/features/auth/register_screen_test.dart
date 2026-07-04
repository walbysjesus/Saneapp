import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saneapp_pro_nuevo/features/auth/register_screen.dart';

void main() {
  testWidgets('RegisterScreen muestra el formulario de registro', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    expect(find.byType(Form), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Confirmar contraseña'), findsOneWidget);
  });
}


