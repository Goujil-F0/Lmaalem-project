import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/presentation/auth/screens/auth_screen.dart';
import 'package:provider/provider.dart';
import 'package:maalem_app/providers/auth_provider.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool isArtisan = false;

  // 1. Déclaration des contrôleurs pour récupérer le texte
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    // Très important : libérer la mémoire
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 2. Logique d'inscription
  void _handleRegister() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Validation basique
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Veuillez remplir les champs obligatoires");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar("Les mots de passe ne correspondent pas");
      return;
    }

    // Préparation des données pour le backend
    Map<String, dynamic> userData = {
      "full_name": _nameController.text,
      "email": _emailController.text,
      "password": _passwordController.text,
      "role": isArtisan ? "artisan" : "client",
      "phone": isArtisan ? _phoneController.text : null,
    };

    print("📦 DONNÉES À ENVOYER : $userData"); 

    // Appel au provider
    final result = await authProvider.register(userData);

    if (result['success']) {
      _showSnackBar("Inscription réussie ! Connectez-vous maintenant.");
      _openLogin();
    } else {
      _showSnackBar(result['error'] ?? "Une erreur est survenue");
    }
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _openLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const AuthScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final slideUp = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
          return SlideTransition(position: slideUp, child: child);
        },
      ),
    );
  }


@override
  Widget build(BuildContext context) {
    // On écoute le provider pour savoir si on doit afficher un loader
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.beige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              const SizedBox(height: 34),
              const _RegisterLogo(),
              const SizedBox(height: 18),
              Text(
                "Rejoignez la communauté Lmaalem",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.navy.withValues(alpha: 0.62),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 34),
              _RoleSwitcher(
                isArtisan: isArtisan,
                onChanged: (value) => setState(() => isArtisan = value),
              ),
              const SizedBox(height: 28),
              
              // --- CORRECTION : Liaison des contrôleurs ---
              _RegisterInput(
                controller: _nameController, 
                hintText: "Nom complet", 
                icon: Icons.person
              ),
              const SizedBox(height: 16),
              _RegisterInput(
                controller: _emailController, 
                hintText: "E-mail",
                icon: Icons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _RegisterInput(
                controller: _passwordController, 
                hintText: "Mot de passe",
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _RegisterInput(
                controller: _confirmPasswordController, 
                hintText: "Confirmer le mot de passe",
                icon: Icons.lock,
                isPassword: true,
              ),
              if (isArtisan) ...[
                const SizedBox(height: 16),
                _RegisterInput(
                  controller: _phoneController, 
                  hintText: "Téléphone",
                  icon: Icons.call,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                const _UploadCinBox(),
              ],
              const SizedBox(height: 34),
              
              // --- CORRECTION : Gestion du loader et appel de la fonction ---
              isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : _PrimaryRegisterButton(
                    text: isArtisan ? "Devenir Artisan Lmaalem" : "S'inscrire",
                    onPressed: _handleRegister, // <--- APPEL DE LA LOGIQUE ICI
                  ),
              
              const SizedBox(height: 44),
              TextButton(
                onPressed: _openLogin,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.navy.withValues(alpha: 0.72),
                      fontSize: 15,
                    ),
                    children: const [
                      TextSpan(text: "Vous avez déjà un compte ? "),
                      TextSpan(
                        text: "Se connecter",
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


class _RegisterLogo extends StatelessWidget {
  const _RegisterLogo();

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

class _RoleSwitcher extends StatelessWidget {
  final bool isArtisan;
  final ValueChanged<bool> onChanged;

  const _RoleSwitcher({required this.isArtisan, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _RoleOption(
            text: "Client",
            selected: !isArtisan,
            onTap: () => onChanged(false),
          ),
          const SizedBox(width: 8),
          _RoleOption(
            text: "Artisan",
            selected: isArtisan,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterInput extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextEditingController controller;

  const _RegisterInput({
    required this.hintText,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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

class _UploadCinBox extends StatelessWidget {
  const _UploadCinBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload,
              color: AppColors.navy.withValues(alpha: 0.72)),
          const SizedBox(height: 8),
          Text(
            "Upload CIN Recto / Verso",
            style: TextStyle(
              color: AppColors.navy.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryRegisterButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryRegisterButton({required this.text, required this.onPressed});

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
