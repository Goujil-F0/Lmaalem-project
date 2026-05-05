import 'package:flutter/material.dart';
import 'package:maalem_app/presentation/dashboard/screens/review_screen.dart';
import 'package:maalem_app/presentation/dashboard/screens/dashboard_screen.dart';
import 'package:maalem_app/presentation/dashboard/screens/complaint_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maalem',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C2C55)),
      ),
      home: const ReviewScreen(
        bookingId: 1,
        artisanId: 1,
        artisanName: "Ahmed le Plombier",
        token: 'VOTRE_TOKEN_ICI',
      ),
    );
  }
}