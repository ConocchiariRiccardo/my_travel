import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_travel/ui/home/home_screen.dart';
import 'package:my_travel/ui/home/home_view_model.dart';
import 'package:my_travel/ui/auth/auth_view_model.dart';
import 'package:my_travel/domain/models/viaggio.dart';

@GenerateMocks([HomeViewModel, AuthViewModel, User])
import 'home_screen_test.mocks.dart';

// ── Helper ──────────────────────────────────────────────────────────────────

Viaggio makeViaggio({
  String id = 'v1',
  String nome = 'Trasferta Milano',
  String dest = 'Milano',
  int giorniAlPartenza = 5,
  bool inCorso = false,
}) {
  final oggi = DateTime.now();
  final inizio = inCorso
      ? oggi.subtract(const Duration(days: 1))
      : oggi.add(Duration(days: giorniAlPartenza));
  return Viaggio(
    id: id,
    userId: 'u1',
    nome: nome,
    destinazione: dest,
    dataInizio: inizio,
    dataFine: inizio.add(const Duration(days: 3)),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockHomeViewModel mockHome;
  late MockAuthViewModel mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockHome = MockHomeViewModel();
    mockAuth = MockAuthViewModel();
    mockUser = MockUser();

    when(mockUser.uid).thenReturn('uid-test');
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockAuth.isAuthenticated).thenReturn(true);
    when(mockAuth.addListener(any)).thenReturn(null);
    when(mockAuth.removeListener(any)).thenReturn(null);

    when(mockHome.isLoading).thenReturn(false);
    when(mockHome.errorMessage).thenReturn(null);
    when(mockHome.filtroCorrente).thenReturn('tutti');
    when(mockHome.viaggi).thenReturn([]);
    when(mockHome.addListener(any)).thenReturn(null);
    when(mockHome.removeListener(any)).thenReturn(null);
  });

  Widget buildWidget() => MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: mockAuth),
          ChangeNotifierProvider<HomeViewModel>.value(value: mockHome),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
          routes: {
            '/add-trip': _stub,
            '/calendar': _stub,
            '/workspace': _stub,
            '/profile': _stub,
          },
          onGenerateRoute: _generateRoute,
        ),
      );

  group('HomeScreen – rendering', () {
    testWidgets('mostra il titolo I miei viaggi', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('I miei viaggi'), findsOneWidget);
    });

    testWidgets('mostra la barra di ricerca', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(
        find.widgetWithText(TextField, 'Cerca per nome o destinazione...'),
        findsOneWidget,
      );
    });

    testWidgets('mostra i tre chip filtro', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Tutti'), findsOneWidget);
      expect(find.text('In corso'), findsOneWidget);
      expect(find.text('In arrivo'), findsOneWidget);
    });

    testWidgets('mostra il FAB Nuovo viaggio', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Nuovo viaggio'), findsOneWidget);
    });

    testWidgets('mostra stato vuoto quando la lista è vuota', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Nessun viaggio in programma'), findsOneWidget);
    });
  });

  group('HomeScreen – loading e errori', () {
    testWidgets('mostra CircularProgressIndicator durante isLoading', (tester) async {
      when(mockHome.isLoading).thenReturn(true);
      await tester.pumpWidget(buildWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('mostra messaggio di errore se errorMessage non è null', (tester) async {
      when(mockHome.errorMessage).thenReturn('Errore nel caricamento dei viaggi.');
      await tester.pumpWidget(buildWidget());
      expect(find.text('Errore nel caricamento dei viaggi.'), findsOneWidget);
    });
  });

  group('HomeScreen – lista viaggi', () {
    testWidgets('mostra una TripCard per ogni viaggio', (tester) async {
      when(mockHome.viaggi).thenReturn([
        makeViaggio(id: 'v1', nome: 'Milano Q1'),
        makeViaggio(id: 'v2', nome: 'Roma Sprint'),
      ]);
      await tester.pumpWidget(buildWidget());
      expect(find.text('Milano Q1'), findsOneWidget);
      expect(find.text('Roma Sprint'), findsOneWidget);
    });

    testWidgets('mostra la destinazione nelle card', (tester) async {
      when(mockHome.viaggi).thenReturn([
        makeViaggio(nome: 'Test', dest: 'Berlino'),
      ]);
      await tester.pumpWidget(buildWidget());
      expect(find.text('Berlino'), findsOneWidget);
    });

    testWidgets('non mostra stato vuoto quando ci sono viaggi', (tester) async {
      when(mockHome.viaggi).thenReturn([makeViaggio()]);
      await tester.pumpWidget(buildWidget());
      expect(find.text('Nessun viaggio in programma'), findsNothing);
    });
  });

  group('HomeScreen – filtri', () {
    testWidgets('tap su "In corso" chiama impostaFiltro', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('In corso'));
      await tester.pump();
      verify(mockHome.impostaFiltro('in_corso')).called(1);
    });

    testWidgets('tap su "In arrivo" chiama impostaFiltro', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('In arrivo'));
      await tester.pump();
      verify(mockHome.impostaFiltro('in_arrivo')).called(1);
    });

    testWidgets('chip "Tutti" risulta selezionato di default', (tester) async {
      await tester.pumpWidget(buildWidget());
      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Tutti'),
      );
      expect(chip.selected, isTrue);
    });
  });

  group('HomeScreen – ricerca', () {
    testWidgets('digitare nel campo ricerca chiama cercaViaggio', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(
        find.widgetWithText(TextField, 'Cerca per nome o destinazione...'),
        'Milano',
      );
      await tester.pump();
      verify(mockHome.cercaViaggio('Milano')).called(1);
    });
  });

  group('HomeScreen – navigazione', () {
    testWidgets('tap FAB naviga verso /add-trip', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Nuovo viaggio'));
      await tester.pumpAndSettle();
      expect(find.text('Stub'), findsOneWidget);
    });
  });
}

// Helpers navigazione
Widget Function(BuildContext) get _stub => (_) => const Scaffold(body: Text('Stub'));

Route<dynamic>? _generateRoute(RouteSettings s) {
  if (s.name == '/trip') {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(body: Text('TripDetail')),
    );
  }
  return null;
}
