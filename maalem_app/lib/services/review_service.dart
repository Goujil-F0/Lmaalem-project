import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reviews';


  Future<void> addReview(ReviewModel review) async {
    // Vérifie qu'un client n'a pas déjà laissé un avis pour cet artisan
    final existing = await _firestore
        .collection(_collection)
        .where('artisanId', isEqualTo: review.artisanId)
        .where('clientId', isEqualTo: review.clientId)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Vous avez déjà laissé un avis pour cet artisan.');
    }

    final docRef = _firestore.collection(_collection).doc();
    await docRef.set(review.toMap());

    // Mettre à jour la note moyenne de l'artisan
    await _updateArtisanRating(review.artisanId);
  }


  Future<void> updateReview(String reviewId, double newRating, String newComment) async {
    final doc = await _firestore.collection(_collection).doc(reviewId).get();
    if (!doc.exists) throw Exception('Avis introuvable.');

    await _firestore.collection(_collection).doc(reviewId).update({
      'rating': newRating,
      'comment': newComment,
    });

    final data = doc.data() as Map<String, dynamic>;
    await _updateArtisanRating(data['artisanId']);
  }


  Future<void> deleteReview(String reviewId) async {
    final doc = await _firestore.collection(_collection).doc(reviewId).get();
    if (!doc.exists) throw Exception('Avis introuvable.');

    final data = doc.data() as Map<String, dynamic>;
    final artisanId = data['artisanId'];

    await _firestore.collection(_collection).doc(reviewId).delete();
    await _updateArtisanRating(artisanId);
  }
  Stream<List<ReviewModel>> getReviewsForArtisan(String artisanId) {
    return _firestore
        .collection(_collection)
        .where('artisanId', isEqualTo: artisanId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ReviewModel.fromFirestore).toList());
  }


  Stream<List<ReviewModel>> getReviewsByClient(String clientId) {
    return _firestore
        .collection(_collection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ReviewModel.fromFirestore).toList());
  }

 
  Future<bool> hasReviewed(String clientId, String artisanId) async {
    final snap = await _firestore
        .collection(_collection)
        .where('artisanId', isEqualTo: artisanId)
        .where('clientId', isEqualTo: clientId)
        .get();
    return snap.docs.isNotEmpty;
  }

  
  Future<void> _updateArtisanRating(String artisanId) async {
    final reviewsSnap = await _firestore
        .collection(_collection)
        .where('artisanId', isEqualTo: artisanId)
        .get();

    if (reviewsSnap.docs.isEmpty) {
      await _firestore.collection('artisans').doc(artisanId).update({
        'averageRating': 0,
        'totalReviews': 0,
      });
      return;
    }

    final ratings = reviewsSnap.docs
        .map((d) => (d['rating'] as num).toDouble())
        .toList();

    final average = ratings.reduce((a, b) => a + b) / ratings.length;

    await _firestore.collection('artisans').doc(artisanId).update({
      'averageRating': double.parse(average.toStringAsFixed(1)),
      'totalReviews': ratings.length,
    });
  }
}