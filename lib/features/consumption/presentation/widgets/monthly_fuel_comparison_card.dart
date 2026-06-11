// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/services/fill_up_monthly_stats_aggregator.dart';

/// "This month vs last month" card for the consumption-statistics page
/// (#2698). Mirrors the Trajets `MonthlyInsightsCard` machinery
/// (`_MetricRow` / `_DeltaArrow` / `_Sentiment`) but compares fill-up
/// metrics: total litres, total spent, average price/L, average
/// L/100km, average cost/km, and fill-ups.
///
/// Δ = current − previous; the percentage is `(Δ / previous) × 100`,
/// suppressed when the previous figure is zero. Sentiment bands:
///   * litres / spent / count → neutral (more activity isn't good/bad)
///   * price/L + L/100km + cost/km → lowerIsBetter (down = success).
///
/// When fewer than two calendar months of data exist the previous
/// column + arrows are hidden and a caption explains why; the current
/// month's figures still render so a single month is never blank.
class MonthlyFuelComparisonCard extends StatelessWidget {
  /// Per-month stats, oldest first — straight from `monthlyFuelStats`.
  final List<MonthlyFuelStats> months;

  const MonthlyFuelComparisonCard({super.key, required this.months});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final hasComparison = months.length >= 2;
    final current = months.isNotEmpty ? months.last.stats : null;
    final previous = hasComparison ? months[months.length - 2].stats : null;

    final rows = <Widget>[
      _row(
        context,
        label: l.statTotalLiters,
        current: current?.totalLiters,
        previous: previous?.totalLiters,
        format: _fmtLiters,
        sentiment: _Sentiment.neutral,
        showPrevious: hasComparison,
      ),
      _row(
        context,
        label: l.statTotalSpent,
        current: current?.totalSpent,
        previous: previous?.totalSpent,
        format: PriceFormatter.formatTotal,
        sentiment: _Sentiment.neutral,
        showPrevious: hasComparison,
      ),
      _row(
        context,
        label: l.consumptionStatsPricePerLiter,
        current: current?.avgPricePerLiter,
        previous: previous?.avgPricePerLiter,
        format: PriceFormatter.formatPriceCompact,
        sentiment: _Sentiment.lowerIsBetter,
        showPrevious: hasComparison,
      ),
      _row(
        context,
        label: l.statAvgConsumption,
        current: current?.avgConsumptionL100km,
        previous: previous?.avgConsumptionL100km,
        format: _fmtConsumption,
        sentiment: _Sentiment.lowerIsBetter,
        showPrevious: hasComparison,
      ),
      _row(
        context,
        label: l.statAvgCostPerKm,
        current: current?.avgCostPerKm,
        previous: previous?.avgCostPerKm,
        format: PriceFormatter.formatPerKm,
        sentiment: _Sentiment.lowerIsBetter,
        showPrevious: hasComparison,
      ),
      _row(
        context,
        label: l.statFillUpCount,
        current: current?.fillUpCount.toDouble(),
        previous: previous?.fillUpCount.toDouble(),
        format: _fmtCount,
        sentiment: _Sentiment.neutral,
        showPrevious: hasComparison,
      ),
    ];

    return Card(
      key: const ValueKey('monthly_fuel_comparison_card'),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.consumptionStatsComparisonTitle,
              style: theme.textTheme.titleMedium,
            ),
            if (!hasComparison) ...[
              const SizedBox(height: 4),
              Text(
                l.consumptionStatsNeedTwoMonths,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            for (final row in rows) ...[row, const SizedBox(height: 6)],
          ],
        ),
      ),
    );
  }

  /// Build a [_MetricRow]. When [current] is null the row is skipped via
  /// an em-dash; when [previous] is null (or [showPrevious] false) the
  /// previous column + arrows are hidden. The percentage is suppressed
  /// when the previous value is zero (division by zero) or absent.
  Widget _row(
    BuildContext context, {
    required String label,
    required double? current,
    required double? previous,
    required String Function(double?) format,
    required _Sentiment sentiment,
    required bool showPrevious,
  }) {
    final l = AppLocalizations.of(context);
    final delta = (current != null && previous != null)
        ? current - previous
        : 0.0;
    String? percentText;
    if (showPrevious && current != null && previous != null && previous != 0) {
      final pct = (current - previous) / previous * 100;
      final sign = pct > 0 ? '+' : '';
      // i18n-ignore: numeric value forwarded into the ARB {pct} mask.
      final value = '$sign${pct.toStringAsFixed(0)}';
      percentText = l.consumptionStatsDeltaPercent(value);
    }
    return _MetricRow(
      label: label,
      currentValue: current != null ? format(current) : '—',
      previousValue: previous != null ? format(previous) : '—',
      percentText: percentText,
      delta: delta,
      sentiment: sentiment,
      // Hide the previous column when there is no comparison OR when
      // this specific metric has no previous figure (e.g. L/100km with
      // no closed window in the prior month).
      showPrevious: showPrevious && previous != null,
    );
  }
}

String _fmtLiters(double? v) => v == null ? '—' : v.toStringAsFixed(1);

String _fmtConsumption(double? v) => v == null ? '—' : v.toStringAsFixed(1);

String _fmtCount(double? v) => v == null ? '—' : v.round().toString();

/// Sentiment band for the trailing delta arrow. `neutral` renders grey
/// regardless of direction; `lowerIsBetter` is for fuel — down green, up
/// red. Mirrors `MonthlyInsightsCard._Sentiment`.
enum _Sentiment { neutral, lowerIsBetter }

/// One labelled row: label, bold current value, muted previous value +
/// percentage (when [showPrevious]), and a trailing delta arrow. Mirrors
/// `MonthlyInsightsCard._MetricRow`.
class _MetricRow extends StatelessWidget {
  final String label;
  final String currentValue;
  final String previousValue;
  final String? percentText;
  final double delta;
  final _Sentiment sentiment;
  final bool showPrevious;

  const _MetricRow({
    required this.label,
    required this.currentValue,
    required this.previousValue,
    required this.percentText,
    required this.delta,
    required this.sentiment,
    required this.showPrevious,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            currentValue,
            textAlign: TextAlign.end,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (showPrevious) ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  previousValue,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (percentText != null)
                  Text(
                    percentText!,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 20,
            child: _DeltaArrow(delta: delta, sentiment: sentiment),
          ),
        ],
      ],
    );
  }
}

/// Trailing arrow. Hidden when the rounded delta is ~0. Colour follows
/// [sentiment]: neutral → grey; lowerIsBetter → up = error, down =
/// success. Mirrors `MonthlyInsightsCard._DeltaArrow`.
class _DeltaArrow extends StatelessWidget {
  final double delta;
  final _Sentiment sentiment;

  const _DeltaArrow({required this.delta, required this.sentiment});

  @override
  Widget build(BuildContext context) {
    // Treat sub-0.005 swings as flat so a rounded-equal display doesn't
    // sprout a coloured arrow.
    if (delta.abs() < 0.005) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final up = delta > 0;
    final color = switch (sentiment) {
      _Sentiment.neutral => theme.colorScheme.onSurfaceVariant,
      _Sentiment.lowerIsBetter =>
        up ? theme.colorScheme.error : DarkModeColors.success(context),
    };
    return Icon(
      up ? Icons.arrow_upward : Icons.arrow_downward,
      size: 16,
      color: color,
    );
  }
}
