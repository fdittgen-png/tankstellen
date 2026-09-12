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
/// #3957 — the band is a ONE-LINE band: the pills are dense
/// ([Spacing.pillPadding], 8/2), capped at 132, and a segment whose glyph
/// already says everything renders glyph-only ([labelVisible] false). Every
/// dp of band height is list height.
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
    this.labelVisible = true,
    this.maxWidth = 132,
    this.onTap,
    this.trailing,
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

  /// #3957 — when false the pill renders its glyph ALONE. The value still
  /// reaches the user through [tooltip] and the screen-reader label, so a
  /// segment whose glyph already says the whole thing (the radar badge)
  /// costs one icon of width instead of a whole band line. Never set this
  /// on a pill carrying a VALUE the glyph cannot express (a price, a
  /// radius, a fuel code).
  final bool labelVisible;

  /// Amber "needs attention" treatment — used by the freshness segment once
  /// the price list is past the staleness threshold.
  final bool emphasized;

  /// Hard ceiling for the pill width (label ellipsises inside it).
  final double maxWidth;

  /// #3955 — a pill that is itself a link (the open-data source credit).
  /// The band around the pills opens the criteria sheet; an inner tap
  /// target wins the gesture arena, so this pill can lead somewhere else
  /// without the band losing its own tap.
  final VoidCallback? onTap;

  /// Optional trailing glyph after the label — the `open_in_new`
  /// affordance of a link pill.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // #4094 — an ordinary segment is TEXT on the band, not a filled
    // surface. Four tonal pills in a row, above a list of filled cards,
    // above a filled navigation bar, is how the screen became a stack of
    // surfaces with no hierarchy left to spend. The emphasized
    // (stale-prices) state keeps its amber fill, which is the point: a
    // fill now means something, because only one thing has it.
    final foreground = emphasized
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final pill = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: Spacing.pillPadding,
        decoration: BoxDecoration(
          // #3948 made these tonal and borderless; #4094 drops the tone
          // from every segment but the one that is an attention state.
          color: emphasized
              ? theme.colorScheme.tertiaryContainer
              : Colors.transparent,
          borderRadius: AppRadius.xl,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            if (labelVisible) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: foreground),
                ),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 3), trailing!],
          ],
        ),
      ),
    );
    final tap = onTap;
    final Widget tappable = tap == null
        ? pill
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: tap,
            child: pill,
          );
    final message = tooltip;
    final Widget decorated = message == null
        ? tappable
        : Tooltip(message: message, child: tappable);
    // A glyph-only pill has no visible text, so its [label] is the last
    // resort for assistive tech — it must never announce nothing.
    final semantics =
        semanticsLabel ?? tooltip ?? (labelVisible ? null : label);
    if (semantics == null) return decorated;
    return Semantics(
      label: semantics,
      link: tap != null,
      excludeSemantics: true,
      child: decorated,
    );
  }
}
