class ArtisanModel {
  final int id;
  final String fullName;
  final String? phone;
  final String? city;
  final double? latitude;
  final double? longitude;

  final int? specialityId;
  final String? description;
  final double hourlyRate;
  final bool isAvailable;
  final double averageRating;

  ArtisanModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.city,
    this.latitude,
    this.longitude,
    this.specialityId,
    this.description,
    required this.hourlyRate,
    this.isAvailable = true,
    this.averageRating = 0.0,
  });

  factory ArtisanModel.fromJson(Map<String, dynamic> json) {
    return ArtisanModel(
      id: json['id'],
      fullName: json['full_name'],
      phone: json['phone'],
      city: json['city'],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      specialityId: json['speciality_id'],
      description: json['description'],
      hourlyRate: (json['hourly_rate'] as num).toDouble(),
      isAvailable: json['is_available'] ?? true,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
