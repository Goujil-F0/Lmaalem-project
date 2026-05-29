import 'package:flutter/material.dart';
import '../data/models/artisan_model.dart';
import '../data/services/artisan_service.dart';

class SearchProvider with ChangeNotifier {
  final ArtisanService _artisanService = ArtisanService();

  List<ArtisanModel> _allArtisans = [];
  List<ArtisanModel> _filteredArtisans = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedCategory = '';
  String _searchQuery = '';

  List<ArtisanModel> get artisans => _filteredArtisans;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

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
      _extractCategories();
    } catch (e) {
      _errorMessage =
          'Impossible de récupérer les artisans. Vérifiez votre connexion.';
      debugPrint('[SearchProvider] Erreur: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Extrait toutes les catégories uniques
  void _extractCategories() {
    final categoriesSet = <String>{};
    for (var artisan in _allArtisans) {
      if (artisan.speciality.isNotEmpty) {
        categoriesSet.add(artisan.speciality);
      }
    }
    _categories = categoriesSet.toList()..sort();
  }

  /// Filtre par nom, spécialité ET disponibilité
  void filterArtisans(String query, {String? category, bool? availableOnly}) {
    _searchQuery = query;
    _selectedCategory = category ?? _selectedCategory;

    _filteredArtisans = _allArtisans.where((artisan) {
      // Filtre par nom
      final matchesName = query.isEmpty ||
          artisan.fullName.toLowerCase().contains(query.toLowerCase()) ||
          artisan.speciality.toLowerCase().contains(query.toLowerCase());

      // Filtre par catégorie
      final matchesCategory = _selectedCategory.isEmpty ||
          artisan.speciality.toLowerCase() == _selectedCategory.toLowerCase();

      // Filtre par disponibilité
      final matchesAvailability =
          availableOnly == null || artisan.isAvailable == availableOnly;

      return matchesName && matchesCategory && matchesAvailability;
    }).toList();

    notifyListeners();
  }

  /// Filtre uniquement par catégorie
  void filterByCategory(String category) {
    _selectedCategory = category;
    filterArtisans(_searchQuery, category: category);
  }

  /// Réinitialise les filtres
  void resetFilters() {
    _filteredArtisans = _allArtisans;
    _selectedCategory = '';
    _searchQuery = '';
    notifyListeners();
  }
}
