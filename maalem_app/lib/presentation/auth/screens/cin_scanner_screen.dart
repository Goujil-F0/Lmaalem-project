import 'package:flutter/material.dart';
// `camera` package may not be available in all environments (analysis server, tests, etc.).
// This file provides a graceful fallback when the camera package isn't present.

class CinScannerScreen extends StatefulWidget {
  final bool isRecto; // Pour savoir si on scanne le recto ou le verso

  const CinScannerScreen({super.key, required this.isRecto});

  @override
  State<CinScannerScreen> createState() => _CinScannerScreenState();
}

class _CinScannerScreenState extends State<CinScannerScreen> {
  // Camera functionality disabled when the camera package is not available.
  // Keep a flag to show a placeholder UI instead of a live preview.
  bool _cameraAvailable = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Attempt to initialize camera if package is available.
    // In this fallback build we don't initialize camera; keep _cameraAvailable=false.
  }

  @override
  void dispose() {
    // nothing to dispose when camera package isn't used
    super.dispose();
  }

  Future<void> _takePicture() async {
    // Camera not available: just close and return null
    Navigator.pop(context, null);
  }

  @override
  Widget build(BuildContext context) {
    // Show placeholder when camera not available

    return Scaffold(
      body: Stack(
        children: [
          // 1. Placeholder (camera preview not available)
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Container(
              color: Colors.black87,
              child: const Center(
                child: Icon(Icons.videocam_off, color: Colors.white, size: 48),
              ),
            ),
          ),

          // 2. L'OVERLAY (Le cadre de scan)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.7), BlendMode.srcOut),
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
                const Text(
                  "Alignez la CIN dans le cadre",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
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
                    child: const Icon(Icons.camera_alt,
                        size: 40, color: Colors.black),
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
