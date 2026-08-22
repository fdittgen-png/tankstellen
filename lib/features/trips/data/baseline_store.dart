// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../../core/logging/error_logger.dart';
import '../domain/baseline_rolling_state.dart';
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
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st, context: {
        'where': 'BaselineStore.loadVehicle: corrupt payload for $vehicleId'
      }));
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
    String? stratumId,
  }) =>
      recordWeighted(
        vehicleId: vehicleId,
        situation: situation,
        value: value,
        weight: 1.0,
        stratumId: stratumId,
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
    String? stratumId,
  }) {
    if (weight <= 0) return;
    if (situation == DrivingSituation.hardAccel ||
        situation == DrivingSituation.fuelCutCoast) {
      return;
    }
    final byVehicle = _cache.putIfAbsent(vehicleId, () => {});
    // #2515 — writes always go to the altitude-stratified composite key
    // `'${situation.name}#$stratumId'`. A null stratum (callers that
    // don't know the altitude — rule-mode tests, legacy paths) writes to
    // the sea-level band, so a sample is never lost.
    final acc = byVehicle.putIfAbsent(
      _compositeKey(situation, stratumId),
      () => WelfordAccumulator(),
    );
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
    String? stratumId,
  }) {
    final coldStart = coldStartBaseline(fuelFamily, situation);
    // #2515 — prefer the altitude-stratified band for this sample; fall
    // back to the legacy bare key (pre-#2515 data, written without a
    // stratum) when the composite cell hasn't accumulated yet, so
    // existing users keep their learned baseline.
    final byVehicle = _cache[vehicleId];
    final acc = byVehicle?[_compositeKey(situation, stratumId)] ??
        byVehicle?[situation.name];
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
  ///
  /// #2515 — with no [stratumId] this sums every altitude band for the
  /// situation (plus any legacy bare-key cell), so the calibration
  /// coverage UI counts a situation as "learned" once its samples reach
  /// the target across all altitudes combined. Pass a [stratumId] to
  /// read a single band.
  int sampleCount({
    required String vehicleId,
    required DrivingSituation situation,
    String? stratumId,
  }) {
    final byVehicle = _cache[vehicleId];
    if (byVehicle == null) return 0;
    if (stratumId != null) {
      return byVehicle[_compositeKey(situation, stratumId)]?.n ?? 0;
    }
    var total = 0;
    final prefix = '${situation.name}#';
    byVehicle.forEach((key, acc) {
      if (key == situation.name || key.startsWith(prefix)) total += acc.n;
    });
    return total;
  }

  /// Compose the on-disk key for a (situation, altitude-stratum) cell.
  /// A null [stratumId] uses the sea-level band so a sample is never
  /// lost when the altitude is unknown.
  String _compositeKey(DrivingSituation situation, String? stratumId) =>
      '${situation.name}#${stratumId ?? BaselineAltitudeStratum.seaLevel.id}';

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
