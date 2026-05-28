import 'package:flutter/material.dart';
import '../data/models/artisan_model.dart';
import '../data/services/artisan_service.dart';

class SearchProvider with ChangeNotifier {
  final ArtisanService _artisanService = ArtisanService();

  List<ArtisanModel> _allArtisans = [];
  List<ArtisanModel> _filteredArtisans = [];
  List<String> _categories = [];
  List<String> _cities = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedCategory = '';
  String _selectedCity = '';
  String _searchQuery = '';
  bool? _availabilityFilter;

  List<ArtisanModel> get artisans => _filteredArtisans;
  List<String> get categories => _categories;
  List<String> get cities => _cities;
  List<String> get allSpecialties => _allSpecialties;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  String get selectedCategory => _selectedCategory;
  String get selectedCity => _selectedCity;
  String get searchQuery => _searchQuery;
  bool? get availabilityFilter => _availabilityFilter;
  int get availableCount =>
      _allArtisans.where((artisan) => artisan.isAvailable).length;
  int get unavailableCount =>
      _allArtisans.where((artisan) => !artisan.isAvailable).length;

  Future<void> loadArtisans() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final results = await _artisanService.fetchAllArtisans();
      _allArtisans = results;
      _extractCategories();
      _extractCities();
      _applyFilters(notify: false);
    } catch (e) {
      _errorMessage =
          'Impossible de recuperer les artisans. Verifiez votre connexion.';
      debugPrint('[SearchProvider] Erreur: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterArtisans(String query, {String? category, String? city, bool? availableOnly}) {
    _searchQuery = query;
    _selectedCategory = category ?? _selectedCategory;
    _selectedCity = city ?? _selectedCity;
    _availabilityFilter = availableOnly ?? _availabilityFilter;
    _applyFilters();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void filterByCity(String city) {
    _selectedCity = city;
    _applyFilters();
  }

  void filterByAvailability(bool? availableOnly) {
    _availabilityFilter = availableOnly;
    _applyFilters();
  }

  void resetFilters() {
    _selectedCategory = '';
    _selectedCity = '';
    _searchQuery = '';
    _availabilityFilter = null;
    _filteredArtisans = _allArtisans;
    notifyListeners();
  }

  void _extractCategories() {
    final byNormalizedName = <String, String>{};
    for (final artisan in _allArtisans) {
      if (artisan.speciality.isNotEmpty) {
        final normalized = _normalize(artisan.speciality);
        if (normalized.isNotEmpty && normalized != 'artisan general') {
          byNormalizedName.putIfAbsent(
            normalized,
            () => _prettySpecialtyName(artisan.speciality),
          );
        }
      }
    }
    _categories = byNormalizedName.values.toList()..sort();
  }

  void _extractCities() {
    final citiesSet = <String>{};
    for (final artisan in _allArtisans) {
      if (artisan.city.isNotEmpty) {
        citiesSet.add(artisan.city);
      }
    }
    _cities = citiesSet.toList()..sort();
  }

  void _applyFilters({bool notify = true}) {
    final normalizedQuery = _normalize(_searchQuery);
    final intent = _detectProblemIntent(normalizedQuery);

    _filteredArtisans = _allArtisans.where((artisan) {
      final artisanSpeciality = _normalize(artisan.speciality);
      final searchableText = _normalize([
        artisan.fullName,
        artisan.speciality,
        artisan.city,
        artisan.phone,
        artisan.bio ?? '',
      ].join(' '));

      final matchesSearch = normalizedQuery.isEmpty ||
          searchableText.contains(normalizedQuery) ||
          (intent.category.isNotEmpty &&
              artisanSpeciality.contains(intent.category));

      final selectedCategory = _normalize(_selectedCategory);
      final matchesCategory = selectedCategory.isEmpty ||
          artisanSpeciality == selectedCategory ||
          artisanSpeciality.contains(selectedCategory) ||
          selectedCategory.contains(artisanSpeciality);

      final matchesCity = _selectedCity.isEmpty || artisan.city == _selectedCity;

      final matchesAvailability = _availabilityFilter == null ||
          artisan.isAvailable == _availabilityFilter;

      return matchesSearch && matchesCategory && matchesCity && matchesAvailability;
    }).toList();

    if (notify) notifyListeners();
  }

  _ProblemIntent _detectProblemIntent(String query) {
    if (query.trim().length < 3) return const _ProblemIntent.empty();

    final scores = <String, int>{};
    for (final rule in _intentRules) {
      var score = 0;

      for (final jobName in rule.jobNames) {
        if (query.contains(jobName)) score += 7;
      }

      for (final phrase in rule.phrases) {
        if (query.contains(phrase)) score += 6;
      }

      for (final symptom in rule.symptoms) {
        if (query.contains(symptom)) score += 3;
      }

      for (final object in rule.objects) {
        if (query.contains(object)) score += 2;
      }

      if (score > 0) scores[rule.category] = score;
    }

    if (scores.isEmpty) return const _ProblemIntent.empty();

    final best = scores.entries.reduce(
      (current, next) => next.value > current.value ? next : current,
    );

    if (best.value < 4) return const _ProblemIntent.empty();
    return _ProblemIntent(best.key, best.value);
  }

  String _normalize(String value) {
    var output = value.toLowerCase();
    const accents = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'î': 'i',
      'ï': 'i',
      'ô': 'o',
      'ö': 'o',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'Ã ': 'a',
      'Ã¡': 'a',
      'Ã¢': 'a',
      'Ã¤': 'a',
      'Ã§': 'c',
      'Ã¨': 'e',
      'Ã©': 'e',
      'Ãª': 'e',
      'Ã«': 'e',
      'Ã®': 'i',
      'Ã¯': 'i',
      'Ã´': 'o',
      'Ã¶': 'o',
      'Ã¹': 'u',
      'Ã»': 'u',
      'Ã¼': 'u',
    };

    accents.forEach((accent, plain) {
      output = output.replaceAll(accent, plain);
    });

    return output.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').replaceAll(
          RegExp(r'\s+'),
          ' ',
        ).trim();
  }

  String _prettySpecialtyName(String value) {
    final normalized = _normalize(value);
    return _specialtyLabels[normalized] ?? value.trim();
  }
}

const _allSpecialties = [
  'Plomberie',
  'Electricite',
  'Maconnerie',
  'Platrerie / Staff',
  'Etancheite',
  'Isolation thermique & phonique',
  'Demolition',
  'Renovation generale',
  'Climatisation',
  'Domotique',
  'Reparation electromenager',
  'Installation TV / Satellite',
  'Panneaux solaires',
  'Peinture',
  'Carrelage',
  'Menuiserie',
  'Serrurerie',
  'Jardinage',
  'Nettoyage',
];

const _specialtyLabels = {
  'plomberie': 'Plomberie',
  'electricite': 'Electricite',
  'maconnerie': 'Maconnerie',
  'platrerie staff': 'Platrerie / Staff',
  'etancheite': 'Etancheite',
  'isolation thermique phonique': 'Isolation thermique & phonique',
  'demolition': 'Demolition',
  'renovation generale': 'Renovation generale',
  'climatisation': 'Climatisation',
  'domotique': 'Domotique',
  'reparation electromenager': 'Reparation electromenager',
  'installation tv satellite': 'Installation TV / Satellite',
  'panneaux solaires': 'Panneaux solaires',
  'peinture': 'Peinture',
  'carrelage': 'Carrelage',
  'menuiserie': 'Menuiserie',
  'serrurerie': 'Serrurerie',
  'jardinage': 'Jardinage',
  'nettoyage': 'Nettoyage',
};

class _ProblemIntent {
  final String category;
  final int score;

  const _ProblemIntent(this.category, this.score);
  const _ProblemIntent.empty()
      : category = '',
        score = 0;
}

class _IntentRule {
  final String category;
  final List<String> jobNames;
  final List<String> phrases;
  final List<String> symptoms;
  final List<String> objects;

  const _IntentRule({
    required this.category,
    required this.jobNames,
    required this.phrases,
    required this.symptoms,
    required this.objects,
  });
}

const _intentRules = [
  _IntentRule(
    category: 'plomberie',
    jobNames: ['plombier', 'plomberie', 'sanitaire'],
    phrases: [
      'pas d eau',
      'plus d eau',
      'fuite d eau',
      'eau qui coule',
      'robinet fuit',
      'wc bouche',
      'evier bouche',
      'lavabo bouche',
      'chauffe eau',
      'canalisation bouchee',
      'tuyau casse',
      'lma kayn mochkil',
    ],
    symptoms: [
      'fuite',
      'coule',
      'bouche',
      'deborde',
      'goutte',
      'inondation',
      'pression',
      'humide',
      'odeur',
    ],
    objects: [
      'eau',
      'lma',
      'robinet',
      'evier',
      'lavabo',
      'wc',
      'toilette',
      'douche',
      'baignoire',
      'tuyau',
      'canalisation',
      'siphon',
      'chauffe eau',
    ],
  ),
  _IntentRule(
    category: 'electricite',
    jobNames: ['electricien', 'electricite'],
    phrases: [
      'pas de courant',
      'plus de courant',
      'prise brule',
      'prise ne marche pas',
      'disjoncteur saute',
      'compteur saute',
      'court circuit',
      'lumiere clignote',
      'ma kaynch do',
      'ma kaynch daw',
    ],
    symptoms: [
      'courant',
      'saute',
      'brule',
      'etincelle',
      'clignote',
      'panne',
      'eteint',
      'allume',
      'daw',
      'do',
    ],
    objects: [
      'prise',
      'interrupteur',
      'lampe',
      'lumiere',
      'cable',
      'fil',
      'tableau',
      'disjoncteur',
      'compteur',
    ],
  ),
  _IntentRule(
    category: 'serrurerie',
    jobNames: ['serrurier', 'serrurerie'],
    phrases: [
      'porte bloquee',
      'cle cassee',
      'cle perdue',
      'porte ne ferme pas',
      'porte ne s ouvre pas',
      'changer serrure',
    ],
    symptoms: ['bloque', 'casse', 'perdu', 'coince', 'ferme pas', 'ouvre pas'],
    objects: ['serrure', 'cle', 'porte', 'verrou', 'cylindre'],
  ),
  _IntentRule(
    category: 'climatisation',
    jobNames: ['climatisation', 'climatiseur', 'technicien clim'],
    phrases: [
      'clim ne refroidit pas',
      'clim coule',
      'clim fait du bruit',
      'installer clim',
      'entretien clim',
    ],
    symptoms: ['froid', 'chaud', 'bruit', 'coule', 'refroidit', 'chauffe'],
    objects: ['clim', 'climatiseur', 'air conditionne', 'split', 'ventilation'],
  ),
  _IntentRule(
    category: 'menuiserie',
    jobNames: ['menuisier', 'menuiserie', 'bois'],
    phrases: [
      'porte cassee',
      'fenetre cassee',
      'placard casse',
      'meuble casse',
      'installer cuisine',
    ],
    symptoms: ['casse', 'coince', 'grince', 'reparer', 'monter', 'installer'],
    objects: ['bois', 'porte', 'fenetre', 'placard', 'meuble', 'cuisine'],
  ),
  _IntentRule(
    category: 'peinture',
    jobNames: ['peintre', 'peinture'],
    phrases: ['repeindre mur', 'peinture mur', 'peinture plafond'],
    symptoms: ['repeindre', 'tache', 'ecaille', 'couleur', 'peindre'],
    objects: ['mur', 'plafond', 'facade', 'chambre', 'salon'],
  ),
  _IntentRule(
    category: 'carrelage',
    jobNames: ['carreleur', 'carrelage'],
    phrases: ['carrelage casse', 'poser carrelage', 'joint carrelage'],
    symptoms: ['casse', 'fissure', 'poser', 'joint', 'remplacer'],
    objects: ['carrelage', 'carreau', 'sol', 'faience'],
  ),
  _IntentRule(
    category: 'maconnerie',
    jobNames: ['macon', 'maconnerie'],
    phrases: ['mur fissure', 'construire mur', 'casser mur'],
    symptoms: ['fissure', 'construire', 'casser', 'beton', 'ciment'],
    objects: ['mur', 'brique', 'beton', 'ciment', 'dalle'],
  ),
  _IntentRule(
    category: 'nettoyage',
    jobNames: ['nettoyage', 'menage'],
    phrases: ['nettoyage maison', 'menage complet', 'apres travaux'],
    symptoms: ['sale', 'nettoyer', 'laver', 'poussiere', 'tache'],
    objects: ['maison', 'appartement', 'bureau', 'vitre', 'sol'],
  ),
  _IntentRule(
    category: 'jardinage',
    jobNames: ['jardinier', 'jardinage'],
    phrases: ['couper herbe', 'tailler arbre', 'arroser jardin'],
    symptoms: ['couper', 'tailler', 'planter', 'arroser', 'entretenir'],
    objects: ['jardin', 'herbe', 'arbre', 'plante', 'gazon'],
  ),
];
