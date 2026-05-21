import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_travel/ui/trips/trip_detail_screen.dart';
import 'package:my_travel/ui/trips/trip_detail_view_model.dart';
import 'package:my_travel/ui/auth/auth_view_model.dart';
import 'package:my_travel/domain/models/viaggio.dart';
import 'package:my_travel/domain/models/attivita.dart';

@GenerateMocks([TripDetailViewModel, AuthViewModel, User])
import 'trip_detail_screen_test.mocks.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Viaggio makeViaggio({int giorniAlPartenza = 5, bool inCorso = false}) {
  final oggi = DateTime.now();
  final inizio = inCorso
      ? oggi.subtract(const Duration(days: 1))
      : oggi.add(Duration(days: giorniAlPartenza));
  return Viaggio(
    id: 'v1',
    userId: 'u1',
    nome: 'Milano Q1',
    destinazione: 'Milano',
    dataInizio: inizio,
    dataFine: inizio.add(const Duration(days: 3)),
  );
}

Attivita makeAttivita({
  String id = 'a1',
  String nome = 'Riunione cliente',
  bool completata = false,
}) =>
    Attivita(id: id, nome: nome, isCompletata: completata);

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  late MockTripDetailViewModel mockVm;
  late MockAuthViewModel mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockVm = MockTripDetailViewModel();
    mockAuth = MockAuthViewModel();
    mockUser = MockUser();

    when(mockUser.uid).thenReturn('uid-test');
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockAuth.addListener(any)).thenReturn(null);
    when(mockAuth.removeListener(any)).thenReturn(null);

    when(mockVm.isLoading).thenReturn(false);
    when(mockVm.viaggio).thenReturn(makeViaggio());
    when(mockVm.attivita).thenReturn([]);
    when(mockVm.percentualeCompletamento).thenReturn(0.0);
    when(mockVm.errorMessage).thenReturn(null);
    when(mockVm.addListener(any)).thenReturn(null);
    when(mockVm.removeListener(any)).thenReturn(null);
  });

  Widget buildWidget() => MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: mockAuth),
          ChangeNotifierProvider<TripDetailViewModel>.value(value: mockVm),
        ],
        child: MaterialApp(
          home: TripDetailScreen(viaggioId: 'v1', viewModel: mockVm),
          routes: {
            '/expenses': (_) => const Scaffold(body: Text('Spese')),
          },
        ),
      );

  group('TripDetailScreen – rendering', () {
    testWidgets('mostra il nome del viaggio nell/AppBar', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      expect(find.text('Milano Q1'), findsWidgets);
    });

    testWidgets('mostra la destinazione', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      expect(find.text('Milano'), findsWidgets);
    });

    testWidgets('mostra spinner durante isLoading', (tester) async {
      when(mockVm.isLoading).thenReturn(true);
      await tester.pumpWidget(buildWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('mostra bottone "Gestisci spese e scontrini"', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      expect(find.text('Gestisci spese e scontrini'), findsOneWidget);
    });

    testWidgets('mostra i quick-link Booking e Skyscanner', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      expect(find.text('Booking'), findsOneWidget);
      expect(find.text('Skyscanner'), findsOneWidget);
    });
  });

  group('TripDetailScreen – badge countdown', () {
    testWidgets('badge "In corso" per viaggio in corso', (tester) async {
      when(mockVm.viaggio).thenReturn(makeViaggio(inCorso: true));
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      expect(find.text('In corso'), findsOneWidget);
    });

    testWidgets('badge con giorni rimanenti per viaggio futuro', (tester) async {
      when(mockVm.viaggio).thenReturn(makeViaggio(giorniAlPartenza: 10));
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      expect(find.textContaining('10'), findsWidgets);
    });
  });

  group('TripDetailScreen – attività', () {
    testWidgets('mostra placeholder quando lista attività è vuota', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      expect(find.text('Nessuna attività pianificata'), findsOneWidget);
    });

    testWidgets('mostra le attività nella lista', (tester) async {
      when(mockVm.attivita).thenReturn([
        makeAttivita(nome: 'Riunione cliente'),
        makeAttivita(id: 'a2', nome: 'Pranzo di lavoro'),
      ]);
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      expect(find.text('Riunione cliente'), findsOneWidget);
      expect(find.text('Pranzo di lavoro'), findsOneWidget);
    });

    testWidgets('attività completata mostra testo barrato', (tester) async {
      when(mockVm.attivita).thenReturn([
        makeAttivita(nome: 'Attività fatta', completata: true),
      ]);
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final text = tester.widget<Text>(find.text('Attività fatta'));
      expect(text.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('mostra LinearProgressIndicator quando ci sono attività', (tester) async {
      when(mockVm.attivita).thenReturn([makeAttivita()]);
      when(mockVm.percentualeCompletamento).thenReturn(0.5);
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('tap sul checkbox chiama toggle sul ViewModel', (tester) async {
      final attivita = makeAttivita();
      when(mockVm.attivita).thenReturn([attivita]);
      when(mockVm.toggle(any, any, any)).thenAnswer((_) async {});
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // Il GestureDetector del checkbox è il leading del ListTile
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      verify(mockVm.toggle('uid-test', 'v1', attivita)).called(1);
    });

    testWidgets('tap elimina attività mostra dialog di conferma', (tester) async {
      when(mockVm.attivita).thenReturn([makeAttivita(nome: 'Da cancellare')]);
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      // L'IconButton delete è nel trailing del tile
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pump();

      verify(mockVm.elimina('uid-test', 'v1', 'a1')).called(1);
    });
  });

  group('TripDetailScreen – navigazione', () {
    testWidgets('tap "Gestisci spese" naviga verso /expenses', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.tap(find.text('Gestisci spese e scontrini'));
      await tester.pumpAndSettle();
      expect(find.text('Spese'), findsOneWidget);
    });

    testWidgets('tap concludi mostra dialog di conferma', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('Concludi viaggio'), findsOneWidget);
    });

    testWidgets('annulla concludi non chiama completa', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      verifyNever(mockVm.completa(any, any));
    });
  });
}
