import 'package:flutter/material.dart';
import '../data/models/artisan_model.dart';
import '../data/services/artisan_service.dart';

class SearchProvider with ChangeNotifier {
  // On crée une instance de notre service
  final ArtisanService _artisanService = ArtisanService();

  // Variables privées
  List<ArtisanModel> _artisans = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters pour accéder aux variables depuis les écrans (sans les modifier)
  List<ArtisanModel> get artisans => _artisans;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // LA MÉTHODE CLÉ : Charger les artisans
  Future<void> loadArtisans() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners(); // On prévient l'UI qu'on commence à charger (pour afficher un spinner)

    try {
      // On appelle le service qu'on a testé tout à l'heure
      _artisans = await _artisanService.fetchAllArtisans();
    } catch (e) {
      _errorMessage = "Erreur : Impossible de récupérer les artisans.";
    } finally {
      _isLoading = false;
      notifyListeners(); // On prévient l'UI que c'est fini (pour afficher la carte)
    }
  }
}
