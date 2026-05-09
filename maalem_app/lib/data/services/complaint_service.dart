import 'dart:convert';
import 'package:http/http.dart' as http;

class ComplaintService {
  final String baseUrl = 'http://localhost:8081/api';
  final String token;

  ComplaintService({required this.token});

  Future<void> createComplaint({
    required int targetId,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/complaints'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'target_id': targetId,
        'description': description,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur lors de l\'envoi de la réclamation');
    }
  }

  Future<List<dynamic>> getComplaints() async {
    final response = await http.get(
      Uri.parse('$baseUrl/complaints'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération des réclamations');
    }
  }

  Future<void> resolveComplaint(int complaintId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/complaints/$complaintId/resolve'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la résolution de la réclamation');
    }
  }
}