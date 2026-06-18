// lib/data/models/booking_model.dart

class Booking {
  final int? id;
  final int clientId;
  final int artisanId;
  final String description;
  final double agreedPrice;
  final String status;
  final DateTime bookingDate;
  final String? artisanName;
  final String? clientName;
  final bool hasReview;
  final int unreadCount;
  final String otherPartyName;

  Booking({
    this.id,
    required this.clientId,
    required this.artisanId,
    required this.description,
    required this.agreedPrice,
    this.status = 'pending',
    required this.bookingDate,
    this.artisanName,
    this.clientName,
    this.hasReview = false,
    this.unreadCount = 0,
    this.otherPartyName = 'Utilisateur Inconnu',
  });

  // Depuis le JSON (Backend -> Flutter)
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      clientId: json['client_id'],
      artisanId: json['artisan_id'],
      description: json['description'] ?? '',
      agreedPrice: double.tryParse(json['agreed_price'].toString()) ?? 0.0,
      status: json['status'] ?? 'pending',
      bookingDate: DateTime.parse(json['booking_date']),
      artisanName: json['artisan_name'],
      clientName: json['client_name'],
      hasReview: json['has_review'] == true,
      unreadCount: int.tryParse(json['unread_count'].toString()) ?? 0,
      otherPartyName: json['other_party_name'] ?? 'Utilisateur Inconnu',
    );
  }

  // Vers le JSON (Flutter -> Backend)
  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'artisan_id': artisanId,
      'description': description,
      'agreed_price': agreedPrice,
      'booking_date': bookingDate.toIso8601String(),
    };
  }
}
