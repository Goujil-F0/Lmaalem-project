import 'package:maalem_app/shared/models/artisan_model.dart';

class User {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? city;
  final String? neighborhood;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final ArtisanProfile? profile;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.city,
    this.neighborhood,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _toInt(json['id'] ?? json['user_id'] ?? json['userId']) ?? 0,
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? json['userRole'] ?? 'client',
      phone: json['phone'],
      city: json['city'],
      neighborhood: json['neighborhood'],
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      profile: json['profile'] != null
          ? ArtisanProfile.fromJson(json['profile'])
          : null,
    );
  }

  User copyWith({
    int? id,
    String? fullName,
    String? email,
    String? role,
    String? phone,
    String? city,
    String? neighborhood,
    double? latitude,
    double? longitude,
    String? photoUrl,
    ArtisanProfile? profile,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      profile: profile ?? this.profile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
      'phone': phone,
      'city': city,
      'neighborhood': neighborhood,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoUrl,
      'profile': profile?.toJson(),
    };
  }

  bool get isArtisan => role == 'artisan';
  bool get isClient => role == 'client';
  bool get isAdmin => role == 'admin';
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
