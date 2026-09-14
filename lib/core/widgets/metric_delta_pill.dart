// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_text.dart';
import '../theme/dark_mode_colors.dart';

/// A metric's change as a tinted pill (#4175) — the direction glyph and
/// the percentage in one tonal container, instead of a bare arrow with
/// the percentage parked in grey text elsewhere in the row.
///
/// A SIBLING of `MetricDeltaArrow`, not a replacement for it: the arrow
/// is still right where there is no percentage to show (the efficiency
/// rows, the trip-length breakdown), and duplicating its sentiment rules
/// here rather than wrapping it keeps each widget readable on its own.
/// The rules are identical and both are tested: with [lowerIsBetter] an
/// increase is error-red and a decrease success-green; [neutral] mutes
/// both for a metric with no better direction. A magnitude below
/// [flatBelow] renders nothing at all — a displayed-equal pair must
/// never sprout a coloured badge.
///
/// ## Why a pill rather than the arrow it replaces
///
/// The arrow says WHICH WAY. The number beside it said how much, in the
/// label role, under the previous month's figure — two glances and a
/// mental join to answer one question. A pill answers it in one, and its
/// tint does the direction so the glyph is reinforcement rather than the
/// only signal.
///
/// ## The constraint that shaped it
///
/// This lives in a table pinned at 320 dp / en_XA / 1.3× by #3950, and a
/// pill is wider than an arrow. So the percentage LEAVES the previous
/// column as it arrives here: the row spends its width once, not twice.
/// [MetricDeltaPill] also drops its glyph when [compact] is set, for the
/// narrowest case, because the colour already carries the direction and
/// a truncated number would not.
class MetricDeltaPill extends StatelessWidget {
  const MetricDeltaPill({
    super.key,
    required this.delta,
    required this.percentText,
    this.lowerIsBetter = true,
    this.neutral = false,
    this.flatBelow = 0,
    this.compact = false,
  });

  /// Current minus previous. Sign decides direction and tint.
  final num delta;

  /// The already-formatted change (e.g. `+133%`), or null when the
  /// previous figure was zero and a percentage would be meaningless.
  final String? percentText;

  /// `true` for consumption, cost, CO₂ — an increase is bad.
  final bool lowerIsBetter;

  /// A metric with no better direction: muted, not green or red.
  final bool neutral;

  /// Magnitudes below this show nothing (rounding noise).
  final double flatBelow;

  /// Drop the direction glyph and keep only the tinted number.
  final bool compact;

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
    final text = percentText;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.md,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: text == null ? 4 : 6,
          vertical: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact || text == null)
              Icon(
                up ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: color,
              ),
            if (text != null) ...[
              if (!compact) const SizedBox(width: 2),
              Text(
                text,
                maxLines: 1,
                softWrap: false,
                style: AppText.label(context).copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [AppText.tabularFigures],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
