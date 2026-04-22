import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../widgets/star_rating_widget.dart';

class AvisScreen extends StatefulWidget {
  final String artisanId;
  final String artisanName;

  const AvisScreen({
    super.key,
    required this.artisanId,
    required this.artisanName,
  });

  @override
  State<AvisScreen> createState() => _AvisScreenState();
}

class _AvisScreenState extends State<AvisScreen> {
  final ReviewService _reviewService = ReviewService();
  final _commentController = TextEditingController();
  double _selectedRating = 0;
  bool _isSubmitting = false;
  bool _hasReviewed = false;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;
  String get _currentUserName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'Anonyme';
  String get _currentUserPhoto =>
      FirebaseAuth.instance.currentUser?.photoURL ?? '';

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyReviewed();
  }

  Future<void> _checkIfAlreadyReviewed() async {
    if (_currentUserId == null) return;
    final reviewed = await _reviewService.hasReviewed(
        _currentUserId!, widget.artisanId);
    if (mounted) setState(() => _hasReviewed = reviewed);
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      _showSnack('Veuillez sélectionner une note.', isError: true);
      return;
    }
    if (_commentController.text.trim().isEmpty) {
      _showSnack('Veuillez écrire un commentaire.', isError: true);
      return;
    }
    if (_currentUserId == null) {
      _showSnack('Vous devez être connecté.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _reviewService.addReview(ReviewModel(
        id: '',
        artisanId: widget.artisanId,
        clientId: _currentUserId!,
        clientName: _currentUserName,
        clientPhotoUrl: _currentUserPhoto,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
      ));
      _commentController.clear();
      setState(() {
        _selectedRating = 0;
        _hasReviewed = true;
      });
      _showSnack('Votre avis a été soumis avec succès !');
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Avis — ${widget.artisanName}'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // En-tête avec note globale
          _buildRatingSummary(),
          const Divider(height: 1),
          // Liste des avis
          Expanded(child: _buildReviewList()),
          // Formulaire de soumission
          if (!_hasReviewed) _buildSubmitForm(),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    return StreamBuilder<List<ReviewModel>>(
      stream: _reviewService.getReviewsForArtisan(widget.artisanId),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Aucun avis pour le moment.',
                style: TextStyle(color: Colors.grey)),
          );
        }

        final reviews = snap.data!;
        final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) /
            reviews.length;

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                children: [
                  Text(avg.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E))),
                  StarRatingWidget(rating: avg, size: 18),
                  const SizedBox(height: 4),
                  Text('${reviews.length} avis',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(child: _buildRatingBars(reviews)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingBars(List<ReviewModel> reviews) {
    return Column(
      children: List.generate(5, (i) {
        final star = 5 - i;
        final count = reviews.where((r) => r.rating.round() == star).length;
        final percent = reviews.isEmpty ? 0.0 : count / reviews.length;
        return Row(
          children: [
            Text('$star', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.star, size: 12, color: Color(0xFFFFB300)),
            const SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE0E0E0),
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFFFFB300)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 24,
              child: Text('$count',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.right),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildReviewList() {
    return StreamBuilder<List<ReviewModel>>(
      stream: _reviewService.getReviewsForArtisan(widget.artisanId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 64, color: Colors.grey),
                SizedBox(height: 8),
                Text('Aucun avis encore.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: snap.data!.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _ReviewCard(
            review: snap.data![i],
            currentUserId: _currentUserId,
            reviewService: _reviewService,
          ),
        );
      },
    );
  }

  Widget _buildSubmitForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Laisser un avis',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Votre note : '),
              StarRatingInput(
                onRatingChanged: (r) => setState(() => _selectedRating = r),
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Décrivez votre expérience...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitReview,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send),
              label: Text(_isSubmitting ? 'Envoi...' : 'Soumettre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final String? currentUserId;
  final ReviewService reviewService;

  const _ReviewCard({
    required this.review,
    required this.currentUserId,
    required this.reviewService,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId == review.clientId;
    final timeAgo = _formatDate(review.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: review.clientPhotoUrl.isNotEmpty
                    ? NetworkImage(review.clientPhotoUrl)
                    : null,
                backgroundColor: const Color(0xFF1A237E),
                child: review.clientPhotoUrl.isEmpty
                    ? Text(review.clientName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.clientName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        StarRatingWidget(rating: review.rating, size: 14),
                        const SizedBox(width: 6),
                        Text(timeAgo,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Supprimer l\'avis ?'),
                        content: const Text(
                            'Cette action est irréversible.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuler')),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Supprimer',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await reviewService.deleteReview(review.id);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment,
              style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    if (diff.inDays < 30) return 'Il y a ${diff.inDays ~/ 7} semaine(s)';
    if (diff.inDays < 365) return 'Il y a ${diff.inDays ~/ 30} mois';
    return 'Il y a ${diff.inDays ~/ 365} an(s)';
  }
}