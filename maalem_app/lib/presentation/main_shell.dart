import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/presentation/auth/screens/profile_artisan_screen.dart';
import 'package:maalem_app/presentation/auth/screens/profile_client_screen.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: SalomonBottomBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: AppColors.teal,
            unselectedItemColor: AppColors.navy.withValues(alpha: 0.4),
            items: items,
          ),
        ),
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

  List<SalomonBottomBarItem> get _clientItems => [
        SalomonBottomBarItem(icon: const Icon(Icons.home_outlined), title: const Text('Accueil')),
        SalomonBottomBarItem(icon: const Icon(Icons.timeline_outlined), title: const Text('Suivi')),
        SalomonBottomBarItem(icon: const Icon(Icons.report_outlined), title: const Text('Declarer')),
        SalomonBottomBarItem(icon: const Icon(Icons.house_outlined), title: const Text('Maison')),
        SalomonBottomBarItem(icon: const Icon(Icons.person_outline), title: const Text('Compte')),
      ];

  List<SalomonBottomBarItem> get _artisanItems => [
        SalomonBottomBarItem(icon: const Icon(Icons.dashboard_outlined), title: const Text('Dashboard')),
        SalomonBottomBarItem(icon: const Icon(Icons.work_outline), title: const Text('Missions')),
        SalomonBottomBarItem(icon: const Icon(Icons.report_outlined), title: const Text('Declarer')),
        SalomonBottomBarItem(icon: const Icon(Icons.house_outlined), title: const Text('Maison')),
        SalomonBottomBarItem(icon: const Icon(Icons.person_outline), title: const Text('Compte')),
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
