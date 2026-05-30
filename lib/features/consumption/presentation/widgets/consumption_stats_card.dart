// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../domain/entities/consumption_stats.dart';
import 'confidence_tier_badge.dart';

/// Card summarising aggregated consumption statistics.
///
/// Since #1362 the card grows two optional decorations on top of the
/// existing stat tiles:
///
///   * a grey **open-window banner** when partial fills sit after the
///     most recent plein-complet — those fills are excluded from the
///     average and the user is told why.
///   * an orange-tinted **correction-share hint** when more than 5 %
///     of the totalled fuel volume came from auto-generated corrections,
///     nudging the user to review the orange entries in the list.
///
/// When neither condition fires, the card renders exactly as before so
/// the all-plein, no-corrections case keeps its calm UX.
///
/// #2433 — the consumption-confidence indicator (ConfidenceTierBadge)
/// and the debug-only raw η_v chip ride a subtitle row directly under
/// the card title. They previously lived here (pre-#2383), briefly moved
/// to the Carburant app-bar in #2383, and #2433 brings them back into the
/// Verbrauchsstatistik card so the precision rating sits next to the
/// figures it qualifies.
class ConsumptionStatsCard extends ConsumerWidget {
  final ConsumptionStats stats;

  /// Active vehicle's auto-learned η_v (#1397). When null the
  /// convergence chip is skipped — useful for tests / no-vehicle
  /// states / EV vehicles where the speed-density estimator never
  /// runs.
  final double? volumetricEfficiency;

  /// Number of plein-complet samples the learner has folded into
  /// [volumetricEfficiency] (#1397). 0 surfaces the "no plein-complet
  /// yet" state, 1-2 the bootstrap state, 3+ the calibrated state.
  final int? volumetricEfficiencySamples;

  /// Whether the user has at least one trip whose `kind` is
  /// `gpsPlusObd2` (#2027). Combined with [volumetricEfficiencySamples]
  /// this drives the A/B/C confidence-tier badge. Defaults to `true`
  /// because every legacy trip was recorded with OBD2 — so a user with
  /// no migration data still sees the historical default.
  final bool hasGpsPlusObd2Trip;

  const ConsumptionStatsCard({
    super.key,
    required this.stats,
    this.volumetricEfficiency,
    this.volumetricEfficiencySamples,
    this.hasGpsPlusObd2Trip = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    // #2262 — the raw η_v learner chip is engineering jargon
    // (volumetric efficiency + sample count). Normal users get the
    // plain accuracy indicator from [ConfidenceTierBadge]; the raw
    // chip is gated behind Developer mode (`Feature.debugMode`,
    // shipped #2248) so only power users see it.
    final showRawCalibration =
        ref.watch(enabledFeaturesProvider).contains(Feature.debugMode);

    final avgConsumption = stats.avgConsumptionL100km;
    final avgCostKm = stats.avgCostPerKm;

    final showOpenWindowBanner = stats.openWindowFillCount > 0;
    final showCorrectionHint = stats.correctionShare > 0.05;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showOpenWindowBanner) ...[
              _OpenWindowBanner(
                text: l?.consumptionStatsOpenWindowBanner(
                      stats.openWindowFillCount,
                    ) ??
                    '${stats.openWindowFillCount} partial fill(s) pending '
                        'plein complet — not in average',
              ),
              const SizedBox(height: 8),
            ],
            if (showCorrectionHint) ...[
              _CorrectionShareHint(
                text: l?.consumptionStatsCorrectionShareHint(
                      (stats.correctionShare * 100).round(),
                    ) ??
                    '${(stats.correctionShare * 100).round()}% of fuel from '
                        'auto-corrections — review entries',
              ),
              const SizedBox(height: 8),
            ],
            Text(
              l?.consumptionStatsTitle ?? 'Consumption stats',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            // #2433 — the precision rating rides a subtitle row directly
            // under the card title: the confidence tier (A/B/C — #2027)
            // and η_v (#1397 / #815) sit side-by-side on a phone in a
            // single Wrap so they read as one calibration-state group and
            // stack only when the row genuinely overflows. The confidence
            // tier leads (user-facing accuracy band); η_v trails
            // (engineer-detail anchor) and is shown ONLY in Developer mode
            // (#2262) — for normal users the accuracy indicator alone
            // conveys trust.
            if (volumetricEfficiencySamples != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ConfidenceTierBadge(
                    samples: volumetricEfficiencySamples!,
                    hasGpsPlusObd2Trip: hasGpsPlusObd2Trip,
                  ),
                  if (showRawCalibration)
                    _CalibrationChip(
                      volumetricEfficiency: volumetricEfficiency ?? 0.85,
                      samples: volumetricEfficiencySamples!,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.speed,
                    label: l?.statAvgConsumption ?? 'Avg L/100km',
                    value: avgConsumption != null
                        ? avgConsumption.toStringAsFixed(2)
                        : '—',
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    icon: Icons.euro,
                    label: l?.statAvgCostPerKm ?? 'Avg /km',
                    value: avgCostKm != null
                        ? avgCostKm.toStringAsFixed(3)
                        : '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.local_gas_station,
                    label: l?.statTotalLiters ?? 'Total L',
                    value: stats.totalLiters.toStringAsFixed(1),
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    icon: Icons.payments_outlined,
                    label: l?.statTotalSpent ?? 'Total spent',
                    value: stats.totalSpent.toStringAsFixed(2),
                  ),
                ),
              ],
            ),
            if (stats.fillUpCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${l?.statFillUpCount ?? 'Fill-ups'}: ${stats.fillUpCount}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            // #2446 — corrections are surfaced transparently on their
            // own line, never folded into the headline Total L. Shown
            // only when at least one correction landed in a closed
            // window so the line stays out of the way otherwise.
            if (stats.correctionLitersTotal > 0) ...[
              const SizedBox(height: 4),
              Text(
                l?.statCorrectionLiters(
                      stats.correctionLitersTotal.toStringAsFixed(1),
                    ) ??
                    'Corrections: +${stats.correctionLitersTotal.toStringAsFixed(1)} L',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DarkModeColors.warning(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Grey informational banner — partials are pending a plein-complet
/// close. Non-tappable v1; tap-to-jump to fill-up list is a follow-up.
class _OpenWindowBanner extends StatelessWidget {
  final String text;

  const _OpenWindowBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_bottom,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Orange-tinted hint — too much of the average comes from auto-
/// corrections. Encourages the user to review the orange entries.
class _CorrectionShareHint extends StatelessWidget {
  final String text;

  const _CorrectionShareHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Reuse the orange palette established by the correction fill-up
    // card (#1361) so the visual language stays consistent.
    final orange = DarkModeColors.warning(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: orange.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, size: 18, color: orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Engineer-detail pill surfacing the auto-learner's η_v state
/// (#1397 / #815). #2112 — restyled to match [ConfidenceTierBadge]'s
/// recipe so the two land as one harmonised group on the Fuel tab.
///
/// Three branches drive the label:
///   * `samples >= 3` → "η_v: 0.87 · N samples"
///   * `0 < samples < 3` → "η_v: 0.87 · N samples" (same shape; the
///     learning vs calibrated distinction lives on the confidence
///     tier next to it — keep this pill engineer-bare).
///   * `samples == 0` → "η_v: ?? · no plein-complet yet"
///
/// Variance tracking would let us print "± 0.04" alongside the mean,
/// but the existing [VeLearner] only stores the EWMA scalar — adding
/// a Welford branch is left to a follow-up. For now the calibrated
/// branch keeps the bare mean.
class _CalibrationChip extends StatelessWidget {
  final double volumetricEfficiency;
  final int samples;

  const _CalibrationChip({
    required this.volumetricEfficiency,
    required this.samples,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final eta = volumetricEfficiency.toStringAsFixed(2);
    final String label;
    if (samples == 0) {
      label = l?.calibrationLearnerStatusNoSamples ??
          'η_v: ?? — no plein-complet yet';
    } else {
      // #2112 — single label shape across learning + calibrated;
      // confidence tier carries the maturity colour.
      label = l?.calibrationLearnerEtaCompact(eta, samples) ??
          'η_v: $eta · $samples samples';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // #1902 — the stat figures (litres, total spent, …) read
              // far smaller than the old bold titleMedium: they were
              // dominating the summary card. Weight still sets them
              // apart from the label above.
              Text(
                value,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
