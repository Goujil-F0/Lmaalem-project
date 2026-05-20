import 'package:flutter/material.dart';
import '../data/models/artisan_model.dart';
import '../data/services/artisan_service.dart';

class SearchProvider with ChangeNotifier {
  final ArtisanService _artisanService = ArtisanService();

  List<ArtisanModel> _allArtisans = [];
  List<ArtisanModel> _filteredArtisans = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<ArtisanModel> get artisans => _filteredArtisans;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  Future<void> loadArtisans() async {
    // Guard : évite un double-appel pendant le chargement
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final results = await _artisanService.fetchAllArtisans();
      _allArtisans = results;
      _filteredArtisans = results;
    } catch (e) {
      _errorMessage =
          'Impossible de récupérer les artisans. Vérifiez votre connexion.';
      debugPrint('[SearchProvider] Erreur: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filtre par nom ET par disponibilité (extensible : spécialité, ville…)
  void filterArtisans(String query, {bool? availableOnly}) {
    _filteredArtisans = _allArtisans.where((artisan) {
      final matchesName =
          query.isEmpty ||
          artisan.fullName.toLowerCase().contains(query.toLowerCase());

      final matchesAvailability =
          availableOnly == null || artisan.isAvailable == availableOnly;

      return matchesName && matchesAvailability;
    }).toList();

    notifyListeners();
  }

  void resetFilters() {
    _filteredArtisans = _allArtisans;
    notifyListeners();
  }
}
