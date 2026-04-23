import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';          
import 'ui/auth/auth_view_model.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/register_screen.dart';
import 'ui/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, 
  );
  runApp(const MyTravelApp());
}

class MyTravelApp extends StatelessWidget {
  const MyTravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ],
      child: Builder(
        builder: (context) {
          final authViewModel = context.watch<AuthViewModel>();

          final GoRouter router = GoRouter(
            initialLocation: '/login',
            redirect: (context, state) {
              final isLoggedIn = authViewModel.isAuthenticated;
              final isOnAuthPage =
                  state.matchedLocation == '/login' ||
                  state.matchedLocation == '/register';

              if (!isLoggedIn && !isOnAuthPage) return '/login';
              if (isLoggedIn && isOnAuthPage) return '/home';
              return null;
            },
            routes: [
              GoRoute(
                path: '/login',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(
                path: '/register',
                builder: (context, state) => const RegisterScreen(),
              ),
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          );

          return MaterialApp.router(
            title: 'MyTravel',
            debugShowCheckedModeBanner: false,
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