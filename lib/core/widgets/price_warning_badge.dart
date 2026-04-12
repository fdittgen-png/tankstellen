import 'package:flutter/material.dart';

import '../services/price_sanity.dart';

/// A small warning badge shown next to suspicious prices.
///
/// Displays a ⚠️ icon with a tooltip explaining why the price was flagged.
class PriceWarningBadge extends StatelessWidget {
  final PriceSanityResult result;

  const PriceWarningBadge({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result == PriceSanityResult.ok) return const SizedBox.shrink();

    final (icon, color, tooltip) = switch (result) {
      PriceSanityResult.suspiciousLow => (
          Icons.warning_amber,
          Colors.orange,
          'Unusually low price — may be outdated',
        ),
      PriceSanityResult.suspiciousHigh => (
          Icons.warning_amber,
          Colors.red,
          'Unusually high price — verify before visiting',
        ),
      PriceSanityResult.aboveAverage => (
          Icons.trending_up,
          Colors.orange,
          'Above average for this search',
        ),
      PriceSanityResult.ok => (Icons.check, Colors.green, ''),
    };

    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 14, color: color),
    );
  }
}
