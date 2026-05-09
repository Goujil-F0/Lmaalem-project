import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  final String baseUrl = 'http://localhost:8081/api';
  final String token;

  DashboardService({required this.token});

  Future<Map<String, dynamic>> getArtisanDashboard(int artisanId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/artisan/$artisanId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement du dashboard');
    }
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/admin'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement du dashboard admin');
    }
  }
}