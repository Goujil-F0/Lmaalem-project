import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../data/services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  UserLocation? _userLocation;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLocationEnabled = true;

  UserLocation? get userLocation => _userLocation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLocationEnabled => _isLocationEnabled;

  /// Récupère la localisation actuelle du client
  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userLocation = await _locationService.getCurrentLocation();
      _isLocationEnabled = true;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLocationEnabled = false;
      if (kDebugMode) {
        print('Erreur localisation: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Démarre la localisation en temps réel
  Future<void> startLocationUpdates() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLocationEnabled = false;
        _errorMessage = 'Service de localisation désactivé';
        notifyListeners();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Permission refusée définitivement';
        notifyListeners();
        return;
      }

      _isLocationEnabled = true;
      await getCurrentLocation();

      // Écoute les changements de localisation
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Mise à jour tous les 10 mètres
        ),
      ).listen(
        (position) {
          _userLocation = UserLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          notifyListeners();
        },
        onError: (e) {
          _errorMessage = 'Erreur flux localisation: $e';
          if (kDebugMode) {
            print(_errorMessage);
          }
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      if (kDebugMode) {
        print('Erreur démarrage localisation: $e');
      }
      notifyListeners();
    }
  }

  /// Arrête la localisation en temps réel
  void stopLocationUpdates() {
    _userLocation = null;
    notifyListeners();
  }

  /// Réinitialise l'état
  void reset() {
    _userLocation = null;
    _isLoading = false;
    _errorMessage = null;
    _isLocationEnabled = true;
    notifyListeners();
  }
}
