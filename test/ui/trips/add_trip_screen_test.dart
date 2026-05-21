import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:my_travel/ui/trips/add_trip_screen.dart';
import 'package:my_travel/ui/auth/auth_view_model.dart';

import 'remaining_screens_mocks.mocks.dart';

void main() {
  late MockAuthViewModel mockAuth;
  late MockUser mockUser;
  late MockViaggioRepository mockViaggioRepo;

  setUpAll(() async {
    await initializeDateFormatting('it_IT');
  });

  setUp(() {
    mockAuth = MockAuthViewModel();
    mockUser = MockUser();
    mockViaggioRepo = MockViaggioRepository();
    when(mockUser.uid).thenReturn('uid-test');
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockAuth.addListener(any)).thenReturn(null);
    when(mockAuth.removeListener(any)).thenReturn(null);
  });

  Widget buildWidget() => ChangeNotifierProvider<AuthViewModel>.value(
        value: mockAuth,
        child: MaterialApp(
          home: AddTripScreen(viaggioRepository: mockViaggioRepo),
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

    testWidgets('mostra bottone Salva nell\'AppBar', (tester) async {
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
      expect(
        find.text('Seleziona le date di inizio e fine viaggio.'),
        findsOneWidget,
      );
    });
  });

  group('AddTripScreen - gestione attività', () {
    testWidgets('aggiungere un\'attività la mostra in lista', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(
        find.widgetWithText(TextField, "Aggiungi un'attività..."),
        'Riunione',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Riunione'), findsOneWidget);
    });

    testWidgets('tap X rimuove l\'attività dalla lista', (tester) async {
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

    testWidgets('tasto aggiungi icona inserisce l\'attività', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(
        find.widgetWithText(TextField, "Aggiungi un'attività..."),
        'Check-in hotel',
      );
      await tester.tap(find.byType(IconButton).last);
      await tester.pump();
      expect(find.text('Check-in hotel'), findsOneWidget);
    });
  });
}

Widget Function(BuildContext) get _stub => (_) => const Scaffold(body: Text('Stub'));
