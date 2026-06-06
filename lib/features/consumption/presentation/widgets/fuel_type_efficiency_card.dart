// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../domain/entities/fuel_type_efficiency_stats.dart';
import '../../domain/services/fuel_type_efficiency_aggregator.dart';
import '../../providers/fuel_type_efficiency_provider.dart';
import 'localized_fuel_name.dart';

part 'fuel_type_efficiency_rows.dart';

/// Per-fuel-composition cost-per-km comparison card (#2928, Epic #2881).
///
/// Surfaces the v2 COMPOSITION-BUCKET model (ADR 0015, superseding ADR 0014's
/// dominant-fuel collapse) for a multi-fuel vehicle: one row per composition
/// the user has actually driven — a PURE grade (a tank ≥ 85 % one fuel, e.g.
/// `E85`) or a BLEND (`E85/E10`, dominant first) — sorted by real
/// `avgCostPerKm` ascending (cheapest to DRIVE first, which is not the same as
/// cheapest per litre — the whole point of the feature). A flex-fuel driver can
/// thus pit pure E85 directly against an E85/E10 blend.
///
/// Self-hides ([SizedBox.shrink]) when the active vehicle is NOT
/// `multiFuelCapable`, or fewer than two distinct composition buckets have been
/// logged — a single-composition comparison is meaningless.
///
/// A "Cheapest per km: {composition}" winner chip is crowned only when the
/// verdict gate ([FuelTypeEfficiencyAggregator.cheapestPerKm]) opens — every
/// compared bucket must clear [kMinAttributedIntervalsForVerdict] closed
/// intervals. Below the gate the numbers still render, but no crown and an
/// insufficient-data footnote. A bucket with zero usable distance (odometer
/// reset / open tail) shows "—" for L/100km and €/km but keeps its
/// total-spent + fill count.
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
    // Gate 2 — at least two distinct composition buckets with fills, else
    // nothing to compare. (The aggregator only emits a row per bucket that
    // has at least one classified interval.)
    final withFills = stats.where((s) => s.fillCount > 0).toList();
    if (withFills.length < 2) return const SizedBox.shrink();

    final crowned = FuelTypeEfficiencyAggregator.cheapestPerKm(withFills);
    // #2888 — only crown a winner whose €/km is actually non-null. The
    // aggregator already guarantees this, but the gate is cheap and hardens
    // the chip against any future change to `cheapestPerKm` (a crowned-but-
    // null bucket would otherwise render "Cheapest per km: … (--)").
    final winner =
        (crowned != null && _costPerKmOf(withFills, crowned) != null)
            ? crowned
            : null;
    // Best (lowest) non-null €/km — the sentiment baseline for the delta
    // arrows. Independent of the verdict gate so arrows render even when no
    // crown is awarded.
    final bestCostPerKm = _bestCostPerKm(withFills);
    final anyMix = withFills.any((s) => s.isMix);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SectionCard(
        key: const ValueKey('fuel_type_efficiency_card'),
        title: l?.fuelEfficiencyCardTitle ?? 'Cost per kilometre by fuel',
        subtitle: l?.fuelEfficiencyCardSubtitle ??
            'Which fuel mix is actually cheapest to drive on',
        leadingIcon: Icons.eco_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (winner != null) ...[
              _WinnerChip(
                label: winner.label,
                costPerKm: _costPerKmOf(withFills, winner),
              ),
              const SizedBox(height: 12),
            ],
            for (final s in withFills) ...[
              _BucketRow(
                stats: s,
                isWinner: winner != null && s.bucket == winner,
                bestCostPerKm: bestCostPerKm,
              ),
              const SizedBox(height: 8),
            ],
            if (winner == null) ...[
              const SizedBox(height: 2),
              _Footnote(
                text: l?.fuelEfficiencyInsufficientData ??
                    'Log at least two full tanks per composition to crown the '
                        'cheapest.',
              ),
            ],
            if (anyMix) ...[
              const SizedBox(height: 4),
              _Footnote(
                text: l?.fuelEfficiencyCompositionFootnote ??
                    'Tanks are grouped by composition: a tank is pure when '
                        'one fuel is at least 85% of it, otherwise a blend.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Lowest non-null `avgCostPerKm` across [stats], or null when no bucket
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

  /// The `avgCostPerKm` of [bucket] within [stats] (the winner always has a
  /// non-null figure, so this never returns null for a crowned bucket).
  static double? _costPerKmOf(
    List<FuelTypeEfficiencyStats> stats,
    FuelEfficiencyBucket bucket,
  ) {
    for (final s in stats) {
      if (s.bucket == bucket) return s.avgCostPerKm;
    }
    return null;
  }
}

/// Winner chip — "Cheapest per km: {composition} ({costPerKm})". Uses the eco
/// surface tokens (primary container) so it reads as a positive verdict. The
/// [label] is the bucket's language-neutral composition code (`E85` /
/// `E85/E10`).
class _WinnerChip extends StatelessWidget {
  final String label;
  final double? costPerKm;

  const _WinnerChip({required this.label, required this.costPerKm});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cost = PriceFormatter.formatPerKm(costPerKm);
    final text = l?.fuelEfficiencyWinnerChip(label, cost) ??
        'Cheapest per km: $label ($cost)';
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
              text,
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
