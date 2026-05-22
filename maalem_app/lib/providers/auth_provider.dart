import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maalem_app/shared/models/user_model.dart';
import '../core/utils/storage_helper.dart';
import '../data/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  String? _pendingCinToken;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;

  final AuthService _authService = AuthService();

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = await StorageHelper.getToken();
      final userJson = await StorageHelper.getUser();
      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      debugPrint("Erreur lors du check l'auth status: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result['success']) {
      final data = result['data'];
      _token = data['token'];
      _pendingCinToken = null;
      _user = User.fromJson(data['user']);
      await StorageHelper.saveToken(_token!);
      await StorageHelper.saveUser(jsonEncode(_user!.toJson()));
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

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
        if (userData['role'] == 'artisan') {
          _pendingCinToken = data['token'];
          _user = data['user'] != null ? User.fromJson(data['user']) : null;
        } else {
          _pendingCinToken = null;
          _user = null;
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

  Future<Map<String, dynamic>> uploadCin(XFile recto, XFile verso) async {
    final uploadToken = _pendingCinToken ?? _token;
    if (uploadToken == null) {
      return {'success': false, 'error': 'Session upload introuvable. Reconnectez-vous.'};
    }

    _isLoading = true;
    notifyListeners();

    final result = await _authService.uploadCin(
      rectoFile: recto,
      versoFile: verso,
      token: uploadToken,
    );

    if (result['success'] && _pendingCinToken != null) {
      _pendingCinToken = null;
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> updateAvailability(bool isAvailable) async {
    if (_token == null) {
      return {'success': false, 'error': 'Token manquant'};
    }
    return _authService.updateAvailability(
      isAvailable: isAvailable,
      token: _token!,
    );
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    _pendingCinToken = null;
    await StorageHelper.clearToken();
    notifyListeners();
  }
}
