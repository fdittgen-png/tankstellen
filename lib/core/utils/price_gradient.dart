// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// Normalized 0..1 position of [price] within the [min]..[max] range.
///
/// Returns 0 for a degenerate range (`max <= min`). Shared by the marker
/// colour gradient and the price-tier classifier so colour and tier use
/// one normalization (#2196).
double normalizedPrice(double price, double min, double max) {
  if (max <= min) return 0;
  return ((price - min) / (max - min)).clamp(0.0, 1.0);
}

/// Four-stop price gradient: `stops[0]` (cheapest) → `stops[3]` (most
/// expensive), with breakpoints at 1/3 and 2/3 of the range.
///
/// Returns [nullColor] when [price] is null and [flatColor] when the
/// range is degenerate (`max <= min`). Callers pass their own palette and
/// fallbacks so each marker style keeps its exact colours (#2196).
Color priceGradientColor(
  double? price,
  double min,
  double max, {
  required List<Color> stops,
  required Color nullColor,
  required Color flatColor,
}) {
  if (price == null) return nullColor;
  if (max <= min) return flatColor;
  final t = normalizedPrice(price, min, max);
  if (t < 0.33) return Color.lerp(stops[0], stops[1], t / 0.33)!;
  if (t < 0.66) return Color.lerp(stops[1], stops[2], (t - 0.33) / 0.33)!;
  return Color.lerp(stops[2], stops[3], (t - 0.66) / 0.34)!;
}
