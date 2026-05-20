import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/presentation/auth/screens/profile_artisan_screen.dart';
import 'package:maalem_app/presentation/auth/screens/profile_client_screen.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isArtisan = user?.isArtisan ?? false;
    final pages = isArtisan ? _artisanPages : _clientPages;
    final items = isArtisan ? _artisanItems : _clientItems;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.teal,
        unselectedItemColor: AppColors.textGrey,
        backgroundColor: AppColors.white,
        items: items,
      ),
    );
  }

  List<Widget> get _clientPages => const [
        _ConstructionScreen(title: 'Accueil'),
        _ConstructionScreen(title: 'Suivi'),
        _ConstructionScreen(title: 'Declarer'),
        _ConstructionScreen(title: 'Maison'),
        ProfileClientScreen(),
      ];

  List<Widget> get _artisanPages => const [
        _ConstructionScreen(title: 'Dashboard'),
        _ConstructionScreen(title: 'Missions'),
        _ConstructionScreen(title: 'Declarer'),
        _ConstructionScreen(title: 'Maison'),
        ProfileArtisanScreen(),
      ];

  List<BottomNavigationBarItem> get _clientItems => const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.timeline_outlined), label: 'Suivi'),
        BottomNavigationBarItem(icon: Icon(Icons.report_outlined), label: 'Declarer'),
        BottomNavigationBarItem(icon: Icon(Icons.house_outlined), label: 'Maison'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Compte'),
      ];

  List<BottomNavigationBarItem> get _artisanItems => const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Missions'),
        BottomNavigationBarItem(icon: Icon(Icons.report_outlined), label: 'Declarer'),
        BottomNavigationBarItem(icon: Icon(Icons.house_outlined), label: 'Maison'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Compte'),
      ];
}

class _ConstructionScreen extends StatelessWidget {
  final String title;

  const _ConstructionScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.beige,
        foregroundColor: AppColors.navy,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'En construction',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
