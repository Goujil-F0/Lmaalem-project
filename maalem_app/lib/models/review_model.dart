class ReviewModel {
  final int? id;           // int, nullable car pas encore créé côté client
  final int artisanId;     // int (FK integer dans la DB)
  final int clientId;      // int (FK integer dans la DB)
  final String clientName;
  final String clientPhotoUrl;
  final int rating;        // int (CHECK 1-5 dans la DB)
  final String comment;
  final DateTime? createdAt;
  final int? bookingId;    // int (FK integer dans la DB)

  ReviewModel({
    this.id,
    required this.artisanId,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl = '',
    required this.rating,
    required this.comment,
    this.createdAt,
    this.bookingId,
  });

  // Remplace fromFirestore — lit la réponse JSON du serveur Dart
  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id            : map['id'],
      artisanId     : map['artisan_id'],
      clientId      : map['client_id'],
      clientName    : map['client_name'] ?? 'Anonyme',
      clientPhotoUrl: map['client_photo_url'] ?? '',
      rating        : map['rating'],
      comment       : map['comment'] ?? '',
      createdAt     : map['created_at'] != null
                        ? DateTime.parse(map['created_at'])
                        : null,
      bookingId     : map['booking_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'artisan_id'       : artisanId,
      'client_id'        : clientId,
      'client_name'      : clientName,
      'client_photo_url' : clientPhotoUrl,
      'rating'           : rating,
      'comment'          : comment,
      'booking_id'       : bookingId,
    };
  }
}