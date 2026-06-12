// lib/providers/booking_provider.dart

import 'package:flutter/material.dart';
import '../data/models/booking_model.dart';
import '../data/services/booking_service.dart';

class BookingProvider with ChangeNotifier {
  final BookingService _bookingService = BookingService();

  // Variables privées
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters (pour que l'interface puisse lire ces variables)
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Fonction pour charger l'historique
  Future<void> fetchBookingHistory(int userId, String role) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners(); // 🔄 Déclenche l'affichage du chargement sur l'écran

    try {
      _bookings = await _bookingService.getBookingHistory(userId, role);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // 🔄 Cache le chargement et affiche les données (ou l'erreur)
    }
  }

  // Fonction pour mettre à jour le statut (Accepter / Refuser / Terminer)
  Future<bool> changeBookingStatus(int bookingId, String newStatus) async {
    try {
      final success =
          await _bookingService.updateBookingStatus(bookingId, newStatus);

      if (success) {
        // Met à jour la liste locale sans avoir à refaire une requête au serveur
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          final oldBooking = _bookings[index];
          // On remplace par un nouvel objet avec le statut mis à jour
          _bookings[index] = Booking(
            id: oldBooking.id,
            clientId: oldBooking.clientId,
            artisanId: oldBooking.artisanId,
            bookingDate: oldBooking.bookingDate,
            status: newStatus,
            description: oldBooking.description,
            agreedPrice: oldBooking.agreedPrice,
            artisanName: oldBooking.artisanName,
            clientName: oldBooking.clientName,
            hasReview: oldBooking.hasReview,
            unreadCount: oldBooking.unreadCount,
            otherPartyName: oldBooking.otherPartyName,
          );
          notifyListeners(); // 🔄 Met à jour l'écran instantanément
        }
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Fonction pour créer une réservation
  Future<bool> addBooking(int clientId, int artisanId, String description,
      double price, DateTime date) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final success = await _bookingService.createBooking(
          clientId, artisanId, description, price, date);

      if (success) {
        // Si ça a marché, on recharge l'historique pour que la nouvelle réservation apparaisse !
        try {
          await fetchBookingHistory(clientId, 'client');
        } catch (_) {
          // La reservation est deja creee. L'historique pourra etre recharge plus tard.
        }
        return true;
      }
      _errorMessage = 'Erreur lors de la creation de la reservation';
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markBookingReviewed(int bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) return;

    final oldBooking = _bookings[index];
    _bookings[index] = Booking(
      id: oldBooking.id,
      clientId: oldBooking.clientId,
      artisanId: oldBooking.artisanId,
      bookingDate: oldBooking.bookingDate,
      status: oldBooking.status,
      description: oldBooking.description,
      agreedPrice: oldBooking.agreedPrice,
      artisanName: oldBooking.artisanName,
      clientName: oldBooking.clientName,
      hasReview: true,
      unreadCount: oldBooking.unreadCount,
      otherPartyName: oldBooking.otherPartyName,
    );
    notifyListeners();
  }
}
