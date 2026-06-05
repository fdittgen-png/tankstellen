// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/station_extensions.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/entities/fuel_type.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../domain/entities/fuel_type_efficiency_stats.dart';
import '../../domain/services/fuel_type_efficiency_aggregator.dart';
import '../../providers/fuel_type_efficiency_provider.dart';
import 'localized_fuel_name.dart';

/// Per-fuel-type cost-per-km comparison card (#2887, Epic #2881).
///
/// Surfaces the dominant-fuel attribution model (ADR 0014) for a
/// multi-fuel vehicle: one row per fuel the user has logged, sorted by
/// real `avgCostPerKm` ascending (cheapest to DRIVE first — which is not
/// the same as cheapest per litre, the whole point of the feature).
///
/// Self-hides ([SizedBox.shrink]) when the active vehicle is NOT
/// `multiFuelCapable`, or fewer than two distinct fuels have been logged
/// — a single-fuel comparison is meaningless.
///
/// A "Cheapest per km: {fuel}" winner chip is crowned only when the
/// verdict gate ([FuelTypeEfficiencyAggregator.cheapestPerKm]) opens —
/// every compared fuel must clear [kMinAttributedIntervalsForVerdict]
/// closed intervals. Below the gate the numbers still render, but no
/// crown and an insufficient-data footnote.
///
/// A fuel with zero attributed intervals (only ever a minority in mixed
/// tanks, or only in the opening fill / open tail) shows "—" for L/100km
/// and €/km but keeps its total-spent + fill count — exactly the
/// null-skip the ADR mandates. A muted footnote discloses how many tanks
/// were mixed.
class FuelTypeEfficiencyCard extends ConsumerWidget {
  const FuelTypeEfficiencyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final vehicle = ref.watch(activeVehicleProfileProvider);
    final stats = ref.watch(fuelTypeEfficiencyComparisonProvider);

    // Gate 1 — the active vehicle must be flagged multi-fuel. A
    // single-fuel vehicle (or no active vehicle) never shows the card.
    if (vehicle == null || !vehicle.multiFuelCapable) {
      return const SizedBox.shrink();
    }
    // Gate 2 — at least two distinct fuels with fills, else nothing to
    // compare. (The aggregator only emits a row per fuel that has fills.)
    final withFills = stats.where((s) => s.fillCount > 0).toList();
    if (withFills.length < 2) return const SizedBox.shrink();

    final crowned = FuelTypeEfficiencyAggregator.cheapestPerKm(withFills);
    // #2888 — only crown a winner whose €/km is actually non-null. The
    // aggregator already guarantees this, but the gate is cheap and
    // hardens the chip against any future change to `cheapestPerKm` (a
    // crowned-but-null fuel would otherwise render "Cheapest per km:
    // … (--)").
    final winner = (crowned != null && _costPerKmOf(withFills, crowned) != null)
        ? crowned
        : null;
    // Best (lowest) non-null €/km — the sentiment baseline for the delta
    // arrows. Independent of the verdict gate so arrows render even when
    // no crown is awarded.
    final bestCostPerKm = _bestCostPerKm(withFills);
    final mixedCount = withFills.fold<int>(
      0,
      (sum, s) => sum + s.mixedIntervalCount,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SectionCard(
        key: const ValueKey('fuel_type_efficiency_card'),
        title: l?.fuelEfficiencyCardTitle ?? 'Cost per kilometre by fuel',
        subtitle: l?.fuelEfficiencyCardSubtitle ??
            'Which fuel is actually cheapest to drive on',
        leadingIcon: Icons.eco_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (winner != null) ...[
              _WinnerChip(
                fuel: winner,
                costPerKm: _costPerKmOf(withFills, winner),
              ),
              const SizedBox(height: 12),
            ],
            for (final s in withFills) ...[
              _FuelRow(
                stats: s,
                isWinner: winner != null && s.fuelType == winner,
                bestCostPerKm: bestCostPerKm,
              ),
              const SizedBox(height: 8),
            ],
            if (winner == null) ...[
              const SizedBox(height: 2),
              _Footnote(
                text: l?.fuelEfficiencyInsufficientData ??
                    'Log at least two full tanks per fuel to crown the '
                        'cheapest.',
              ),
            ],
            if (mixedCount > 0) ...[
              const SizedBox(height: 4),
              _Footnote(
                text: l?.fuelEfficiencyMixedFootnote(mixedCount) ??
                    '$mixedCount mixed tanks counted toward their main fuel',
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Lowest non-null `avgCostPerKm` across [stats], or null when no fuel
  /// has a per-km figure yet.
  static double? _bestCostPerKm(List<FuelTypeEfficiencyStats> stats) {
    double? best;
    for (final s in stats) {
      final c = s.avgCostPerKm;
      if (c == null) continue;
      if (best == null || c < best) best = c;
    }
    return best;
  }

  /// The `avgCostPerKm` of [fuel] within [stats] (the winner always has a
  /// non-null figure, so this never returns null for a crowned fuel).
  static double? _costPerKmOf(
    List<FuelTypeEfficiencyStats> stats,
    FuelType fuel,
  ) {
    for (final s in stats) {
      if (s.fuelType == fuel) return s.avgCostPerKm;
    }
    return null;
  }
}

/// Winner chip — "Cheapest per km: {fuel} ({costPerKm})". Uses the eco
/// surface tokens (primary container) so it reads as a positive verdict.
class _WinnerChip extends StatelessWidget {
  final FuelType fuel;
  final double? costPerKm;

  const _WinnerChip({required this.fuel, required this.costPerKm});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fuelName = localizedFuelName(l, fuel);
    final cost = PriceFormatter.formatPerKm(costPerKm);
    final label = l?.fuelEfficiencyWinnerChip(fuelName, cost) ??
        'Cheapest per km: $fuelName ($cost)';
    return Container(
      key: const ValueKey('fuel_efficiency_winner_chip'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 18,
            color: scheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One fuel's row: icon + localized name + a metric block (L/100km,
/// cost/km, total spent, fill count). The cost/km carries a sentiment
/// delta arrow vs the best €/km (down/equal = good; the winner has no
/// arrow). A fuel with no attributed interval shows "—" for the per-km
/// metrics but keeps total-spent + fill count (ADR 0014 null-skip).
class _FuelRow extends StatelessWidget {
  final FuelTypeEfficiencyStats stats;
  final bool isWinner;
  final double? bestCostPerKm;

  const _FuelRow({
    required this.stats,
    required this.isWinner,
    required this.bestCostPerKm,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fuel = stats.fuelType;
    final fuelName = localizedFuelName(l, fuel);
    final l100 = stats.avgL100km;
    final costPerKm = stats.avgCostPerKm;

    // Delta vs the best €/km drives the sentiment arrow (lowerIsBetter).
    // Capture the field into a local so the analyzer can promote it past
    // the null check.
    final best = bestCostPerKm;
    final delta = (costPerKm != null && best != null)
        ? costPerKm - best
        : 0.0;

    return Row(
      key: ValueKey('fuel_efficiency_row_${fuel.apiValue}'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(fuel.icon, size: 20, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fuelName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                // Reuse the language-neutral grade code as a compact
                // secondary identifier (e.g. "E10", "Diesel").
                shortFuelLabel(fuel),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
                label: l?.fuelEfficiencyColCostPerKm ?? 'Cost/km',
                value: costPerKm != null
                    ? PriceFormatter.formatPerKm(costPerKm)
                    : '—',
                trailing: _DeltaArrow(delta: delta),
                emphasised: true,
              ),
              _MetricLine(
                label: l?.fuelEfficiencyColL100km ?? 'L/100km',
                value: l100 != null ? l100.toStringAsFixed(1) : '—',
              ),
              _MetricLine(
                label: l?.fuelEfficiencyColTotalSpent ?? 'Total spent',
                value: PriceFormatter.formatTotal(stats.totalSpent),
              ),
              Text(
                l?.fuelEfficiencyFillCount(stats.fillCount) ??
                    '${stats.fillCount} fills',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One label/value pair in a fuel row's metric block, right-aligned with
/// tabular figures so columns line up. [trailing] hosts the optional
/// delta arrow; [emphasised] bolds the cost/km headline.
class _MetricLine extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  final bool emphasised;

  const _MetricLine({
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
          style: (emphasised
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

/// Sentiment delta arrow for €/km (lowerIsBetter). Hidden when the delta
/// is ~0 (the winner, or a tie). Up = costlier than the best (error
/// colour); there is no "down" since the best is the baseline. Mirrors
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

/// Muted, italic footnote (mixed-tank disclosure / insufficient-data).
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
