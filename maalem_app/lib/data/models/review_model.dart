class ReviewModel {
  final int? id;
  final int bookingId;
  final int clientId;
  final int artisanId;
  final int rating;
  final String? comment;
  final String? clientName;
  final DateTime? createdAt;

  ReviewModel({
    this.id,
    required this.bookingId,
    required this.clientId,
    required this.artisanId,
    required this.rating,
    this.comment,
    this.clientName,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      bookingId: json['booking_id'],
      clientId: json['client_id'],
      artisanId: json['artisan_id'],
      rating: json['rating'],
      comment: json['comment'],
      clientName: json['client_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'artisan_id': artisanId,
      'rating': rating,
      'comment': comment,
    };
  }
}