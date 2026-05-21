import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:my_travel/ui/auth/auth_view_model.dart';
import 'package:my_travel/ui/expenses/expense_screen.dart';
import 'package:my_travel/ui/expenses/expense_view_model.dart';
import 'package:my_travel/domain/models/spesa.dart';
import '../trips/remaining_screens_mocks.mocks.dart';

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

void main() {
  late MockExpenseViewModel mockVm;
  late MockAuthViewModel mockAuth;
  late MockUser mockUser;

  setUpAll(() async {
    await initializeDateFormatting('it_IT');
  });

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
            '/expenses/add': _stub,
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

    testWidgets('mostra icona PDF nell\'AppBar', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    });
  });

  group('ExpenseScreen – riepilogo categorie', () {
    testWidgets('mostra chip per ogni categoria', (tester) async {
      when(mockVm.spese).thenReturn([makeSpesa(), makeSpesa(id: 's2', cat: 'Trasporto')]);
      when(mockVm.totalePerCategoria).thenReturn({'Pasto': 25.50, 'Trasporto': 15.00});
      await tester.pumpWidget(buildWidget());
      expect(find.text('Pasto: €25.50'), findsOneWidget);
      expect(find.text('Trasporto: €15.00'), findsOneWidget);
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

Widget Function(BuildContext) get _stub => (_) => const Scaffold(body: Text('Stub'));
