// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// The ONE canonical cheap→expensive price-band colour ramp (#2492).
///
/// Before this, the map markers ([StationMarkerBuilder]) used
/// `[green, yellow, orange, red]` while the [PriceLegend] used a 3-stop
/// success/warning/error gradient with no yellow — two divergent
/// price-colour systems. Both now consume [PriceBandColors.ramp] so the
/// legend always describes exactly what the markers paint.
///
/// The stops are tuned for colourblind safety:
/// - The middle "average" stop replaces pure `Colors.yellow` (`#FFEB00`),
///   which is near-invisible on the white-bordered marker bubbles, with a
///   saturated amber `#F9A825` that reads clearly against white and is
///   well separated in luminance from both the cheap green and the
///   expensive red (amber L≈0.48 vs red L≈0.14).
/// - These are fill colours sitting behind dark marker text and rendered
///   as standalone legend swatches, so the bright amber is intentional;
///   the *semantic* `warning` text token in [DarkModeColors] darkens the
///   same hue to keep AA contrast as text.
class PriceBandColors {
  PriceBandColors._();

  /// Cheap (bottom third). Green = good, mirrors the brand-green leitmotiv.
  static const Color cheap = Color(0xFF43A047); // green.shade600

  /// Lower-middle pivot toward "average".
  static const Color belowAverage = Color(0xFFF9A825); // amber.shade800

  /// Upper-middle pivot toward "expensive".
  static const Color aboveAverage = Color(0xFFF57C00); // orange.shade700

  /// Expensive (top third). Red = costly.
  static const Color expensive = Color(0xFFC62828); // red.shade800

  /// The canonical 4-stop ramp consumed by both the map markers and the
  /// legend. Breakpoints at 1/3 and 2/3 of the price range (see
  /// `priceGradientColor` / `priceTierOf`).
  static const List<Color> ramp = [
    cheap,
    belowAverage,
    aboveAverage,
    expensive,
  ];

  /// Representative colour for each of the three price tiers the legend
  /// shows (cheap / average / expensive). The "average" swatch samples the
  /// midpoint of the ramp (between [belowAverage] and [aboveAverage]) so
  /// the legend mirrors what `priceTierOf` classifies as the middle band.
  static const Color cheapTier = cheap;
  static Color get averageTier =>
      Color.lerp(belowAverage, aboveAverage, 0.5)!;
  static const Color expensiveTier = expensive;
}
