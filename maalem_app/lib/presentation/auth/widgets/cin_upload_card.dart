import 'dart:typed_data';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';

class CinUploadCard extends StatelessWidget {
  final String label;
  final Uint8List? fileBytes;
  final String? fileName;
  final bool isPdf;
  final VoidCallback onTap;

  const CinUploadCard({
    super.key,
    required this.label,
    required this.onTap,
    this.fileBytes,
    this.fileName,
    this.isPdf = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileBytes != null;
    return GestureDetector(
      onTap: onTap,
      child: hasFile ? _buildFilled() : _buildEmpty(),
    );
  }

  Widget _buildFilled() {
    return Stack(
      children: [
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: isPdf ? _buildPdfPreview() : _buildImagePreview(),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.navy,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(
          fileBytes!,
          fit: BoxFit.cover,
          color: Colors.black.withValues(alpha: 0.34),
          colorBlendMode: BlendMode.darken,
        ),
        _buildSuccessContent(),
      ],
    );
  }

  Widget _buildPdfPreview() {
    return Container(
      color: Colors.green,
      child: _buildSuccessContent(icon: Icons.picture_as_pdf),
    );
  }

  Widget _buildSuccessContent({IconData icon = Icons.check}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.green, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            isPdf ? 'PDF ajoute' : 'Document ajoute',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (fileName != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                fileName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cliquez pour uploader',
              style: TextStyle(
                color: AppColors.navy.withValues(alpha: 0.62),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
