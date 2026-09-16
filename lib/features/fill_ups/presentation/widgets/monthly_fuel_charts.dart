// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/panel_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../../../core/theme/fuel_colors.dart';
import '../../../carbon/domain/monthly_summary.dart';
import '../../../carbon/presentation/widgets/monthly_bar_chart.dart';
import '../../domain/services/fill_up_monthly_stats_aggregator.dart';
import '../../../../core/utils/localized_fuel_name.dart';
import 'monthly_metric_chart.dart';

/// Monthly evolution for the consumption-statistics page (#2698, #4175).
///
/// ## What changed, and why it was the real complaint
///
/// This used to render litres, spend, price/L and L/100 km as FOUR
/// full-width cards stacked vertically, each with its own title and its
/// own axis. Comparing two of those numbers meant scrolling past three
/// screens of near-identical green bars, and the page read as a
/// spreadsheet printout rather than a report.
///
/// One card now, with a metric selector. The chart animates between
/// metrics instead of the user travelling between charts.
///
/// ## Line, except where a line would lie
///
/// A trend across months is a line; bars compare discrete quantities.
/// The default is therefore a line with a soft area beneath it — but
/// the per-fuel breakdown (#3691) STACKS each month's bar by fuel, and
/// a line cannot express a composition. So the additive metrics (litres,
/// spend) keep the stacked bar rendering whenever two or more fuels are
/// logged, and the ratio metrics (price/L, L/100 km) are always a line.
///
/// That is not a compromise: each encoding is used for the question it
/// answers.
class MonthlyFuelCharts extends StatefulWidget {
  /// Per-month stats, oldest first — straight from `monthlyFuelStats`.
  final List<MonthlyFuelStats> months;

  /// Per-fuel monthly stats (#3691): when ≥2 fuels are present, the
  /// ADDITIVE metrics stack each month by fuel — with a colour legend —
  /// so the user sees how each fuel performs. Ratio metrics stay
  /// aggregate; the page's fuel filter provides their per-fuel reading.
  final Map<FuelType, List<MonthlyFuelStats>> perFuel;

  const MonthlyFuelCharts({
    super.key,
    required this.months,
    this.perFuel = const {},
  });

  @override
  State<MonthlyFuelCharts> createState() => _MonthlyFuelChartsState();
}

/// Which series the one chart is showing.
enum _Metric { litres, spend, pricePerLitre, consumption }

class _MonthlyFuelChartsState extends State<MonthlyFuelCharts> {
  _Metric _metric = _Metric.litres;

  /// Additive metrics can be decomposed by fuel; ratio metrics cannot —
  /// an average of averages is not an average, so stacking price/L by
  /// fuel would draw a number that does not exist.
  bool get _isAdditive =>
      _metric == _Metric.litres || _metric == _Metric.spend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final months = widget.months;

    final stackedFuels = widget.perFuel.length >= 2 ? widget.perFuel : null;
    final showStack = stackedFuels != null && _isAdditive;

    // L/100 km only materialises when a closed plein-to-plein window
    // falls inside a month, so its series is the null-skipped subset and
    // the selector hides it entirely when no month has a figure.
    final consumptionRows = [
      for (final m in months)
        if (m.stats.avgConsumptionL100km != null) m,
    ];
    final hasConsumption = consumptionRows.isNotEmpty;
    final metric = _metric == _Metric.consumption && !hasConsumption
        ? _Metric.litres
        : _metric;

    final rows = metric == _Metric.consumption ? consumptionRows : months;
    final summaries = [
      for (final m in rows)
        MonthlySummary(
          month: m.month,
          totalCost: _valueOf(metric, m),
          totalLiters: m.stats.totalLiters,
          totalCo2Kg: 0,
          fillUpCount: m.stats.fillUpCount,
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
      child: PanelCard(
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricSelector(
              value: metric,
              hasConsumption: hasConsumption,
              onChanged: (m) => setState(() => _metric = m),
            ),
            const SizedBox(height: Spacing.md),
            if (showStack)
              _FuelLegend(fuels: stackedFuels.keys.toList())
            else
              const SizedBox.shrink(),
            SizedBox(
              height: 168,
              // The key changes with the metric so the chart REBUILDS
              // rather than tweening between two unrelated series — a
              // litres curve morphing into a price curve would animate
              // a transition that has no meaning.
              child: showStack
                  ? MonthlyBarChart(
                      key: ValueKey('monthly_stack_${metric.name}'),
                      summaries: summaries,
                      valueOf: (MonthlySummary s) => s.totalCost,
                      color: _colorOf(metric, theme),
                      unitLabel: _unitOf(metric, l),
                      stacks: _stacksOf(metric, stackedFuels, months),
                    )
                  : MonthlyMetricChart(
                      key: ValueKey('monthly_line_${metric.name}'),
                      values: [for (final s in summaries) s.totalCost],
                      months: [for (final s in summaries) s.month],
                      color: _colorOf(metric, theme),
                      maxLabel: _maxLabel(summaries, metric, l),
                    ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              _captionOf(metric, l),
              style: AppText.label(context).copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The top-right reference label. Formatting goes through
  /// [UnitFormatter] rather than a bare `toStringAsFixed` — the
  /// presentation layer has a ratchet against inline number formatting
  /// (#3743), and a chart axis is exactly the place a stray locale-blind
  /// decimal point would hide.
  String _maxLabel(
    List<MonthlySummary> summaries,
    _Metric metric,
    AppLocalizations l,
  ) {
    if (summaries.isEmpty) return '';
    final max = summaries
        .map((s) => s.totalCost)
        .reduce((a, b) => a > b ? a : b);
    return '${UnitFormatter.formatDecimal(max, fractionDigits: 0)} '
        '${_unitOf(metric, l)}';
  }

  double _valueOf(_Metric m, MonthlyFuelStats s) => switch (m) {
        _Metric.litres => s.stats.totalLiters,
        _Metric.spend => s.stats.totalSpent,
        _Metric.pricePerLitre => s.stats.avgPricePerLiter ?? 0,
        _Metric.consumption => s.stats.avgConsumptionL100km ?? 0,
      };

  Color _colorOf(_Metric m, ThemeData t) => switch (m) {
        _Metric.litres => t.colorScheme.primary,
        _Metric.spend => t.colorScheme.tertiary,
        _Metric.pricePerLitre => t.colorScheme.secondary,
        _Metric.consumption => t.colorScheme.primary,
      };

  String _unitOf(_Metric m, AppLocalizations l) => switch (m) {
        _Metric.litres => 'L',
        _Metric.spend || _Metric.pricePerLitre => PriceFormatter.currency,
        _Metric.consumption => l.consumptionMetricPerHundred,
      };

  String _captionOf(_Metric m, AppLocalizations l) => switch (m) {
        _Metric.litres => l.consumptionStatsChartLiters,
        _Metric.spend => l.consumptionStatsChartSpend,
        _Metric.pricePerLitre => l.consumptionStatsChartPricePerLiter,
        _Metric.consumption => l.consumptionStatsChartConsumption,
      };

  /// Per-fuel stacks aligned with [months] (#3691): fuel → month →
  /// metric, missing months contributing 0.
  List<List<BarSegment>> _stacksOf(
    _Metric metric,
    Map<FuelType, List<MonthlyFuelStats>> fuels,
    List<MonthlyFuelStats> months,
  ) {
    final byFuelMonth = {
      for (final e in fuels.entries)
        e.key: {for (final m in e.value) m.month: _valueOf(metric, m)},
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
}

/// The four series, as one control instead of four cards.
class _MetricSelector extends StatelessWidget {
  const _MetricSelector({
    required this.value,
    required this.hasConsumption,
    required this.onChanged,
  });

  final _Metric value;
  final bool hasConsumption;
  final ValueChanged<_Metric> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entries = <(_Metric, String)>[
      (_Metric.litres, l.consumptionMetricLitres),
      (_Metric.spend, l.consumptionMetricSpend),
      (_Metric.pricePerLitre, l.consumptionMetricPricePerLitre),
      if (hasConsumption) (_Metric.consumption, l.consumptionMetricPerHundred),
    ];
    // Scrollable rather than a SegmentedButton: four localized metric
    // names do not fit a 320 dp row in any language, and a segmented
    // control that ellipsises its own labels is worse than a row that
    // admits it scrolls.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (metric, label) in entries)
            Padding(
              padding: const EdgeInsets.only(right: Spacing.xs),
              child: ChoiceChip(
                key: Key('metric_${metric.name}'),
                label: Text(label),
                selected: metric == value,
                onSelected: (_) => onChanged(metric),
              ),
            ),
        ],
      ),
    );
  }
}

/// Which colour is which fuel, for the stacked additive metrics.
class _FuelLegend extends StatelessWidget {
  const _FuelLegend({required this.fuels});

  final List<FuelType> fuels;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xs),
      child: Wrap(
        key: const Key('fuel_stack_legend'),
        spacing: Spacing.md,
        runSpacing: 4,
        children: [
          for (final fuel in fuels)
            // ConstrainedBox + Flexible, because a Wrap hands each child
            // the FULL width and a Row that cannot shrink overflows
            // instead of wrapping. Under en_XA at 1.3x a pseudo-expanded
            // fuel name does exactly that — 76 px past the card edge,
            // which is how this was found.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle,
                      size: 10, color: FuelColors.forType(fuel)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      localizedFuelName(l, fuel),
                      style: AppText.label(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
