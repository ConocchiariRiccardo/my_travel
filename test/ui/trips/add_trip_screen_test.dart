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
      expect(find.byKey(const Key('addtrip-name-field')), findsOneWidget);
      expect(find.byKey(const Key('addtrip-destination-field')), findsOneWidget);
    });

    testWidgets('mostra le row per la selezione delle date', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byKey(const Key('addtrip-date-inizio')), findsOneWidget);
      expect(find.byKey(const Key('addtrip-date-fine')), findsOneWidget);
    });

    testWidgets('mostra bottone Salva nell\'AppBar', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byKey(const Key('addtrip-save-btn')), findsOneWidget);
    });

    testWidgets('campo attività e bottone aggiungi presenti', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byKey(const Key('addtrip-activity-field')), findsOneWidget);
      expect(find.byKey(const Key('addtrip-add-activity-btn')), findsOneWidget);
    });
  });

  group('AddTripScreen - validazione', () {
    testWidgets('mostra errore se nome vuoto al salvataggio', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byKey(const Key('addtrip-save-btn')));
      await tester.pump();
      expect(find.text('Campo obbligatorio'), findsWidgets);
    });

    testWidgets('non salva se le date non sono selezionate', (tester) async {
      await tester.pumpWidget(buildWidget());
        await tester.enterText(find.byKey(const Key('addtrip-name-field')), 'Test');
        await tester.enterText(find.byKey(const Key('addtrip-destination-field')), 'Roma');
        await tester.tap(find.byKey(const Key('addtrip-save-btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addtrip-date-error-snackbar')), findsOneWidget);
    });
  });

  group('AddTripScreen - gestione attività', () {
    testWidgets('aggiungere un\'attività la mostra in lista', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byKey(const Key('addtrip-activity-field')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('addtrip-activity-field')), 'Riunione');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addtrip-activity-title-0')), findsOneWidget);
    });

    testWidgets('tap X rimuove l\'attività dalla lista', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byKey(const Key('addtrip-activity-field')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('addtrip-activity-field')), 'Da rimuovere');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addtrip-activity-title-0')), findsOneWidget);
      // trova il ListTile che contiene il testo e clicca il pulsante di rimozione al suo interno
      final removeBtn = find.byKey(const Key('addtrip-remove-activity-0'));
      // Call the onPressed directly to avoid hit-test issues in the test environment
      final iconButton = tester.widget<IconButton>(removeBtn);
      iconButton.onPressed!();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addtrip-activity-title-0')), findsNothing);
    });

    testWidgets('tasto aggiungi icona inserisce l\'attività', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byKey(const Key('addtrip-activity-field')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('addtrip-activity-field')), 'Check-in hotel');
      await tester.ensureVisible(find.byKey(const Key('addtrip-add-activity-btn')));
      await tester.tap(find.byKey(const Key('addtrip-add-activity-btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addtrip-activity-title-0')), findsOneWidget);
    });
  });
}

Widget Function(BuildContext) get _stub => (_) => const Scaffold(body: Text('Stub'));
