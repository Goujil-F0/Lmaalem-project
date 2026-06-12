// lib/data/services/booking_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking_model.dart';
import 'api_client.dart';

class BookingService {
  // 1. Récupérer l'historique des réservations
  Future<List<Booking>> getBookingHistory(int userId, String role) async {
    // Construit l'URL finale: http://localhost:8081/api/bookings/history/1/client
    final url =
        Uri.parse('${ApiClient.baseUrl}/api/bookings/history/$userId/$role');

    try {
      final response = await http.get(url, headers: ApiClient.getHeaders(null));

      if (response.statusCode == 200) {
        // Si le backend répond OK, on décode le JSON
        final Map<String, dynamic> decodedJson = json.decode(response.body);

        // Notre backend renvoie les données dans une clé "data"
        final List<dynamic> bookingsData = decodedJson['data'];

        // On transforme la liste de JSON en liste d'objets Dart 'Booking'
        return bookingsData.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(
          'Erreur de connexion lors de la récupération de l\'historique: $e');
    }
  }

  // 2. Mettre à jour le statut d'une réservation (Accepter/Refuser)
  Future<bool> updateBookingStatus(int bookingId, String newStatus) async {
    final url =
        Uri.parse('${ApiClient.baseUrl}/api/bookings/$bookingId/status');

    try {
      final response = await http.patch(
        url,
        headers: ApiClient.getHeaders(null),
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) return true;
      throw Exception(_errorMessage(response));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // 3. Créer une nouvelle réservation (POST)
  Future<bool> createBooking(int clientId, int artisanId, String description,
      double agreedPrice, DateTime bookingDate) async {
    final url = Uri.parse('${ApiClient.baseUrl}/api/bookings');

    try {
      final response = await http.post(
        url,
        headers: ApiClient.getHeaders(null),
        body: json.encode({
          'client_id': clientId,
          'artisan_id': artisanId,
          'description': description,
          'agreed_price': agreedPrice,
          'booking_date': bookingDate.toIso8601String(),
          'status': 'pending', // <-- AJOUTE CETTE LIGNE par sécurité
        }),
      );

      if (response.statusCode == 201) return true;
      throw Exception(_errorMessage(response));
    } catch (e) {
      throw Exception(
          'Erreur de connexion lors de la création de la réservation: $e');
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final data = json.decode(response.body);
      return data['message'] ?? data['error'] ?? 'Erreur serveur';
    } catch (_) {
      return 'Erreur serveur: ${response.statusCode}';
    }
  }
}
