// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/guarded.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/situation_classifier.dart';
import '../../providers/vehicle_baseline_summary_provider.dart';

part 'vehicle_baseline_section_parts.dart';

/// The persisted driving situations the baseline learns — transients
/// never accumulate. The three #2515 buckets (cold-start / sustained-
/// load / partial-decel) are persistent, so they join the breakdown +
/// the coverage bar.
const List<DrivingSituation> kBaselineSituations = [
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

/// Sample count at which a situation is considered fully learned —
/// mirrors `BaselineStore.fullConfidenceSamples`.
const int kBaselineFullConfidenceSamples = 30;

/// #2514 — baseline *coverage* in [0, 1]: Σ min(count, target) / (9 ×
/// target). Caps each bucket at its target, so a single over-filled
/// situation (urban 224k) can never mask two empty ones — the figure
/// can NEVER read 100% while any persisted bucket is still 0/target.
double baselineCoverageFraction(
  Map<DrivingSituation, int> counts, {
  int target = kBaselineFullConfidenceSamples,
}) {
  final maxTotal = kBaselineSituations.length * target;
  if (maxTotal == 0) return 0;
  final covered = kBaselineSituations.fold<int>(
    0,
    (acc, s) => acc + (counts[s] ?? 0).clamp(0, target),
  );
  return covered / maxTotal;
}

/// #3900 — the Edit-vehicle topic tile reads the coverage as a whole
/// percent without importing the summary provider (which stays
/// trips-internal). Guarded: an unwired provider reads as 0 %.
extension VehicleBaselineCoverage on WidgetRef {
  int baselineCoveragePercent(String vehicleId) => guard(
        () => (baselineCoverageFraction(
                  watch(vehicleBaselineSummaryProvider(vehicleId)),
                ) *
                100)
            .round(),
        where: 'VehicleBaselineCoverage: summary lookup failed',
        fallback: 0,
      );
}

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
/// sit at 0/30. When any persisted situation has zero samples an
/// informational chip names the missing buckets and the per-situation
/// breakdown auto-expands.
///
/// #3900 — a per-situation row reads `min(count, target)/target` with
/// a check once full, and the raw count as secondary text ("954
/// samples") — never "954/30". The not-yet-detected box is
/// informational, not an error.
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
    this.fullConfidenceSamples = kBaselineFullConfidenceSamples,
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
    final counts = ref.watch(vehicleBaselineSummaryProvider(widget.vehicleId));
    final theme = Theme.of(context);

    const situations = kBaselineSituations;
    final target = widget.fullConfidenceSamples;
    final totalSamples = situations.fold<int>(
      0,
      (acc, s) => acc + (counts[s] ?? 0),
    );
    final maxTotal = situations.length * target;

    // #2514 — drive the aggregate bar off *coverage*, not raw volume.
    final coveredSamples = situations.fold<int>(
      0,
      (acc, s) => acc + (counts[s] ?? 0).clamp(0, target),
    );
    final coverageValue = baselineCoverageFraction(counts, target: target);

    // Persisted situations that have not accumulated a single sample yet
    // (e.g. Stop & go and Climbing on the Fuzzy path, #2512). When any
    // exist — and the baseline isn't simply empty — we surface an
    // informational chip and force the per-situation breakdown open so
    // the user sees exactly which buckets are stuck at 0/target.
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
                    l.vehicleBaselineSectionTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              totalSamples == 0
                  ? (l.vehicleBaselineEmpty)
                  : (l.vehicleBaselineProgress),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            // #1529 — aggregate progress bar shown always; per-
            // situation breakdown only when the user taps Show
            // details. #2514 — the bar tracks COVERAGE, so it can never
            // sit at 100% while a bucket is empty.
            ClipRRect(
              borderRadius: AppRadius.md,
              child: LinearProgressIndicator(
                key: const Key('vehicleBaselineAggregateBar'),
                value: coverageValue,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.vehicleBaselineCoverageSamples(coveredSamples, maxTotal),
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.right,
            ),
            // #2514 — surface the empty buckets the over-filled
            // aggregate used to hide, so the user knows a driving
            // situation has never been detected yet.
            if (hasMissing) ...[
              const SizedBox(height: 8),
              _MissingSituationsNote(
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
                      ? (l.vehicleBaselineHideDetails)
                      : (l.vehicleBaselineShowDetails),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                // behaviour" connotation — distinct from the pump-gain
                // reset's local_gas_station_outlined icon (#1219).
                icon: const Icon(Icons.tune_outlined),
                label: Text(l.vehicleBaselineReset),
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
    AppLocalizations l,
  ) async {
    // #3682 — the ONE shared destructive-action dialog.
    final confirm = await confirmDestructiveAction(
      context,
      title: l.vehicleBaselineResetConfirmTitle,
      message: l.vehicleBaselineResetConfirmBody,
      confirmLabel: l.vehicleBaselineReset,
    );
    // #3159 — guard before the post-dialog ref use: a dead WidgetRef throws
    // a StateError under Riverpod 3, and the read itself performs the reset
    // so it cannot be captured before the confirmation dialog.
    if (confirm != true || !mounted) return;
    await ref.read(resetVehicleBaselinesProvider(widget.vehicleId).future);
  }

  String _label(DrivingSituation s, AppLocalizations l) {
    switch (s) {
      case DrivingSituation.idle:
        return l.situationIdle;
      case DrivingSituation.stopAndGo:
        return l.situationStopAndGo;
      case DrivingSituation.urbanCruise:
        return l.situationUrban;
      case DrivingSituation.highwayCruise:
        return l.situationHighway;
      case DrivingSituation.deceleration:
        return l.situationDecel;
      case DrivingSituation.climbingOrLoaded:
        return l.situationClimbing;
      // #2515 — the three new persistent buckets.
      case DrivingSituation.coldStartWarmup:
        return l.situationColdStart;
      case DrivingSituation.sustainedLoadOrTowing:
        return l.situationSustainedLoad;
      case DrivingSituation.partialThrottleDecel:
        return l.situationPartialDecel;
      // Transients are filtered out at the call site.
      case DrivingSituation.hardAccel:
      case DrivingSituation.fuelCutCoast:
        return s.name;
    }
  }
}
