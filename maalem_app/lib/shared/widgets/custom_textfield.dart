import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.label,
    required this.icon,
    this.hintText,
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: AppColors.navy),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}