class ArtisanModel {
  final int id;
  final String fullName;
  final String? phone;
  final String? city;
  final double? latitude;
  final double? longitude;
  final int? specialtyId; // ← était specialityId (faute de frappe)
  final String? description;
  final double hourlyRate;
  final bool isAvailable;
  final double averageRating;

  const ArtisanModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.city,
    this.latitude,
    this.longitude,
    this.specialtyId,
    this.description,
    required this.hourlyRate,
    this.isAvailable = true,
    this.averageRating = 0.0,
  });

  factory ArtisanModel.fromJson(Map<String, dynamic> json) {
    return ArtisanModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      city: json['city'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      specialtyId: json['specialty_id'] as int?, // ← aligné sur le JSON
      description: json['description'] as String?,
      hourlyRate: (json['hourly_rate'] as num).toDouble(),
      isAvailable: json['is_available'] as bool? ?? true,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
