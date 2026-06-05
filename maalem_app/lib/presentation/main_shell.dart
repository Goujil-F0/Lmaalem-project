import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/presentation/auth/screens/profile_artisan_screen.dart';
import 'package:maalem_app/presentation/auth/screens/profile_client_screen.dart';
import 'package:maalem_app/presentation/dashboard/screens/admin_dashboard_screen.dart';
import 'package:maalem_app/presentation/dashboard/screens/complaint_screen.dart';
import 'package:maalem_app/presentation/dashboard/screens/dashboard_screen.dart';
import 'package:maalem_app/presentation/home/screens/client_home_screen.dart';
import 'package:maalem_app/presentation/search/screens/map_screen.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:maalem_app/presentation/booking/screens/history_screen.dart';

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
    final isAdmin = user?.isAdmin ?? false;
    final pages = isAdmin
        ? _adminPages
        : isArtisan
            ? _artisanPages(user?.id ?? 0)
            : _clientPages;
    final items = isAdmin
        ? _adminItems
        : isArtisan
            ? _artisanItems
            : _clientItems;

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
        ClientHomeScreen(),
        HistoryScreen(),
        MapScreen(),
        _ConstructionScreen(title: 'Maison'),
        ProfileClientScreen(),
      ];

  List<Widget> _artisanPages(int artisanId) => [
        DashboardScreen(artisanId: artisanId),
        const HistoryScreen(),
        const MapScreen(),
        const _ConstructionScreen(title: 'Maison'),
        const ProfileArtisanScreen(),
      ];

  List<Widget> get _adminPages => const [
        AdminDashboardScreen(),
        ComplaintScreen(
          bookingId: 0,
          artisanId: 0,
          isAdmin: true,
        ),
        _ConstructionScreen(title: 'Compte'),
      ];

  List<SalomonBottomBarItem> get _clientItems => [
        SalomonBottomBarItem(
            icon: const Icon(Icons.home_outlined),
            title: const Text('Accueil')),
        SalomonBottomBarItem(
            icon: const Icon(Icons.timeline_outlined),
            title: const Text('Suivi')),
        SalomonBottomBarItem(
            icon: const Icon(Icons.map_outlined), title: const Text('Map')),
        SalomonBottomBarItem(
            icon: const Icon(Icons.house_outlined),
            title: const Text('Maison')),
        SalomonBottomBarItem(
            icon: const Icon(Icons.person_outline),
            title: const Text('Compte')),
      ];

  List<SalomonBottomBarItem> get _artisanItems => [
        SalomonBottomBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard')),
        SalomonBottomBarItem(
            icon: const Icon(Icons.work_outline),
            title: const Text('Missions')),
        SalomonBottomBarItem(
            icon: const Icon(Icons.map_outlined), title: const Text('Map')),
        SalomonBottomBarItem(
            icon: const Icon(Icons.house_outlined),
            title: const Text('Maison')),
        SalomonBottomBarItem(
            icon: const Icon(Icons.person_outline),
            title: const Text('Compte')),
      ];

  List<SalomonBottomBarItem> get _adminItems => [
        SalomonBottomBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard')),
        SalomonBottomBarItem(
            icon: const Icon(Icons.report_problem_outlined),
            title: const Text('Réclamations')),
        SalomonBottomBarItem(
            icon: const Icon(Icons.person_outline),
            title: const Text('Compte')),
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
