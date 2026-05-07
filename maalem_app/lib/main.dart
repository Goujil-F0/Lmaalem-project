import 'package:flutter/material.dart';
import 'package:maalem_app/presentation/auth/screens/splash_screen.dart';

void main() {
  // On s'assure que les widgets sont initialisés
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MaalemApp());
}

class MaalemApp extends StatelessWidget {
  const MaalemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maalem',
      debugShowCheckedModeBanner: false, // Enlève la bannière "Debug"
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Tu pourras ajouter ici ton AppTheme plus tard
      ),
      home: SplashScreen(), // L'écran de départ est l'écran d'authentification
    );
  }
}