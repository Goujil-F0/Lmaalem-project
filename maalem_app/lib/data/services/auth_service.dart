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

      return _handleResponse(
        response,
        successStatuses: const [200],
        fallbackError: 'Une erreur est survenue lors de la connexion',
      );
    } catch (e) {
      return _networkError('connexion', e);
    }
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? specialty,
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
          'specialty': specialty,
          'city': city,
          'neighborhood': neighborhood,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      return _handleResponse(
        response,
        successStatuses: const [201],
        fallbackError: "Une erreur est survenue lors de l'inscription",
      );
    } catch (e) {
      return _networkError('inscription', e);
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

      final response = await http.Response.fromStream(await request.send());
      return _handleResponse(
        response,
        successStatuses: const [200],
        fallbackError: 'Erreur upload CIN',
      );
    } catch (e) {
      return _networkError('upload CIN', e);
    }
  }

  Future<Map<String, dynamic>> registerArtisanWithCin({
    required Map<String, dynamic> userData,
    required XFile rectoFile,
    required XFile versoFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/register-artisan'),
      );
      request.fields.addAll({
        'full_name': (userData['full_name'] ?? '').toString(),
        'email': (userData['email'] ?? '').toString(),
        'password': (userData['password'] ?? '').toString(),
        'phone': (userData['phone'] ?? '').toString(),
        'specialty': (userData['specialty'] ?? '').toString(),
        'city': (userData['city'] ?? '').toString(),
        'neighborhood': (userData['neighborhood'] ?? '').toString(),
        'latitude': (userData['latitude'] ?? '').toString(),
        'longitude': (userData['longitude'] ?? '').toString(),
      });
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

      final response = await http.Response.fromStream(await request.send());
      return _handleResponse(
        response,
        successStatuses: const [201],
        fallbackError: "Erreur lors de l'inscription artisan",
      );
    } catch (e) {
      return _networkError('inscription artisan', e);
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

      return _handleResponse(
        response,
        successStatuses: const [200],
        fallbackError: 'Erreur lors de la mise a jour du statut',
      );
    } catch (e) {
      return _networkError('mise a jour du statut', e);
    }
  }

  Future<Map<String, dynamic>> updateClientProfile({
    required String token,
    String? fullName,
    String? email,
    String? phone,
    String? city,
    String? neighborhood,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final body = <String, dynamic>{
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (city != null) 'city': city,
        if (neighborhood != null) 'neighborhood': neighborhood,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/auth/profile'),
        headers: ApiClient.getHeaders(token),
        body: jsonEncode(body),
      );

      return _handleResponse(
        response,
        successStatuses: const [200],
        fallbackError: 'Erreur lors de la mise a jour du profil',
      );
    } catch (e) {
      return _networkError('mise a jour du profil', e);
    }
  }

  Future<Map<String, dynamic>> updateArtisanProfile({
    required String token,
    String? specialty,
    double? hourlyRate,
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{
        if (specialty != null) 'specialty': specialty,
        if (hourlyRate != null) 'hourly_rate': hourlyRate,
        if (description != null) 'description': description,
      };

      final response = await http.patch(
        Uri.parse('$baseUrl/auth/artisan/profile'),
        headers: ApiClient.getHeaders(token),
        body: jsonEncode(body),
      );

      return _handleResponse(
        response,
        successStatuses: const [200],
        fallbackError: 'Erreur lors de la mise a jour du profil artisan',
      );
    } catch (e) {
      return _networkError('mise a jour du profil artisan', e);
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? specialty,
    double? hourlyRate,
  }) {
    return updateArtisanProfile(
      token: token,
      specialty: specialty,
      hourlyRate: hourlyRate,
    );
  }

  Future<Map<String, dynamic>> uploadProfilePhoto({
    required String token,
    required XFile image,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/profile/photo'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_photo',
          await image.readAsBytes(),
          filename: image.name,
          contentType: _contentTypeFor(image.name),
        ),
      );

      final response = await http.Response.fromStream(await request.send());
      return _handleResponse(
        response,
        successStatuses: const [200, 201],
        fallbackError: 'Erreur lors de l upload de la photo',
      );
    } catch (e) {
      return _networkError('upload photo', e);
    }
  }

  Future<Map<String, dynamic>> uploadPortfolioImage({
    required String token,
    required XFile image,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/auth/artisan/portfolio'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'portfolio_image',
          await image.readAsBytes(),
          filename: image.name,
          contentType: _contentTypeFor(image.name),
        ),
      );

      final response = await http.Response.fromStream(await request.send());
      return _handleResponse(
        response,
        successStatuses: const [200, 201],
        fallbackError: 'Erreur lors de l upload du portfolio',
      );
    } catch (e) {
      return _networkError('upload portfolio', e);
    }
  }

  Future<Map<String, dynamic>> replacePortfolioImage({
    required String token,
    required int index,
    required XFile image,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/auth/artisan/portfolio/$index'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'portfolio_image',
          await image.readAsBytes(),
          filename: image.name,
          contentType: _contentTypeFor(image.name),
        ),
      );

      final response = await http.Response.fromStream(await request.send());
      return _handleResponse(
        response,
        successStatuses: const [200],
        fallbackError: 'Erreur lors de la modification du portfolio',
      );
    } catch (e) {
      return _networkError('modification portfolio', e);
    }
  }

  Map<String, dynamic> _handleResponse(
    http.Response response, {
    required List<int> successStatuses,
    required String fallbackError,
  }) {
    final decoded = _decodeBody(response);
    final isSuccess = successStatuses.contains(response.statusCode);

    if (isSuccess) {
      return {'success': true, 'data': decoded};
    }

    final serverError = decoded['error'] ?? decoded['message'];
    return {
      'success': false,
      'statusCode': response.statusCode,
      'error': serverError ?? '$fallbackError (${response.statusCode})',
      'raw': decoded['raw'],
    };
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return {};

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    } on FormatException {
      final preview = body.length > 160 ? '${body.substring(0, 160)}...' : body;
      return {
        'error': 'Reponse serveur invalide. Le serveur n a pas renvoye du JSON.',
        'raw': preview,
      };
    }
  }

  Map<String, dynamic> _networkError(String action, Object error) {
    return {
      'success': false,
      'error': 'Erreur de $action : $error',
    };
  }

  MediaType _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return MediaType('application', 'pdf');
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    return MediaType('image', 'jpeg');
  }
}
