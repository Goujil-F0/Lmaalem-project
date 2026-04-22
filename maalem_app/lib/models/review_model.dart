import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String artisanId;
  final String clientId;
  final String clientName;
  final String clientPhotoUrl;
  final double rating; 
  final String comment;
  final DateTime createdAt;
  final String? bookingId; 

  ReviewModel({
    required this.id,
    required this.artisanId,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl = '',
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.bookingId,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      artisanId: data['artisanId'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? 'Anonyme',
      clientPhotoUrl: data['clientPhotoUrl'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      bookingId: data['bookingId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'artisanId': artisanId,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhotoUrl': clientPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'bookingId': bookingId,
    };
  }
}