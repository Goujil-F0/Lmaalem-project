import 'package:flutter/material.dart';
import 'package:maalem_app/presentation/dashboard/screens/review_screen.dart';
import 'package:maalem_app/presentation/dashboard/screens/dashboard_screen.dart';
import 'package:maalem_app/presentation/dashboard/screens/complaint_screen.dart';
import 'package:maalem_app/presentation/auth/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaalemApp());
}

class MaalemApp extends StatelessWidget {
  const MaalemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maalem',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C2C55),
          primary: const Color(0xFF0C2C55),
        ),
      ),
      home: const TestMenuScreen(),
    );
  }
}

class TestMenuScreen extends StatelessWidget {
  const TestMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String testToken = "TEST_TOKEN";
    const int testArtisanId = 1;
    const int testBookingId = 1;
    const String testArtisanName = "Ahmed le Plombier";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu de Test - Missions Wissal'),
        backgroundColor: const Color(0xFF0C2C55),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMenuButton(
                context,
                "1. Tester les AVIS",
                Icons.star,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReviewScreen(
                      bookingId: testBookingId,
                      artisanId: testArtisanId,
                      artisanName: testArtisanName,
                      token: testToken,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                "2. Tester le DASHBOARD",
                Icons.dashboard,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(
                      artisanId: testArtisanId,
                      token: testToken,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                "3. Tester les RÉCLAMATIONS (Client)",
                Icons.report_problem,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComplaintScreen(
                      artisanId: testArtisanId,
                      token: testToken,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildMenuButton(
                context,
                "4. Tester les RÉCLAMATIONS (Admin)",
                Icons.admin_panel_settings,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ComplaintScreen(
                      artisanId: testArtisanId,
                      token: testToken,
                      isAdmin: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0C2C55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon),
        label: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: onPressed,
      ),
    );
  }
}