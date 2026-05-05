import 'package:flutter/material.dart';
import 'package:maalem_app/data/services/review_service.dart';
import 'package:maalem_app/presentation/dashboard/widgets/star_rating_widget.dart';

class ReviewScreen extends StatefulWidget {
  final int bookingId;
  final int artisanId;
  final String artisanName;
  final String token;

  const ReviewScreen({
    super.key,
    required this.bookingId,
    required this.artisanId,
    required this.artisanName,
    required this.token,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une note')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ReviewService(token: widget.token);
      await service.addReview(
        bookingId: widget.bookingId,
        artisanId: widget.artisanId,
        rating: _rating.toInt(),
        comment: _commentController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avis envoyé avec succès !'),
            backgroundColor: Color(0xFF296374),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDCE),
      appBar: AppBar(
        title: Text('Avis sur ${widget.artisanName}'),
        backgroundColor: const Color(0xFF0C2C55),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF629FAD).withOpacity(0.2),
              child: const Icon(Icons.person, size: 50, color: Color(0xFF296374)),
            ),
            const SizedBox(height: 16),
            Text(
              'Comment s\'est passée votre expérience avec ${widget.artisanName} ?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C2C55),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            StarRatingInput(
              initialRating: _rating,
              onRatingChanged: (value) => setState(() => _rating = value),
              size: 48,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Écrivez votre commentaire...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF296374)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF296374),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Envoyer l\'avis',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}