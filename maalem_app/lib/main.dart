import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/search_provider.dart';
import 'presentation/search/screens/map_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SearchProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lmaalem',
      debugShowCheckedModeBanner: false,
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
      home: const MapScreen(),
    );
  }
}
