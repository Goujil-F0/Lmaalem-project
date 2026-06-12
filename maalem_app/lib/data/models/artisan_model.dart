class ArtisanModel {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String speciality;
  final String city;
  final String? bio;
  final double latitude;
  final double longitude;
  final bool isAvailable;
  final String? profileImage;
  final double? rating;
  final int? reviewCount;
  final double? averageRating;
  final double? hourlyRate;
  final List<String> portfolioImages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ArtisanModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.speciality,
    required this.city,
    this.bio,
    required this.latitude,
    required this.longitude,
    required this.isAvailable,
    this.profileImage,
    this.rating,
    this.reviewCount,
    this.averageRating,
    this.hourlyRate,
    this.portfolioImages = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor pour créer depuis JSON (API)
  factory ArtisanModel.fromJson(Map<String, dynamic> json) {
    final latitude = _toDouble(json['latitude']) ?? 0.0;
    final longitude = _toDouble(json['longitude']) ?? 0.0;
    final city = json['city'] ?? '';

    // Si pas de coordonnées valides, utiliser les coordonnées par défaut de la ville
    final coords = (latitude == 0 && longitude == 0)
        ? _getDefaultCoordinates(city)
        : (latitude, longitude);

    return ArtisanModel(
      id: _toInt(json['id']) ?? _toInt(json['user_id']) ?? 0,
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      speciality: json['speciality'] ??
          json['specialty'] ??
          json['specialite'] ??
          json['speciality_name'] ??
          '',
      city: city,
      bio: json['bio'] ?? json['description'],
      latitude: coords.$1,
      longitude: coords.$2,
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
      profileImage: json['profileImage'] ??
          json['profile_image'] ??
          json['photo_url'] ??
          json['photoUrl'] ??
          json['profile_photo_url'] ??
          json['profilePhotoUrl'],
      rating: _toDouble(json['rating']) ?? _toDouble(json['average_rating']),
      reviewCount: _toInt(json['reviewCount']) ?? _toInt(json['review_count']),
      averageRating:
          _toDouble(json['averageRating']) ?? _toDouble(json['average_rating']),
      hourlyRate:
          _toDouble(json['hourlyRate']) ?? _toDouble(json['hourly_rate']),
      portfolioImages: _toStringList(
        json['portfolioImages'] ?? json['portfolio_images'],
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'speciality': speciality,
      'city': city,
      'bio': bio,
      'latitude': latitude,
      'longitude': longitude,
      'isAvailable': isAvailable,
      'profileImage': profileImage,
      'rating': rating,
      'reviewCount': reviewCount,
      'averageRating': averageRating,
      'hourlyRate': hourlyRate,
      'portfolioImages': portfolioImages,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// CopyWith pour créer une copie modifiée
  ArtisanModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    String? speciality,
    String? city,
    String? bio,
    double? latitude,
    double? longitude,
    bool? isAvailable,
    String? profileImage,
    double? rating,
    int? reviewCount,
    double? averageRating,
    double? hourlyRate,
    List<String>? portfolioImages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArtisanModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      speciality: speciality ?? this.speciality,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAvailable: isAvailable ?? this.isAvailable,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      averageRating: averageRating ?? this.averageRating,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'ArtisanModel(id: $id, fullName: $fullName, city: $city, isAvailable: $isAvailable)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtisanModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Mappe les villes marocaines aux coordonnées GPS par défaut
(double, double) _getDefaultCoordinates(String city) {
  const cityCoordinates = {
    'agadir': (30.4278, -9.5981),
    'al hoceïma': (35.2531, -3.9289),
    'beni mellal': (32.3436, -6.3531),
    'berkane': (34.9289, -2.3206),
    'casablanca': (33.5731, -7.5898),
    'chefchaouen': (35.1684, -5.2686),
    'dakhla': (23.7635, -15.9582),
    'essaouira': (31.5085, -9.7673),
    'fez': (34.0333, -5.0),
    'guelmim': (28.9864, -10.0615),
    'ifrane': (33.5186, -5.1089),
    'kenitra': (34.2598, -6.5898),
    'khemisset': (33.8208, -5.6454),
    'khouribga': (32.8829, -6.9081),
    'larache': (35.1897, -6.1526),
    'marrakech': (31.6295, -8.0088),
    'meknès': (33.8935, -5.5898),
    'midelt': (32.6833, -4.7417),
    'mohammedia': (33.7667, -7.75),
    'nador': (35.1667, -2.9333),
    'ouarzazate': (30.9256, -6.8973),
    'oujda': (34.6741, -1.9086),
    'rabat': (34.0209, -6.8416),
    'safi': (32.2964, -8.7606),
    'salé': (34.0833, -6.8167),
    'settat': (33.0043, -7.6187),
    'tanger': (35.7595, -5.8342),
    'taroudannt': (30.4740, -8.8783),
    'taza': (34.2247, -4.0081),
    'tetouan': (35.5731, -5.3636),
    'tiznit': (29.6469, -9.7369),
  };

  final normalizedCity = city.toLowerCase().trim();
  if (cityCoordinates.containsKey(normalizedCity)) {
    return cityCoordinates[normalizedCity]!;
  }

  // Fallback: Casablanca si la ville n'est pas trouvée
  return (33.5731, -7.5898);
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return const [];
}
