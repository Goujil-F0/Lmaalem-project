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
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor pour créer depuis JSON (API)
  factory ArtisanModel.fromJson(Map<String, dynamic> json) {
    return ArtisanModel(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      speciality: json['speciality'] ?? json['specialty'] ?? '',
      city: json['city'] ?? '',
      bio: json['bio'],
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? true,
      profileImage: json['profileImage'] ?? json['profile_image'],
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] ?? json['review_count'],
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
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
