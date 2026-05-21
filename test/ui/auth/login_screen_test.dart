import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_travel/ui/auth/login_screen.dart';
import 'package:my_travel/ui/auth/auth_view_model.dart';

@GenerateMocks([AuthViewModel])
import 'login_screen_test.mocks.dart';

void main() {
  late MockAuthViewModel mockAuth;

  setUp(() {
    mockAuth = MockAuthViewModel();
    when(mockAuth.isLoading).thenReturn(false);
    when(mockAuth.errorMessage).thenReturn(null);
    when(mockAuth.isAuthenticated).thenReturn(false);
    when(mockAuth.addListener(any)).thenReturn(null);
    when(mockAuth.removeListener(any)).thenReturn(null);
  });

  Widget buildWidget() => MaterialApp(
        home: ChangeNotifierProvider<AuthViewModel>.value(
          value: mockAuth,
          child: const LoginScreen(),
        ),
        routes: {
          '/home': (_) => const Scaffold(body: Text('Home')),
          '/register': (_) => const Scaffold(body: Text('Register')),
        },
      );

  group('LoginScreen – rendering', () {
    testWidgets('mostra i campi email e password', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('mostra il titolo MyTravel', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('MyTravel'), findsOneWidget);
    });

    testWidgets('mostra bottone Accedi abilitato', (tester) async {
      await tester.pumpWidget(buildWidget());
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('mostra bottone Google Sign-In', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Accedi con Google'), findsOneWidget);
    });

    testWidgets('mostra link Registrati', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.text('Registrati'), findsOneWidget);
    });
  });

  group('LoginScreen – loading state', () {
    testWidgets('mostra spinner e disabilita bottone durante isLoading', (tester) async {
      when(mockAuth.isLoading).thenReturn(true);
      await tester.pumpWidget(buildWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final btn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('bottone Google disabilitato durante isLoading', (tester) async {
      when(mockAuth.isLoading).thenReturn(true);
      await tester.pumpWidget(buildWidget());
      final btn = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(btn.onPressed, isNull);
    });
  });

  group('LoginScreen – toggle password', () {
    testWidgets('password oscurata di default', (tester) async {
      await tester.pumpWidget(buildWidget());
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      // Il secondo TextField è la password
      expect(fields[1].obscureText, isTrue);
    });

    testWidgets('tap sull/icona mostra la password', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields[1].obscureText, isFalse);
    });

    testWidgets('secondo tap nasconde di nuovo la password', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields[1].obscureText, isTrue);
    });
  });

  group('LoginScreen – interazione login', () {
    testWidgets('chiama login con le credenziali corrette', (tester) async {
      when(mockAuth.login(any, any)).thenAnswer((_) async => true);
      await tester.pumpWidget(buildWidget());

      await tester.enterText(find.byType(TextField).at(0), 'test@mail.com');
      await tester.enterText(find.byType(TextField).at(1), 'pass123');
      await tester.tap(find.text('Accedi'));
      await tester.pump();

      verify(mockAuth.login('test@mail.com', 'pass123')).called(1);
    });

    testWidgets('mostra SnackBar su errore di login', (tester) async {
      when(mockAuth.login(any, any)).thenAnswer((_) async => false);
      when(mockAuth.errorMessage).thenReturn('Password errata. Riprova.');
      await tester.pumpWidget(buildWidget());

      await tester.enterText(find.byType(TextField).at(0), 'x@x.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrong');
      await tester.tap(find.text('Accedi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Password errata. Riprova.'), findsOneWidget);
    });

    testWidgets('navigazione verso /home dopo login riuscito', (tester) async {
      when(mockAuth.login(any, any)).thenAnswer((_) async => true);
      await tester.pumpWidget(buildWidget());

      await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(1), 'abc123');
      await tester.tap(find.text('Accedi'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('chiama loginWithGoogle al tap', (tester) async {
      when(mockAuth.loginWithGoogle()).thenAnswer((_) async => true);
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Accedi con Google'));
      await tester.pump();
      verify(mockAuth.loginWithGoogle()).called(1);
    });

    testWidgets('tap Registrati naviga verso /register', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.tap(find.text('Registrati'));
      await tester.pumpAndSettle();
      expect(find.text('Register'), findsOneWidget);
    });
  });
}
