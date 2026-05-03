import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/consumption_stats.dart';

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
class ConsumptionStatsCard extends StatelessWidget {
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

  const ConsumptionStatsCard({
    super.key,
    required this.stats,
    this.volumetricEfficiency,
    this.volumetricEfficiencySamples,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final avgConsumption = stats.avgConsumptionL100km;
    final avgCostKm = stats.avgCostPerKm;

    final showOpenWindowBanner = stats.openWindowFillCount > 0;
    final showCorrectionHint = stats.correctionShare > 0.05;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 12),
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
            // #1397 — convergence chip surfacing the auto-learner's
            // η_v state. Renders nothing when the active vehicle hasn't
            // been wired in (volumetricEfficiencySamples == null).
            if (volumetricEfficiencySamples != null) ...[
              const SizedBox(height: 8),
              _CalibrationChip(
                volumetricEfficiency: volumetricEfficiency ?? 0.85,
                samples: volumetricEfficiencySamples!,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    final orange = Colors.orange.shade700;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

/// Inline chip surfacing the auto-learner's η_v state (#1397).
///
/// Three branches drive the label:
///   * `samples >= 3` → "η_v: 0.87 (calibrated, N samples)"
///   * `0 < samples < 3` → "η_v: 0.87 (learning, N samples)"
///   * `samples == 0` → "η_v: ?? (no plein-complet yet)"
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
    final eta = volumetricEfficiency.toStringAsFixed(2);
    final String label;
    if (samples == 0) {
      label = l?.calibrationLearnerStatusNoSamples ??
          'η_v: ?? (no plein-complet yet)';
    } else if (samples < 3) {
      label = l?.calibrationLearnerStatusLearning(eta, samples) ??
          'η_v: $eta (learning, $samples samples)';
    } else {
      label = l?.calibrationLearnerStatusCalibrated(eta, samples) ??
          'η_v: $eta (calibrated, $samples samples)';
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Chip(
        label: Text(label),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
