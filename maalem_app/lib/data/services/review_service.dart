import 'dart:convert';
import 'package:http/http.dart' as http;

class ReviewService {
  final String baseUrl = 'http://localhost:8081/api/reviews';
  final String? token;

  ReviewService({this.token});

  // RÉCUPÉRER les avis
  Future<List<dynamic>> getArtisanReviews(int artisanId) async {
    final response = await http.get(Uri.parse('$baseUrl/$artisanId'));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Erreur chargement avis');
  }

  // AJOUTER un avis (C'est cette méthode qui manquait !)
  Future<void> addReview({
    required int bookingId,
    required int artisanId,
    required int rating,
    String? comment,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'bookingId': bookingId,
        'artisanId': artisanId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 201) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Erreur lors de l\'envoi');
    }
  }
}