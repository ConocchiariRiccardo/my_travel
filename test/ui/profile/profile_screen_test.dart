import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:my_travel/ui/auth/auth_view_model.dart';
import 'package:my_travel/ui/profile/profile_screen.dart';
import 'package:my_travel/ui/profile/profile_view_model.dart';
import 'package:my_travel/domain/models/utente.dart';
import '../trips/remaining_screens_mocks.mocks.dart';

Utente makeUtente({String nome = 'Mario Rossi'}) => Utente(
      id: 'u1',
      email: 'mario@test.com',
      nomeCompleto: nome,
    );

void main() {
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
        child: MaterialApp(
          home: ProfileScreen(),
          routes: {'/history': _stub, '/login': _stub},
        ),
      );

  group('ProfileScreen – rendering', () {
    testWidgets('mostra nome completo dell\'utente', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Mario Rossi'), findsWidgets);
    });

    testWidgets('mostra email dell\'utente', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('mario@test.com'), findsWidgets);
    });

    testWidgets('mostra l\'icona di modifica quando non in edit mode', (tester) async {
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
      await tester.scrollUntilVisible(
        find.text("Esci dall'account"),
        200,
      );
      expect(find.text("Esci dall'account"), findsOneWidget);
    });
  });

  group('ProfileScreen – edit mode', () {
    testWidgets('tap sull\'icona edit mostra il campo nome', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, 'Nome completo'), findsOneWidget);
    });

    testWidgets('in edit mode mostra bottone Salva al posto dell\'icona', (tester) async {
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
      await tester.scrollUntilVisible(
        find.text("Esci dall'account"),
        200,
      );
      await tester.tap(find.text("Esci dall'account"));
      await tester.pumpAndSettle();
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('tap Annulla nel dialog non chiama logout', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.scrollUntilVisible(
        find.text("Esci dall'account"),
        200,
      );
      await tester.tap(find.text("Esci dall'account"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      verifyNever(mockAuth.logout());
    });

    testWidgets('tap Esci nel dialog chiama logout', (tester) async {
      when(mockAuth.logout()).thenAnswer((_) async {});
      await tester.pumpWidget(buildWidget());
      await tester.scrollUntilVisible(
        find.text("Esci dall'account"),
        200,
      );
      await tester.tap(find.text("Esci dall'account"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esci'));
      await tester.pumpAndSettle();
      verify(mockAuth.logout()).called(1);
    });
  });
}

Widget Function(BuildContext) get _stub => (_) => const Scaffold(body: Text('Stub'));
