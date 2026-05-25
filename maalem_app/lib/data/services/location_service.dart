import 'package:geolocator/geolocator.dart';

class UserLocation {
  final double latitude;
  final double longitude;

  const UserLocation({
    required this.latitude,
    required this.longitude,
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

    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
