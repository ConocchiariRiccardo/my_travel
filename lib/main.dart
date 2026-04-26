import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'ui/auth/auth_view_model.dart';
import 'ui/home/home_view_model.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/register_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/trips/add_trip_screen.dart';
import 'ui/trips/trip_detail_screen.dart';
import 'ui/calendar/calendar_screen.dart';
import 'ui/expenses/expense_screen.dart';
import 'ui/expenses/add_expense_screen.dart';
import 'ui/expenses/pdf_preview_screen.dart';
import 'ui/workspace/workspace_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Firebase è già stato inizializzato nativamente, forziamo l'avvio ignorando l'errore.
    debugPrint("Firebase già inizializzato, ignoro e vado avanti.");
  }

  // Inizializza le localizzazioni italiane per le date
  await initializeDateFormatting('it_IT', null);
  runApp(const MyTravelApp());
}

class MyTravelApp extends StatelessWidget {
  const MyTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
      ],
      child: Builder(
        builder: (context) {
          final authViewModel = context.watch<AuthViewModel>();

          final GoRouter router = GoRouter(
            initialLocation: '/login',
            redirect: (context, state) {
              final isLoggedIn = authViewModel.isAuthenticated;
              final isOnAuthPage = state.matchedLocation == '/login' ||
                  state.matchedLocation == '/register';
              if (!isLoggedIn && !isOnAuthPage) return '/login';
              if (isLoggedIn && isOnAuthPage) return '/home';
              return null;
            },
            routes: [
              GoRoute(
                path: '/login',
                builder: (_, __) => const LoginScreen(),
              ),
              GoRoute(
                path: '/register',
                builder: (_, __) => const RegisterScreen(),
              ),
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
              ),
              GoRoute(
                path: '/add-trip',
                builder: (_, __) => const AddTripScreen(),
              ),
              GoRoute(
                path: '/trip/:id',
                builder: (context, state) {
                  final tripId = state.pathParameters['id']!;
                  return TripDetailScreen(viaggioId: tripId);
                },
              ),
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
              GoRoute(
                path: '/trip/:id/expenses',
                builder: (context, state) {
                  final tripId = state.pathParameters['id']!;
                  return ExpenseScreen(viaggioId: tripId);
                },
              ),
              GoRoute(
                path: '/trip/:id/expenses/add',
                builder: (context, state) {
                  final tripId = state.pathParameters['id']!;
                  return AddExpenseScreen(viaggioId: tripId);
                },
              ),
              GoRoute(
                path: '/trip/:id/pdf',
                builder: (context, state) {
                  final tripId = state.pathParameters['id']!;
                  return PdfPreviewScreen(viaggioId: tripId);
                },
              ),
              GoRoute(
                path: '/workspace',
                builder: (context, state) => const WorkspaceScreen(),
              ),
              // Aggiungeremo /trip/:id, /calendar, /profile nelle prossime fasi
            ],
          );

          return MaterialApp.router(
            title: 'MyTravel',
            debugShowCheckedModeBanner: false,
            locale: const Locale('it', 'IT'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('it', 'IT'),
              Locale('en', 'US'),
            ],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1E3A8A),
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
