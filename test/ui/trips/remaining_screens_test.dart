//  test/ui/trips/add_trip_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_travel/ui/trips/add_trip_screen.dart';
import 'package:my_travel/ui/auth/auth_view_model.dart';

import '../auth/login_screen_test.mocks.dart'; // MockAuthViewModel
import '../trips/trip_detail_screen_test.mocks.dart'; // MockUser

void _addTripTests() {
  late MockAuthViewModel mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockAuthViewModel();
    mockUser = MockUser();
    when(mockUser.uid).thenReturn('uid-test');
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockAuth.addListener(any)).thenReturn(null);
    when(mockAuth.removeListener(any)).thenReturn(null);
  });

  Widget buildWidget() => ChangeNotifierProvider<AuthViewModel>.value(
        value: mockAuth,
        child: const MaterialApp(
          home: AddTripScreen(),
          routes: {'/home': _stub},
        ),
      );

  group('AddTripScreen – rendering', () {
    testWidgets('mostra i campi nome e destinazione', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.widgetWithText(TextFormField, 'Nome viaggio'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Destinazione'), findsOneWidget);
    });

    testWidgets('mostra le row per la selezione delle date', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Data inizio'), findsOneWidget);
      expect(find.text('Data fine'), findsOneWidget);
    });

    testWidgets('mostra bottone Salva nell'AppBar', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Salva'), findsOneWidget);
    });

    testWidgets('campo attività e bottone aggiungi presenti', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(
        find.widgetWithText(TextField, "Aggiungi un'attività..."),
        findsOneWidget,
      );
      expect(find.byType(IconButton), findsWidgets);
    });
  });

  group('AddTripScreen - validazione', () {
    testWidgets('mostra errore se nome vuoto al salvataggio', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Salva'));
      await tester.pump();
      expect(find.text('Campo obbligatorio'), findsWidgets);
    });

    testWidgets('non salva se le date non sono selezionate', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome viaggio'), 'Test');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Destinazione'), 'Roma');
      await tester.tap(find.text('Salva'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Deve mostrare SnackBar con messaggio sulle date
      expect(
        find.text('Seleziona le date di inizio e fine viaggio.'),
        findsOneWidget,
      );
    });
  });

  group('AddTripScreen - gestione attività', () {
    testWidgets('aggiungere un'attività la mostra in lista', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(
        find.widgetWithText(TextField, "Aggiungi un'attività..."),
        'Riunione',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Riunione'), findsOneWidget);
    });

    testWidgets('tap X rimuove l'attività dalla lista', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(
        find.widgetWithText(TextField, "Aggiungi un'attività..."),
        'Da rimuovere',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Da rimuovere'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pump();
      expect(find.text('Da rimuovere'), findsNothing);
    });

    testWidgets('tasto aggiungi icona inserisce l'attività', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(
        find.widgetWithText(TextField, "Aggiungi un'attività..."),
        'Check-in hotel',
      );
      // Trova IconButton.filled (il bottone +)
      await tester.tap(find.byType(IconButton).last);
      await tester.pump();
      expect(find.text('Check-in hotel'), findsOneWidget);
    });
  });
}


//  test/ui/expenses/expense_screen_test.dart

import 'package:my_travel/ui/expenses/expense_screen.dart';
import 'package:my_travel/ui/expenses/expense_view_model.dart';
import 'package:my_travel/domain/models/spesa.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([ExpenseViewModel])
import 'expense_screen_test.mocks.dart';

Spesa makeSpesa({
  String id = 's1',
  String desc = 'Pranzo',
  double importo = 25.50,
  String cat = 'Pasto',
}) =>
    Spesa(
      id: id,
      viaggioId: 'v1',
      descrizione: desc,
      importo: importo,
      categoria: cat,
      data: DateTime.now(),
    );

void _expenseTests() {
  late MockExpenseViewModel mockVm;
  late MockAuthViewModel mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockVm = MockExpenseViewModel();
    mockAuth = MockAuthViewModel();
    mockUser = MockUser();

    when(mockUser.uid).thenReturn('uid-test');
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockAuth.addListener(any)).thenReturn(null);
    when(mockAuth.removeListener(any)).thenReturn(null);

    when(mockVm.isLoading).thenReturn(false);
    when(mockVm.spese).thenReturn([]);
    when(mockVm.totaleFormattato).thenReturn('€ 0,00');
    when(mockVm.totalePerCategoria).thenReturn({});
    when(mockVm.errorMessage).thenReturn(null);
    when(mockVm.addListener(any)).thenReturn(null);
    when(mockVm.removeListener(any)).thenReturn(null);
  });

  Widget buildWidget() => MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: mockAuth),
          ChangeNotifierProvider<ExpenseViewModel>.value(value: mockVm),
        ],
        child: MaterialApp(
          home: ExpenseScreen(viaggioId: 'v1', viewModel: mockVm),
          routes: {
            '/expense/add': _stub,
            '/pdf': _stub,
          },
        ),
      );

  group('ExpenseScreen – rendering', () {
    testWidgets('mostra il totale formattato', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('€ 0,00'), findsOneWidget);
    });

    testWidgets('mostra stato vuoto quando non ci sono spese', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Nessuna spesa registrata'), findsOneWidget);
    });

    testWidgets('mostra le spese in lista', (tester) async {
      when(mockVm.spese).thenReturn([
        makeSpesa(desc: 'Pranzo', importo: 25.50),
        makeSpesa(id: 's2', desc: 'Taxi', cat: 'Trasporto', importo: 15.00),
      ]);
      when(mockVm.totaleFormattato).thenReturn('€ 40,50');
      await tester.pumpWidget(buildWidget());
      expect(find.text('Pranzo'), findsOneWidget);
      expect(find.text('Taxi'), findsOneWidget);
    });

    testWidgets('mostra spinner durante isLoading', (tester) async {
      when(mockVm.isLoading).thenReturn(true);
      await tester.pumpWidget(buildWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('mostra FAB Aggiungi spesa', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Aggiungi spesa'), findsOneWidget);
    });

    testWidgets('mostra icona PDF nell'AppBar', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    });
  });

  group('ExpenseScreen – riepilogo categorie', () {
    testWidgets('mostra chip per ogni categoria', (tester) async {
      when(mockVm.spese).thenReturn([makeSpesa(), makeSpesa(id: 's2', cat: 'Trasporto')]);
      when(mockVm.totalePerCategoria).thenReturn({'Pasto': 25.50, 'Trasporto': 15.00});
      await tester.pumpWidget(buildWidget());
      expect(find.textContaining('Pasto'), findsOneWidget);
      expect(find.textContaining('Trasporto'), findsOneWidget);
    });
  });

  group('ExpenseScreen – navigazione', () {
    testWidgets('tap FAB naviga verso /expense/add', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Aggiungi spesa'));
      await tester.pumpAndSettle();
      expect(find.text('Stub'), findsOneWidget);
    });

    testWidgets('tap icona PDF naviga verso /pdf', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Stub'), findsOneWidget);
    });
  });
}

// ════════════════════════════════════════════════════════════
//  test/ui/expenses/add_expense_screen_test.dart
// ════════════════════════════════════════════════════════════
import 'package:my_travel/ui/expenses/add_expense_screen.dart';

void _addExpenseTests() {
  late MockAuthViewModel mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockAuthViewModel();
    mockUser = MockUser();
    when(mockUser.uid).thenReturn('uid-test');
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockAuth.addListener(any)).thenReturn(null);
    when(mockAuth.removeListener(any)).thenReturn(null);
  });

  Widget buildWidget() => ChangeNotifierProvider<AuthViewModel>.value(
        value: mockAuth,
        child: const MaterialApp(home: AddExpenseScreen(viaggioId: 'v1')),
      );

  group('AddExpenseScreen – rendering', () {
    testWidgets('mostra area placeholder fotocamera', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Fotografa lo scontrino'), findsOneWidget);
    });

    testWidgets('mostra campi descrizione e importo', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.widgetWithText(TextFormField, 'Descrizione'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Importo (€)'), findsOneWidget);
    });

    testWidgets('mostra i 5 ChoiceChip di categoria', (tester) async {
      await tester.pumpWidget(buildWidget());
      for (final cat in ['Pasto', 'Trasporto', 'Alloggio', 'Carburante', 'Altro']) {
        expect(find.widgetWithText(ChoiceChip, cat), findsOneWidget);
      }
    });

    testWidgets('mostra il bottone Salva nell'AppBar', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Salva'), findsOneWidget);
    });

    testWidgets('mostra il data picker nella sezione data', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Data spesa'), findsOneWidget);
    });
  });

  group('AddExpenseScreen – validazione', () {
    testWidgets('mostra errore se descrizione vuota', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Salva'));
      await tester.pump();
      expect(find.text('Campo obbligatorio'), findsOneWidget);
    });

    testWidgets('mostra errore se importo vuoto', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Descrizione'), 'Pranzo');
      await tester.tap(find.text('Salva'));
      await tester.pump();
      expect(find.textContaining("importo"), findsOneWidget);
    });

    testWidgets('mostra errore se importo non è un numero valido', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Descrizione'), 'Test');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Importo (€)'), 'abc');
      await tester.tap(find.text('Salva'));
      await tester.pump();
      expect(find.text('Importo non valido'), findsOneWidget);
    });
  });

  group('AddExpenseScreen – selezione categoria', () {
    testWidgets('tap su un ChoiceChip lo seleziona', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.widgetWithText(ChoiceChip, 'Trasporto'));
      await tester.pump();
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Trasporto'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('"Altro" è selezionato di default', (tester) async {
      await tester.pumpWidget(buildWidget());
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Altro'),
      );
      expect(chip.selected, isTrue);
    });
  });
}


//  test/ui/profile/profile_screen_test.dart

import 'package:my_travel/ui/profile/profile_screen.dart';
import 'package:my_travel/ui/profile/profile_view_model.dart';
import 'package:my_travel/domain/models/utente.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([ProfileViewModel])
import 'profile_screen_test.mocks.dart';

Utente makeUtente({String nome = 'Mario Rossi'}) => Utente(
      id: 'u1',
      email: 'mario@test.com',
      nomeCompleto: nome,
    );

void _profileTests() {
  late MockProfileViewModel mockProfile;
  late MockAuthViewModel mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockProfile = MockProfileViewModel();
    mockAuth = MockAuthViewModel();
    mockUser = MockUser();

    when(mockUser.uid).thenReturn('uid-test');
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockAuth.addListener(any)).thenReturn(null);
    when(mockAuth.removeListener(any)).thenReturn(null);

    when(mockProfile.isLoading).thenReturn(false);
    when(mockProfile.isSaving).thenReturn(false);
    when(mockProfile.utente).thenReturn(makeUtente());
    when(mockProfile.email).thenReturn('mario@test.com');
    when(mockProfile.errorMessage).thenReturn(null);
    when(mockProfile.successMessage).thenReturn(null);
    when(mockProfile.addListener(any)).thenReturn(null);
    when(mockProfile.removeListener(any)).thenReturn(null);
  });

  Widget buildWidget() => MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: mockAuth),
          ChangeNotifierProvider<ProfileViewModel>.value(value: mockProfile),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
          routes: {'/history': _stub, '/login': _stub},
        ),
      );

  group('ProfileScreen – rendering', () {
    testWidgets('mostra nome completo dell'utente', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Mario Rossi'), findsWidgets);
    });

    testWidgets('mostra email dell'utente', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('mario@test.com'), findsWidgets);
    });

    testWidgets('mostra l'icona di modifica quando non in edit mode', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('mostra spinner durante isLoading', (tester) async {
      when(mockProfile.isLoading).thenReturn(true);
      await tester.pumpWidget(buildWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('mostra link a Storico viaggi', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Storico viaggi'), findsOneWidget);
    });

    testWidgets('mostra bottone Esci', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.textContaining("Esci"), findsOneWidget);
    });
  });

  group('ProfileScreen – edit mode', () {
    testWidgets('tap sull'icona edit mostra il campo nome', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'Nome completo'), findsOneWidget);
    });

    testWidgets('in edit mode mostra bottone Salva al posto dell'icona', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      expect(find.text('Salva'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets('tap Salva chiama aggiornaNome col testo inserito', (tester) async {
      when(mockProfile.aggiornaNome(any)).thenAnswer((_) async {});
      when(mockProfile.successMessage).thenReturn('Nome aggiornato con successo!');
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome completo'), 'Luca Bianchi');
      await tester.tap(find.text('Salva'));
      await tester.pump();

      verify(mockProfile.aggiornaNome('Luca Bianchi')).called(1);
    });
  });

  group('ProfileScreen – logout', () {
    testWidgets('tap Esci mostra dialog di conferma', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.textContaining("Esci"));
      await tester.pumpAndSettle();
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('tap Annulla nel dialog non chiama logout', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.textContaining("Esci"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      verifyNever(mockAuth.logout());
    });

    testWidgets('tap Esci nel dialog chiama logout', (tester) async {
      when(mockAuth.logout()).thenAnswer((_) async {});
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.textContaining("Esci dall'account"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esci'));
      await tester.pumpAndSettle();
      verify(mockAuth.logout()).called(1);
    });
  });
}


//  Entrypoint unico — raggruppa tutti i test in un solo file
void main() {
  group('AddTripScreen', _addTripTests);
  group('ExpenseScreen', _expenseTests);
  group('AddExpenseScreen', _addExpenseTests);
  group('ProfileScreen', _profileTests);
}

// Helper comuni
Widget Function(BuildContext) get _stub => (_) => const Scaffold(body: Text('Stub'));
