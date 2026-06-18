class ArtisanProfile {
  final int userId;
  final int? specialtyId;
  final String? description;
  final String? specialty;
  final double? hourlyRate;
  final bool isAvailable;
  final String? cinUrl;
  final bool cinVerified;
  final double averageRating;
  final List<String> portfolioImages;

  ArtisanProfile({
    required this.userId,
    this.specialtyId,
    this.description,
    this.specialty,
    this.hourlyRate,
    required this.isAvailable,
    this.cinUrl,
    required this.cinVerified,
    required this.averageRating,
    this.portfolioImages = const [],
  });

  factory ArtisanProfile.fromJson(Map<String, dynamic> json) {
    return ArtisanProfile(
      userId: json['user_id'] ?? json['userId'] ?? 0,
      specialtyId: json['specialty_id'] ?? json['specialtyId'],
      description: json['description'],
      specialty: json['specialty'] ?? json['speciality'],
      hourlyRate: json['hourly_rate'] != null
          ? double.parse(json['hourly_rate'].toString())
          : json['hourlyRate'] != null
              ? double.parse(json['hourlyRate'].toString())
              : null,
      isAvailable: json['is_available'] ?? json['isAvailable'] ?? true,
      cinUrl: json['cin_url'] ?? json['cinUrl'],
      cinVerified: json['cin_verified'] ?? json['cinVerified'] ?? false,
      averageRating: double.parse(
        (json['average_rating'] ?? json['averageRating'] ?? '0').toString(),
      ),
      portfolioImages: _parsePortfolioImages(
        json['portfolio_images'] ?? json['portfolioImages'],
      ),
    );
  }

  ArtisanProfile copyWith({
    int? userId,
    int? specialtyId,
    String? description,
    String? specialty,
    double? hourlyRate,
    bool? isAvailable,
    String? cinUrl,
    bool? cinVerified,
    double? averageRating,
    List<String>? portfolioImages,
  }) {
    return ArtisanProfile(
      userId: userId ?? this.userId,
      specialtyId: specialtyId ?? this.specialtyId,
      description: description ?? this.description,
      specialty: specialty ?? this.specialty,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      isAvailable: isAvailable ?? this.isAvailable,
      cinUrl: cinUrl ?? this.cinUrl,
      cinVerified: cinVerified ?? this.cinVerified,
      averageRating: averageRating ?? this.averageRating,
      portfolioImages: portfolioImages ?? this.portfolioImages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'specialty_id': specialtyId,
      'description': description,
      'specialty': specialty,
      'hourly_rate': hourlyRate,
      'is_available': isAvailable,
      'cin_url': cinUrl,
      'cin_verified': cinVerified,
      'average_rating': averageRating,
      'portfolio_images': portfolioImages,
    };
  }

  static List<String> _parsePortfolioImages(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }
}
