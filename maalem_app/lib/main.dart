import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/booking_provider.dart';
import 'presentation/booking/screens/history_screen.dart';
// import 'presentation/booking/screens/chat_screen.dart';
import 'providers/chat_provider.dart';

void main() {
  // On s'assure que les widgets sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // MultiProvider permet d'ajouter plusieurs providers facilement plus tard
    MultiProvider(
      providers: [
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
      title: 'Maalem',
      debugShowCheckedModeBanner: false, // Enlève la bannière "Debug"
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Tu pourras ajouter ici ton AppTheme plus tard
      ),
      // home: SplashScreen(), <-- commente temporairement cette ligne
      home: const HistoryScreen(),
      // home: const ChatScreen(bookingId: 4, currentUserId: 1),
    );
  }
}
