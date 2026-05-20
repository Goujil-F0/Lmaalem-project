import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class CinScannerScreen extends StatefulWidget {
  final bool isRecto; // Pour savoir si on scanne le recto ou le verso

  const CinScannerScreen({super.key, required this.isRecto});

  @override
  State<CinScannerScreen> createState() => _CinScannerScreenState();
}

class _CinScannerScreenState extends State<CinScannerScreen> {
  CameraController? _controller;
  // Liste des caméras disponibles
  List<CameraDescription>? cameras;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    cameras = await availableCameras();
    if (cameras != null && cameras!.isNotEmpty) {
      _controller = CameraController(
        cameras![0], // Utilise la caméra arrière
        ResolutionPreset.high,
      );
      await _controller!.initialize();
      setState(() {}); // Rafraîchit l'écran pour afficher la preview
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      // On retourne l'image capturée à l'écran précédent
      Navigator.pop(context, File(image.path));
    } catch (e) {
      print("Erreur capture: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Le flux vidéo en direct
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_controller!),
          ),

          // 2. L'OVERLAY (Le cadre de scan)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7), 
              BlendMode.srcOut
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
                Center(
                  child: Container(
                    width: 300,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Instructions et Bouton
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Alignez la CIN dans le cadre",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, size: 40, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}