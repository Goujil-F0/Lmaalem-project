import 'package:flutter/material.dart';
import 'package:maalem_app/presentation/auth/screens/auth_screen.dart';
import 'package:maalem_app/presentation/auth/screens/splash_screen.dart';
import 'package:maalem_app/presentation/main_shell.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
import 'providers/search_provider.dart';
import 'providers/auth_provider.dart';
import 'presentation/search/screens/map_screen.dart';
import 'presentation/auth/screens/upload_cin_screen.dart';
import 'presentation/auth/screens/splash_screen.dart';
import 'presentation/auth/screens/register_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SearchProvider()),
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
      title: 'Lmaalem',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: ThemeData(
        fontFamily: 'Inter',
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const _AppGate(),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (_showSplash || auth.isLoading) {
      return const SplashScreen();
    }

    if (auth.token != null) {
      return const MainShell();
    }

    return const AuthScreen();
  }
}
