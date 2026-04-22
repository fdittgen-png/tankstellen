import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/hive_boxes.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/baselines_sync.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../data/baseline_store.dart';
import '../data/obd2/obd2_service.dart';
import '../data/obd2/trip_recording_controller.dart';
import '../data/trip_history_repository.dart';
import '../domain/cold_start_baselines.dart';
import '../domain/situation_classifier.dart';
import '../domain/trip_recorder.dart';
import 'trip_history_provider.dart';

part 'trip_recording_provider.g.dart';

/// Lifecycle phase of the app-wide OBD2 trip recording (#726).
enum TripRecordingPhase { idle, recording, paused, finished }

/// Haptic strength emitted when the consumption band changes (#767).
enum HapticIntensity { none, light, medium }

/// Decide which haptic (if any) fires when [previous] transitions to
/// [current]. Pure function: no platform calls, easily unit-tested.
/// Only escalations vibrate — heavy or worse. Positive transitions
/// (eco / normal) stay silent so the feedback is a corrective nudge,
/// not constant noise.
HapticIntensity hapticForBandTransition(
  ConsumptionBand previous,
  ConsumptionBand current,
) {
  if (previous == current) return HapticIntensity.none;
  if (current == ConsumptionBand.veryHeavy &&
      previous != ConsumptionBand.veryHeavy) {
    return HapticIntensity.medium;
  }
  if (current == ConsumptionBand.heavy &&
      previous != ConsumptionBand.heavy &&
      previous != ConsumptionBand.veryHeavy) {
    return HapticIntensity.light;
  }
  return HapticIntensity.none;
}

/// Immutable snapshot the UI observes.
@immutable
class TripRecordingState {
  final TripRecordingPhase phase;
  final TripLiveReading? live;
  final DrivingSituation situation;
  final ConsumptionBand band;

  /// How far live consumption deviates from the situation's baseline
  /// as a signed fraction (e.g. -0.08 = 8 % below baseline). Null
  /// when the car doesn't report fuel rate or a live L/100 km can't
  /// be computed (idle uses L/h — caller formats it differently).
  final double? liveDeltaFraction;

  const TripRecordingState({
    this.phase = TripRecordingPhase.idle,
    this.live,
    this.situation = DrivingSituation.idle,
    this.band = ConsumptionBand.normal,
    this.liveDeltaFraction,
  });

  TripRecordingState copyWith({
    TripRecordingPhase? phase,
    TripLiveReading? live,
    DrivingSituation? situation,
    ConsumptionBand? band,
    double? liveDeltaFraction,
    bool clearDelta = false,
  }) =>
      TripRecordingState(
        phase: phase ?? this.phase,
        live: live ?? this.live,
        situation: situation ?? this.situation,
        band: band ?? this.band,
        liveDeltaFraction: clearDelta
            ? null
            : (liveDeltaFraction ?? this.liveDeltaFraction),
      );

  bool get isActive =>
      phase == TripRecordingPhase.recording ||
      phase == TripRecordingPhase.paused;
}

/// App-wide owner of the trip recording (#726).
///
/// Hoisted out of [TripRecordingScreen]'s state so a trip survives
/// navigation — the user can start recording, switch to the Search
/// tab, tap a station, come back, and find the trip still running.
/// Lives for the app's lifetime (`keepAlive: true`) because dropping
/// it mid-drive would silently throw away the trip.
///
/// Owns the [Obd2Service] while a trip is active; the
/// [Obd2ConnectionService] hands ownership here on [start] and gets
/// it back on [stop].
@Riverpod(keepAlive: true)
class TripRecording extends _$TripRecording {
  Obd2Service? _service;
  TripRecordingController? _controller;
  StreamSubscription<TripLiveReading>? _liveSub;
  SituationClassifier? _classifier;
  BaselineStore? _store;
  String? _vehicleId;
  ConsumptionFuelFamily _fuelFamily = ConsumptionFuelFamily.gasoline;

  /// Tests count haptic fires via these instead of hooking the
  /// platform channel. The production path also still calls
  /// [HapticFeedback], so counting here doesn't short-circuit the
  /// real vibration on a device.
  @visibleForTesting
  int hapticLightCount = 0;
  @visibleForTesting
  int hapticMediumCount = 0;

  @override
  TripRecordingState build() {
    return const TripRecordingState();
  }

  /// Begin a recording session backed by [service]. The provider
  /// takes ownership of the service — don't disconnect it from the
  /// caller; [stop] handles the full teardown.
  Future<void> start(Obd2Service service) async {
    if (state.isActive) return;
    _service = service;
    final ctl = TripRecordingController(service: service);
    _controller = ctl;
    _classifier = SituationClassifier();

    // #769 — resolve the active vehicle + fuel family and load its
    // learned baselines from Hive. Falls back silently to cold-start
    // defaults when the box isn't open (widget tests) or the active
    // vehicle is unavailable.
    try {
      final vehicle = ref.read(activeVehicleProfileProvider);
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
    } catch (e) {
      debugPrint('TripRecording.start: baseline setup failed: $e');
      _store = null;
    }

    await ctl.start();
    _liveSub = ctl.live.listen((reading) {
      final situation = _classifyFrom(reading);
      _recordToStore(reading, situation);
      final band = _classifyBandFrom(reading, situation);
      final delta = _computeDelta(reading, situation);
      _fireBandTransitionHaptic(state.band, band);
      state = state.copyWith(
        phase: ctl.isPaused
            ? TripRecordingPhase.paused
            : TripRecordingPhase.recording,
        live: reading,
        situation: situation,
        band: band,
        liveDeltaFraction: delta,
      );
    });
    state = state.copyWith(phase: TripRecordingPhase.recording);
  }

  /// #767 — fire a short haptic when the band crosses *into* heavy
  /// territory. Positive improvements (normal → eco) stay silent so
  /// the vibration is a corrective nudge, not constant feedback.
  void _fireBandTransitionHaptic(
    ConsumptionBand previous,
    ConsumptionBand current,
  ) {
    switch (hapticForBandTransition(previous, current)) {
      case HapticIntensity.light:
        hapticLightCount++;
        HapticFeedback.lightImpact();
      case HapticIntensity.medium:
        hapticMediumCount++;
        HapticFeedback.mediumImpact();
      case HapticIntensity.none:
        break;
    }
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
    store.record(
      vehicleId: vid,
      situation: situation,
      value: live,
    );
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
    );
  }

  DrivingSituation _classifyFrom(TripLiveReading r) {
    final cls = _classifier;
    if (cls == null) return DrivingSituation.idle;
    return cls.onSample(DrivingSample(
      timestamp: DateTime.now(),
      speedKmh: r.speedKmh ?? 0,
      rpm: r.rpm ?? 0,
      throttlePercent: r.engineLoadPercent, // close-enough proxy
      engineLoadPercent: r.engineLoadPercent,
      fuelRateLPerHour: r.fuelRateLPerHour,
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

  void pause() {
    final ctl = _controller;
    if (ctl == null || !state.isActive) return;
    ctl.pause();
    state = state.copyWith(phase: TripRecordingPhase.paused);
  }

  void resume() {
    final ctl = _controller;
    if (ctl == null || state.phase != TripRecordingPhase.paused) return;
    ctl.resume();
    state = state.copyWith(phase: TripRecordingPhase.recording);
  }

  /// Stop the polling loop, refresh the odometer one last time,
  /// release the service, and return the accumulated [TripSummary].
  /// Safe to call when no trip is active — returns a default empty
  /// summary so callers don't have to null-check.
  Future<StoppedTripResult> stop() async {
    final ctl = _controller;
    final svc = _service;
    if (ctl == null || svc == null) {
      state = const TripRecordingState();
      return const StoppedTripResult.empty();
    }
    try {
      await ctl.refreshOdometer();
    } catch (e) {
      debugPrint('TripRecording.stop: refreshOdometer failed: $e');
    }
    final summary = await ctl.stop();
    final odometerStartKm = ctl.odometerStartKm;
    final odometerLatestKm = ctl.odometerLatestKm;
    await _liveSub?.cancel();
    _liveSub = null;
    _controller = null;
    // #726 — persist to the trip history rolling log. Every trip
    // (including discarded ones) is logged; the fill-up flow is a
    // *separate* decision. Best-effort: a Hive write failure here
    // shouldn't block service teardown.
    await _saveToHistory(summary);
    // #769 — flush learned baselines before releasing the service so
    // the next trip starts from the updated values. Best-effort: a
    // Hive write failure here shouldn't block teardown.
    final store = _store;
    final vid = _vehicleId;
    if (store != null && vid != null) {
      try {
        await store.flush(vid);
      } catch (e) {
        debugPrint('TripRecording.stop: baseline flush failed: $e');
      }
      // #780 — fold in the server copy once the local flush lands.
      // `syncVehicleBaseline` returns the merged JSON; if the merge
      // changed anything, we rewrite Hive and reload so the next
      // trip sees the higher-confidence per-situation accumulators.
      // Entirely best-effort: offline, unauthenticated, or sync
      // errors all return the local payload unchanged.
      await _syncBaselineAfterFlush(vid);
    }
    _store = null;
    _vehicleId = null;
    try {
      await svc.disconnect();
    } catch (e) {
      debugPrint('TripRecording.stop: service disconnect failed: $e');
    }
    _service = null;
    state = state.copyWith(phase: TripRecordingPhase.finished);
    return StoppedTripResult(
      summary: summary,
      odometerStartKm: odometerStartKm,
      odometerLatestKm: odometerLatestKm,
    );
  }

  /// Return to idle — used after the caller consumes the
  /// [StoppedTripResult] (saves as fill-up or discards).
  void reset() {
    state = const TripRecordingState();
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
      final settings = ref.read(settingsStorageProvider);
      final enabled = settings.getSetting(
            StorageKeys.syncBaselinesEnabled,
          ) ==
          true;
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
    } catch (e) {
      debugPrint('TripRecording.stop: baseline sync failed: $e');
    }
  }

  Future<void> _saveToHistory(TripSummary summary) async {
    // Skip empty trips — the user tapped Stop without any usable
    // sample, or the service disconnected immediately. No signal, no
    // history clutter.
    if (summary.distanceKm < 0.01 && summary.startedAt == null) return;
    try {
      final repo = ref.read(tripHistoryRepositoryProvider);
      if (repo == null) return;
      final id = summary.startedAt?.toIso8601String() ??
          DateTime.now().toIso8601String();
      await repo.save(TripHistoryEntry(
        id: id,
        vehicleId: _vehicleId,
        summary: summary,
      ));
      ref.read(tripHistoryListProvider.notifier).refresh();
    } catch (e) {
      debugPrint('TripRecording._saveToHistory: $e');
    }
  }
}

/// Returned by [TripRecording.stop]. Bundles the summary with the
/// raw odometer reads so the save-as-fill-up flow can pre-fill the
/// form.
class StoppedTripResult {
  final TripSummary summary;
  final double? odometerStartKm;
  final double? odometerLatestKm;

  const StoppedTripResult({
    required this.summary,
    required this.odometerStartKm,
    required this.odometerLatestKm,
  });

  const StoppedTripResult.empty()
      : summary = const TripSummary(
          distanceKm: 0,
          maxRpm: 0,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
        ),
        odometerStartKm = null,
        odometerLatestKm = null;

  /// End-of-trip km, derived: latest odometer read if we have one,
  /// otherwise start + integrated distance. Null when neither
  /// odometer read ever succeeded.
  double? get endOdometerKm =>
      odometerLatestKm ??
      (odometerStartKm == null
          ? null
          : odometerStartKm! + summary.distanceKm);
}
