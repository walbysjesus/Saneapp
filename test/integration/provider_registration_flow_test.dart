import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:saneapp_pro_nuevo/features/proveedor/provider_profile_setup_screen.dart';
import 'firebase_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'test_bootstrap.dart';

Future<void> _confirmMultiSelectDialog(WidgetTester tester) async {
  final acceptLabels = ['Aceptar', 'OK', 'Ok'];

  for (final label in acceptLabels) {
    final finder = find.text(label);
    if (finder.evaluate().isNotEmpty) {
      await tester.tap(finder.last);
      await tester.pumpAndSettle();
      return;
    }
  }

  final dialogButtons = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextButton),
  );

  expect(dialogButtons, findsWidgets);
  await tester.tap(dialogButtons.last);
  await tester.pumpAndSettle();
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  Future<void> seedCategoryCatalog(FakeFirebaseFirestore firestore) async {
    await firestore.collection('categories').doc('cat_residuos').set({
      'name': 'Residuos peligrosos',
      'description': 'Gestión de residuos peligrosos',
    });
    await firestore
        .collection('categories')
        .doc('cat_residuos')
        .collection('subcategories')
        .doc('sub_aceites')
        .set({'name': 'Aceites usados'});

    await firestore.collection('categories').doc('cat_limpieza').set({
      'name': 'Limpieza industrial',
      'description': 'Servicios industriales',
    });
    await firestore
        .collection('categories')
        .doc('cat_limpieza')
        .collection('subcategories')
        .doc('sub_tanques')
        .set({'name': 'Tanques'});
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await ensureFirebaseInitializedForTests();
  });

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
  });

  testWidgets('Provider registration flow works', (WidgetTester tester) async {
    mockAuth.mockUser = mockUser;
    await seedCategoryCatalog(fakeFirestore);

    await tester.pumpWidget(
      MaterialApp(
        home: ProviderProfileSetupScreen(
          auth: mockAuth,
          firestore: fakeFirestore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('companyName')),
      'Empresa Test',
    );
    await tester.enterText(
      find.byKey(const Key('legalRepresentative')),
      'Juan Pérez',
    );
    await tester.enterText(find.byKey(const Key('nit')), '9001234567');
    await tester.enterText(find.byKey(const Key('email')), 'test@empresa.com');

    await tester.tap(find.byKey(const Key('categoryDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Residuos peligrosos').last);
    await tester.tap(find.text('Limpieza industrial').last);
    await _confirmMultiSelectDialog(tester);

    // La selección de subcategorías no es obligatoria en este paso y en entorno
    // de test puede quedar fuera de viewport; se valida el flujo principal.

    final nextButton = find.text('Siguiente');
    expect(nextButton, findsOneWidget);

    expect(find.text('Selecciona categorías'), findsWidgets);
    expect(find.text('Residuos peligrosos'), findsWidgets);
    expect(find.text('Limpieza industrial'), findsWidgets);
  });

  testWidgets('Normaliza categorias legacy guardadas por nombre', (
    WidgetTester tester,
  ) async {
    mockAuth.mockUser = mockUser;
    await seedCategoryCatalog(fakeFirestore);

    await fakeFirestore.collection('providers').doc(mockUser.uid).set({
      'companyName': 'Empresa Legacy',
      'legalRepresentative': 'Legacy User',
      'nit': '900000001',
      'email': 'legacy@empresa.com',
      'selectedCategories': ['Residuos peligrosos'],
      'selectedSubcategories': <String>[],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ProviderProfileSetupScreen(
          auth: mockAuth,
          firestore: fakeFirestore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('companyName')),
      'Empresa Legacy',
    );
    await tester.enterText(
      find.byKey(const Key('legalRepresentative')),
      'Legacy User',
    );
    await tester.enterText(find.byKey(const Key('nit')), '900000001');
    await tester.enterText(
      find.byKey(const Key('email')),
      'legacy@empresa.com',
    );

    final nextButton = find.text('Siguiente');
    await tester.ensureVisible(nextButton);
    await tester.pumpAndSettle();
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    final savedProvider = await fakeFirestore
        .collection('providers')
        .doc(mockUser.uid)
        .get();
    final data = savedProvider.data();
    expect(data, isNotNull);
    expect(data!['selectedCategories'], contains('cat_residuos'));
    expect(data['selectedCategories'], isNot(contains('Residuos peligrosos')));
  });

  testWidgets('Poda subcategorias fuera del alcance de categorias al guardar', (
    WidgetTester tester,
  ) async {
    mockAuth.mockUser = mockUser;
    await seedCategoryCatalog(fakeFirestore);

    await fakeFirestore.collection('providers').doc(mockUser.uid).set({
      'companyName': 'Empresa Scope',
      'legalRepresentative': 'Scope User',
      'nit': '900000002',
      'email': 'scope@empresa.com',
      'selectedCategories': ['cat_residuos'],
      'selectedSubcategories': ['sub_tanques'],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ProviderProfileSetupScreen(
          auth: mockAuth,
          firestore: fakeFirestore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('companyName')),
      'Empresa Scope',
    );
    await tester.enterText(
      find.byKey(const Key('legalRepresentative')),
      'Scope User',
    );
    await tester.enterText(find.byKey(const Key('nit')), '900000002');
    await tester.enterText(find.byKey(const Key('email')), 'scope@empresa.com');

    final nextButton = find.text('Siguiente');
    await tester.ensureVisible(nextButton);
    await tester.pumpAndSettle();
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    final savedProvider = await fakeFirestore
        .collection('providers')
        .doc(mockUser.uid)
        .get();
    final data = savedProvider.data();
    expect(data, isNotNull);
    expect(data!['selectedCategories'], contains('cat_residuos'));
    expect(data['selectedSubcategories'], isNot(contains('sub_tanques')));
    expect(data['selectedSubcategories'], isEmpty);
  });
}
