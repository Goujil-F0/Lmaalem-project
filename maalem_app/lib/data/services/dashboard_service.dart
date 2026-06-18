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

  Future<double> rechargeWallet(int artisanId, double amount) async {
    final response = await http.post(
      Uri.parse(
        '${ApiClient.baseUrl}/api/dashboard/artisan/$artisanId/wallet/recharge',
      ),
      headers: ApiClient.getHeaders(token),
      body: jsonEncode({'amount': amount}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return double.tryParse('${data['balance']}') ?? 0;
    }

    try {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erreur lors de la recharge');
    } catch (_) {
      throw Exception('Erreur lors de la recharge');
    }
  }
}
