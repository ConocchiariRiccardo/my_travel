import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_travel/ui/widgets/trip_card.dart';
import 'package:my_travel/domain/models/viaggio.dart';

// ── Helper ───────────────────────────────────────────────────────────────────

Viaggio makeViaggio({
  String id = 'v1',
  String nome = 'Trasferta Test',
  String dest = 'Milano',
  int giorniAlPartenza = 5,
  bool inCorso = false,
  bool concluso = false,
}) {
  final oggi = DateTime.now();
  late DateTime inizio;
  late DateTime fine;

  if (inCorso) {
    inizio = oggi.subtract(const Duration(days: 1));
    fine = oggi.add(const Duration(days: 2));
  } else if (concluso) {
    inizio = oggi.subtract(const Duration(days: 10));
    fine = oggi.subtract(const Duration(days: 7));
  } else {
    inizio = oggi.add(Duration(days: giorniAlPartenza));
    fine = inizio.add(const Duration(days: 3));
  }

  return Viaggio(
    id: id,
    userId: 'u1',
    nome: nome,
    destinazione: dest,
    dataInizio: inizio,
    dataFine: fine,
  );
}

Widget buildCard({
  required Viaggio viaggio,
  VoidCallback? onTap,
  VoidCallback? onDelete,
}) =>
    MaterialApp(
      home: Scaffold(
        body: TripCard(
          viaggio: viaggio,
          onTap: onTap ?? () {},
          onDelete: onDelete ?? () {},
        ),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('it_IT');
  });

  group('TripCard – contenuto', () {
    testWidgets('mostra nome e destinazione', (tester) async {
      await tester.pumpWidget(buildCard(viaggio: makeViaggio(nome: 'Roma Q2', dest: 'Roma')));
      expect(find.byKey(const Key('trip-v1')), findsOneWidget);
    });

    testWidgets('mostra icona del cestino', (tester) async {
      await tester.pumpWidget(buildCard(viaggio: makeViaggio()));
      expect(find.byKey(const Key('trip-delete-v1')), findsOneWidget);
    });
  });

  group('TripCard – badge di stato', () {
    testWidgets('mostra badge "In corso" per viaggio in corso', (tester) async {
      await tester.pumpWidget(buildCard(viaggio: makeViaggio(inCorso: true)));
      final badge = tester.widget<Text>(find.byKey(const Key('trip-status-v1')));
      expect(badge.data, contains('In corso'));
    });

    testWidgets('mostra badge con giorni rimanenti per viaggio futuro', (tester) async {
      await tester.pumpWidget(buildCard(viaggio: makeViaggio(giorniAlPartenza: 7)));
      final badge = tester.widget<Text>(find.byKey(const Key('trip-status-v1')));
      expect(badge.data, contains('7'));
    });

    testWidgets('mostra badge "Concluso" per viaggio passato', (tester) async {
      await tester.pumpWidget(buildCard(viaggio: makeViaggio(concluso: true)));
      final badge = tester.widget<Text>(find.byKey(const Key('trip-status-v1')));
      expect(badge.data, 'Concluso');
    });
  });

  group('TripCard – interazioni', () {
    testWidgets('tap sulla card chiama onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildCard(
        viaggio: makeViaggio(),
        onTap: () => tapped = true,
      ));
      await tester.tap(find.byKey(const Key('trip-v1')));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('tap sul cestino mostra dialog di conferma', (tester) async {
      await tester.pumpWidget(buildCard(viaggio: makeViaggio(nome: 'Da eliminare')));
      await tester.tap(find.byKey(const Key('trip-delete-v1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trip-delete-title')), findsOneWidget);
      expect(find.byKey(const Key('trip-delete-message')), findsOneWidget);
    });

    testWidgets('tap Annulla nel dialog non chiama onDelete', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(buildCard(
        viaggio: makeViaggio(),
        onDelete: () => deleted = true,
      ));
      await tester.tap(find.byKey(const Key('trip-delete-v1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('trip-delete-cancel')));
      await tester.pumpAndSettle();
      expect(deleted, isFalse);
    });

    testWidgets('tap Elimina nel dialog chiama onDelete', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(buildCard(
        viaggio: makeViaggio(),
        onDelete: () => deleted = true,
      ));
      await tester.tap(find.byKey(const Key('trip-delete-v1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('trip-delete-confirm')));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });
  });
}
