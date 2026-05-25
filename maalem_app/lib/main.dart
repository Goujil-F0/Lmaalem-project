import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports des Providers
import 'package:maalem_app/providers/search_provider.dart';
import 'package:maalem_app/providers/auth_provider.dart';

// Imports des Écrans
import 'package:maalem_app/presentation/search/screens/map_screen.dart';
import 'package:maalem_app/presentation/auth/screens/upload_cin_screen.dart';
import 'package:maalem_app/presentation/auth/screens/splash_screen.dart';
import 'package:maalem_app/presentation/auth/screens/register_screen.dart';
import 'package:maalem_app/presentation/auth/screens/auth_screen.dart';
import 'package:maalem_app/presentation/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C5F8A),
          primary: const Color(0xFF2C5F8A),
          secondary: const Color(0xFFF5ECD7),
          surface: const Color(0xFFF5ECD7),
          onPrimary: Colors.white,
          onSecondary: const Color(0xFF1A2D42),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5ECD7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C5F8A),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C5F8A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      // On utilise l'AppGate pour gérer la logique de démarrage
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
    // Petit délai pour laisser le temps au Splash Screen de s'afficher
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1. ÉCRAN DE CHARGEMENT (Splash)
    if (_showSplash || auth.isLoading) {
      return const SplashScreen();
    }

    // 2. SI L'UTILISATEUR EST CONNECTÉ
    if (auth.token != null) {
      // Vérification spéciale pour l'artisan : doit-il uploader sa CIN ?
      if (auth.user?.isArtisan == true && auth.user?.profile == null) {
        return const UploadCinScreen();
      }
      // Sinon, direction l'écran principal (MainShell qui contient la Map)
      return const MainShell();
    }

    // 3. SI PAS CONNECTÉ -> Direction l'écran d'authentification
    return const AuthScreen();
  }
}