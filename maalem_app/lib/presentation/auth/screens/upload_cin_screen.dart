import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/presentation/auth/widgets/cin_upload_card.dart';
import 'package:provider/provider.dart';
import 'package:maalem_app/providers/auth_provider.dart';

class UploadCinScreen extends StatefulWidget {
  const UploadCinScreen({super.key});

  @override
  State<UploadCinScreen> createState() => _UploadCinScreenState();
}

class _UploadCinScreenState extends State<UploadCinScreen> {
  XFile? _rectoFile;
  XFile? _versoFile;
  Uint8List? _rectoBytes;
  Uint8List? _versoBytes;
  bool _isLoading = false;

  Future<void> _pickImage(bool isRecto) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        if (isRecto) {
          _rectoFile = picked;
          _rectoBytes = bytes;
        } else {
          _versoFile = picked;
          _versoBytes = bytes;
        }
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_rectoFile == null || _versoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les deux côtés de la CIN sont obligatoires'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.uploadCin(_rectoFile!, _versoFile!);

    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CIN uploadée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Erreur'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Maalem",
          style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                "Vérification d'Identité",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Pour garantir la sécurité de la plateforme, veuillez uploader votre CIN",
                style: TextStyle(
                  color: AppColors.navy.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Recto
              CinUploadCard(
                label: "Côté Recto",
                imageBytes: _rectoBytes,
                onTap: () => _pickImage(true),
              ),
              const SizedBox(height: 20),

              // Verso
              CinUploadCard(
                label: "Côté Verso",
                imageBytes: _versoBytes,
                onTap: () => _pickImage(false),
              ),
              const SizedBox(height: 24),

              // Tips box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.navy.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lightbulb,
                        color: AppColors.teal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Tips: Assurez-vous que la photo est nette et que les 4 coins de la carte sont visibles.",
                        style: TextStyle(
                          color: AppColors.navy.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _isLoading
                  ? const CircularProgressIndicator(color: AppColors.teal)
                  : SizedBox(
                      width: double.infinity,
                      height: 62,
                      child: ElevatedButton.icon(
                        onPressed: _handleUpload,
                        icon: const Icon(Icons.arrow_forward, color: Colors.white),
                        label: const Text(
                          "Valider mon Profil",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
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
}