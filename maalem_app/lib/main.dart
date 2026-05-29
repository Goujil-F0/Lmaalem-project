import 'package:flutter/material.dart';
import 'package:maalem_app/presentation/auth/screens/auth_screen.dart';
import 'package:maalem_app/presentation/auth/screens/splash_screen.dart';
import 'package:maalem_app/presentation/main_shell.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:maalem_app/providers/booking_provider.dart';
import 'package:maalem_app/providers/chat_provider.dart';
import 'package:maalem_app/providers/location_provider.dart';
import 'package:maalem_app/providers/search_provider.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MaalemApp(),
    ),
  );
}

class MaalemApp extends StatelessWidget {
  const MaalemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lmaalem',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        fontFamily: 'Inter',
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const _AppGate(),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // 1. Display splash during initialization or manual check
        if (_showSplash || auth.isCheckingAuth) {
          return const SplashScreen();
        }

        // 2. Si un token est présent, l'utilisateur est connecté
        if (auth.token != null) {
          // On attend que les données utilisateur (profil) soient prêtes
          if (auth.user != null) {
            return const MainShell();
          }
          // Si on a le token mais pas encore le profil, on affiche le SplashScreen
          return const SplashScreen();
        }

        // 3. Sinon, on demande la connexion
        return const AuthScreen();
      },
    );
  }
}
