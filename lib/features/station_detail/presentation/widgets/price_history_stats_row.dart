// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../price_history/domain/entities/price_stats.dart';

/// Honest min / max / average / delta row for the station-detail price
/// history (#3928, epic #3925).
///
/// Two lies of the shared `PriceStatsCard` are fixed here:
///
///  1. **Colour.** It painted Min green and Max red unconditionally, so a
///     station with a single observed price rendered `Min 2,329 €` in
///     green next to `Max 2,329 €` in red — the same number, coloured as
///     if it were a spread. Min/Max only carry colour when they actually
///     differ; equal values render in the neutral `onSurface`.
///  2. **The trend arrow.** `↑` next to the current price had no visible
///     reference. It is replaced by an explicit delta against the OLDEST
///     observation of the window the chart draws: `+0.03 € since Aug 21,
///     2026`, or `Unchanged since …` when the two match.
///
/// The four figures sit in a [Wrap], not a fixed [Row]: at 320 dp under
/// an expanded translation four labelled columns cannot share one line,
/// and wrapping beats an overflow stripe.
class PriceHistoryStatsRow extends StatelessWidget {
  /// Aggregate min/max/avg/current for the selected fuel.
  final PriceStats stats;

  /// Price of the oldest plottable point in the displayed window, and
  /// when it was observed. Null hides the delta line.
  final double? windowStartPrice;
  final DateTime? windowStartAt;

  const PriceHistoryStatsRow({
    super.key,
    required this.stats,
    this.windowStartPrice,
    this.windowStartAt,
  });

  /// Below this the two prices are the same money — 0.05 cent is finer
  /// than any pump ever posts.
  static const double _epsilon = 0.0005;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final neutral = theme.colorScheme.onSurface;

    // The spread is only real information when the two ends differ.
    final min = stats.min;
    final max = stats.max;
    final spread = min != null && max != null && (max - min).abs() >= _epsilon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _Stat(
              valueKey: statValueKey('min'),
              label: l10n.priceStatsMin,
              value: PriceFormatter.formatPrice(min),
              color: spread ? DarkModeColors.success(context) : neutral,
            ),
            _Stat(
              valueKey: statValueKey('max'),
              label: l10n.priceStatsMax,
              value: PriceFormatter.formatPrice(max),
              color: spread ? DarkModeColors.error(context) : neutral,
            ),
            _Stat(
              valueKey: statValueKey('avg'),
              label: l10n.priceStatsAvg,
              value: PriceFormatter.formatPrice(stats.avg),
              color: neutral,
            ),
            _Stat(
              valueKey: statValueKey('current'),
              label: l10n.priceStatsCurrent,
              value: PriceFormatter.formatPrice(stats.current),
              color: neutral,
              bold: true,
            ),
          ],
        ),
        if (_deltaLine(context, l10n) case final line?) ...[
          const SizedBox(height: 6),
          line,
        ],
      ],
    );
  }

  /// `↑ +0.03 € since Aug 21, 2026` — the reference the bare arrow never
  /// gave. Null when there is nothing to compare against.
  Widget? _deltaLine(BuildContext context, AppLocalizations l10n) {
    final current = stats.current;
    final start = windowStartPrice;
    final startAt = windowStartAt;
    if (current == null || start == null || startAt == null) return null;

    final since = UnitFormatter.formatMediumDate(
      startAt,
      locale: Localizations.localeOf(context).toString(),
    );
    final diff = current - start;
    final theme = Theme.of(context);

    final (IconData icon, Color color, String text) = switch (diff) {
      _ when diff >= _epsilon => (
          Icons.trending_up,
          DarkModeColors.error(context),
          l10n.priceHistoryDeltaSince(_signed(diff), since),
        ),
      _ when diff <= -_epsilon => (
          Icons.trending_down,
          DarkModeColors.success(context),
          l10n.priceHistoryDeltaSince(_signed(diff), since),
        ),
      _ => (
          Icons.trending_flat,
          theme.colorScheme.onSurfaceVariant,
          l10n.priceHistoryUnchangedSince(since),
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }

  /// `+0.03 €` / `−0.03 €` — the magnitude through the country-aware
  /// price formatter, the sign as a language-neutral numeric glyph
  /// (U+2212 minus so it lines up with the plus), never prose.
  static String _signed(double diff) =>
      '${diff >= 0 ? '+' : '−'}${PriceFormatter.formatPrice(diff.abs())}';
}

/// Widget key of one figure's VALUE text, so a test can read the colour
/// the figure was painted in without matching on a number that repeats
/// across columns (Min and Max are the same string when they are equal
/// — which is exactly the case #3928 is about).
ValueKey<String> statValueKey(String stat) =>
    ValueKey<String>('price-history-stat-$stat');

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;
  final Key valueKey;

  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    required this.valueKey,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          key: valueKey,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
