// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../../core/sync/baselines_sync.dart';
import '../../sync/providers/baseline_sync_enabled_provider.dart';
import '../../../core/domain/vehicle_profile.dart';
import '../../vehicle/domain/fuzzy_classifier.dart';
import '../../vehicle/providers/calibration_mode_providers.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../data/baseline_store.dart';
import '../../obd2/api.dart';
import '../domain/baseline_rolling_state.dart';
import '../domain/cold_start_baselines.dart';
import '../domain/situation_classifier.dart';
import '../../../core/logging/error_logger.dart';

/// Owns the #769 / #780 / #894 baseline-learning concern extracted
/// from the [TripRecording] notifier (#1679): the per-trip situation
/// classifier, the learned-baseline [BaselineStore], and the
/// classify → record → band → delta pipeline that runs on every live
/// reading.
///
/// The notifier hands one live reading in via [recordAndClassify] and
/// gets `(situation, band, delta)` back to stamp onto its state. The
/// collaborator reads its Riverpod dependencies through [_ref].
class TripBaselineRecorder {
  /// [now] is an injectable clock — production passes the default
  /// `DateTime.now`; tests inject a virtual clock so the rolling
  /// stop-and-go window and the rule-path [SituationClassifier]'s
  /// debounce advance deterministically without real time passing
  /// (#2513).
  TripBaselineRecorder(this._ref, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final Ref _ref;
  final DateTime Function() _now;

  SituationClassifier? _classifier;
  BaselineStore? _store;
  String? _vehicleId;
  ConsumptionFuelFamily _fuelFamily = ConsumptionFuelFamily.gasoline;

  /// #2513 — per-trip rolling window (30-s speed variance + finite-diff
  /// accel) and GPS-altitude road-grade estimate the fuzzy path needs.
  /// The [FuzzyClassifier] is pure, so this windowed state lives here.
  final BaselineRollingState _rolling = BaselineRollingState();

  /// Vehicle id the current recording's baselines are scoped to.
  /// Surfaced so the notifier can tag the active-trip snapshot and
  /// the saved [TripHistoryEntry] with it. Null between trips.
  String? get vehicleId => _vehicleId;

  /// #769 — resolve the active vehicle + fuel family and load its
  /// learned baselines from Hive. Falls back silently to cold-start
  /// defaults when the box isn't open (widget tests) or the active
  /// vehicle is unavailable.
  Future<void> load() async {
    _classifier = SituationClassifier();
    // #2513 — start each trip with a clean stop-and-go window + grade
    // estimate so the previous trip's tail can't leak into the first
    // few samples.
    _rolling.reset();
    try {
      final vehicle = _ref.read(activeVehicleProfileProvider);
      _vehicleId = vehicle?.id;
      _fuelFamily = _resolveFuelFamily(vehicle?.preferredFuelType);
      if (Hive.isBoxOpen(HiveBoxes.obd2Baselines)) {
        _store = BaselineStore(
          box: Hive.box<String>(HiveBoxes.obd2Baselines),
        );
        if (_vehicleId != null) {
          await _store!.loadVehicle(_vehicleId!);
        }
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording.start: baseline setup failed'}));
      _store = null;
    }
  }

  /// Classify one live [reading], record it into the learned-baseline
  /// store, and return the situation, consumption band, and live
  /// delta-fraction the notifier stamps onto its state.
  ({DrivingSituation situation, ConsumptionBand band, double? delta})
      recordAndClassify(TripLiveReading reading) {
    // #2513 — fold this reading into the rolling stop-and-go window and
    // the road-grade estimate BEFORE classifying, so the fuzzy path
    // sees the up-to-date context (variance flag, finite-diff accel,
    // confident grade) for this very sample.
    _rolling.add(reading, _now());
    final situation = _classifyFrom(reading);
    _recordToStore(reading, situation);
    final band = _classifyBandFrom(reading, situation);
    final delta = _computeDelta(reading, situation);
    return (situation: situation, band: band, delta: delta);
  }

  /// #769 — flush learned baselines before releasing the service so
  /// the next trip starts from the updated values, then #780 — fold
  /// in the server copy. Best-effort: a Hive write failure here
  /// shouldn't block trip teardown. Resets state for the next trip.
  Future<void> flushAndSync() async {
    final store = _store;
    final vid = _vehicleId;
    if (store != null && vid != null) {
      try {
        await store.flush(vid);
      } catch (e, st) {
        unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording.stop: baseline flush failed'}));
      }
      // #780 — fold in the server copy once the local flush lands.
      await _syncBaselineAfterFlush(vid);
    }
    _store = null;
    _vehicleId = null;
    _classifier = null;
    // #2513 — drop the rolling stop-and-go window + grade state.
    _rolling.reset();
  }

  /// Map a [FuelType] apiValue onto a [ConsumptionFuelFamily] for
  /// the cold-start tables. Everything that isn't diesel maps to
  /// gasoline — LPG/CNG calorific values are close enough to petrol
  /// that the cold-start number is within measurement noise.
  ConsumptionFuelFamily _resolveFuelFamily(String? apiValue) {
    if (apiValue == null) return ConsumptionFuelFamily.gasoline;
    if (apiValue.startsWith('diesel')) return ConsumptionFuelFamily.diesel;
    return ConsumptionFuelFamily.gasoline;
  }

  void _recordToStore(TripLiveReading r, DrivingSituation situation) {
    final store = _store;
    final vid = _vehicleId;
    if (store == null || vid == null) return;
    final baseline = coldStartBaseline(_fuelFamily, situation);
    final live = _liveConsumptionFor(r, baseline);
    if (live == null) return;

    // #894 wiring (#1426): when the active vehicle has opted into
    // fuzzy calibration, route this sample through the fuzzy
    // classifier and record one weighted vote per non-zero
    // membership bucket. Rule mode keeps the legacy single-bucket
    // path so users who haven't opted in see no behaviour change.
    final profile = _tryReadActiveVehicle();
    if (profile?.calibrationMode == VehicleCalibrationMode.fuzzy) {
      _recordFuzzy(store, vid, r, live);
      return;
    }

    store.record(
      vehicleId: vid,
      situation: situation,
      value: live,
      // #2515 — stratify the learned mean by altitude band.
      stratumId: _rolling.altitudeStratumId,
    );
  }

  /// Fuzzy path: split [live] across all non-transient buckets the
  /// classifier flags as members, weighted by membership.
  ///
  /// #2513 — every input the classifier needs is now derived from the
  /// recorder's rolling state instead of the previous `0` literals that
  /// left `stopAndGo` and `climbing` permanently empty:
  ///
  ///  * `isStopAndGoContext` from the 30-s speed-variance window;
  ///  * `grade` from the GPS-altitude [RoadGradeCalculator], but only
  ///    when it's confident (else 0 → the load ramp carries climbing);
  ///  * `loadPct` from absolute / engine load, so a loaded-flat drive
  ///    still fills climbing on cars without GPS altitude;
  ///  * `throttlePct` from the real PID 0x11 throttle (engine-load
  ///    proxy only as a fallback);
  ///  * `accel` from a finite difference over the speed window so the
  ///    decel membership can fire.
  ///
  /// #2515 (PR 2) — two precision-folding steps wrap the record loop:
  /// (1) the per-sample [live] value is renormalised by
  /// [BaselineRollingState.fuelMassCorrectionFactor] (λ / fuel-trim /
  /// MAP-density) before it feeds the Welford accumulator, so a bucket
  /// learns the stoichiometric demand instead of an average of commanded
  /// mixtures — the factor degrades to 1.0 per missing PID, so no-PID
  /// cars are unchanged; (2) a belt-and-braces warm-up gate: while
  /// [BaselineRollingState.isWarmUp] holds, only the cold-start bucket
  /// may record, so warm-up never bleeds into a steady mean even if the
  /// classifier's own cold-start override ever regresses.
  ///
  /// [Situation.fuelCut] maps onto a transient and is filtered by
  /// [BaselineStore]; we drop it pre-call so the bridge stays explicit.
  void _recordFuzzy(
    BaselineStore store,
    String vehicleId,
    TripLiveReading r,
    double live,
  ) {
    final classifier = _ref.read(fuzzyClassifierProvider);
    final memberships = classifier.classify(
      speedKmh: r.speedKmh ?? 0,
      accel: _rolling.recentAccelMps2(),
      grade: _rolling.confidentGradePct,
      throttlePct: BaselineRollingState.throttleSignal(r) ?? 0,
      rpm: r.rpm ?? 0,
      isStopAndGoContext: _rolling.isStopAndGoContext,
      loadPct: BaselineRollingState.loadSignal(r),
      // #2515 — feed the precision signals so the cold-start /
      // partial-decel buckets can fire. coldStart gates on coolant (or
      // oil when coolant is null); pedal/ambient are plumbed for PR 2.
      coolantTempC: r.coolantTempC,
      oilTempC: r.oilTempC,
      ambientTempC: r.ambientTempC,
      pedalPct: r.pedalPercent,
    );
    // #2515 PR2 — stoichiometry-normalise the sample's value so two
    // samples at different commanded mixtures yield comparable
    // baselines. Identity (× 1.0) on cars lacking the λ/trim/MAP PIDs.
    final corrected = live * BaselineRollingState.fuelMassCorrectionFactor(r);
    // #2515 PR2 — belt-and-braces warm-up gate: while the engine is
    // below operating temperature, only the cold-start bucket may
    // record. Robust even if the classifier's own cold-start override
    // ever regresses.
    final warmUp = BaselineRollingState.isWarmUp(r);
    for (final entry in memberships.entries) {
      if (entry.value <= 0) continue;
      final ds = _bridgeFuzzySituation(entry.key);
      if (ds == null) continue;
      if (warmUp && ds != DrivingSituation.coldStartWarmup) continue;
      store.recordWeighted(
        vehicleId: vehicleId,
        situation: ds,
        value: corrected,
        weight: entry.value,
        // #2515 — stratify the learned mean by altitude band.
        stratumId: _rolling.altitudeStratumId,
      );
    }
  }

  /// Bridge between the vehicle layer's [Situation] enum (#894) and
  /// the consumption layer's [DrivingSituation] enum (#769). Returns
  /// null for transient buckets the [BaselineStore] doesn't persist.
  static DrivingSituation? _bridgeFuzzySituation(Situation s) {
    switch (s) {
      case Situation.idle:
        return DrivingSituation.idle;
      case Situation.stopAndGo:
        return DrivingSituation.stopAndGo;
      case Situation.urban:
        return DrivingSituation.urbanCruise;
      case Situation.highway:
        return DrivingSituation.highwayCruise;
      case Situation.climbing:
        return DrivingSituation.climbingOrLoaded;
      case Situation.decel:
        return DrivingSituation.deceleration;
      case Situation.fuelCut:
        return null;
      // #2515 — the three new buckets map 1:1 onto their consumption-
      // layer mirrors. All three are persistent (not transient).
      case Situation.coldStart:
        return DrivingSituation.coldStartWarmup;
      case Situation.sustainedLoad:
        return DrivingSituation.sustainedLoadOrTowing;
      case Situation.partialDecel:
        return DrivingSituation.partialThrottleDecel;
    }
  }

  SituationBaseline _baselineFor(DrivingSituation situation) {
    final store = _store;
    final vid = _vehicleId;
    if (store == null || vid == null) {
      return coldStartBaseline(_fuelFamily, situation);
    }
    return store.lookup(
      vehicleId: vid,
      situation: situation,
      fuelFamily: _fuelFamily,
      // #2515 — read the band matching the car's current altitude, with
      // the store falling back to the legacy bare key when the band is
      // still empty.
      stratumId: _rolling.altitudeStratumId,
    );
  }

  DrivingSituation _classifyFrom(TripLiveReading r) {
    final cls = _classifier;
    if (cls == null) return DrivingSituation.idle;
    return cls.onSample(DrivingSample(
      timestamp: _now(),
      speedKmh: r.speedKmh ?? 0,
      rpm: r.rpm ?? 0,
      // #2513 — feed the real PID 0x11 throttle into the throttle slot;
      // the calculated engine load only stands in when throttle is
      // unavailable. Previously engine load was mis-fed into BOTH slots,
      // which over-read the closed-pedal state and corrupted the
      // idle / decel / urban gating.
      throttlePercent: r.throttlePercent ?? r.engineLoadPercent,
      engineLoadPercent: r.engineLoadPercent,
      fuelRateLPerHour: r.fuelRateLPerHour,
      // #2515 — coolant lets the rule path detect a cold-start warm-up;
      // the confident grade lets it separate a flat sustained load
      // (towing) from a hill climb.
      coolantTempC: r.coolantTempC,
      gradePct: _rolling.confidentGradePct,
    ));
  }

  ConsumptionBand _classifyBandFrom(
    TripLiveReading r,
    DrivingSituation situation,
  ) {
    final baseline = _baselineFor(situation);
    final live = _liveConsumptionFor(r, baseline);
    if (live == null) return ConsumptionBand.normal;
    return classifyBand(
      situation: situation,
      live: live,
      baseline: baseline,
    );
  }

  double? _computeDelta(
    TripLiveReading r,
    DrivingSituation situation,
  ) {
    final baseline = _baselineFor(situation);
    if (baseline.value <= 0) return null;
    final live = _liveConsumptionFor(r, baseline);
    if (live == null) return null;
    return (live - baseline.value) / baseline.value;
  }

  /// Compute the live consumption value in the baseline's unit —
  /// L/h for idle baselines, L/100 km otherwise. Returns null when
  /// the car isn't reporting enough data to derive the metric.
  double? _liveConsumptionFor(
    TripLiveReading r,
    SituationBaseline baseline,
  ) {
    final fuelRate = r.fuelRateLPerHour;
    final speed = r.speedKmh;
    if (fuelRate == null) return null;
    if (baseline.unit == BaselineUnit.lPerHour) return fuelRate;
    if (speed == null || speed <= 5) return null; // avoid /0
    return fuelRate * 100.0 / speed;
  }

  /// Read the active vehicle profile, swallowing any provider-wiring
  /// errors that show up in widget tests (where the Riverpod graph
  /// for the vehicle-active-profile chain isn't always overridden).
  VehicleProfile? _tryReadActiveVehicle() {
    try {
      return _ref.read(activeVehicleProfileProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording: active vehicle unavailable'}));
      return null;
    }
  }

  /// #780 — merge local + server baselines for [vehicleId] via the
  /// sync service. Called after the Hive flush so the payload on
  /// disk is what actually gets sent, and the merged result (higher
  /// per-situation sample counts) overwrites disk for the next
  /// trip. No-op when the Hive box is closed or the sync client
  /// is offline/unauthenticated — both paths return the input
  /// payload unchanged.
  Future<void> _syncBaselineAfterFlush(String vehicleId) async {
    try {
      // #780 phase 3 — honour the opt-in setting. Default false so
      // users who never toggled it in the sync setup screen don't
      // silently upload driving data. Ungated favourite sync etc.
      // are unaffected.
      // #1373 phase 3e — read the central feature flag instead of the
      // legacy Hive key. ref.read (not watch) — this is a one-shot
      // gate at flush time, not a reactive dependency.
      final enabled = _ref.read(baselineSyncEnabledProvider);
      if (!enabled) return;
      if (!Hive.isBoxOpen(HiveBoxes.obd2Baselines)) return;
      final box = Hive.box<String>(HiveBoxes.obd2Baselines);
      final key = 'baseline:$vehicleId';
      final localJson = box.get(key);
      final merged = await BaselinesSync.merge(
        vehicleId: vehicleId,
        localJson: localJson,
      );
      if (merged != null && merged != localJson) {
        await box.put(key, merged);
        // No in-memory cache refresh needed — _store is nulled out
        // right after this call and the next trip creates a fresh
        // BaselineStore whose loadVehicle reads the merged JSON
        // from disk.
      }
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {'where': 'TripRecording.stop: baseline sync failed'}));
    }
  }
}
