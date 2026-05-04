import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../domain/cold_start_baselines.dart';
import '../domain/situation_classifier.dart';
import 'welford.dart';

/// Hive-backed per-vehicle per-situation baseline store (#769).
///
/// Every steady-state sample the recording provider observes gets
/// fed in via [record]. The store updates a Welford accumulator for
/// the right (vehicle, situation) cell and, at trip end, [flush]
/// writes the accumulators back to disk.
///
/// Only steady-state situations are persisted — transients
/// (`hardAccel`, `fuelCutCoast`) are events rather than stable
/// baselines and always yield [ConsumptionBand.transient] anyway.
///
/// On read, [lookup] weights the learned mean against the
/// cold-start default: 0 % learned weight for a brand-new vehicle,
/// 100 % once the sample count for that situation reaches
/// [fullConfidenceSamples] (default 30, ≈5 min of driving in that
/// mode). The shape of the blend is linear — simple, predictable,
/// no surprising S-curve artefacts.
class BaselineStore {
  /// Welford accumulators, keyed by vehicleId → situation name →
  /// accumulator. Situations are stored by their enum `.name` string
  /// to keep the Hive encoding version-independent of Dart enum
  /// index ordering.
  final Map<String, Map<String, WelfordAccumulator>> _cache = {};

  /// Hive box where the per-vehicle baselines are persisted. Tests
  /// can inject a fake implementing the same Box API.
  final Box<String> _box;

  final int fullConfidenceSamples;

  BaselineStore({
    required Box<String> box,
    this.fullConfidenceSamples = 30,
  }) : _box = box;

  /// Box name used by the production wiring. Tests use their own
  /// in-memory box with a different name so they don't collide.
  static const String boxName = 'obd2_baselines';

  /// Load all persisted baselines for [vehicleId] into the in-memory
  /// cache. Idempotent — re-reading an already-cached vehicle is a
  /// no-op. Called at trip start from the provider.
  Future<void> loadVehicle(String vehicleId) async {
    if (_cache.containsKey(vehicleId)) return;
    final raw = _box.get(_keyFor(vehicleId));
    if (raw == null || raw.isEmpty) {
      _cache[vehicleId] = {};
      return;
    }
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final perSituation = decoded['perSituation'] as Map<String, dynamic>?;
      final m = <String, WelfordAccumulator>{};
      perSituation?.forEach((k, v) {
        if (v is Map) {
          m[k] = WelfordAccumulator.fromJson(Map<String, dynamic>.from(v));
        }
      });
      _cache[vehicleId] = m;
    } catch (e, st) { // ignore: unused_catch_stack
      debugPrint('BaselineStore.loadVehicle: corrupt payload '
          'for $vehicleId — starting fresh: $e');
      _cache[vehicleId] = {};
    }
  }

  /// Feed one sample into the (vehicle, situation) accumulator.
  /// Silently ignores transient situations — they don't have a
  /// stable mean to learn.
  ///
  /// Defaults to weight 1.0 — the rule-mode (winner-take-all) path.
  /// The fuzzy path (#894) calls [recordWeighted] instead so it can
  /// split a single sample across multiple buckets.
  void record({
    required String vehicleId,
    required DrivingSituation situation,
    required double value,
  }) =>
      recordWeighted(
        vehicleId: vehicleId,
        situation: situation,
        value: value,
        weight: 1.0,
      );

  /// Feed one sample at [weight] into the (vehicle, situation)
  /// accumulator. Used by the fuzzy calibration path (#894 wiring) to
  /// route each driving sample's membership vector — one
  /// `recordWeighted` call per non-zero bucket — into a per-bucket
  /// [WelfordAccumulator] without inflating the rule-mode sample
  /// counter on near-zero votes.
  ///
  /// Zero weights are a no-op (the membership produced no contribution
  /// for this bucket). Transient situations are still skipped — the
  /// fuzzy classifier can flag `fuelCut` but it's not a baseline we
  /// learn a stable mean for.
  void recordWeighted({
    required String vehicleId,
    required DrivingSituation situation,
    required double value,
    required double weight,
  }) {
    if (weight <= 0) return;
    if (situation == DrivingSituation.hardAccel ||
        situation == DrivingSituation.fuelCutCoast) {
      return;
    }
    final byVehicle = _cache.putIfAbsent(vehicleId, () => {});
    final acc =
        byVehicle.putIfAbsent(situation.name, () => WelfordAccumulator());
    acc.updateWeighted(value, weight);
  }

  /// Look up the blended baseline for a (vehicle, situation) —
  /// learned-weight ramps linearly from 0 to 1 across
  /// [fullConfidenceSamples]. Returns the cold-start default unit,
  /// so callers don't have to juggle L/h vs L/100 km.
  ///
  /// Uses [WelfordAccumulator.effectiveSampleCount] (#1426) rather
  /// than the raw count — under the fuzzy path a bucket fed by 30
  /// samples × 0.05 weight has effective N = 1.5, not 30, and the
  /// blend correctly stays close to the cold-start default until the
  /// bucket actually accumulates ground-truth-equivalent evidence.
  /// Pre-#1426 persisted baselines decode with effective-N == raw
  /// count (see [WelfordAccumulator.fromJson]) so existing users see
  /// no behaviour change.
  SituationBaseline lookup({
    required String vehicleId,
    required DrivingSituation situation,
    required ConsumptionFuelFamily fuelFamily,
  }) {
    final coldStart = coldStartBaseline(fuelFamily, situation);
    final acc = _cache[vehicleId]?[situation.name];
    if (acc == null || acc.effectiveSampleCount <= 0) return coldStart;
    final weight =
        (acc.effectiveSampleCount / fullConfidenceSamples).clamp(0.0, 1.0);
    final blended = acc.mean * weight + coldStart.value * (1.0 - weight);
    return SituationBaseline(blended, coldStart.unit);
  }

  /// Sample count for the (vehicle, situation) pair — useful for the
  /// UI to show "learning…" until the learned weight is meaningful.
  /// Returns the raw [WelfordAccumulator.n] count, which under the
  /// fuzzy path can over-state confidence. The blend math in [lookup]
  /// uses the effective-N formula and is the correct number to drive
  /// behaviour off; this getter is for the UI counter only.
  int sampleCount({
    required String vehicleId,
    required DrivingSituation situation,
  }) =>
      _cache[vehicleId]?[situation.name]?.n ?? 0;

  /// Persist the vehicle's accumulators to disk. Called at trip end;
  /// never mid-trip to keep 1 Hz polling off the I/O path.
  Future<void> flush(String vehicleId) async {
    final perSituation = _cache[vehicleId];
    if (perSituation == null) return;
    final payload = <String, dynamic>{
      'version': 1,
      'perSituation': {
        for (final e in perSituation.entries) e.key: e.value.toJson(),
      },
    };
    await _box.put(_keyFor(vehicleId), json.encode(payload));
  }

  /// Wipe every baseline for [vehicleId]. Exposed for a future
  /// "reset baselines" setting; not used in normal flow.
  Future<void> clear(String vehicleId) async {
    _cache[vehicleId] = {};
    await _box.delete(_keyFor(vehicleId));
  }

  String _keyFor(String vehicleId) => 'baseline:$vehicleId';
}
