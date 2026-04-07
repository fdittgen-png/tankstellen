import 'package:flutter/material.dart';

/// Price tier classification for accessibility — ensures price levels
/// are distinguishable without relying on color alone (WCAG 1.4.1).
enum PriceTier {
  /// Bottom third of the price range.
  cheap,

  /// Middle third of the price range.
  average,

  /// Top third of the price range.
  expensive,

  /// Price is unavailable.
  unknown,
}

/// Determines the [PriceTier] for a price within a given range.
///
/// The range [minPrice]..[maxPrice] is split into three equal bands:
/// - cheap:     0%–33%
/// - average:  33%–66%
/// - expensive: 66%–100%
PriceTier priceTierOf(double? price, double minPrice, double maxPrice) {
  if (price == null) return PriceTier.unknown;
  if (maxPrice <= minPrice) return PriceTier.cheap;
  final t = ((price - minPrice) / (maxPrice - minPrice)).clamp(0.0, 1.0);
  if (t < 0.33) return PriceTier.cheap;
  if (t < 0.66) return PriceTier.average;
  return PriceTier.expensive;
}

/// Returns the icon for a given [PriceTier].
///
/// - cheap:     arrow_downward (price is low)
/// - average:   remove (dash — neutral)
/// - expensive: arrow_upward (price is high)
/// - unknown:   help_outline (no data)
IconData iconForPriceTier(PriceTier tier) => switch (tier) {
      PriceTier.cheap => Icons.arrow_downward,
      PriceTier.average => Icons.remove,
      PriceTier.expensive => Icons.arrow_upward,
      PriceTier.unknown => Icons.help_outline,
    };
