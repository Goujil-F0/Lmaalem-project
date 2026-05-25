import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:maalem_app/presentation/auth/screens/register_screen.dart';
import 'package:maalem_app/presentation/dashboard/screens/review_screen.dart';
import 'package:maalem_app/presentation/dashboard/screens/dashboard_screen.dart';
import 'package:maalem_app/presentation/dashboard/screens/complaint_screen.dart';

class AuthScreen extends StatefulWidget {
  // CHANGÉ : StatefulWidget
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // 1. AJOUT : Contrôleurs pour récupérer le texte
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openRegister() {
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
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return SlideTransition(position: slideUp, child: child);
        },
      ),
    );
  }

  // 2. LOGIQUE DE CONNEXION
  void _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Veuillez remplir tous les champs"),
            backgroundColor: Colors.red),
      );
      return;
    }

    bool success = await authProvider.login(
        _emailController.text, _passwordController.text);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Email ou mot de passe incorrect"),
            backgroundColor: Colors.red),
      );
    }
    // Note: Si success est true, le main.dart redirigera automatiquement vers la Map !
  }

  @override
  Widget build(BuildContext context) {
    // On écoute l'état de chargement pour afficher un loader sur le bouton
    final isLoading = context.watch<AuthProvider>().isLoading;

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

              // MODIFICATION : Utilisation du controller
              _AuthInput(
                controller: _emailController, // AJOUTÉ
                hintText: "E-mail",
                icon: Icons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              _AuthInput(
                controller: _passwordController, // AJOUTÉ
                hintText: "Mot de passe",
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 36),

              // MODIFICATION : Loader sur le bouton
              isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.teal))
                  : _PrimaryAuthButton(
                      text: "Se connecter",
                      onPressed: _handleLogin, // APPEL DE LA LOGIQUE
                    ),

              const SizedBox(height: 80),
              TextButton(
                onPressed: _openRegister,
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

// --- MODIFICATION DU WIDGET INPUT POUR ACCEPTER LE CONTROLLER ---
class _AuthInput extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextEditingController controller; // AJOUTÉ

  const _AuthInput({
    required this.hintText,
    required this.icon,
    required this.controller, // AJOUTÉ
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // LIÉ ICI
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

// Garde le reste des widgets (_AuthLogo, _PrimaryAuthButton, etc.) tel quel...

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
    // Données temporaires en attendant l'intégration avec la recherche et les réservations.
    const int demoArtisanId = 1;
    const int demoBookingId = 1;
    const String demoArtisanName = "Ahmed le Plombier";

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
                    builder: (context) => const ReviewScreen(
                      bookingId: demoBookingId,
                      artisanId: demoArtisanId,
                      artisanName: demoArtisanName,
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
                    builder: (context) => const DashboardScreen(
                      artisanId: demoArtisanId,
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
                    builder: (context) => const ComplaintScreen(
                      bookingId: demoBookingId,
                      artisanId: demoArtisanId,
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
