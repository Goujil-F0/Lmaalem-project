class ArtisanProfile {
  final int userId;
  final int? specialtyId;
  final String? description;
  final double? hourlyRate;
  final bool isAvailable;
  final String? cinUrl;
  final bool cinVerified;
  final double averageRating;

  ArtisanProfile({
    required this.userId,
    this.specialtyId,
    this.description,
    this.hourlyRate,
    required this.isAvailable,
    this.cinUrl,
    required this.cinVerified,
    required this.averageRating,
  });

  factory ArtisanProfile.fromJson(Map<String, dynamic> json) {
    return ArtisanProfile(
      userId: json['user_id'],
      specialtyId: json['specialty_id'],
      description: json['description'],
      hourlyRate: json['hourly_rate'] != null
          ? double.parse(json['hourly_rate'].toString())
          : null,
      isAvailable: json['is_available'] ?? true,
      cinUrl: json['cin_url'],
      cinVerified: json['cin_verified'] ?? false,
      averageRating: double.parse(
        (json['average_rating'] ?? '0').toString(),
      ),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'specialty_id': specialtyId,
      'description': description,
      'hourly_rate': hourlyRate,
      'is_available': isAvailable,
      'cin_url': cinUrl,
      'cin_verified': cinVerified,
      'average_rating': averageRating,
    };
  }
}