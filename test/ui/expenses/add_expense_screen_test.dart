import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:my_travel/ui/expenses/add_expense_screen.dart';
import 'package:my_travel/ui/auth/auth_view_model.dart';
import '../trips/remaining_screens_mocks.mocks.dart';

void main() {
  late MockAuthViewModel mockAuth;
  late MockUser mockUser;
  late MockSpesaRepository mockRepo;

  setUpAll(() async {
    await initializeDateFormatting('it_IT');
  });

  setUp(() {
    mockAuth = MockAuthViewModel();
    mockUser = MockUser();
    mockRepo = MockSpesaRepository();
    when(mockUser.uid).thenReturn('uid-test');
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockAuth.addListener(any)).thenReturn(null);
    when(mockAuth.removeListener(any)).thenReturn(null);
  });

  Widget buildWidget() => ChangeNotifierProvider<AuthViewModel>.value(
        value: mockAuth,
        child: MaterialApp(
          home: AddExpenseScreen(
            viaggioId: 'v1',
            spesaRepository: mockRepo,
          ),
        ),
      );

  group('AddExpenseScreen – rendering', () {
    testWidgets('mostra area placeholder fotocamera', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byKey(const Key('addexpense-photo-title')), findsOneWidget);
    });

    testWidgets('mostra campi descrizione e importo', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byKey(const Key('addexpense-description')), findsOneWidget);
      expect(find.byKey(const Key('addexpense-amount')), findsOneWidget);
    });

    testWidgets('mostra i 5 ChoiceChip di categoria', (tester) async {
      await tester.pumpWidget(buildWidget());
      for (final cat in ['Pasto', 'Trasporto', 'Alloggio', 'Carburante', 'Altro']) {
        expect(find.byKey(Key('addexpense-category-${cat.toLowerCase()}')), findsOneWidget);
      }
    });

    testWidgets('mostra il bottone Salva nell\'AppBar', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byKey(const Key('addexpense-save-btn')), findsOneWidget);
    });

    testWidgets('mostra il data picker nella sezione data', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addexpense-date')), findsOneWidget);
    });
  });

  group('AddExpenseScreen – validazione', () {
    testWidgets('mostra errore se descrizione vuota', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byKey(const Key('addexpense-save-btn')));
      await tester.pump();
      expect(find.text('Campo obbligatorio'), findsOneWidget);
    });

    testWidgets('mostra errore se importo vuoto', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(find.byKey(const Key('addexpense-description')), 'Pranzo');
      await tester.tap(find.byKey(const Key('addexpense-save-btn')));
      await tester.pump();
      expect(find.textContaining("importo"), findsOneWidget);
    });

    testWidgets('mostra errore se importo non è un numero valido', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(find.byKey(const Key('addexpense-description')), 'Test');
      await tester.enterText(find.byKey(const Key('addexpense-amount')), 'abc');
      await tester.tap(find.byKey(const Key('addexpense-save-btn')));
      await tester.pump();
      expect(find.text('Importo non valido'), findsOneWidget);
    });
  });

  group('AddExpenseScreen – selezione categoria', () {
    // Category visual tests validated elsewhere; keeping core flows only.
  });
}
