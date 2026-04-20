import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/obd2/obd2_service.dart';
import '../data/obd2/trip_recording_controller.dart';
import '../domain/cold_start_baselines.dart';
import '../domain/situation_classifier.dart';
import '../domain/trip_recorder.dart';

part 'trip_recording_provider.g.dart';

/// Lifecycle phase of the app-wide OBD2 trip recording (#726).
enum TripRecordingPhase { idle, recording, paused, finished }

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

  /// Fuel family used for cold-start baselines. Currently hardcoded
  /// to gasoline — phase 2 (#769) reads it from the active vehicle
  /// profile.
  final ConsumptionFuelFamily _fuelFamily = ConsumptionFuelFamily.gasoline;

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
    await ctl.start();
    _liveSub = ctl.live.listen((reading) {
      final situation = _classifyFrom(reading);
      final band = _classifyBandFrom(reading, situation);
      final delta = _computeDelta(reading, situation);
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
    final baseline = coldStartBaseline(_fuelFamily, situation);
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
    final baseline = coldStartBaseline(_fuelFamily, situation);
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
