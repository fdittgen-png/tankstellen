// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';

/// One recessed pill inside the results **summary bar** (row A, #3926).
///
/// Row A merges what used to be three stacked strips — the country/source
/// link, the fuel + radius chip row and the "Your position: GPS (1 min)"
/// bar — into a single tappable band of segments. Every segment renders
/// through this pill so they share one shape, one density and one
/// truncation rule.
///
/// The pill never grows past [maxWidth]; its label ellipsises instead, so
/// an expanded translation (de/en_XA) can never push the band into a
/// horizontal overflow at 320 dp.
class SummaryChip extends StatelessWidget {
  const SummaryChip({
    super.key,
    required this.icon,
    required this.label,
    this.semanticsLabel,
    this.emphasized = false,
    this.maxWidth = 168,
  });

  /// Leading glyph — an [Icon] or a small progress indicator.
  final Widget icon;

  /// Visible pill text.
  final String label;

  /// Screen-reader label when the visible text alone is not self-explanatory
  /// (e.g. the position segment, which reads "GPS · 1 min" visually).
  final String? semanticsLabel;

  /// Amber "needs attention" treatment — used by the freshness segment once
  /// the price list is past the staleness threshold.
  final bool emphasized;

  /// Hard ceiling for the pill width (label ellipsises inside it).
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = emphasized
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final pill = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          // #2117 — the segment sits on the bar's `surfaceContainerHighest`
          // surface; `surfaceContainerLow` is the M3 inversion that reads as
          // a recessed pill rather than fighting the bar.
          color: emphasized
              ? theme.colorScheme.tertiaryContainer
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: AppRadius.xl,
          border: Border.all(
            color: emphasized
                ? theme.colorScheme.tertiary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
    final semantics = semanticsLabel;
    if (semantics == null) return pill;
    return Semantics(label: semantics, excludeSemantics: true, child: pill);
  }
}
