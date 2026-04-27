import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/situation_classifier.dart';
import '../../providers/vehicle_baseline_summary_provider.dart';

/// "Baseline calibration" section on the vehicle edit screen (#779).
///
/// Reads the learned Welford sample counts per driving situation and
/// renders a compact progress bar per situation so the user sees how
/// close each one is to full confidence (30 samples). A Reset button
/// wipes the vehicle's baselines — useful when a car's fuel economy
/// shifts (new tyres, new firmware, heavy load).
class VehicleBaselineSection extends ConsumerWidget {
  final String vehicleId;

  /// Sample count at which the baseline is considered fully learned —
  /// mirrors [BaselineStore.fullConfidenceSamples]. Kept as a field so
  /// tests can exercise partial-confidence rendering without pumping
  /// 30 synthetic samples.
  final int fullConfidenceSamples;

  const VehicleBaselineSection({
    super.key,
    required this.vehicleId,
    this.fullConfidenceSamples = 30,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final counts = ref.watch(vehicleBaselineSummaryProvider(vehicleId));
    final theme = Theme.of(context);

    // Persisted situations only — transients never accumulate.
    const situations = [
      DrivingSituation.idle,
      DrivingSituation.stopAndGo,
      DrivingSituation.urbanCruise,
      DrivingSituation.highwayCruise,
      DrivingSituation.deceleration,
      DrivingSituation.climbingOrLoaded,
    ];

    final totalSamples =
        situations.fold<int>(0, (acc, s) => acc + (counts[s] ?? 0));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.tune),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l?.vehicleBaselineSectionTitle ??
                        'Baseline calibration',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              totalSamples == 0
                  ? (l?.vehicleBaselineEmpty ??
                      'No samples yet — start an OBD2 trip to begin learning this vehicle\'s fuel profile.')
                  : (l?.vehicleBaselineProgress ??
                      'Learned from $totalSamples sample(s) across driving situations.'),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final s in situations)
              _BaselineRow(
                label: _label(s, l),
                count: counts[s] ?? 0,
                fullConfidenceSamples: fullConfidenceSamples,
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('resetBaselinesButton'),
                onPressed: totalSamples == 0
                    ? null
                    : () => _confirmReset(context, ref, l),
                // tune_outlined picks up the "tuning learned per-situation
                // behaviour" connotation — distinct from the η_v reset's
                // local_gas_station_outlined icon (#1219).
                icon: const Icon(Icons.tune_outlined),
                label: Text(
                  l?.vehicleBaselineReset ??
                      'Reset driving-situation baseline',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l?.vehicleBaselineResetConfirmTitle ??
              'Reset driving-situation baseline?',
        ),
        content: Text(
          l?.vehicleBaselineResetConfirmBody ??
              'This wipes every learned sample for this vehicle. '
                  'You\'ll drift back to the cold-start defaults until '
                  'new trips refill the profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l?.vehicleBaselineReset ?? 'Reset driving-situation baseline',
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(resetVehicleBaselinesProvider(vehicleId).future);
  }

  String _label(DrivingSituation s, AppLocalizations? l) {
    switch (s) {
      case DrivingSituation.idle:
        return l?.situationIdle ?? 'Idle';
      case DrivingSituation.stopAndGo:
        return l?.situationStopAndGo ?? 'Stop & go';
      case DrivingSituation.urbanCruise:
        return l?.situationUrban ?? 'Urban';
      case DrivingSituation.highwayCruise:
        return l?.situationHighway ?? 'Highway';
      case DrivingSituation.deceleration:
        return l?.situationDecel ?? 'Decelerating';
      case DrivingSituation.climbingOrLoaded:
        return l?.situationClimbing ?? 'Climbing / loaded';
      // Transients are filtered out at the call site.
      case DrivingSituation.hardAccel:
      case DrivingSituation.fuelCutCoast:
        return s.name;
    }
  }
}

class _BaselineRow extends StatelessWidget {
  final String label;
  final int count;
  final int fullConfidenceSamples;

  const _BaselineRow({
    required this.label,
    required this.count,
    required this.fullConfidenceSamples,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (count / fullConfidenceSamples).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            flex: 5,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              '$count/$fullConfidenceSamples',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
