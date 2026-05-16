import 'package:flutter/material.dart';
import 'package:maalem_app/presentation/auth/screens/upload_cin_screen.dart';
import 'package:provider/provider.dart';
import 'package:maalem_app/presentation/auth/screens/splash_screen.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:maalem_app/presentation/auth/screens/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
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
      title: 'Maalem',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          print(
              "🔄 DEBUG: Re-build de l'écran Home. isLoading: ${auth.isLoading}, token: ${auth.token}");
          // 1. ÉCRAN DE CHARGEMENT
          if (auth.isLoading) {
            return const SplashScreen();
          }

          // 2. SI L'UTILISATEUR EST CONNECTÉ -> DIRECTION LA MAP
          if (auth.token != null) {
            if (auth.user?.isArtisan == true && auth.user?.profile == null) {
              return const UploadCinScreen(); // Redirection forcée vers l'upload
            }
            // On met un Scaffold pour éviter le fond noir et le texte rouge
            return const Scaffold(
              body: Center(
                child: Text(
                  "Bienvenue sur la Map !",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          // 3. SI PAS CONNECTÉ -> DIRECTION L'ÉCRAN AUTH (Login/Register)
          // ✅ CORRECTION : On retourne l'AuthScreen au lieu du simple texte
          return const RegisterScreen();
        },
      ),
    );
  }
}
