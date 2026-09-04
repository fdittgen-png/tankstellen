// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/panel_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/services/fill_up_monthly_stats_aggregator.dart';
import 'monthly_insights_table.dart';

/// "This month vs last month" panel for the consumption-statistics page
/// (#2698). Since #3950 it renders the SAME [MonthlyMetricsTable] as the
/// Trajets `MonthlyInsightsCard` (one table implementation, one
/// hierarchy) but compares fill-up metrics: total litres, total spent,
/// average price/L, average L/100km, average cost/km, and fill-ups.
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

    final metrics = <MonthlyMetric>[
      _metric(
        l,
        label: l.statTotalLiters,
        current: current?.totalLiters,
        previous: previous?.totalLiters,
        format: _fmtLiters,
        sentiment: MonthlyMetricSentiment.neutral,
        showPrevious: hasComparison,
      ),
      _metric(
        l,
        label: l.statTotalSpent,
        current: current?.totalSpent,
        previous: previous?.totalSpent,
        format: PriceFormatter.formatTotal,
        sentiment: MonthlyMetricSentiment.neutral,
        showPrevious: hasComparison,
      ),
      _metric(
        l,
        label: l.consumptionStatsPricePerLiter,
        current: current?.avgPricePerLiter,
        previous: previous?.avgPricePerLiter,
        format: PriceFormatter.formatPriceCompact,
        sentiment: MonthlyMetricSentiment.lowerIsBetter,
        showPrevious: hasComparison,
      ),
      _metric(
        l,
        label: l.statAvgConsumption,
        current: current?.avgConsumptionL100km,
        previous: previous?.avgConsumptionL100km,
        format: _fmtConsumption,
        sentiment: MonthlyMetricSentiment.lowerIsBetter,
        showPrevious: hasComparison,
      ),
      _metric(
        l,
        label: l.statAvgCostPerKm,
        current: current?.avgCostPerKm,
        previous: previous?.avgCostPerKm,
        format: PriceFormatter.formatPerKm,
        sentiment: MonthlyMetricSentiment.lowerIsBetter,
        showPrevious: hasComparison,
      ),
      _metric(
        l,
        label: l.statFillUpCount,
        current: current?.fillUpCount.toDouble(),
        previous: previous?.fillUpCount.toDouble(),
        format: _fmtCount,
        sentiment: MonthlyMetricSentiment.neutral,
        showPrevious: hasComparison,
      ),
    ];

    return PanelCard(
      key: const ValueKey('monthly_fuel_comparison_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.consumptionStatsComparisonTitle,
            style: AppText.title(context),
          ),
          if (!hasComparison) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              l.consumptionStatsNeedTwoMonths,
              style: AppText.label(context).copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: Spacing.md),
          MonthlyMetricsTable(
            metrics: metrics,
            showPreviousColumn: hasComparison,
          ),
        ],
      ),
    );
  }

  /// Build one [MonthlyMetric]. When [current] is null the value is an
  /// em-dash; when [previous] is null (or [showPrevious] false) the
  /// previous column + arrow are hidden for this row. The percentage is
  /// suppressed when the previous value is zero (division by zero) or
  /// absent.
  MonthlyMetric _metric(
    AppLocalizations l, {
    required String label,
    required double? current,
    required double? previous,
    required String Function(double?) format,
    required MonthlyMetricSentiment sentiment,
    required bool showPrevious,
  }) {
    final delta = (current != null && previous != null)
        ? current - previous
        : 0.0;
    String? percentText;
    if (showPrevious && current != null && previous != null && previous != 0) {
      final pct = (current - previous) / previous * 100;
      final sign = pct > 0 ? '+' : '';
      // i18n-ignore: numeric value forwarded into the ARB {pct} mask.
      final value = '$sign${UnitFormatter.formatDecimal(pct, fractionDigits: 0)}';
      percentText = l.consumptionStatsDeltaPercent(value);
    }
    return MonthlyMetric(
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

String _fmtLiters(double? v) =>
    v == null ? '—' : UnitFormatter.formatDecimal(v);

String _fmtConsumption(double? v) =>
    v == null ? '—' : UnitFormatter.formatDecimal(v);

String _fmtCount(double? v) => v == null ? '—' : v.round().toString();
