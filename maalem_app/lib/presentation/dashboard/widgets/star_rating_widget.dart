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
    this.activeColor = const Color(0xFFFFB300), // Gold premium
    this.inactiveColor = const Color(0xFFE0E0E6),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final full = index + 1 <= rating.floor();
        final half = !full && index < rating && rating - index >= 0.5;
        return Icon(
          full
              ? Icons.star_rounded
              : (half ? Icons.star_half_rounded : Icons.star_outline_rounded),
          color: (full || half) ? activeColor : inactiveColor,
          size: size,
        );
      }),
    );
  }
}

/// Widget interactif pour sélectionner une note (avec tap et glissement)
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
  static const double _spacing = 6.0;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  void _updateRatingFromPosition(Offset localPosition) {
    final starWidth = widget.size + _spacing;
    double index = localPosition.dx / starWidth;
    double newRating = (index + 1).floorToDouble();
    if (newRating < 1.0) newRating = 1.0;
    if (newRating > 5.0) newRating = 5.0;

    if (newRating != _rating) {
      setState(() => _rating = newRating);
      widget.onRatingChanged(_rating);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        _updateRatingFromPosition(details.localPosition);
      },
      onHorizontalDragUpdate: (details) {
        _updateRatingFromPosition(details.localPosition);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final filled = index < _rating;
          return Padding(
            padding: EdgeInsets.only(right: index == 4 ? 0 : _spacing),
            child: GestureDetector(
              onTap: () {
                setState(() => _rating = index + 1.0);
                widget.onRatingChanged(_rating);
              },
              child: AnimatedScale(
                scale: filled ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  key: ValueKey('$index-$filled'),
                  color: filled
                      ? const Color(0xFFFFB300)
                      : const Color(0xFFD0D0DB),
                  size: widget.size,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}