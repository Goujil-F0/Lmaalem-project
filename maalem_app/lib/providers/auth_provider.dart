import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maalem_app/data/services/auth_service.dart';
import 'package:maalem_app/shared/models/artisan_model.dart';
import 'package:maalem_app/shared/models/user_model.dart';

import '../core/utils/storage_helper.dart';

class AuthProvider with ChangeNotifier {
  static const bool _mockProfileWhenBackendMissing = true;

  final AuthService _authService = AuthService();

  User? _user;
  String? _token;
  String? _pendingCinToken;

  bool _isLoading = false;
  bool _isUpdatingProfile = false;
  bool _isUploadingPhoto = false;
  bool _isUploadingPortfolio = false;
  bool _isUpdatingAvailability = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isUpdatingProfile => _isUpdatingProfile;
  bool get isUploadingPhoto => _isUploadingPhoto;
  bool get isUploadingPortfolio => _isUploadingPortfolio;
  bool get isUpdatingAvailability => _isUpdatingAvailability;

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

    try {
      final result = await _authService.login(email, password);
      if (result['success'] == true) {
        final data = result['data'];
        _token = data['token'];
        _pendingCinToken = null;
        _user = await _mergeWithMockUser(User.fromJson(data['user']));
        await StorageHelper.saveToken(_token!);
        await _persistUser();
        return true;
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

      if (result['success'] == true) {
        final data = result['data'];
        if (userData['role'] == 'artisan') {
          _pendingCinToken = data['token'];
          _user = data['user'] != null ? User.fromJson(data['user']) : null;
        } else {
          _pendingCinToken = null;
          _user = null;
        }
      }

      return result;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> uploadCin(XFile recto, XFile verso) async {
    final uploadToken = _pendingCinToken ?? _token;
    if (uploadToken == null) {
      return {
        'success': false,
        'error': 'Session upload introuvable. Reconnectez-vous.',
      };
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.uploadCin(
        rectoFile: recto,
        versoFile: verso,
        token: uploadToken,
      );

      if (result['success'] == true && _pendingCinToken != null) {
        _pendingCinToken = null;
        _user = null;
      }

      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateAvailability(bool isAvailable) async {
    if (_token == null) {
      return {'success': false, 'error': 'Token manquant'};
    }

    _isUpdatingAvailability = true;
    notifyListeners();

    try {
      final result = await _authService.updateAvailability(
        isAvailable: isAvailable,
        token: _token!,
      );

      if ((result['success'] == true || _shouldMockProfileSuccess(result)) &&
          _user != null) {
        final currentProfile = _user!.profile;
        if (currentProfile != null) {
          _user = _user!.copyWith(
            profile: currentProfile.copyWith(isAvailable: isAvailable),
          );
          await _persistUser();
          if (result['success'] != true) await _persistMockUser();
        }
        if (result['success'] != true) return _mockedSuccess();
      }

      return result;
    } finally {
      _isUpdatingAvailability = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateArtisanProfile({
    String? specialty,
    double? hourlyRate,
    String? description,
  }) async {
    if (_token == null) {
      return {'success': false, 'error': 'Session expiree'};
    }

    _isUpdatingProfile = true;
    notifyListeners();

    try {
      final result = await _authService.updateArtisanProfile(
        token: _token!,
        specialty: specialty,
        hourlyRate: hourlyRate,
        description: description,
      );

      if ((result['success'] == true || _shouldMockProfileSuccess(result)) &&
          _user != null) {
        _user = _userFromResponse(result) ??
            _user!.copyWith(
              profile: _updatedArtisanProfile(
                specialty: specialty,
                hourlyRate: hourlyRate,
                description: description,
              ),
            );
        await _persistUser();
        if (result['success'] != true) await _persistMockUser();
        if (result['success'] != true) return _mockedSuccess();
      }

      return result;
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateClientProfile({
    String? fullName,
    String? email,
    String? phone,
    String? city,
    String? neighborhood,
    double? latitude,
    double? longitude,
  }) async {
    if (_token == null) {
      return {'success': false, 'error': 'Session expiree'};
    }

    _isUpdatingProfile = true;
    notifyListeners();

    try {
      final result = await _authService.updateClientProfile(
        token: _token!,
        fullName: fullName,
        email: email,
        phone: phone,
        city: city,
        neighborhood: neighborhood,
        latitude: latitude,
        longitude: longitude,
      );

      if ((result['success'] == true || _shouldMockProfileSuccess(result)) &&
          _user != null) {
        _user = _userFromResponse(result) ??
            _user!.copyWith(
              fullName: fullName,
              email: email,
              phone: phone,
              city: city,
              neighborhood: neighborhood,
              latitude: latitude,
              longitude: longitude,
            );
        await _persistUser();
        if (result['success'] != true) await _persistMockUser();
        if (result['success'] != true) return _mockedSuccess();
      }

      return result;
    } finally {
      _isUpdatingProfile = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateProfilePhoto(XFile image) async {
    if (_token == null) {
      return {'success': false, 'error': 'Session expiree'};
    }

    _isUploadingPhoto = true;
    notifyListeners();

    try {
      final result = await _authService.uploadProfilePhoto(
        token: _token!,
        image: image,
      );

      if ((result['success'] == true || _shouldMockProfileSuccess(result)) &&
          _user != null) {
        final data = result['data'];
        final photoUrl = data is Map<String, dynamic>
            ? data['photo_url'] ?? data['photoUrl'] ?? data['url']
            : null;
        final mockPhotoUrl =
            result['success'] == true ? null : await _imageToDataUrl(image);
        _user = _userFromResponse(result) ??
            _user!.copyWith(photoUrl: photoUrl ?? mockPhotoUrl ?? image.path);
        await _persistUser();
        if (result['success'] != true) await _persistMockUser();
        if (result['success'] != true) return _mockedSuccess();
      }

      return result;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> uploadPortfolioImage(XFile image) async {
    if (_token == null) {
      return {'success': false, 'error': 'Session expiree'};
    }

    _isUploadingPortfolio = true;
    notifyListeners();

    try {
      final result = await _authService.uploadPortfolioImage(
        token: _token!,
        image: image,
      );

      if (result['success'] == true || _shouldMockProfileSuccess(result)) {
        final updatedUser = _userFromResponse(result);
        if (updatedUser != null) {
          _user = updatedUser;
          await _persistUser();
        } else if (_user != null && result['success'] != true) {
          final imageUrl = await _imageToDataUrl(image);
          _user = _user!.copyWith(
            profile: _updatedArtisanProfile(
              portfolioImages: [
                ...(_user!.profile?.portfolioImages ?? const []),
                imageUrl,
              ],
            ),
          );
          await _persistUser();
          await _persistMockUser();
        }
        if (result['success'] != true) return _mockedSuccess();
      }

      return result;
    } finally {
      _isUploadingPortfolio = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? specialty,
    double? hourlyRate,
  }) {
    return updateArtisanProfile(
      specialty: specialty,
      hourlyRate: hourlyRate,
    );
  }

  Uri contactSupportUri() {
    return Uri.https('wa.me', '/212658416668', {
      'text': "Bonjour, j'ai besoin d'aide avec mon compte Lmaalem.",
    });
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    _pendingCinToken = null;
    await StorageHelper.clearToken();
    await StorageHelper.clearMockUser();
    notifyListeners();
  }

  Future<void> _persistUser() async {
    final currentUser = _user;
    if (currentUser == null) return;
    await StorageHelper.saveUser(jsonEncode(currentUser.toJson()));
  }

  Future<void> _persistMockUser() async {
    final currentUser = _user;
    if (currentUser == null) return;
    await StorageHelper.saveMockUser(jsonEncode(currentUser.toJson()));
  }

  Future<User> _mergeWithMockUser(User backendUser) async {
    final mockJson = await StorageHelper.getMockUser();
    if (mockJson == null) return backendUser;

    try {
      final mockUser = User.fromJson(jsonDecode(mockJson));
      final sameUser = mockUser.id == backendUser.id ||
          mockUser.email.toLowerCase() == backendUser.email.toLowerCase();
      if (!sameUser) return backendUser;

      return backendUser.copyWith(
        fullName: mockUser.fullName,
        email: mockUser.email,
        phone: mockUser.phone,
        city: mockUser.city,
        neighborhood: mockUser.neighborhood,
        latitude: mockUser.latitude,
        longitude: mockUser.longitude,
        photoUrl: mockUser.photoUrl,
        profile: _mergeProfiles(backendUser.profile, mockUser.profile),
      );
    } catch (e) {
      debugPrint('Erreur lors de la fusion mock profile: $e');
      return backendUser;
    }
  }

  ArtisanProfile? _mergeProfiles(
    ArtisanProfile? backendProfile,
    ArtisanProfile? mockProfile,
  ) {
    if (mockProfile == null) return backendProfile;
    if (backendProfile == null) return mockProfile;

    return backendProfile.copyWith(
      specialty: mockProfile.specialty,
      hourlyRate: mockProfile.hourlyRate,
      description: mockProfile.description,
      isAvailable: mockProfile.isAvailable,
      portfolioImages: mockProfile.portfolioImages,
    );
  }

  User? _userFromResponse(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is! Map<String, dynamic>) return null;

    final userJson = data['user'];
    if (userJson is Map<String, dynamic>) {
      return User.fromJson(userJson);
    }

    return null;
  }

  bool _shouldMockProfileSuccess(Map<String, dynamic> result) {
    if (!_mockProfileWhenBackendMissing || result['success'] == true) {
      return false;
    }

    final statusCode = result['statusCode'];
    final error = (result['error'] ?? '').toString().toLowerCase();
    final raw = (result['raw'] ?? '').toString().toLowerCase();

    return statusCode == 404 ||
        error.contains('reponse serveur invalide') ||
        error.contains('route introuvable') ||
        raw.contains('<!doctype html') ||
        raw.contains('<html');
  }

  Map<String, dynamic> _mockedSuccess() {
    return {
      'success': true,
      'mocked': true,
      'message': 'Modification simulee localement',
    };
  }

  ArtisanProfile _updatedArtisanProfile({
    String? specialty,
    double? hourlyRate,
    String? description,
    List<String>? portfolioImages,
  }) {
    final currentProfile = _user?.profile;
    if (currentProfile != null) {
      return currentProfile.copyWith(
        specialty: specialty,
        hourlyRate: hourlyRate,
        description: description,
        portfolioImages: portfolioImages,
      );
    }

    return ArtisanProfile(
      userId: _user?.id ?? 0,
      specialty: specialty,
      hourlyRate: hourlyRate,
      description: description,
      isAvailable: true,
      cinVerified: false,
      averageRating: 0,
      portfolioImages: portfolioImages ?? const [],
    );
  }

  Future<String> _imageToDataUrl(XFile image) async {
    final bytes = await image.readAsBytes();
    final lower = image.name.toLowerCase();
    final mimeType = lower.endsWith('.png')
        ? 'image/png'
        : lower.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }
}
