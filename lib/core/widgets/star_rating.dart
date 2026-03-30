import 'package:flutter/material.dart';

/// Interactive 5-star rating widget.
class StarRating extends StatelessWidget {
  final int? rating;
  final ValueChanged<int> onRatingChanged;
  final double starSize;

  const StarRating({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.starSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isFilled = rating != null && starNumber <= rating!;
        return GestureDetector(
          onTap: () => onRatingChanged(starNumber),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isFilled ? Icons.star : Icons.star_border,
              color: isFilled ? Colors.amber : Colors.grey.shade400,
              size: starSize,
            ),
          ),
        );
      }),
    );
  }
}
