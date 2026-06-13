import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/presentation/auth/widgets/cin_upload_card.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class UploadCinScreen extends StatefulWidget {
  final Map<String, dynamic> registrationData;

  const UploadCinScreen({
    super.key,
    required this.registrationData,
  });

  @override
  State<UploadCinScreen> createState() => _UploadCinScreenState();
}

class _UploadCinScreenState extends State<UploadCinScreen> {
  XFile? _rectoFile;
  XFile? _versoFile;
  Uint8List? _rectoBytes;
  Uint8List? _versoBytes;
  String? _rectoName;
  String? _versoName;
  bool _rectoIsPdf = false;
  bool _versoIsPdf = false;
  bool _isLoading = false;

  Future<void> _pickFile(bool isRecto) async {
    final selected = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (selected == null) return;

    final bytes = await selected.readAsBytes();
    if (bytes.isEmpty) {
      _showSnackBar('Fichier illisible. Reessayez.', Colors.redAccent);
      return;
    }

    final validation = await _validateCinImage(bytes);
    if (!validation.isValid) {
      _showSnackBar(validation.message, Colors.redAccent);
      return;
    }

    final fileName = selected.name;

    if (!mounted) return;
    setState(() {
      if (isRecto) {
        _rectoFile = selected;
        _rectoBytes = bytes;
        _rectoName = fileName;
        _rectoIsPdf = false;
      } else {
        _versoFile = selected;
        _versoBytes = bytes;
        _versoName = fileName;
        _versoIsPdf = false;
      }
    });
  }

  Future<void> _handleUpload() async {
    if (_rectoFile == null || _versoFile == null) {
      _showSnackBar(
        'Les deux cotes de la CIN sont obligatoires',
        Colors.redAccent,
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result;
    try {
      final auth = context.read<AuthProvider>();
      result = await auth.registerArtisanWithCin(
        widget.registrationData,
        _rectoFile!,
        _versoFile!,
      );
    } catch (e) {
      result = {
        'success': false,
        'error': 'Erreur upload : $e',
      };
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    if (result['success'] == true) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Compte cree avec succes. Connectez-vous maintenant.'),
            backgroundColor: Colors.green,
          ),
        );
      return;
    }

    _showSnackBar(result['error'] ?? 'Erreur upload', Colors.redAccent);
  }

  Future<_CinValidationResult> _validateCinImage(Uint8List bytes) async {
    try {
      final image = await _decodeImage(bytes);
      final width = image.width;
      final height = image.height;
      image.dispose();

      final shortestSide = width < height ? width : height;
      final longestSide = width > height ? width : height;
      if (shortestSide < 180 || longestSide < 320) {
        return const _CinValidationResult(
          false,
          'Image trop petite. Choisissez une photo un peu plus nette de la CIN.',
        );
      }

      final ratio = width > height ? width / height : height / width;
      if (ratio < 1.15 || ratio > 2.25) {
        return const _CinValidationResult(
          false,
          'Image difficile a verifier. Essayez de cadrer la carte CIN de plus pres.',
        );
      }

      return const _CinValidationResult(true, '');
    } catch (_) {
      return const _CinValidationResult(
        false,
        'Impossible de verifier cette image. Reessayez avec une photo nette.',
      );
    }
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.beige,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Lmaalem',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                "Verification d'identite",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ajoutez le recto et le verso de votre CIN. Cadrez uniquement la carte, sans decor autour.',
                style: TextStyle(
                  color: AppColors.navy.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              CinUploadCard(
                label: 'Cote Recto',
                fileBytes: _rectoBytes,
                fileName: _rectoName,
                isPdf: _rectoIsPdf,
                onTap: () => _pickFile(true),
              ),
              const SizedBox(height: 20),
              CinUploadCard(
                label: 'Cote Verso',
                fileBytes: _versoBytes,
                fileName: _versoName,
                isPdf: _versoIsPdf,
                onTap: () => _pickFile(false),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          const Icon(Icons.info_outline, color: AppColors.teal),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Formats acceptes: JPG ou PNG. Les images doivent etre nettes et cadrees comme une carte CIN.',
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
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleUpload,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.arrow_forward, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Upload...' : 'Valider mon profil',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    disabledBackgroundColor:
                        AppColors.teal.withValues(alpha: 0.6),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _CinValidationResult {
  final bool isValid;
  final String message;

  const _CinValidationResult(this.isValid, this.message);
}
