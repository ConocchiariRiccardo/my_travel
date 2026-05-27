import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:my_travel/ui/auth/register_screen.dart';
import 'package:my_travel/ui/auth/auth_view_model.dart';

// Riutilizza il mock generato in login_screen_test.dart
import '../auth/login_screen_test.mocks.dart';

void main() {
  late MockAuthViewModel mockAuth;

  setUp(() {
    mockAuth = MockAuthViewModel();
    when(mockAuth.isLoading).thenReturn(false);
    when(mockAuth.errorMessage).thenReturn(null);
    when(mockAuth.addListener(any)).thenReturn(null);
    when(mockAuth.removeListener(any)).thenReturn(null);
  });

  Widget buildWidget() => MaterialApp(
        home: ChangeNotifierProvider<AuthViewModel>.value(
          value: mockAuth,
          child: const RegisterScreen(),
        ),
        routes: {
          '/login': (_) => const Scaffold(body: Text('Login', key: Key('login-route'))),
          '/home': (_) => const Scaffold(body: Text('Home', key: Key('home-route'))),
        },
      );

  group('RegisterScreen – rendering', () {
    testWidgets('mostra tre campi TextFormField', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byKey(const Key('register-email-field')), findsOneWidget);
      expect(find.byKey(const Key('register-password-field')), findsOneWidget);
      expect(find.byKey(const Key('register-confirm-password-field')), findsOneWidget);
    });

    testWidgets('mostra il bottone Crea Account', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byKey(const Key('register-btn')), findsOneWidget);
    });

    testWidgets('mostra il link Accedi', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byKey(const Key('register-login-link')), findsOneWidget);
    });
  });

  group('RegisterScreen – validazione form', () {
    testWidgets('mostra errore se email vuota', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byKey(const Key('register-btn')));
      await tester.pump();
      expect(find.text('Inserisci la tua email'), findsOneWidget);
    });

    testWidgets('mostra errore se email senza @', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(find.byKey(const Key('register-email-field')), 'emailsenza');
      await tester.tap(find.byKey(const Key('register-btn')));
      await tester.pump();
      expect(find.text('Formato email non valido'), findsOneWidget);
    });

    testWidgets('mostra errore se password troppo corta', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(find.byKey(const Key('register-email-field')), 'ok@ok.com');
      await tester.enterText(find.byKey(const Key('register-password-field')), '123');
      await tester.tap(find.byKey(const Key('register-btn')));
      await tester.pump();
      expect(find.text('La password deve avere almeno 8 caratteri'), findsOneWidget);
    });

    testWidgets('mostra errore se le password non coincidono', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(find.byKey(const Key('register-email-field')), 'ok@ok.com');
      await tester.enterText(find.byKey(const Key('register-password-field')), 'pass123');
      await tester.enterText(find.byKey(const Key('register-confirm-password-field')), 'diversa');
      await tester.ensureVisible(find.byKey(const Key('register-btn')));
      await tester.tap(find.byKey(const Key('register-btn')));
      await tester.pump();
      expect(find.text('Le password non coincidono'), findsOneWidget);
    });

    testWidgets('non chiama register se form non valido', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.ensureVisible(find.byKey(const Key('register-btn')));
      await tester.tap(find.byKey(const Key('register-btn')));
      await tester.pump();
      verifyNever(mockAuth.register(any, any));
    });
  });

  group('RegisterScreen – loading state', () {
    testWidgets('mostra spinner durante isLoading', (tester) async {
      when(mockAuth.isLoading).thenReturn(true);
      await tester.pumpWidget(buildWidget());
      expect(find.byKey(const Key('register-loading')), findsOneWidget);
    });

    testWidgets('bottone disabilitato durante isLoading', (tester) async {
      when(mockAuth.isLoading).thenReturn(true);
      await tester.pumpWidget(buildWidget());
      final btn = tester.widget<ElevatedButton>(find.byKey(const Key('register-btn')));
      expect(btn.onPressed, isNull);
    });
  });

  group('RegisterScreen – interazione', () {
    testWidgets('chiama register con email e password corretti', (tester) async {
      when(mockAuth.register(any, any)).thenAnswer((_) async => true);
      await tester.pumpWidget(buildWidget());

      await tester.enterText(find.byKey(const Key('register-email-field')), 'nuovo@user.com');
      await tester.enterText(find.byKey(const Key('register-password-field')), 'Password1!');
      await tester.enterText(find.byKey(const Key('register-confirm-password-field')), 'Password1!');
      await tester.ensureVisible(find.byKey(const Key('register-btn')));
      await tester.tap(find.byKey(const Key('register-btn')));
      await tester.pump();

      verify(mockAuth.register('nuovo@user.com', 'Password1!')).called(1);
    });

    testWidgets('mostra SnackBar di successo dopo registrazione', (tester) async {
      when(mockAuth.register(any, any)).thenAnswer((_) async => true);
      await tester.pumpWidget(buildWidget());

      await tester.enterText(find.byKey(const Key('register-email-field')), 'n@n.com');
      await tester.enterText(find.byKey(const Key('register-password-field')), 'Validpass1!');
      await tester.enterText(find.byKey(const Key('register-confirm-password-field')), 'Validpass1!');
      await tester.ensureVisible(find.byKey(const Key('register-btn')));
      await tester.tap(find.byKey(const Key('register-btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('register-success-snackbar')), findsOneWidget);
    });

    testWidgets('mostra SnackBar di errore su registrazione fallita', (tester) async {
      when(mockAuth.register(any, any)).thenAnswer((_) async => false);
      when(mockAuth.errorMessage).thenReturn('Email già in uso. Prova ad accedere.');
      await tester.pumpWidget(buildWidget());

      await tester.enterText(find.byKey(const Key('register-email-field')), 'gia@usata.com');
      await tester.enterText(find.byKey(const Key('register-password-field')), 'Validpass1!');
      await tester.enterText(find.byKey(const Key('register-confirm-password-field')), 'Validpass1!');
      await tester.ensureVisible(find.byKey(const Key('register-btn')));
      await tester.tap(find.byKey(const Key('register-btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('register-error-snackbar')), findsOneWidget);
    });

    testWidgets('tap Accedi naviga verso /login', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.ensureVisible(find.byKey(const Key('register-login-link')));
      await tester.tap(find.byKey(const Key('register-login-link')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('login-route')), findsOneWidget);
    });

    testWidgets('toggle visibilità password funziona', (tester) async {
      await tester.pumpWidget(buildWidget());
      final vis1 = find.byKey(const Key('register-password-visibility-btn'));
      final vis2 = find.byKey(const Key('register-confirm-password-visibility-btn'));
      await tester.tap(vis1);
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsWidgets);
    });
  });
}
