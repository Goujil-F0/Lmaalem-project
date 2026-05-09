import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/presentation/auth/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:maalem_app/presentation/dashboard/screens/review_screen.dart';
import 'package:maalem_app/presentation/dashboard/screens/dashboard_screen.dart';
import 'package:maalem_app/presentation/dashboard/screens/complaint_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  void _openRegister(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const RegisterScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final slideUp = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return SlideTransition(position: slideUp, child: child);
        },
      ),
    );
  }

  void _enterApp(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const _AppEntryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              const SizedBox(height: 42),
              const _AuthLogo(),
              const SizedBox(height: 22),
              const Text(
                "Bon retour",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Connectez-vous a votre compte Lmaalem",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.navy.withValues(alpha: 0.62),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 54),
              const _AuthInput(
                hintText: "E-mail",
                icon: Icons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              const _AuthInput(
                hintText: "Mot de passe",
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 36),
              _PrimaryAuthButton(
                text: "Se connecter",
                onPressed: () => _enterApp(context),
              ),
              const SizedBox(height: 80),
              TextButton(
                onPressed: () => _openRegister(context),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.navy.withValues(alpha: 0.72),
                      fontSize: 15,
                    ),
                    children: const [
                      TextSpan(text: "Vous n'avez pas de compte ? "),
                      TextSpan(
                        text: "S'inscrire",
                        style: TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.handyman, color: AppColors.navy, size: 38),
        ),
        const SizedBox(height: 14),
        Text(
          "Lmaalem",
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: AppColors.teal.withValues(alpha: 0.22),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthInput extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;

  const _AuthInput({
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.navy.withValues(alpha: 0.52)),
        prefixIcon: Icon(icon, color: AppColors.navy.withValues(alpha: 0.72)),
        filled: true,
        fillColor: AppColors.navy.withValues(alpha: 0.08),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: AppColors.navy.withValues(alpha: 0.03)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
        ),
      ),
    );
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryAuthButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 62,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          elevation: 6,
          shadowColor: AppColors.teal.withValues(alpha: 0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AppEntryScreen extends StatelessWidget {
  const _AppEntryScreen();

  @override
  Widget build(BuildContext context) {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    const int artisanId = 1;

    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: const Text('Lmaalem'),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Bienvenue dans Lmaalem",
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 40),
              _buildMenuButton(
                context,
                "Laisser un Avis",
                Icons.star,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewScreen(
                      bookingId: 1,
                      artisanId: artisanId,
                      artisanName: "Ahmed le Plombier",
                      token: token,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                "Mon Dashboard",
                Icons.dashboard,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DashboardScreen(
                      artisanId: artisanId,
                      token: token,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                "Déposer une Réclamation",
                Icons.report_problem,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ComplaintScreen(
                      artisanId: artisanId,
                      token: token,
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
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon),
        label: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: onPressed,
      ),
    );
  }
}