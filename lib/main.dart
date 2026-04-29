import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
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
import 'ui/profile/profile_screen.dart';
import 'ui/profile/history_screen.dart';
import 'ui/profile/profile_view_model.dart';
import 'data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('it_IT', null);
  await NotificationService().inizializza();
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
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: MaterialApp(
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
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        // Schermata iniziale sempre il login
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/add-trip': (context) => const AddTripScreen(),
          '/calendar': (context) => const CalendarScreen(),
          '/workspace': (context) => const WorkspaceScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/history': (context) => const HistoryScreen(),
        },
        // Per le route con parametri usiamo onGenerateRoute
        onGenerateRoute: (settings) {
          if (settings.name == '/trip') {
            final tripId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => TripDetailScreen(viaggioId: tripId),
            );
          }
          if (settings.name == '/expenses') {
            final tripId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => ExpenseScreen(viaggioId: tripId),
            );
          }
          if (settings.name == '/expenses/add') {
            final tripId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => AddExpenseScreen(viaggioId: tripId),
            );
          }
          if (settings.name == '/pdf') {
            final tripId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => PdfPreviewScreen(viaggioId: tripId),
            );
          }
          return null;
        },
      ),
    );
  }
}