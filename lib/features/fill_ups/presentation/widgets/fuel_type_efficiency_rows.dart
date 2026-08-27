// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'fuel_type_efficiency_card.dart';

/// One composition bucket's row: dominant-fuel icon + the language-neutral
/// composition label (`E85` / `E85/E10`) + a Pure/Blend badge + a metric
/// block (cost/km, L/100km, total spent, fill count). A blend row also names
/// its dominant ("Mostly {fuel}"). The cost/km carries a sentiment delta arrow
/// vs the best €/km (the winner has no arrow). A bucket with no usable
/// distance shows "—" for the per-km metrics but keeps total-spent + count.
class _BucketRow extends StatelessWidget {
  final FuelTypeEfficiencyStats stats;
  final bool isWinner;
  final double? bestCostPerKm;

  const _BucketRow({
    required this.stats,
    required this.isWinner,
    required this.bestCostPerKm,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bucket = stats.bucket;
    final l100 = stats.avgL100km;
    final costPerKm = stats.avgCostPerKm;

    // Delta vs the best €/km drives the sentiment arrow (lowerIsBetter).
    // Capture the field into a local so the analyzer can promote it past the
    // null check.
    final best = bestCostPerKm;
    final delta = (costPerKm != null && best != null) ? costPerKm - best : 0.0;

    final badge = stats.isMix
        ? (l.fuelEfficiencyMixBadge)
        : (l.fuelEfficiencyPureBadge);
    final dominantName = localizedFuelName(l, bucket.dominant);
    // Secondary line: a blend names its dominant fuel; a pure bucket names
    // its (single) fuel so the row is never just an opaque grade code.
    final secondaryLine = stats.isMix
        ? (l.fuelEfficiencyMixDominant(dominantName))
        : dominantName;

    return Column(
      key: ValueKey('fuel_efficiency_row_${bucket.key}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(bucket.dominant.icon, size: 20, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          // The composition label is a language-neutral grade
                          // code / A/B mix mask (see FuelEfficiencyBucket.label).
                          bucket.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isWinner
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _CompositionBadge(text: badge, isMix: stats.isMix),
                    ],
                  ),
                  Text(
                    secondaryLine,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MetricLine(
                    label: l.fuelEfficiencyColCostPerKm,
                    value: costPerKm != null
                        ? PriceFormatter.formatPerKm(costPerKm)
                        : '—',
                    trailing: _DeltaArrow(delta: delta),
                    emphasised: true,
                  ),
                  _MetricLine(
                    label: l.fuelEfficiencyColL100km,
                    value: l100 != null ? UnitFormatter.formatDecimal(l100) : '—',
                  ),
                  // #3828 — the pump price actually paid. Previously invisible,
                  // and it is the fact that explains how a fuel can burn fewer
                  // litres per 100 km yet cost more per kilometre.
                  _MetricLine(
                    key: ValueKey('fuel_efficiency_perlitre_${bucket.key}'),
                    label: l.fuelComparePricePerLitre,
                    value: stats.avgPricePerLitre != null
                        ? PriceFormatter.formatTotal(stats.avgPricePerLitre!)
                        : '—',
                  ),
                  // #3764 — interval count first-class next to the fill count:
                  // "2 full tanks · 3 fills". The interval count is what feeds
                  // the verdict gate, so surfacing it makes "why no crown yet"
                  // legible per row.
                  Text(
                    '${l.fuelEfficiencyIntervalCount(stats.attributedIntervalCount)}'
                    ' · ${l.fuelEfficiencyFillCount(stats.fillCount)}',
                    key: ValueKey('fuel_efficiency_counts_${bucket.key}'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // #3828 — supporting figures as a compact wrapped line instead of a
        // ninth stacked metric: the three decisive numbers stay in the row,
        // the evidence behind them sits underneath without blowing the row
        // height (stacking them all overflowed by 86px).
        _SupportingFigures(stats: stats),
      ],
    );
  }
}

/// A small pill marking a row as a pure grade or a blend (ADR 0015). Blends
/// use the tertiary container so they are visually distinct from pure rows.
class _CompositionBadge extends StatelessWidget {
  final String text;
  final bool isMix;

  const _CompositionBadge({required this.text, required this.isMix});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = isMix
        ? scheme.tertiaryContainer
        : scheme.surfaceContainerHighest;
    final fg = isMix ? scheme.onTertiaryContainer : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// One label/value pair in a row's metric block, right-aligned with tabular
/// figures so columns line up. [trailing] hosts the optional delta arrow;
/// [emphasised] bolds the cost/km headline.
class _MetricLine extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  final bool emphasised;

  const _MetricLine({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style:
              (emphasised
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: emphasised ? FontWeight.w700 : null,
                  ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 2),
          SizedBox(width: 18, child: trailing),
        ],
      ],
    );
  }
}

/// Sentiment delta arrow for €/km (lowerIsBetter). Hidden when the delta is
/// ~0 (the winner, or a tie). Up = costlier than the best (error colour);
/// there is no "down" since the best is the baseline. Mirrors
/// `MonthlyFuelComparisonCard._DeltaArrow`.
class _DeltaArrow extends StatelessWidget {
  final double delta;

  const _DeltaArrow({required this.delta});

  @override
  Widget build(BuildContext context) {
    if (delta.abs() < 0.0005) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final up = delta > 0;
    return Icon(
      up ? Icons.arrow_upward : Icons.arrow_downward,
      size: 14,
      color: up ? theme.colorScheme.error : DarkModeColors.success(context),
    );
  }
}

/// Muted, italic footnote (composition disclosure / insufficient-data).
class _Footnote extends StatelessWidget {
  final String text;

  const _Footnote({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

/// The evidence behind a row's three headline numbers (#3828), as a compact
/// wrapped line of `label value` chips.
///
/// These began life as extra entries in the row's vertical metric stack,
/// which took it from four lines to nine and overflowed the card by 86px —
/// and read as a wall of figures rather than an analysis. Wrapping them
/// keeps the row's height unchanged while still showing what the verdict
/// rests on: the pump price paid, the cost over a distance people can feel,
/// and how much driving is actually behind the average.
class _SupportingFigures extends StatelessWidget {
  const _SupportingFigures({required this.stats});

  final FuelTypeEfficiencyStats stats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final co2PerKm = stats.isMix
        ? null
        : stats.co2PerKmWith(
            Co2Calculator.emissionFactorFor(stats.bucket.dominant),
          );
    final co2Per100 = co2PerKm == null ? null : co2PerKm * 100;

    final chips = <Widget>[
      if (stats.avgCostPer100km != null)
        _FigureChip(
          key: ValueKey('fuel_efficiency_cost100_${stats.bucket.key}'),
          label: l.fuelCompareCostPer100km,
          value: PriceFormatter.formatTotal(stats.avgCostPer100km!),
        ),
      _FigureChip(
        label: l.fuelEfficiencyColTotalSpent,
        value: PriceFormatter.formatTotal(stats.totalSpent),
      ),
      if (stats.totalDistanceKm > 0)
        _FigureChip(
          key: ValueKey('fuel_efficiency_distance_${stats.bucket.key}'),
          label: l.fuelCompareDistance,
          value: UnitFormatter.formatDistance(stats.totalDistanceKm,
              fractionDigits: 0),
        ),
      if (stats.totalLitres > 0)
        _FigureChip(
          key: ValueKey('fuel_efficiency_litres_${stats.bucket.key}'),
          label: l.fuelCompareLitres,
          value: UnitFormatter.formatDecimal(stats.totalLitres),
        ),
      // #3828 — the emissions axis. Pure buckets only: a blend's factor
      // depends on shares this row does not carry, and an invented factor
      // would be worse than no number.
      if (co2Per100 != null)
        _FigureChip(
          key: ValueKey('fuel_efficiency_co2_${stats.bucket.key}'),
          label: l.fuelCompareCo2Per100km,
          value: '${UnitFormatter.formatDecimal(co2Per100)} kg',
        ),
      // Confidence travels WITH the figures — every number here is an
      // average over full-tank intervals, and one interval is a data point,
      // not a verdict. In the SAME wrap so the supporting block stays one
      // line: the row lost `total spent` from its stack, so this nets to no
      // extra height.
      Text(
        stats.isConfident
            ? l.fuelCompareBasedOn(stats.attributedIntervalCount)
            : l.fuelCompareProvisional(stats.attributedIntervalCount),
        key: ValueKey('fuel_efficiency_confidence_${stats.bucket.key}'),
        style: theme.textTheme.labelSmall?.copyWith(
          color: stats.isConfident ? scheme.onSurfaceVariant : scheme.tertiary,
          fontStyle: stats.isConfident ? null : FontStyle.italic,
        ),
      ),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 2),
      child: Wrap(spacing: 10, runSpacing: 2, children: chips),
    );
  }
}

/// One `label value` pair in the supporting-figures line.
class _FigureChip extends StatelessWidget {
  const _FigureChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Text.rich(
      TextSpan(
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
