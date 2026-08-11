// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../carbon/domain/monthly_summary.dart';
import '../../../carbon/presentation/widgets/monthly_bar_chart.dart';
import '../../domain/services/fill_up_monthly_stats_aggregator.dart';
import 'localized_fuel_name.dart';

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

  /// Per-fuel monthly stats (#3691): when ≥2 fuels are present, the
  /// ADDITIVE charts (litres, spend) stack each month's bar by fuel —
  /// with a colour legend — so the user sees how each fuel performs.
  /// Ratio charts (price/L, L/100km) stay aggregate; the page's fuel
  /// filter provides their per-fuel reading.
  final Map<FuelType, List<MonthlyFuelStats>> perFuel;

  const MonthlyFuelCharts({
    super.key,
    required this.months,
    this.perFuel = const {},
  });

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

    // Per-fuel stacks aligned with [months] (#3691): fuel → month →
    // metric, missing months contribute 0.
    final stackedFuels = perFuel.length >= 2 ? perFuel : null;
    List<List<BarSegment>>? stacksOf(
      double Function(MonthlyFuelStats) pick,
    ) {
      if (stackedFuels == null) return null;
      final byFuelMonth = {
        for (final e in stackedFuels.entries)
          e.key: {for (final m in e.value) m.month: pick(m)},
      };
      return [
        for (final m in months)
          [
            for (final e in byFuelMonth.entries)
              BarSegment(
                value: e.value[m.month] ?? 0,
                color: FuelColors.forType(e.key),
              ),
          ],
      ];
    }

    return Column(
      children: [
        if (stackedFuels != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Wrap(
              key: const Key('fuel_stack_legend'),
              spacing: 12,
              runSpacing: 4,
              children: [
                for (final fuel in stackedFuels.keys)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle,
                          size: 10, color: FuelColors.forType(fuel)),
                      const SizedBox(width: 4),
                      Text(
                        localizedFuelName(l, fuel),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        _chart(
          context,
          key: const Key('monthly_litres_chart'),
          title: l.consumptionStatsChartLiters,
          summaries: rows((m) => m.stats.totalLiters),
          color: theme.colorScheme.primary,
          unitLabel: 'L',
          stacks: stacksOf((m) => m.stats.totalLiters),
        ),
        _chart(
          context,
          key: const Key('monthly_spend_chart'),
          title: l.consumptionStatsChartSpend,
          summaries: rows((m) => m.stats.totalSpent),
          color: theme.colorScheme.tertiary,
          unitLabel: PriceFormatter.currency,
          stacks: stacksOf((m) => m.stats.totalSpent),
        ),
        _chart(
          context,
          key: const Key('monthly_price_per_litre_chart'),
          title: l.consumptionStatsChartPricePerLiter,
          summaries: rows((m) => m.stats.avgPricePerLiter ?? 0),
          color: theme.colorScheme.secondary,
          unitLabel: PriceFormatter.currency,
        ),
        if (consumptionRows.isNotEmpty)
          _chart(
            context,
            key: const Key('monthly_consumption_chart'),
            title: l.consumptionStatsChartConsumption,
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
    List<List<BarSegment>>? stacks,
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
          stacks: stacks,
        ),
      ),
    );
  }
}
