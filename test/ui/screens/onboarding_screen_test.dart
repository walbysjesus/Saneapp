import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saneapp_pro_nuevo/ui/screens/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen muestra el texto de bienvenida', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    expect(find.textContaining('Bienvenido'), findsOneWidget);
  });
}


