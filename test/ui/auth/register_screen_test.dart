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
          '/login': (_) => const Scaffold(body: Text('Login')),
          '/home': (_) => const Scaffold(body: Text('Home')),
        },
      );

  group('RegisterScreen – rendering', () {
    testWidgets('mostra tre campi TextFormField', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('mostra il bottone Crea Account', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Crea Account'), findsOneWidget);
    });

    testWidgets('mostra il link Accedi', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Accedi'), findsOneWidget);
    });
  });

  group('RegisterScreen – validazione form', () {
    testWidgets('mostra errore se email vuota', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Crea Account'));
      await tester.pump();
      expect(find.text('Inserisci la tua email'), findsOneWidget);
    });

    testWidgets('mostra errore se email senza @', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(find.byType(TextFormField).at(0), 'emailsenza');
      await tester.tap(find.text('Crea Account'));
      await tester.pump();
      expect(find.text('Formato email non valido'), findsOneWidget);
    });

    testWidgets('mostra errore se password troppo corta', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(find.byType(TextFormField).at(0), 'ok@ok.com');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.tap(find.text('Crea Account'));
      await tester.pump();
      expect(find.text('La password deve avere almeno 6 caratteri'), findsOneWidget);
    });

    testWidgets('mostra errore se le password non coincidono', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.enterText(find.byType(TextFormField).at(0), 'ok@ok.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'pass123');
      await tester.enterText(find.byType(TextFormField).at(2), 'diversa');
      await tester.tap(find.text('Crea Account'));
      await tester.pump();
      expect(find.text('Le password non coincidono'), findsOneWidget);
    });

    testWidgets('non chiama register se form non valido', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Crea Account'));
      await tester.pump();
      verifyNever(mockAuth.register(any, any));
    });
  });

  group('RegisterScreen – loading state', () {
    testWidgets('mostra spinner durante isLoading', (tester) async {
      when(mockAuth.isLoading).thenReturn(true);
      await tester.pumpWidget(buildWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('bottone disabilitato durante isLoading', (tester) async {
      when(mockAuth.isLoading).thenReturn(true);
      await tester.pumpWidget(buildWidget());
      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNull);
    });
  });

  group('RegisterScreen – interazione', () {
    testWidgets('chiama register con email e password corretti', (tester) async {
      when(mockAuth.register(any, any)).thenAnswer((_) async => true);
      await tester.pumpWidget(buildWidget());

      await tester.enterText(find.byType(TextFormField).at(0), 'nuovo@user.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password1');
      await tester.enterText(find.byType(TextFormField).at(2), 'password1');
      await tester.tap(find.text('Crea Account'));
      await tester.pump();

      verify(mockAuth.register('nuovo@user.com', 'password1')).called(1);
    });

    testWidgets('mostra SnackBar di successo dopo registrazione', (tester) async {
      when(mockAuth.register(any, any)).thenAnswer((_) async => true);
      await tester.pumpWidget(buildWidget());

      await tester.enterText(find.byType(TextFormField).at(0), 'n@n.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'validpass');
      await tester.enterText(find.byType(TextFormField).at(2), 'validpass');
      await tester.tap(find.text('Crea Account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Account creato con successo! Benvenuto.'), findsOneWidget);
    });

    testWidgets('mostra SnackBar di errore su registrazione fallita', (tester) async {
      when(mockAuth.register(any, any)).thenAnswer((_) async => false);
      when(mockAuth.errorMessage).thenReturn('Email già in uso. Prova ad accedere.');
      await tester.pumpWidget(buildWidget());

      await tester.enterText(find.byType(TextFormField).at(0), 'gia@usata.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'validpass');
      await tester.enterText(find.byType(TextFormField).at(2), 'validpass');
      await tester.tap(find.text('Crea Account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Email già in uso. Prova ad accedere.'), findsOneWidget);
    });

    testWidgets('tap Accedi naviga verso /login', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Accedi'));
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('toggle visibilità password funziona', (tester) async {
      await tester.pumpWidget(buildWidget());
      // Il primo IconButton visibility è relativo alla password
      final icons = find.byIcon(Icons.visibility_outlined);
      await tester.tap(icons.first);
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off_outlined), findsWidgets);
    });
  });
}
