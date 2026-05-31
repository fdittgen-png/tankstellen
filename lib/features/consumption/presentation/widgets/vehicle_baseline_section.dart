// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
///
/// #1529 — collapsed by default to a single aggregate progress bar
/// + sample tally. Tap the "Show details" affordance to reveal the
/// per-driving-situation breakdown (the original 6-row view). Saves
/// ~360 dp on the vehicle-edit screen for users who only care
/// whether their baseline is "ready" or not.
///
/// #2514 — the aggregate bar tracks *coverage* (Σ min(count, target))
/// rather than raw sample volume, so an over-filled bucket (urban
/// 224k) can no longer drive it to 100% while Stop & go / Climbing
/// sit at 0/30. When any persisted situation has zero samples a
/// warning chip names the missing buckets and the per-situation
/// breakdown auto-expands.
class VehicleBaselineSection extends ConsumerStatefulWidget {
  final String vehicleId;

  /// Sample count at which the baseline is considered fully learned —
  /// mirrors [BaselineStore.fullConfidenceSamples]. Kept as a field so
  /// tests can exercise partial-confidence rendering without pumping
  /// 30 synthetic samples.
  final int fullConfidenceSamples;

  /// Test/diagnostic seam: when true, the per-driving-situation
  /// breakdown is visible from the first frame instead of behind the
  /// "Show details" toggle (#1529). Production callers leave it
  /// `false` so the user gets the compact aggregate view by default.
  final bool expandDetailsByDefault;

  const VehicleBaselineSection({
    super.key,
    required this.vehicleId,
    this.fullConfidenceSamples = 30,
    this.expandDetailsByDefault = false,
  });

  @override
  ConsumerState<VehicleBaselineSection> createState() =>
      _VehicleBaselineSectionState();
}

class _VehicleBaselineSectionState
    extends ConsumerState<VehicleBaselineSection> {
  /// `null` means "follow the auto policy" (expand when buckets are
  /// empty, #2514, or when the test seam forces it). Once the user taps
  /// the toggle we latch their explicit choice here and stop deriving
  /// it from coverage.
  bool? _showDetailsOverride;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final counts =
        ref.watch(vehicleBaselineSummaryProvider(widget.vehicleId));
    final theme = Theme.of(context);

    // Persisted situations only — transients never accumulate. The
    // three #2515 buckets (cold-start / sustained-load / partial-decel)
    // are persistent, so they join the breakdown + the coverage bar.
    const situations = [
      DrivingSituation.idle,
      DrivingSituation.stopAndGo,
      DrivingSituation.urbanCruise,
      DrivingSituation.highwayCruise,
      DrivingSituation.deceleration,
      DrivingSituation.climbingOrLoaded,
      DrivingSituation.coldStartWarmup,
      DrivingSituation.sustainedLoadOrTowing,
      DrivingSituation.partialThrottleDecel,
    ];

    final target = widget.fullConfidenceSamples;
    final totalSamples =
        situations.fold<int>(0, (acc, s) => acc + (counts[s] ?? 0));
    final maxTotal = situations.length * target;

    // #2514 — drive the aggregate bar off *coverage*, not raw volume.
    // Σ min(count, target) caps each bucket at its target, so a single
    // over-filled situation (urban 224k) can no longer mask two empty
    // ones: the bar can NEVER read 100% while any persisted bucket is
    // still 0/target.
    final coveredSamples = situations.fold<int>(
      0,
      (acc, s) => acc + (counts[s] ?? 0).clamp(0, target),
    );
    final coverageValue = maxTotal == 0 ? 0.0 : coveredSamples / maxTotal;

    // Persisted situations that have not accumulated a single sample yet
    // (e.g. Stop & go and Climbing on the Fuzzy path, #2512). When any
    // exist — and the baseline isn't simply empty — we surface a warning
    // chip and force the per-situation breakdown open so the user sees
    // exactly which buckets are stuck at 0/target.
    final missingSituations = totalSamples == 0
        ? const <DrivingSituation>[]
        : [
            for (final s in situations)
              if ((counts[s] ?? 0) == 0) s,
          ];
    final hasMissing = missingSituations.isNotEmpty;

    // Auto-expand when buckets are empty (or the test seam asks for it);
    // otherwise honour the user's explicit toggle, defaulting collapsed.
    final showDetails =
        _showDetailsOverride ?? (widget.expandDetailsByDefault || hasMissing);

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
            // #1529 — aggregate progress bar shown always; per-
            // situation breakdown only when the user taps Show
            // details. Saves 5 of the 6 rows (~300 dp) on the
            // common path.
            //
            // #2514 — the bar tracks COVERAGE (Σ min(count, target)),
            // not raw volume, so it can never sit at 100% while a
            // bucket is empty.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                key: const Key('vehicleBaselineAggregateBar'),
                value: coverageValue,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$coveredSamples / $maxTotal samples',
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.right,
            ),
            // #2514 — surface the empty buckets the over-filled
            // aggregate used to hide, so the user knows a driving
            // situation has never been detected yet.
            if (hasMissing) ...[
              const SizedBox(height: 8),
              _MissingSituationsWarning(
                situations: missingSituations
                    .map((s) => _label(s, l))
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const Key('vehicleBaselineDetailsToggle'),
                onPressed: () =>
                    setState(() => _showDetailsOverride = !showDetails),
                icon: Icon(
                  showDetails ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(
                  showDetails
                      ? (l?.vehicleBaselineHideDetails ??
                          'Hide per-situation breakdown')
                      : (l?.vehicleBaselineShowDetails ??
                          'Show per-situation breakdown'),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
            if (showDetails) ...[
              const SizedBox(height: 4),
              for (final s in situations)
                _BaselineRow(
                  label: _label(s, l),
                  count: counts[s] ?? 0,
                  fullConfidenceSamples: widget.fullConfidenceSamples,
                ),
            ],
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
    await ref.read(resetVehicleBaselinesProvider(widget.vehicleId).future);
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
      // #2515 — the three new persistent buckets.
      case DrivingSituation.coldStartWarmup:
        return l?.situationColdStart ?? 'Cold start';
      case DrivingSituation.sustainedLoadOrTowing:
        return l?.situationSustainedLoad ?? 'Sustained load / towing';
      case DrivingSituation.partialThrottleDecel:
        return l?.situationPartialDecel ?? 'Coasting';
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

/// #2514 — amber warning chip listing the driving situations that have
/// never been detected (0 samples). It exists because the coverage bar
/// alone tells the user calibration is incomplete but not *which*
/// buckets are stuck; naming them (e.g. "Stop & go", "Climbing /
/// loaded") points at the root cause tracked by Epic #2512.
class _MissingSituationsWarning extends StatelessWidget {
  final List<String> situations;

  const _MissingSituationsWarning({required this.situations});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Comma-join is locale-neutral punctuation, not prose.
    final joined = situations.join(', '); // i18n-ignore: list separator
    return Container(
      key: const Key('vehicleBaselineMissingWarning'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l?.vehicleBaselineMissingWarning(joined) ??
                  'Not detected yet: $joined. These driving situations '
                      'still read 0 samples, so the baseline is incomplete.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
