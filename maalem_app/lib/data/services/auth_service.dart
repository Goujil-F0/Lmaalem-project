import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maalem_app/data/services/api_client.dart';

class AuthService {
  final String baseUrl = ApiClient.baseUrl;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: ApiClient.getHeaders(null),
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': data['error'] ?? 'Une erreur est survenue lors de la connexion',
      };
    } catch (e) {
      return {'success': false, 'error': 'Erreur de connexion au serveur : $e'};
    }
  }

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
        headers: ApiClient.getHeaders(null),
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
      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      }
      return {
        'success': false,
        'error': data['error'] ?? 'Une erreur est survenue lors de l inscription',
      };
    } catch (e) {
      return {'success': false, 'error': 'Erreur de connexion au serveur : $e'};
    }
  }

  Future<Map<String, dynamic>> uploadCin({
    required XFile rectoFile,
    required XFile versoFile,
    required String token,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/upload-cin'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        http.MultipartFile.fromBytes(
          'cin_recto',
          await rectoFile.readAsBytes(),
          filename: rectoFile.name,
          contentType: _contentTypeFor(rectoFile.name),
        ),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'cin_verso',
          await versoFile.readAsBytes(),
          filename: versoFile.name,
          contentType: _contentTypeFor(versoFile.name),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': data['error'] ?? 'Erreur upload'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur upload : $e'};
    }
  }

  Future<Map<String, dynamic>> updateAvailability({
    required bool isAvailable,
    required String token,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/auth/availability'),
        headers: ApiClient.getHeaders(token),
        body: jsonEncode({'is_available': isAvailable}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': data['error'] ?? 'Erreur serveur'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur serveur : $e'};
    }
  }

  MediaType _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return MediaType('application', 'pdf');
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    return MediaType('image', 'jpeg');
  }
}
