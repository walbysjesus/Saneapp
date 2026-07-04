import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saneapp_pro_nuevo/features/home/home_page.dart';

void main() {
  testWidgets('RecentRequestPreviewCard navega al detalle de solicitud', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RecentRequestPreviewCard(
            requestId: 'sol-123',
            data: {
              'titulo': 'Retiro de residuos especiales',
              'serviceInterest': 'Residuos peligrosos',
              'status': 'pending',
              'type': 'normal',
            },
          ),
        ),
      ),
    );

    expect(find.text('Retiro de residuos especiales'), findsOneWidget);

    await tester.tap(find.byType(RecentRequestPreviewCard));
    await tester.pumpAndSettle();

    expect(find.text('Detalle de solicitud'), findsOneWidget);
    expect(
      find.text(
        'Detalle no disponible mientras Firebase no esté inicializado.',
      ),
      findsOneWidget,
    );
  });
}
