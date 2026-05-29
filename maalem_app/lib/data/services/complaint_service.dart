import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maalem_app/data/services/api_client.dart';

class ComplaintService {
  final String token;

  ComplaintService({required this.token});

  Future<void> createComplaint({
    required int bookingId,
    required int artisanId,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiClient.baseUrl}/api/complaints'),
      headers: ApiClient.getHeaders(token),
      body: jsonEncode({
        'booking_id': bookingId,
        'artisan_id': artisanId,
        'description': description,
      }),
    );

    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['message'] ??
            errorData['error'] ??
            'Erreur lors de l\'envoi de la réclamation',
      );
    }
  }

  Future<List<dynamic>> getComplaints() async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/api/complaints'),
      headers: ApiClient.getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Erreur lors de la récupération des réclamations');
  }

  Future<void> resolveComplaint(int complaintId) async {
    final response = await http.put(
      Uri.parse('${ApiClient.baseUrl}/api/complaints/$complaintId/resolve'),
      headers: ApiClient.getHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la résolution de la réclamation');
    }
  }
}