import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';

class ReviewService {
  static const String _baseUrl = 'http://10.0.2.2:8081';

  Future<ReviewModel> addReview({
    required int clientId,
    required int artisanId,
    required int bookingId,
    required int rating,
    String? commentaire,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reviews/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'client_id'  : clientId,
        'artisan_id' : artisanId,
        'booking_id' : bookingId,
        'rating'     : rating,
        'commentaire': commentaire,
      }),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return ReviewModel.fromMap(data['review']);
    }
    final error = jsonDecode(response.body)['error'];
    throw Exception('Erreur : $error');
  }

  // ── Récupérer les avis d'un artisan ──────────────────────────
  Future<List<ReviewModel>> getReviewsForArtisan(int artisanId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reviews/artisan/$artisanId'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body)['reviews'];
      return data.map((r) => ReviewModel.fromMap(r)).toList();
    }
    throw Exception('Impossible de charger les avis');
  }

  // ── Vérifier si le client a déjà noté cet artisan ────────────
  Future<bool> hasReviewed(int clientId, int artisanId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/reviews/check?client_id=$clientId&artisan_id=$artisanId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['has_reviewed'] as bool;
    }
    return false;
  }

  // ── Supprimer un avis ─────────────────────────────────────────
  Future<void> deleteReview(int reviewId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/reviews/$reviewId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Impossible de supprimer l\'avis');
    }
  }
}