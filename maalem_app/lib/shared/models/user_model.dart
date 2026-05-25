import 'package:maalem_app/shared/models/artisan_model.dart';

class User {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? city;
  final String? neighborhood;
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
    this.photoUrl,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'client',
      phone: json['phone'],
      city: json['city'],
      neighborhood: json['neighborhood'],
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
      'photo_url': photoUrl,
      'profile': profile?.toJson(),
    };
  }

  bool get isArtisan => role == 'artisan';
  bool get isClient => role == 'client';
}
