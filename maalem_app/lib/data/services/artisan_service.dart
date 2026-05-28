import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/artisan_model.dart';
import 'api_client.dart';

class ArtisanService {
  Future<List<ArtisanModel>> fetchAllArtisans({String query = ''}) async {
    try {
      final uri = Uri.parse('${ApiClient.baseUrl}/api/artisans').replace(
        queryParameters: query.trim().isEmpty ? null : {'q': query.trim()},
      );
      final response = await http.get(
        uri,
        headers: ApiClient.getHeaders(null),
      );

      if (response.statusCode == 200) {
        // json.decode transforme le texte brut en liste d'objets
        List<dynamic> body = json.decode(response.body);

        // On transforme chaque objet JSON en "ArtisanModel" grâce au factory créé avant
        return body.map((item) => ArtisanModel.fromJson(item)).toList();
      } else {
        throw Exception('Échec du chargement des artisans');
      }
    } catch (e) {
      throw Exception('Erreur de connexion : $e');
    }
  }
}
