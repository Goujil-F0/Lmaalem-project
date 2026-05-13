// lib/data/models/booking_model.dart

class Booking {
  final int? id;
  final int clientId;
  final int artisanId;
  final String description;
  final double agreedPrice;
  final String status;
  final DateTime bookingDate;

  Booking({
    this.id,
    required this.clientId,
    required this.artisanId,
    required this.description,
    required this.agreedPrice,
    this.status = 'pending',
    required this.bookingDate,
  });

  // Depuis le JSON (Backend -> Flutter)
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      clientId: json['client_id'],
      artisanId: json['artisan_id'],
      description: json['description'] ?? '',
      // On s'assure de bien parser en double même si Postgres renvoie un String
      agreedPrice: double.tryParse(json['agreed_price'].toString()) ?? 0.0,
      status: json['status'] ?? 'pending',
      bookingDate: DateTime.parse(json['booking_date']),
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
