import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saneapp_pro_nuevo/features/providers/providers_page.dart';

void main() {
  group('ProvidersPage', () {
    testWidgets('Muestra proveedores y filtra por nombre', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProvidersPage()));

      // Verifica que un proveedor estÃ© visible
      expect(find.widgetWithText(ListTile, 'EcoSoluciones SAS'), findsOneWidget);

      // Busca por nombre
      await tester.enterText(find.byType(TextField).first, 'LimpiaYa');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'LimpiaYa'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'EcoSoluciones SAS'), findsNothing);
    });

    testWidgets('Limpia filtros y muestra todos', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ProvidersPage()));

      // Aplica filtro por nombre
      await tester.enterText(find.byType(TextField).first, 'LimpiaYa');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'LimpiaYa'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'EcoSoluciones SAS'), findsNothing);

      // Pulsa el botÃ³n Limpiar
      await tester.tap(find.text('Limpiar'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'EcoSoluciones SAS'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'LimpiaYa'), findsOneWidget);
    });
  });
}


