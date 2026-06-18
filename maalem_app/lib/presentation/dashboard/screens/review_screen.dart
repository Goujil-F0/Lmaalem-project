import 'package:flutter/material.dart';
import 'package:maalem_app/core/constants/app_colors.dart';
import 'package:maalem_app/data/services/review_service.dart';
import 'package:maalem_app/presentation/dashboard/widgets/star_rating_widget.dart';
import 'package:maalem_app/providers/auth_provider.dart';
import 'package:maalem_app/shared/widgets/maalem_app_bar.dart';
import 'package:provider/provider.dart';

class ReviewScreen extends StatefulWidget {
  final int bookingId;
  final int artisanId;
  final String artisanName;

  const ReviewScreen({
    super.key,
    required this.bookingId,
    required this.artisanId,
    required this.artisanName,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  void _handleRatingChanged(double value) {
    setState(() => _rating = value);
  }

  Future<void> _showThankYouDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.24),
                      width: 2.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFFFB300),
                    size: 46,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Avis Enregistré !',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Merci pour votre évaluation de ${_rating.toInt()} étoiles. Votre avis aide la communauté à choisir le bon artisan et permet à ${widget.artisanName} de s\'améliorer.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une note en cliquant ou faisant glisser'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null || token.isEmpty) {
        throw Exception('Utilisateur non connecté');
      }

      final service = ReviewService(token: token);
      await service.addReview(
        bookingId: widget.bookingId,
        artisanId: widget.artisanId,
        rating: _rating.toInt(),
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        await _showThankYouDialog();
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: MaalemAppBar(
        title: 'Laisser un Avis',
        subtitle: widget.artisanName,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: AppColors.navy.withValues(alpha: 0.04),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    width: 2.5,
                  ),
                ),
                child: const Icon(
                  Icons.handyman_rounded,
                  size: 36,
                  color: AppColors.teal,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Évaluer ${widget.artisanName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navy,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Votre avis aide la communauté à choisir le bon maalem et valorise son travail.',
                style: TextStyle(
                  color: AppColors.textGrey,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              StarRatingInput(
                initialRating: _rating,
                onRatingChanged: _handleRatingChanged,
                size: 46,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _rating == 0
                      ? Colors.grey.shade100
                      : const Color(0xFFFFB300).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _rating == 0 ? 'Faites glisser ou touchez les étoiles' : _ratingLabel(),
                  style: TextStyle(
                    color: _rating == 0
                        ? AppColors.textGrey
                        : const Color(0xFFD68A00),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 500,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Décrivez la qualité du travail, le respect du délai, la propreté...',
                  hintStyle: TextStyle(
                    color: AppColors.textGrey.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: AppColors.beige.withValues(alpha: 0.25),
                  counterStyle: const TextStyle(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w700,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.teal.withValues(alpha: 0.15),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.teal.withValues(alpha: 0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.teal, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitReview,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: const Text('Soumettre mon avis'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shadowColor: AppColors.navy.withValues(alpha: 0.25),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel() {
    if (_rating >= 5) return 'Excellent (5/5)';
    if (_rating >= 4) return 'Très bien (4/5)';
    if (_rating >= 3) return 'Correct (3/5)';
    if (_rating >= 2) return 'À améliorer (2/5)';
    return 'Mauvaise expérience (1/5)';
  }
}
