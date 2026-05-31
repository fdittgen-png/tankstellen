// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/entities/vehicle_profile.dart';
import '../domain/fuzzy_classifier.dart';
import 'vehicle_providers.dart';

part 'calibration_mode_providers.g.dart';

/// A single driving sample (#894) as far as the vehicle-side
/// calibration pipeline cares about it.
///
/// Intentionally thin: we don't depend on the consumption feature's
/// `DrivingSample` here because the vehicle layer must not import
/// `lib/features/consumption/**`. Callers that already hold a richer
/// `DrivingSample` can drop its fields into this struct before
/// invoking [applyCalibrationVotes].
class CalibrationSample {
  final double speedKmh;
  final double accelMps2;
  final double gradePct;
  final double throttlePct;
  final double rpm;

  /// Caller-owned stop-and-go flag — true when the 30-second rolling
  /// speed variance exceeds the stop-and-go threshold. Keeps the
  /// fuzzy classifier pure.
  final bool isStopAndGoContext;

  /// Observed value to bump the Welford accumulator with (L/h, L/100 km,
  /// or whatever the caller is learning). The fuzzy path feeds this
  /// into multiple buckets weighted by membership.
  final double observedValue;

  // --- #2515 (epic #2512) signals the three new buckets need --------
  /// Engine / absolute load %, feeding the sustained-load + climbing
  /// load ramps. 0 when neither load PID is available.
  final double loadPct;

  /// Engine coolant temperature in °C (PID 0x05) — gates the cold-start
  /// bucket. Null when the car doesn't surface it.
  final double? coolantTempC;

  /// Engine oil temperature in °C (PID 0x5C) — the cold-start fallback
  /// when [coolantTempC] is null.
  final double? oilTempC;

  /// Ambient air temperature in °C (PID 0x46) — plumbed for PR 2's
  /// precision folding; not consumed by [classify] yet.
  final double? ambientTempC;

  /// Accelerator-pedal position % (PIDs 0x49–0x4B) — driver intent,
  /// plumbed for PR 2; not consumed by [classify] yet.
  final double? pedalPct;

  const CalibrationSample({
    required this.speedKmh,
    required this.accelMps2,
    required this.gradePct,
    required this.throttlePct,
    required this.rpm,
    required this.observedValue,
    this.isStopAndGoContext = false,
    this.loadPct = 0,
    this.coolantTempC,
    this.oilTempC,
    this.ambientTempC,
    this.pedalPct,
  });
}

/// One (situation, weighted-value) vote produced by a calibration
/// sample. The downstream `BaselineStore` converts these back into
/// Welford updates.
class SituationVote {
  final Situation situation;
  final double weight;
  final double value;

  const SituationVote({
    required this.situation,
    required this.weight,
    required this.value,
  });
}

/// Fuzzy classifier provider. Pure, stateless — kept behind a
/// Riverpod provider so tests can `override` it with a spy if they
/// want to assert classification was invoked.
@Riverpod(keepAlive: true)
FuzzyClassifier fuzzyClassifier(Ref ref) => const FuzzyClassifier();

/// Turn [sample] into a list of Welford votes according to the
/// vehicle's current calibration mode.
///
/// * `rule` mode → one vote at weight 1.0 on whatever situation wins
///   by plain threshold logic — matches the legacy #779 behaviour.
/// * `fuzzy` mode → up to seven votes, one per situation, weights
///   summing to 1.0.
///
/// Calibration reserves the right to drop situations we don't
/// persist (the #779 store filters transients anyway).
@Riverpod(keepAlive: true)
List<SituationVote> calibrationVotes(
  Ref ref, {
  required String vehicleId,
  required CalibrationSample sample,
}) {
  final profile = ref
      .watch(vehicleProfileListProvider)
      .where((v) => v.id == vehicleId)
      .firstOrNull;
  final mode = profile?.calibrationMode ?? VehicleCalibrationMode.rule;

  if (mode == VehicleCalibrationMode.rule) {
    final winner = _ruleWinner(sample);
    return [
      SituationVote(
        situation: winner,
        weight: 1,
        value: sample.observedValue,
      ),
    ];
  }

  final memberships = ref.read(fuzzyClassifierProvider).classify(
        speedKmh: sample.speedKmh,
        accel: sample.accelMps2,
        grade: sample.gradePct,
        throttlePct: sample.throttlePct,
        rpm: sample.rpm,
        isStopAndGoContext: sample.isStopAndGoContext,
        // #2515 — feed the load + precision signals so the new buckets
        // (cold-start / sustained-load / partial-decel) can fire.
        loadPct: sample.loadPct,
        coolantTempC: sample.coolantTempC,
        oilTempC: sample.oilTempC,
        ambientTempC: sample.ambientTempC,
        pedalPct: sample.pedalPct,
      );

  return [
    for (final entry in memberships.entries)
      if (entry.value > 0)
        SituationVote(
          situation: entry.key,
          weight: entry.value,
          value: sample.observedValue,
        ),
  ];
}

/// Replay state for "what happens when the user flips the
/// calibration mode" — the UI kicks this, the test asserts on it.
///
/// We can't re-ingest a historical OBD2 trip from raw samples
/// (Tankstellen only persists Welford summaries, not per-tick
/// sample arrays) so "re-run on the last trip" means: trigger a
/// replay event. Consumers (e.g. a future trip-history replay
/// job) subscribe to the invalidation signal.
@Riverpod(keepAlive: true)
class CalibrationReplayQueue extends _$CalibrationReplayQueue {
  @override
  List<String> build() => const <String>[];

  /// Enqueue a replay for [vehicleId]. Idempotent — duplicate
  /// enqueues collapse.
  void requestReplay(String vehicleId) {
    if (state.contains(vehicleId)) return;
    state = [...state, vehicleId];
  }

  /// Clear one vehicle's queued replay (callers call this after
  /// they've finished reprocessing).
  void consume(String vehicleId) {
    state = state.where((id) => id != vehicleId).toList();
  }
}

/// Internal: #779-compatible winner-take-all rule used by the `rule`
/// calibration mode. Matches the classifier pseudo-code from the
/// original baseline work — idle < 2 km/h, stop-and-go flagged by
/// the caller, highway ≥ 80 km/h, climbing > 3 % grade under load,
/// decel when coasting off the pedal, fuel-cut when injectors close.
///
/// #2515 adds the three new buckets in priority order:
///  * **coldStart** is checked FIRST — a cold engine running rich must
///    win over everything else (mirrors the fuzzy path's high-priority
///    override) so warm-up samples never pollute a steady-state mean.
///  * **partialDecel** sits between [Situation.decel] and the
///    speed-based modes: the gentle-coast accel band `[-0.5, -0.1)` is
///    disjoint from decel's `< -0.5`, so the two never collide.
///  * **sustainedLoad** is checked right after the climbing-grade test
///    — same high-load signature but on the flat (grade < 2 %).
Situation _ruleWinner(CalibrationSample s) {
  // #2515 — cold-start override: coolant (or oil when coolant is null)
  // below operating temperature beats every other classification.
  final temp = s.coolantTempC ?? s.oilTempC;
  final coldThreshold = s.coolantTempC != null ? 70 : 60;
  if (temp != null && temp < coldThreshold) {
    return Situation.coldStart;
  }
  if (s.throttlePct < 5 && s.rpm > 1500 && s.speedKmh > 20) {
    return Situation.fuelCut;
  }
  if (s.accelMps2 < -0.5 && s.throttlePct < 5) {
    return Situation.decel;
  }
  // #2515 — partial-throttle / gentle coast: lighter lift-off than
  // decel, injectors still firing. Disjoint accel band from decel.
  if (s.accelMps2 >= -0.5 &&
      s.accelMps2 < -0.1 &&
      s.throttlePct < 5 &&
      s.speedKmh > 15) {
    return Situation.partialDecel;
  }
  if (s.speedKmh <= 2) return Situation.idle;
  if (s.isStopAndGoContext) return Situation.stopAndGo;
  if (s.gradePct >= 3) return Situation.climbing;
  // #2515 — sustained load / towing on the flat: the same high-load,
  // moving signature as a climb but with no grade.
  if (s.gradePct < 2 && s.speedKmh > 20 && s.loadPct >= 60) {
    return Situation.sustainedLoad;
  }
  if (s.speedKmh >= 80) return Situation.highway;
  return Situation.urban;
}
