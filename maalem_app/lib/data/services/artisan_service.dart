import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/artisan_model.dart';

class ArtisanService {
  final String _baseUrl = "http://localhost:8081/api";

  Future<List<ArtisanModel>> fetchAllArtisans() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/artisans'));

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
