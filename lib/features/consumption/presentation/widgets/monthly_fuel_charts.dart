// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../carbon/domain/monthly_summary.dart';
import '../../../carbon/presentation/widgets/monthly_bar_chart.dart';
import '../../domain/services/fill_up_monthly_stats_aggregator.dart';

/// Per-metric monthly evolution bar charts for the consumption-statistics
/// page (#2698).
///
/// Reuses the carbon dashboard's [MonthlyBarChart] (CustomPaint, generic
/// over a [MonthlySummary] + `valueOf` extractor — the repo carries no
/// fl_chart). Each metric builds a thin [MonthlySummary] adapter list and
/// swaps the `valueOf` closure, exactly as `ChartsTab` does for cost +
/// CO2.
///
/// Litres, spend and price/L are always available, so their charts span
/// every month. Average L/100km only materialises when a closed
/// plein-to-plein window falls inside a month, so that chart is built
/// from the null-skipped subset and is omitted entirely when no month
/// has a figure.
class MonthlyFuelCharts extends StatelessWidget {
  /// Per-month stats, oldest first — straight from `monthlyFuelStats`.
  final List<MonthlyFuelStats> months;

  const MonthlyFuelCharts({super.key, required this.months});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Adapter rows where the metric of interest is stashed in
    // `totalCost`, so a single `valueOf: (s) => s.totalCost` drives the
    // chart regardless of which metric it represents. `totalLiters` is
    // also populated so the litres chart can read its natural field.
    List<MonthlySummary> rows(double Function(MonthlyFuelStats) pick) => [
      for (final m in months)
        MonthlySummary(
          month: m.month,
          totalCost: pick(m),
          totalLiters: m.stats.totalLiters,
          totalCo2Kg: 0,
          fillUpCount: m.stats.fillUpCount,
        ),
    ];

    // L/100km is null-skipped: only months with a closed window appear.
    final consumptionRows = <MonthlySummary>[
      for (final m in months)
        if (m.stats.avgConsumptionL100km != null)
          MonthlySummary(
            month: m.month,
            totalCost: m.stats.avgConsumptionL100km!,
            totalLiters: m.stats.totalLiters,
            totalCo2Kg: 0,
            fillUpCount: m.stats.fillUpCount,
          ),
    ];

    return Column(
      children: [
        _chart(
          context,
          key: const Key('monthly_litres_chart'),
          title: l?.consumptionStatsChartLiters ?? 'Litres per month',
          summaries: rows((m) => m.stats.totalLiters),
          color: theme.colorScheme.primary,
          unitLabel: 'L',
        ),
        _chart(
          context,
          key: const Key('monthly_spend_chart'),
          title: l?.consumptionStatsChartSpend ?? 'Spend per month',
          summaries: rows((m) => m.stats.totalSpent),
          color: theme.colorScheme.tertiary,
          unitLabel: PriceFormatter.currency,
        ),
        _chart(
          context,
          key: const Key('monthly_price_per_litre_chart'),
          title: l?.consumptionStatsChartPricePerLiter ?? 'Price per litre',
          summaries: rows((m) => m.stats.avgPricePerLiter ?? 0),
          color: theme.colorScheme.secondary,
          unitLabel: PriceFormatter.currency,
        ),
        if (consumptionRows.isNotEmpty)
          _chart(
            context,
            key: const Key('monthly_consumption_chart'),
            title: l?.consumptionStatsChartConsumption ?? 'L/100km per month',
            summaries: consumptionRows,
            color: theme.colorScheme.primary,
            unitLabel: 'L/100km',
          ),
      ],
    );
  }

  Widget _chart(
    BuildContext context, {
    required Key key,
    required String title,
    required List<MonthlySummary> summaries,
    required Color color,
    required String unitLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SectionCard(
        title: title,
        child: MonthlyBarChart(
          key: key,
          summaries: summaries,
          valueOf: (s) => s.totalCost,
          color: color,
          unitLabel: unitLabel,
        ),
      ),
    );
  }
}
