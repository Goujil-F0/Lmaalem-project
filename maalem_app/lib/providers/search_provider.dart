import 'dart:math' as math;

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
  String _detectedCategory = '';
  bool? _availabilityFilter;
  double _maxDistanceKm = 15;
  double _minRating = 0;

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
  String get detectedCategory => _detectedCategory;
  String get detectedCategoryLabel => _detectedCategory.isEmpty
      ? ''
      : (_specialtyLabels[_detectedCategory] ?? _detectedCategory);
  bool? get availabilityFilter => _availabilityFilter;
  double get maxDistanceKm => _maxDistanceKm;
  double get minRating => _minRating;
  int get resultCount => _filteredArtisans.length;
  bool get hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedCategory.isNotEmpty ||
      _selectedCity.isNotEmpty ||
      _availabilityFilter != null;
  int get availableCount =>
      _filteredArtisans.where((artisan) => artisan.isAvailable).length;
  int get unavailableCount =>
      _filteredArtisans.where((artisan) => !artisan.isAvailable).length;

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

  void filterArtisans(
    String query, {
    String? category,
    String? city,
    bool? availableOnly,
  }) {
    _searchQuery = query;
    if (category != null) _selectedCategory = category;
    if (city != null) _selectedCity = city;
    if (availableOnly != null) _availabilityFilter = availableOnly;
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

  void setMaxDistanceKm(double value) {
    final nextValue = value.clamp(1, 80).toDouble();
    if ((_maxDistanceKm - nextValue).abs() < 0.1) return;
    _maxDistanceKm = nextValue;
    notifyListeners();
  }

  void filterByMinRating(double value) {
    final nextValue = value.clamp(0, 5).toDouble();
    if ((_minRating - nextValue).abs() < 0.1) return;
    _minRating = nextValue;
    _applyFilters();
  }

  void resetFilters() {
    _selectedCategory = '';
    _selectedCity = '';
    _searchQuery = '';
    _detectedCategory = '';
    _availabilityFilter = null;
    _minRating = 0;
    _filteredArtisans = List.of(_allArtisans);
    _sortArtisans(_filteredArtisans, const {});
    notifyListeners();
  }

  List<ArtisanModel> artisansForLocation(double? latitude, double? longitude) {
    if (latitude == null ||
        longitude == null ||
        (latitude == 0 && longitude == 0)) {
      return _filteredArtisans;
    }

    final result = _filteredArtisans.where((artisan) {
      final distance = distanceToArtisan(artisan, latitude, longitude);
      return distance == null || distance <= _maxDistanceKm;
    }).toList();

    if (result.isEmpty) return _filteredArtisans;

    result.sort((a, b) {
      final distanceA = distanceToArtisan(a, latitude, longitude) ?? 9999;
      final distanceB = distanceToArtisan(b, latitude, longitude) ?? 9999;
      final availableCompare = (b.isAvailable ? 1 : 0).compareTo(
        a.isAvailable ? 1 : 0,
      );
      if (availableCompare != 0) return availableCompare;
      return distanceA.compareTo(distanceB);
    });

    return result;
  }

  int countForLocation(double? latitude, double? longitude) {
    return artisansForLocation(latitude, longitude).length;
  }

  double? distanceToArtisan(
    ArtisanModel artisan,
    double latitude,
    double longitude,
  ) {
    if (artisan.latitude == 0 || artisan.longitude == 0) return null;
    return _distanceKm(
      latitude,
      longitude,
      artisan.latitude,
      artisan.longitude,
    );
  }

  String distanceLabel(
    ArtisanModel artisan,
    double? latitude,
    double? longitude,
  ) {
    if (latitude == null || longitude == null) return 'Distance inconnue';
    final distance = distanceToArtisan(artisan, latitude, longitude);
    if (distance == null) return 'Position approximative';
    if (distance < 1) return '${(distance * 1000).round()} m';
    return '${distance.toStringAsFixed(distance < 10 ? 1 : 0)} km';
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
    final byNormalizedName = <String, String>{};

    // Ajouter d'abord les villes statiques marocaines
    for (final city in _moroccanCities) {
      byNormalizedName.putIfAbsent(
        _normalize(city),
        () => city,
      );
    }

    // Ajouter ensuite les villes des artisans existants
    for (final artisan in _allArtisans) {
      if (artisan.city.isNotEmpty) {
        byNormalizedName.putIfAbsent(
          _normalize(artisan.city),
          () => artisan.city.trim(),
        );
      }
    }
    _cities = byNormalizedName.values.toList()..sort();
  }

  void _applyFilters({bool notify = true}) {
    final normalizedQuery = _normalize(_searchQuery);
    final queryTokens = _tokens(normalizedQuery);
    final intent = _detectProblemIntent(normalizedQuery);
    _detectedCategory = intent.category;

    final selectedCategory = _normalize(_selectedCategory);
    final selectedCity = _normalize(_selectedCity);
    final scores = <int, int>{};

    _filteredArtisans = _allArtisans.where((artisan) {
      final artisanSpeciality = _normalize(artisan.speciality);
      final artisanCity = _normalize(artisan.city);

      final matchesCategory = selectedCategory.isEmpty ||
          artisanSpeciality == selectedCategory ||
          artisanSpeciality.contains(selectedCategory) ||
          selectedCategory.contains(artisanSpeciality);

      final matchesCity = selectedCity.isEmpty || artisanCity == selectedCity;

      final matchesAvailability = _availabilityFilter == null ||
          artisan.isAvailable == _availabilityFilter;

      final artisanRating = artisan.averageRating ?? artisan.rating ?? 0;
      final matchesRating = artisanRating >= _minRating;

      if (!matchesCategory ||
          !matchesCity ||
          !matchesAvailability ||
          !matchesRating) {
        return false;
      }

      final score = _scoreArtisan(
        artisan: artisan,
        normalizedQuery: normalizedQuery,
        queryTokens: queryTokens,
        intent: intent,
      );
      scores[artisan.id] = score;

      return normalizedQuery.isEmpty || score >= 18;
    }).toList();

    _sortArtisans(_filteredArtisans, scores);
    if (notify) notifyListeners();
  }

  int _scoreArtisan({
    required ArtisanModel artisan,
    required String normalizedQuery,
    required List<String> queryTokens,
    required _ProblemIntent intent,
  }) {
    if (normalizedQuery.isEmpty) return _qualityScore(artisan);

    final fullName = _normalize(artisan.fullName);
    final speciality = _normalize(artisan.speciality);
    final city = _normalize(artisan.city);
    final phone = _normalize(artisan.phone);
    final bio = _normalize(artisan.bio ?? '');
    final searchableText = [
      fullName,
      speciality,
      city,
      phone,
      bio,
    ].where((value) => value.isNotEmpty).join(' ');

    var score = 0;

    if (fullName.contains(normalizedQuery)) score += 95;
    if (speciality.contains(normalizedQuery)) score += 88;
    if (city.contains(normalizedQuery)) score += 70;
    if (phone.contains(normalizedQuery)) score += 65;
    if (bio.contains(normalizedQuery)) score += 35;
    if (searchableText.contains(normalizedQuery)) score += 30;

    for (final token in queryTokens) {
      if (fullName.split(' ').contains(token)) score += 18;
      if (speciality.contains(token)) score += 16;
      if (city.contains(token)) score += 12;
      if (phone.contains(token)) score += 10;
      if (bio.contains(token)) score += 6;
      if (_hasNearToken(token, searchableText)) score += 7;
    }

    if (queryTokens.length > 1 &&
        queryTokens.every((token) => searchableText.contains(token))) {
      score += 24;
    }

    if (intent.category.isNotEmpty) {
      final matchesIntent = speciality.contains(intent.category) ||
          intent.category.contains(speciality);
      if (matchesIntent) score += 90 + intent.score;
    }

    if (artisan.isAvailable) score += 10;
    score += _qualityScore(artisan);
    return score;
  }

  int _qualityScore(ArtisanModel artisan) {
    final rating = artisan.averageRating ?? artisan.rating ?? 0;
    final reviews = artisan.reviewCount ?? 0;
    var score = 0;
    score += (rating * 6).round();
    score += math.min(reviews, 20);
    if (artisan.profileImage?.trim().isNotEmpty == true) score += 4;
    if (artisan.bio?.trim().isNotEmpty == true) score += 4;
    if (artisan.hourlyRate != null && artisan.hourlyRate! > 0) score += 3;
    if (artisan.isAvailable) score += 6;
    return score;
  }

  void _sortArtisans(List<ArtisanModel> artisans, Map<int, int> scores) {
    artisans.sort((a, b) {
      final scoreCompare = (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0);
      if (scoreCompare != 0) return scoreCompare;

      final availableCompare = (b.isAvailable ? 1 : 0).compareTo(
        a.isAvailable ? 1 : 0,
      );
      if (availableCompare != 0) return availableCompare;

      final ratingCompare = (b.averageRating ?? b.rating ?? 0).compareTo(
        a.averageRating ?? a.rating ?? 0,
      );
      if (ratingCompare != 0) return ratingCompare;

      return a.fullName.compareTo(b.fullName);
    });
  }

  _ProblemIntent _detectProblemIntent(String query) {
    if (query.trim().length < 3) return const _ProblemIntent.empty();

    final scores = <String, int>{};
    for (final rule in _intentRules) {
      var score = 0;

      for (final jobName in rule.jobNames) {
        if (query.contains(jobName)) score += 8;
      }

      for (final phrase in rule.phrases) {
        if (query.contains(phrase)) score += 7;
      }

      for (final symptom in rule.symptoms) {
        if (query.contains(symptom)) score += 4;
      }

      for (final object in rule.objects) {
        if (query.contains(object)) score += 3;
      }

      if (score > 0) scores[rule.category] = score;
    }

    if (scores.isEmpty) return const _ProblemIntent.empty();

    final best = scores.entries.reduce(
      (current, next) => next.value > current.value ? next : current,
    );

    if (best.value < 5) return const _ProblemIntent.empty();
    return _ProblemIntent(best.key, best.value);
  }

  bool _hasNearToken(String token, String searchableText) {
    if (token.length < 4) return false;
    final words = searchableText.split(' ');
    for (final word in words) {
      if (word.length < 4) continue;
      if (_similarity(token, word) >= 0.78) return true;
    }
    return false;
  }

  double _similarity(String a, String b) {
    final distance = _levenshtein(a, b);
    final longest = math.max(a.length, b.length);
    if (longest == 0) return 1;
    return 1 - (distance / longest);
  }

  int _levenshtein(String a, String b) {
    final previous = List<int>.generate(b.length + 1, (index) => index);
    final current = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      current[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        current[j + 1] = math.min(
          math.min(current[j] + 1, previous[j + 1] + 1),
          previous[j] + cost,
        );
      }
      for (var j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }

    return previous[b.length];
  }

  List<String> _tokens(String value) {
    if (value.trim().isEmpty) return const [];
    return value
        .split(' ')
        .where((token) => token.length > 1 && !_stopWords.contains(token))
        .toList();
  }

  String _normalize(String value) {
    var output = value.toLowerCase();
    const replacements = {
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
      'ÿ': 'y',
      'œ': 'oe',
      'æ': 'ae',
      'Ã ': 'a',
      'Ã¡': 'a',
      'Ã¢': 'a',
      'Ã¤': 'a',
      'Ã£': 'a',
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

    replacements.forEach((accent, plain) {
      output = output.replaceAll(accent, plain);
    });

    return output
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _prettySpecialtyName(String value) {
    final normalized = _normalize(value);
    return _specialtyLabels[normalized] ?? value.trim();
  }

  double _distanceKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(endLat - startLat);
    final dLng = _toRadians(endLng - startLng);
    final lat1 = _toRadians(startLat);
    final lat2 = _toRadians(endLat);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}

const _moroccanCities = [
  'Agadir',
  'Al Hoceïma',
  'Beni Mellal',
  'Berkane',
  'Casablanca',
  'Chefchaouen',
  'Dakhla',
  'Essaouira',
  'Fez',
  'Guelmim',
  'Ifrane',
  'Imouzzer Kandar',
  'Kelaat M\'Gouna',
  'Kenitra',
  'Khemisset',
  'Khouribga',
  'Larache',
  'Marrakech',
  'Meknès',
  'Midelt',
  'Mohammedia',
  'Nador',
  'Oualidla',
  'Ouarzazate',
  'Oujda',
  'Rabat',
  'Safi',
  'Salé',
  'Sefrou',
  'Settat',
  'Skhirat',
  'Tafraoute',
  'Tanger',
  'Taroudannt',
  'Taza',
  'Tetouan',
  'Tiznit',
  'Toudgha',
  'Azilal',
  'Benslimane',
  'Boujdour',
  'Boulemane',
  'Cascades d\'Ouzoud',
  'Driouch',
  'El Jadida',
  'Erfoud',
  'Figuig',
  'Guercif',
  'Jorf El Melha',
  'Laâyoune',
  'Missour',
  'Moulay Brahim',
  'Moulay Yacoub',
  'Oualidia',
  'Oulmes',
  'Oum El Bouaghi',
  'Ounagha',
  'Outat El Haj',
  'Rifisseni',
  'Sagouine',
  'Sidi Bennour',
  'Sidi Ifni',
  'Sidi Kacem',
  'Sidi Rahhal',
  'Sidi Slimane',
  'Souk El Arba',
  'Souira Guemra',
  'Tahanaoute',
  'Talat N\'Yaaqoub',
  'Tamanar',
  'Tamerzift',
  'Tameslouht',
  'Tamksar',
  'Tamtert',
  'Tanger-Assilah',
  'Tangier',
  'Tanoumrite',
  'Taouz',
  'Taounate',
  'Tapant',
  'Targuist',
  'Taroudant',
  'Taounate',
  'Tataouin',
  'Tata',
  'Tataouine',
  'Tazouta',
  'Temara',
  'Tetuán',
  'Thal',
  'Thandoufane',
  'Thataouine',
  'Thénia',
  'Thibaouine',
  'Thibkess',
  'Thifelt',
  'Thighjijt',
  'Thighiza',
  'Thiklamine',
  'Thilaouine',
  'Thinissine',
  'Thioum',
  'Thiouia',
  'Thizirt',
  'Thizka',
  'Thizouzou',
  'Thodi',
  'Thodra',
  'Thomia',
  'Thoni',
  'Thonja',
  'Thonsa',
  'Thouda',
  'Thouent',
  'Thouiba',
  'Thouimi',
  'Thouina',
  'Thouisa',
  'Thouiech',
  'Thouliba',
];

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

const _stopWords = {
  'de',
  'des',
  'du',
  'la',
  'le',
  'les',
  'un',
  'une',
  'et',
  'a',
  'au',
  'aux',
  'pour',
  'avec',
  'dans',
  'sur',
  'mon',
  'ma',
  'mes',
  'je',
  'j',
  'ai',
  'besoin',
  'cherche',
  'trouver',
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
      'lma kaytseleb',
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
  _IntentRule(
    category: 'reparation electromenager',
    jobNames: ['reparateur electromenager', 'electromenager'],
    phrases: [
      'machine a laver panne',
      'frigo ne refroidit pas',
      'four ne chauffe pas',
      'lave vaisselle panne',
    ],
    symptoms: ['panne', 'bruit', 'chauffe pas', 'refroidit pas', 'fuit'],
    objects: ['frigo', 'refrigerateur', 'machine', 'four', 'lave vaisselle'],
  ),
];
