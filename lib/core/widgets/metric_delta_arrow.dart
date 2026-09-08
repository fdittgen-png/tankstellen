// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/dark_mode_colors.dart';

/// The up/down arrow beside a metric delta (#3983).
///
/// Three private copies had diverged — different flat thresholds, different
/// sizes, one comparing two averages, one with a "neutral" sentiment — so
/// the same change read differently on the month table, the efficiency rows
/// and the carbon card. One widget, with the divergence as parameters, all
/// primitives so any feature can use it without importing another's types.
///
/// Semantics follow the design system's status trio: with [lowerIsBetter]
/// an increase is [DarkModeColors.error]-red and a decrease
/// [DarkModeColors.success]-green; [neutral] paints both directions in
/// `onSurfaceVariant` for a metric with no better direction (a count, a
/// distance). A delta whose magnitude is below [flatBelow] renders nothing.
class MetricDeltaArrow extends StatelessWidget {
  const MetricDeltaArrow({
    super.key,
    required this.delta,
    this.lowerIsBetter = true,
    this.neutral = false,
    this.flatBelow = 0,
    this.size = 16,
  });

  /// Current minus previous. Sign decides the arrow's direction.
  final num delta;

  /// `true` for consumption, cost, CO₂ — an increase is bad.
  final bool lowerIsBetter;

  /// A metric with no better direction: both arrows muted.
  final bool neutral;

  /// Magnitudes below this show nothing (rounding noise).
  final double flatBelow;

  /// Icon size in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    if (delta.abs() < flatBelow) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final up = delta > 0;
    final Color color;
    if (neutral) {
      color = theme.colorScheme.onSurfaceVariant;
    } else {
      final bad = up == lowerIsBetter;
      color = bad ? theme.colorScheme.error : DarkModeColors.success(context);
    }
    return Icon(
      up ? Icons.arrow_upward : Icons.arrow_downward,
      size: size,
      color: color,
    );
  }
}
