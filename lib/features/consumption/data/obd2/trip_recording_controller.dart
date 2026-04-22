import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../domain/trip_recorder.dart';
import 'obd2_service.dart';

/// Live read-out from the currently-recording trip (#726).
///
/// Emitted on every poll tick so the recording screen can show the
/// user speed / RPM / distance / estimated fuel without having to
/// ask the recorder for a full summary each time.
@immutable
class TripLiveReading {
  final double? speedKmh;
  final double? rpm;
  final double? fuelRateLPerHour;
  final double? fuelLevelPercent;
  final double? engineLoadPercent;
  final double distanceKmSoFar;
  final double? fuelLitersSoFar;
  final Duration elapsed;
  final double? odometerStartKm;
  final double? odometerNowKm;

  const TripLiveReading({
    this.speedKmh,
    this.rpm,
    this.fuelRateLPerHour,
    this.fuelLevelPercent,
    this.engineLoadPercent,
    required this.distanceKmSoFar,
    this.fuelLitersSoFar,
    required this.elapsed,
    this.odometerStartKm,
    this.odometerNowKm,
  });

  /// Live L/100 km estimate — uses trip-so-far totals, so early
  /// samples are noisy and converge as the trip progresses. Returns
  /// null when the car doesn't surface a fuel-rate PID.
  double? get liveAvgLPer100Km {
    if (fuelLitersSoFar == null || distanceKmSoFar < 0.01) return null;
    return fuelLitersSoFar! / distanceKmSoFar * 100.0;
  }
}

/// Drives the polling loop that feeds an [Obd2Service]'s live PIDs
/// into a [TripRecorder] (#726).
///
/// Not a Riverpod notifier — kept as a plain class so the recording
/// screen owns the lifecycle (start on screen mount, stop on tap).
/// The screen subscribes to [live] for UI updates and calls [stop]
/// to finalise the trip.
///
/// Polling cadence is 1 Hz — faster than that doesn't improve the
/// derived metrics (RPM/speed integration is already smooth at 1 Hz
/// for typical driving), and most cheap ELM327 clones can't answer
/// 5 PIDs reliably inside a 500 ms window.
class TripRecordingController {
  final Obd2Service _service;
  final TripRecorder _recorder;
  final Duration _pollInterval;
  final DateTime Function() _now;

  /// Active [VehicleProfile] snapshot for the speed-density
  /// fuel-rate fallback (#810, #812 phase 3). Captured once at
  /// construction — the user's vehicle doesn't change mid-trip, and
  /// re-reading the profile every tick would just burn CPU. When
  /// null, `readFuelRateLPerHour` falls back to its generic 1.0 L /
  /// η_v 0.85 defaults — still honest, just less precise.
  final VehicleProfile? _vehicle;

  final StreamController<TripLiveReading> _liveController =
      StreamController<TripLiveReading>.broadcast();

  Timer? _timer;
  DateTime? _startedAt;
  double? _odometerStartKm;
  double? _odometerLatestKm;
  double _fuelLitersSoFar = 0;
  bool _fuelRateSeen = false;
  bool _polling = false;
  bool _paused = false;

  TripRecordingController({
    required Obd2Service service,
    TripRecorder? recorder,
    Duration pollInterval = const Duration(seconds: 1),
    DateTime Function()? now,
    VehicleProfile? vehicle,
  })  : _service = service,
        _recorder = recorder ?? TripRecorder(),
        _pollInterval = pollInterval,
        _now = now ?? DateTime.now,
        _vehicle = vehicle;

  /// Live metrics stream — subscribe to update the recording UI.
  Stream<TripLiveReading> get live => _liveController.stream;

  bool get isRecording => _timer != null && !_paused;
  bool get isPaused => _paused;
  bool get isActive => _timer != null;

  /// Pause the polling loop without tearing down the recorder. The
  /// controller keeps its timer alive internally and ignores ticks
  /// while paused; [resume] flips the flag back without resetting
  /// state. Safe to call when not recording — no-op.
  void pause() {
    if (_timer == null) return;
    _paused = true;
  }

  /// Resume a paused recording. Idempotent; no-op if not paused.
  void resume() {
    _paused = false;
  }

  /// Start polling. Reads the odometer ONCE to pin the trip start;
  /// subsequent ticks read speed/RPM/fuel-rate/etc. Safe to call
  /// multiple times — no-op when already recording.
  Future<void> start() async {
    if (_timer != null) return;
    _startedAt = _now();
    _odometerStartKm = await _service.readOdometerKm();
    _odometerLatestKm = _odometerStartKm;
    _timer = Timer.periodic(_pollInterval, (_) => _pollOnce());
  }

  /// Stop the polling loop and return the accumulated summary.
  /// Idempotent — calling twice returns the same summary.
  Future<TripSummary> stop() async {
    _timer?.cancel();
    _timer = null;
    await _liveController.close();
    return _recorder.buildSummary();
  }

  /// Odometer reading at trip start. Null when the adapter can't
  /// read the odometer (no PID A6, no PID 31 fallback, unknown
  /// manufacturer). Exposed so the save-as-fill-up flow can pre-fill
  /// the "odometer" field with the END km — which is start + the
  /// recorder's accumulated distance.
  double? get odometerStartKm => _odometerStartKm;

  /// Latest odometer reading read during the trip. Returns null
  /// until the first successful odometer poll. The recording UI
  /// doesn't poll the odometer every tick (it's an expensive Mode
  /// 22 query on some cars) — just once at start and once near the
  /// end via [refreshOdometer].
  double? get odometerLatestKm => _odometerLatestKm;

  /// Refresh the odometer reading. Call this just before [stop] so
  /// the save-as-fill-up gets a ground-truth end km rather than a
  /// derived value.
  Future<void> refreshOdometer() async {
    final km = await _service.readOdometerKm();
    if (km != null) _odometerLatestKm = km;
  }

  Future<void> _pollOnce() async {
    if (_paused) return; // paused — skip this tick but keep the timer
    if (_polling) return; // previous tick still in flight — skip
    _polling = true;
    try {
      final speed = await _service.readSpeedKmh();
      final rpm = await _service.readRpm();
      final fuelRate = await _service.readFuelRateLPerHour(vehicle: _vehicle);
      final engineLoad = await _service.readEngineLoad();
      final fuelLevel = await _service.readFuelLevelPercent();
      final sample = TripSample(
        timestamp: _now(),
        speedKmh: (speed ?? 0).toDouble(),
        rpm: rpm ?? 0,
        fuelRateLPerHour: fuelRate,
      );
      _recorder.onSample(sample);
      if (fuelRate != null) {
        _fuelRateSeen = true;
        // The recorder integrates fuel rate internally (private), but
        // we also track a copy here for the live UI readout. Uses the
        // same Δt as the recorder — a single-tick lag is invisible.
        _fuelLitersSoFar =
            (_recorder.buildSummary().fuelLitersConsumed) ?? _fuelLitersSoFar;
      }
      final reading = TripLiveReading(
        speedKmh: sample.speedKmh,
        rpm: sample.rpm,
        fuelRateLPerHour: fuelRate,
        fuelLevelPercent: fuelLevel,
        engineLoadPercent: engineLoad,
        distanceKmSoFar: _recorder.buildSummary().distanceKm,
        fuelLitersSoFar: _fuelRateSeen ? _fuelLitersSoFar : null,
        elapsed: _now().difference(_startedAt ?? _now()),
        odometerStartKm: _odometerStartKm,
        odometerNowKm: _odometerLatestKm,
      );
      if (!_liveController.isClosed) _liveController.add(reading);
    } catch (e) {
      debugPrint('TripRecordingController poll error: $e');
    } finally {
      _polling = false;
    }
  }
}
