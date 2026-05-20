import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maalem_app/data/services/api_client.dart';

class DashboardService {
  final String token;

  DashboardService({required this.token});

  Future<Map<String, dynamic>> getArtisanDashboard(int artisanId) async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/api/dashboard/artisan/$artisanId'),
      headers: ApiClient.getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement du dashboard');
    }
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(
      Uri.parse('${ApiClient.baseUrl}/api/dashboard/admin'),
      headers: ApiClient.getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur lors du chargement du dashboard admin');
    }
  }
}
