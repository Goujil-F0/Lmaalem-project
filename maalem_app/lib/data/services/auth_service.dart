import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maalem_app/data/services/api_client.dart';

class AuthService {
  // On utilise l'ApiClient pour avoir l'URL de base centralisée
  final String baseUrl = ApiClient.baseUrl;

  // 1. CONNEXION (Login)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Le serveur renvoie : { "token": "...", "user": { ... } }
        return {
          'success': true, 
          'data': jsonDecode(response.body)
        };
      } else {
        // On récupère le message d'erreur envoyé par Node.js (ex: "Email ou mot de passe incorrect")
        final errorData = jsonDecode(response.body);
        return {
          'success': false, 
          'error': errorData['error'] ?? 'Une erreur est survenue lors de la connexion'
        };
      }
    } catch (e) {
      return {
        'success': false, 
        'error': 'Erreur de connexion au serveur : $e'
      };
    }
  }

  // 2. INSCRIPTION (Register)
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? city,
    String? neighborhood,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'role': role,
          'phone': phone,
          'city': city,
          'neighborhood': neighborhood,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true, 
          'data': jsonDecode(response.body)
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false, 
          'error': errorData['error'] ?? 'Une erreur est survenue lors de l\'inscription'
        };
      }
    } catch (e) {
      return {
        'success': false, 
        'error': 'Erreur de connexion au serveur : $e'
      };
    }
  }
}