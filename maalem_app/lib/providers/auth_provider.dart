import 'package:flutter/material.dart';
import 'package:maalem_app/shared/models/user_model.dart';
import '../data/services/auth_service.dart';
import '../core/utils/storage_helper.dart';

class AuthProvider with ChangeNotifier {
  // État privé
  User? _user;
  String? _token;
  bool _isLoading = false;

  // Getters pour l'UI (lecture seule)
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;

  // Instance du service
  final AuthService _authService = AuthService();

  // ---------------------------------------------------------------------------
  // 1. INITIALISATION (Vérifier si l'utilisateur est déjà connecté au démarrage)
  // ---------------------------------------------------------------------------
  Future<void> checkAuthStatus() async {
    print("🔍 DEBUG: checkAuthStatus commencé..."); 

    _isLoading = true;
    notifyListeners();

    try {
      // On récupère le token sauvegardé dans le téléphone
      final savedToken = await StorageHelper.getToken();

      if (savedToken != null) {
        _token = savedToken;
        // OPTIONNEL: Ici, on pourrait appeler un endpoint /auth/me
        // pour récupérer les infos fraîches de l'utilisateur depuis le serveur.
        // Pour l'instant, on considère que si on a un token, on est connecté.
      }
    } catch (e) {
      debugPrint("Erreur lors du check l'auth status: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 2. CONNEXION (Login)
  // ---------------------------------------------------------------------------
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result['success']) {
      final data = result['data'];
      _token = data['token'];
      _user = User.fromJson(data['user']); // Transformation JSON -> Objet User

      // Sauvegarde du token localement pour la prochaine fois
      await StorageHelper.saveToken(_token!);

      _isLoading = false;
      notifyListeners(); // Notifie l'UI pour rediriger vers la Map
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false; // Retourne false pour afficher l'erreur dans l'UI
  }

  // ---------------------------------------------------------------------------
  // 3. INSCRIPTION (Register)
  // ---------------------------------------------------------------------------
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

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

    // ---------------------------------------------------------------------------
    // 4. DÉCONNEXION (Logout)
    // ---------------------------------------------------------------------------
    Future<void> logout() async {
      _user = null;
      _token = null;
      await StorageHelper.clearToken(); // Efface le token du téléphone
      notifyListeners(); // L'UI redirige automatiquement vers l'écran Login
    }
  }
