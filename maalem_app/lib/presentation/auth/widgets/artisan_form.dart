import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/presentation/auth/screens/register_screen.dart';
import 'package:maalem_app/shared/widgets/custom_button.dart';
import 'package:maalem_app/shared/widgets/custom_textfield.dart';

class ArtisanForm extends StatelessWidget {
  const ArtisanForm({super.key});

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
        CustomTextField(
          label: "Nom complet",
          hintText: "Ahmed Mansour",
          icon: Icons.person,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Téléphone",
          hintText: "+212 6XX XX XX XX",
          icon: Icons.call,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Email",
          hintText: "artisan@exemple.ma",
          icon: Icons.mail,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: "Mot de passe",
          hintText: "••••••••",
          icon: Icons.lock,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        // Zone Upload CIN
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.navy.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(20),
            color: AppColors.beige.withValues(alpha: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload, color: AppColors.teal, size: 40),
              Text(
                "Cliquez pour uploader la CIN",
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                "Recto / Verso",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CustomButton(
          text: "Devenir Artisan Maalem",
          onPressed: () => _navigateTo(context,  RegisterScreen()),
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