import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import indispensable pour XFile
import 'dart:io'; // AJOUTÉ : Indispensable pour transformer XFile en File
import 'package:maalem_app/shared/models/user_model.dart';
import '../data/services/auth_service.dart';
import '../core/utils/storage_helper.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;

  final AuthService _authService = AuthService();

  // 1. INITIALISATION
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedToken = await StorageHelper.getToken();
      if (savedToken != null) {
        _token = savedToken;
        // Optionnel : appeler un endpoint /auth/me pour récupérer l'objet User
      }
    } catch (e) {
      debugPrint("Erreur lors du check l'auth status: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. CONNEXION
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result['success']) {
      final data = result['data'];
      _token = data['token'];
      _user = User.fromJson(data['user']);
      await StorageHelper.saveToken(_token!);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // 3. INSCRIPTION
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.register(
        fullName: userData['full_name'] ?? '',
        email: userData['email'] ?? '',
        password: userData['password'] ?? '',
        role: userData['role'] ?? 'client',
        phone: userData['phone'],
        city: userData['city'],
        neighborhood: userData['neighborhood'],
        latitude: userData['latitude'],
        longitude: userData['longitude'],
      );
      
      if (result['success']) {
        final data = result['data'];
        if (data['token'] != null) {
          _token = data['token'];
          await StorageHelper.saveToken(_token!);
        }
        if (data['user'] != null) {
          _user = User.fromJson(data['user']);
        }
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  // 4. DÉCONNEXION
  Future<void> logout() async {
    _user = null;
    _token = null;
    await StorageHelper.clearToken();
    notifyListeners();
  }

  // 5. UPLOAD CIN (CORRIGÉ)
  Future<Map<String, dynamic>> uploadCin(XFile recto, XFile verso) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ✅ CORRECTION : Convertir XFile en File pour le service
      // .path donne le chemin du fichier sur le téléphone
      final result = await _authService.uploadCin(
        rectoFile: File(recto.path), 
        versoFile: File(verso.path),
        token: _token!,
      );

      // Optionnel : Une fois l'upload réussi, on pourrait rafraîchir l'utilisateur
      // pour mettre à jour la valeur de profile dans l'état global.
      
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }
}