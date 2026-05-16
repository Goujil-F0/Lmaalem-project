import 'dart:typed_data';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';

class CinUploadCard extends StatelessWidget {
  final String label;
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const CinUploadCard({
    super.key,
    required this.label,
    required this.onTap,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageBytes != null;
    return GestureDetector(
      onTap: onTap,
      child: hasImage ? _buildSuccess() : _buildEmpty(),
    );
  }

  Widget _buildSuccess() {
    return Stack(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.memory(
                    imageBytes!,
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.3),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Document ajouté ✓",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.navy,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(24),
      color: AppColors.teal,
      strokeWidth: 2,
      dashPattern: const [8, 8],
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload, color: AppColors.teal, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Cliquez pour uploader",
              style: TextStyle(
                color: AppColors.navy.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}