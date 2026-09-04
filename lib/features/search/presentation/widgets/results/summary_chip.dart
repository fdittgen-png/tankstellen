// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/spacing.dart';

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
///
/// #3939 (Epic #3937) — the pills now carry the **value only** (`E85`,
/// `10 km`, `1 min`): the glyph beside each one already says the noun the
/// old label repeated. Nothing is lost, because the full sentence moves
/// into [tooltip], which is also what a screen reader announces.
/// #3948 (Epic #3947) — the pill is the grammar's **summary** chip role:
/// tonal (`secondaryContainer`), borderless, `labelSmall`, 8 dp padding.
/// It is *read*, not pressed, and must look unlike a choice chip (outlined,
/// `primaryContainer` when selected) so a summary of the search can never
/// be mistaken for a filter that is still selectable.
class SummaryChip extends StatelessWidget {
  const SummaryChip({
    super.key,
    required this.icon,
    required this.label,
    this.tooltip,
    this.semanticsLabel,
    this.emphasized = false,
    this.maxWidth = 168,
  });

  /// Leading glyph — an [Icon] or a small progress indicator.
  final Widget icon;

  /// Visible pill text — the VALUE alone since #3939.
  final String label;

  /// The full sentence the visible value is the short form of ("Within
  /// 10 km"). Shown on long-press and, unless [semanticsLabel] overrides
  /// it, announced by assistive tech — so dropping the word from the pill
  /// costs neither discoverability nor accessibility.
  final String? tooltip;

  /// Screen-reader label when neither the visible text nor [tooltip] is
  /// the right thing to announce (e.g. the position segment, which reads
  /// "GPS · 1 min" visually). Defaults to [tooltip].
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
        : theme.colorScheme.onSecondaryContainer;
    final pill = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: Spacing.chipPadding,
        decoration: BoxDecoration(
          // #3948 — a tonal, borderless read-only pill. The emphasized
          // (stale-prices) state keeps its amber tertiary tone.
          color: emphasized
              ? theme.colorScheme.tertiaryContainer
              : theme.colorScheme.secondaryContainer,
          borderRadius: AppRadius.xl,
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
    final message = tooltip;
    final Widget decorated = message == null
        ? pill
        : Tooltip(message: message, child: pill);
    final semantics = semanticsLabel ?? tooltip;
    if (semantics == null) return decorated;
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: decorated,
    );
  }
}
