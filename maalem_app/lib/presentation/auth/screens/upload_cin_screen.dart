import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:maalem_app/presentation/auth/widgets/cin_upload_card.dart';


class UploadCinScreen extends StatefulWidget {
  const UploadCinScreen({super.key});

  @override
  State<UploadCinScreen> createState() => _UploadCinScreenState();
}

class _UploadCinScreenState extends State<UploadCinScreen> {
  // Fichiers pour le recto et le verso
  XFile? _rectoFile;
  XFile? _versoFile;
  bool _isLoading = false;

  // FONCTION PRINCIPALE : Sélection de l'image (Galerie ou Scanner)
  Future<void> _pickImage(bool isRecto) async {
    // 1. Affichage du menu de choix (Bottom Sheet)
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.teal),
            title: const Text("Scanner la CIN (Caméra)"),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppColors.teal),
            title: const Text("Choisir dans la galerie"),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    if (source == null) return;
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source, // galerie ou caméra directement
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        if (isRecto) {
          _rectoFile = picked;
        } else {
          _versoFile = picked;
        }
      });
    }
      
  }

  // FONCTION D'ENVOI AU SERVEUR
  Future<void> _handleUpload() async {
    // 1. Validation : Les deux fichiers sont-ils présents ?
    if (_rectoFile == null || _versoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le recto et le verso de la CIN sont obligatoires'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Accès au provider sans écouter (listen: false)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Appel du service d'upload
      final result = await authProvider.uploadCin(
        _rectoFile!, 
        _versoFile!,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CIN uploadée avec succès ! Votre profil est en cours de vérification.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Redirection vers la Map ou le Profil après succès
        // Navigator.pushReplacementNamed(context, '/map'); 
      } else {
        _showError(result['error'] ?? 'Une erreur est survenue lors de l\'upload');
      }
    } catch (e) {
      _showError("Erreur critique : $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
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
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
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

              // Carte Recto
              CinUploadCard(
                label: "Côté Recto",
                imageFile: _rectoFile,
                onTap: () => _pickImage(true),
              ),
              const SizedBox(height: 20),

              // Carte Verso
              CinUploadCard(
                label: "Côté Verso",
                imageFile: _versoFile,
                onTap: () => _pickImage(false),
              ),
              const SizedBox(height: 24),

              // Box de conseils (Tips)
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

              // Bouton de validation final
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
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