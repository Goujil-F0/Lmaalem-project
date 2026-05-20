import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/search_provider.dart';
import 'providers/auth_provider.dart';
import 'presentation/search/screens/map_screen.dart';
import 'presentation/auth/screens/upload_cin_screen.dart';
import 'presentation/auth/screens/splash_screen.dart';
import 'presentation/auth/screens/register_screen.dart';

void main() async {
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
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          // 1. ÉCRAN DE CHARGEMENT
          if (auth.isLoading) {
            return const SplashScreen();
          }

          // 2. SI L'UTILISATEUR EST CONNECTÉ -> DIRECTION LA MAP
          if (auth.token != null) {
            if (auth.user?.isArtisan == true && auth.user?.profile == null) {
              return const UploadCinScreen();
            }
            return const MapScreen();
          }

          // 3. SI PAS CONNECTÉ -> DIRECTION L'ÉCRAN AUTH
          return const RegisterScreen();
        },
      ),
    );
  }
}
