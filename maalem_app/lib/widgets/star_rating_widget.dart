import 'package:flutter/material.dart';

class StarRatingWidget extends StatelessWidget {
  final double rating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.size = 20,
    this.activeColor = const Color(0xFFFFB300),
    this.inactiveColor = const Color(0xFFE0E0E0),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final full = index + 1 <= rating.floor();
        final half = !full && index < rating && rating - index >= 0.5;
        return Icon(
          full ? Icons.star : (half ? Icons.star_half : Icons.star_border),
          color: (full || half) ? activeColor : inactiveColor,
          size: size,
        );
      }),
    );
  }
}

/// Widget interactif pour sélectionner une note
class StarRatingInput extends StatefulWidget {
  final double initialRating;
  final void Function(double) onRatingChanged;
  final double size;

  const StarRatingInput({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 36,
  });

  @override
  State<StarRatingInput> createState() => _StarRatingInputState();
}

class _StarRatingInputState extends State<StarRatingInput> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < _rating;
        return GestureDetector(
          onTap: () {
            setState(() => _rating = index + 1.0);
            widget.onRatingChanged(_rating);
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              filled ? Icons.star : Icons.star_border,
              key: ValueKey('$index-$filled'),
              color: filled ? const Color(0xFFFFB300) : const Color(0xFFBDBDBD),
              size: widget.size,
            ),
          ),
        );
      }),
    );
  }
}