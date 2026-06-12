import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class UserLocation {
  final double latitude;
  final double longitude;
  final String? city;
  final String? neighborhood;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.neighborhood,
  });

  String get coordinatesLabel {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }
}

class LocationService {
  Future<UserLocation> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Activez la localisation sur votre appareil.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Permission de localisation refusee.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Permission de localisation bloquee. Activez-la dans les reglages.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final address = await _reverseGeocode(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      city: address.city,
      neighborhood: address.neighborhood,
    );
  }

  Future<({String? city, String? neighborhood})> _reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'addressdetails': '1',
        'accept-language': 'fr',
      });
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (!kIsWeb) 'User-Agent': 'Lmaalem/1.0 (mobile application)',
        },
      );

      if (response.statusCode != 200) {
        return (city: null, neighborhood: null);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return (city: null, neighborhood: null);
      }
      final address = decoded['address'];
      if (address is! Map<String, dynamic>) {
        return (city: null, neighborhood: null);
      }

      final city = _firstNonEmpty(address, const [
        'city',
        'town',
        'village',
        'municipality',
        'county',
      ]);
      final neighborhood = _firstNonEmpty(address, const [
        'neighbourhood',
        'suburb',
        'quarter',
        'city_district',
        'road',
      ]);

      return (city: city, neighborhood: neighborhood);
    } catch (_) {
      return (city: null, neighborhood: null);
    }
  }

  String? _firstNonEmpty(
    Map<String, dynamic> values,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = values[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
