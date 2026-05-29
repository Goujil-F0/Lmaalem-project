import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/presentation/auth/screens/register_screen.dart';
import 'package:maalem_app/shared/widgets/custom_button.dart';
import 'package:maalem_app/shared/widgets/custom_textfield.dart';

class ClientForm extends StatelessWidget {
  const ClientForm({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          final slideUp = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return SlideTransition(position: slideUp, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CustomTextField(
          label: "Nom complet",
          hintText: "Ahmed Mansour",
          icon: Icons.person,
        ),
        const SizedBox(height: 16),
        const CustomTextField(
          label: "Email",
          hintText: "ahmed@exemple.ma",
          icon: Icons.mail,
        ),
        const SizedBox(height: 16),
        const CustomTextField(
          label: "Mot de passe",
          hintText: "••••••••",
          icon: Icons.lock,
          isPassword: true,
        ),
        const SizedBox(height: 20),
        CustomButton(
          text: "S'inscrire en tant que Client",
          onPressed: () => _navigateTo(context,  const RegisterScreen()),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: AppColors.navy.withValues(alpha: 0.6)),
              children: const [
                TextSpan(text: "Déjà un compte ? "),
                TextSpan(
                  text: "Se connecter",
                  style: TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}