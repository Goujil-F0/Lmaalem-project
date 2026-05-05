import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1. Tes imports (Vérifie bien les chemins)
import 'providers/search_provider.dart';
import 'presentation/search/screens/map_screen.dart';

void main() {
  runApp(
    // Le MultiProvider est le "centre de contrôle" des cerveaux de l'app
    MultiProvider(
      providers: [
        // On enregistre ton SearchProvider pour qu'il soit accessible partout
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        // Si tes collègues ont d'autres providers, ils s'ajoutent ici
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lmaalem Project',
      debugShowCheckedModeBanner:
          false, // Enlève le bandeau "Debug" en haut à droite
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      // 2. On définit ta carte comme page de démarrage
      home: MapScreen(),
    );
  }
}
