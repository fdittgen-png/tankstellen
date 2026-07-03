// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/error_logger.dart';
import '../../../core/sensors/imu_sample.dart';
import '../../../core/sensors/imu_sensor_source.dart';
import '../../driving/providers/live_harsh_event_bus_provider.dart';
import '../../../core/domain/gps_calibration_matrix.dart';
import '../../obd2/api.dart';
import 'active_vehicle_read.dart';
import '../domain/entities/trip_save_stage.dart';
import '../domain/gps_driving_features.dart';
import '../domain/services/gps_fuel_estimator.dart';
import '../domain/services/gps_live_estimate_folder.dart';
import '../domain/services/imu_event_detector.dart';
import '../domain/trip_recorder.dart';
import 'gps_only_trip_wal.dart';
import 'gps_sample_diagnostics_recorder.dart';
import 'motion_gated_gps_source.dart';
import 'recording_pipeline.dart';
import 'trip_recording_phase.dart';
import 'trip_recording_state.dart';

/// #2025 GPS-only recording pipeline, extracted from the [TripRecording]
/// notifier behind the [RecordingPipeline] strategy seam (#2190).
///
/// Lets users record a trajet without an OBD2 dongle: samples come from
/// Geolocator, the [TripRecorder] accumulator runs the same harsh-event /
/// distance / idle integration it does for OBD2 trips, and the persisted
/// summary carries `kind: TripKind.gpsOnly` so downstream surfaces
/// (confidence-tier badge, recording-screen redesign) can adapt.
///
/// Owns (moved off the notifier verbatim): the [TripRecorder], the
/// Geolocator [StreamSubscription], the raw [TripSample] buffer +
/// trip-start timestamp, the per-fix ingest ([_onPosition]), and the
/// stop path (summary build, #2080 GPS-fuel imputation, persist).
///
/// Deliberately NOT owned:
/// Publishing the notifier's Riverpod `state`, the last-trip identity
/// fields, and the shared `_saveToHistory` write stay on the notifier and
/// are reached through the injected [RecordingPipelineHost] — exactly the
/// host-seam idiom [DroppedSessionManager] uses (#2188). Riverpod-backed
/// reads (the Geolocator wrapper, the active vehicle's calibration
/// matrix) go through [_ref], mirroring [TripGpsStreamController].
class GpsOnlyRecordingPipeline implements RecordingPipeline {
  GpsOnlyRecordingPipeline({
    required Ref ref,
    required RecordingPipelineHost host,
    GpsOnlyTripWal? wal, // #3248 — injectable for tests
    GpsSampleDiagnosticsRecorder? gpsDiagnostics, // #3253 — injectable
  })  : _ref = ref,
        _host = host,
        _wal = wal ?? GpsOnlyTripWal(),
        _gpsDiagnostics = gpsDiagnostics ?? GpsSampleDiagnosticsRecorder();

  final Ref _ref;
  final RecordingPipelineHost _host;
  final GpsOnlyTripWal _wal; // #3248 — write-ahead log

  // #3253 — per-fix cadence diagnostics (#1458), OBD2 parity: lights up
  // the trip-detail GpsDiagnosticsCard for GPS-only trips too.
  final GpsSampleDiagnosticsRecorder _gpsDiagnostics;

  @override
  bool get isGpsOnly => true;

  /// GPS-only recording has no live engine loop to pause — the position
  /// stream keeps running (#2227). Returns false so the phase is untouched.
  @override
  bool pause() => false;

  @override
  bool resume() => false;

  /// #3438 — the app was backgrounded: force-flush the WAL immediately so
  /// an imminent OS kill loses at most the fixes since this write, not the
  /// whole debounce window. No-op between trips (the recorder is null).
  /// Never throws — a WAL write must not take the recording path down.
  void onAppBackgrounded() {
    final recorder = _recorder;
    if (recorder == null) return;
    try {
      _wal.flushNow(_samples, recorder.buildSummary());
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
        'where': 'GpsOnlyRecordingPipeline.onAppBackgrounded'
      }));
    }
  }

  /// Pure accumulator — same recorder the OBD2 path uses, so the
  /// distance / harsh-event / idle integration is byte-identical.
  TripRecorder? _recorder;

  /// #3319 — owns the recording GPS subscription and motion-gates its cadence
  /// (fine while moving, coarse once stationary). Null between trips; opened
  /// on [start], cancelled on [stop].
  MotionGatedGpsSource? _gpsSource;
  final List<TripSample> _samples = [];
  DateTime? _startedAt;

  /// #2760 — IMU sensor-fusion attaches ONLY here, in the dongle-less
  /// pipeline (the OBD2 path is behaviour-preserving). The detector folds
  /// the ~50 Hz inertial stream into a handful of in-memory counters — it
  /// NEVER buffers raw samples (the aggregate-only constraint). Both are
  /// null between trips; the subscription opens on [start] and is cancelled
  /// on [stop], mirroring the Geolocator [_sub] lifecycle.
  StreamSubscription<ImuSample>? _imuSub;
  ImuEventDetector? _imuDetector;

  /// #2389 / #2506 — shared GPS-physics live-estimate + coaching folder.
  /// Turns the same GPS speed stream into a live L/100 km figure (instant
  /// + running-average + litres) and the GPS coaching hint, folding both
  /// the OBD2 [TripRecordingController] and this pipeline through one
  /// implementation so they can't diverge (#2506). Resolved once at [start]
  /// from the active vehicle + its calibration matrix; null between trips.
  GpsLiveEstimateFolder? _estimateFolder;

  /// Open the Geolocator stream, prime the recorder, and seed recording state.
  /// Moved verbatim from `TripRecording.startGpsOnly`'s body — the re-entrancy
  /// guard + `alreadyActive` short-circuit stay on the notifier, so this entry
  /// point assumes it is clear to start.
  void start() {
    _recorder = TripRecorder(
      maxIntegrationGapSeconds: 30,
      // #2663 — harsh events onto the shared live bus (dongle-less coaching).
      onHarshEvent: _ref.read(liveHarshEventBusProvider.notifier).add,
    );
    _samples.clear();
    _gpsDiagnostics.clear(); // #3253
    _startedAt = DateTime.now();
    _host.lastTripStartedAt = DateTime.now();
    _host.lastTripVehicleId = _host.readActiveVehicleId();
    // #3248 — seed the WAL so an OS kill recovers (not loses) the trip.
    _wal.seed(startedAt: _startedAt!, automatic: false, vehicleId: _host.readActiveVehicleId());
    // #2389 / #2506 — build the shared live physics estimate + coaching
    // folder from the active vehicle + its calibration matrix (physicsScale
    // #2388). A null vehicle / matrix falls back to the population-default
    // class + cold-start scale, so the estimate still flows on a fresh
    // install — it just isn't yet OBD2-anchored.
    final vehicle = tryReadActiveVehicleProfile(_ref,
        where: 'GpsOnlyRecordingPipeline: active vehicle unavailable');
    final matrix = vehicle?.gpsCalibration;
    _estimateFolder = GpsLiveEstimateFolder.forVehicle(vehicle, matrix);
    // Subscribe to the position stream at high accuracy — the
    // post-trip map polyline + confidence-tier UX both want ~10 m
    // precision. Permission failure is non-fatal: the stream errors
    // and we log; the user sees an unmoving recording until they
    // grant permission or stop.
    // #2646 — subscribe to the SHARED, refcounted broadcast position source
    // rather than a fresh per-call `getPositionStream`. The live
    // ApproachDetector subscribes to the same source the instant the trip
    // flips active (approach_state_provider.dart); two independent
    // `getPositionStream` listeners contend on geolocator's single platform
    // EventChannel and starve one of them, which broke the fuel-station radar
    // + swipe in GPS-only recording. One underlying subscription, multiplexed,
    // feeds every fix to both consumers.
    // #2766 — open the SHARED source with the fine, foreground-service
    // promoted recording settings (Android ~1 s + foreground service;
    // iOS automotiveNavigation + background updates) so the OS stops the
    // ~5 s background batching that coarsened the trace + analytics. Marked
    // `recording: true` so these settings WIN the cadence on the shared
    // upstream even if the ApproachDetector opened the channel first with its
    // coarse settings. The notification copy comes from the already-merged
    // ARB keys, resolved for the active in-app language without a
    // BuildContext (this runs from the notifier, not a widget).
    _gpsSource = MotionGatedGpsSource(ref: _ref, onPosition: _onPosition)
      ..start();
    // #2760 — attach IMU sensor fusion (this dongle-less pipeline ONLY).
    // The detector feeds confirmed accel/brake episodes onto the SAME live
    // harsh-event bus the OBD2 / GPS-speed paths use (mirroring the recorder's
    // onHarshEvent above), so spoken coaching fires without a dongle. Sensor
    // failure is non-fatal — we log and the trip still records off GPS alone.
    final imuDetector = ImuEventDetector(
      onEvent: _ref.read(liveHarshEventBusProvider.notifier).add,
    );
    _imuDetector = imuDetector;
    _imuSub = _ref
        .read(imuSensorSourceProvider)
        .stream()
        .listen(
          imuDetector.onSample,
          onError: (Object e, StackTrace st) {
            unawaited(errorLogger.log(ErrorLayer.providers, e, st,
                context: const {
                  'where': 'GpsOnlyRecordingPipeline.start: IMU stream error'
                }));
          },
        );
    // Seed the state so the recording screen renders immediately
    // (the first GPS fix can be 1-3 s away on a cold start).
    _host.state = _host.state.copyWith(
      phase: TripRecordingPhase.recording,
      live: const TripLiveReading(
        elapsed: Duration.zero,
        distanceKmSoFar: 0,
      ),
    );
  }

  void _onPosition(Position p) {
    final recorder = _recorder;
    final startedAt = _startedAt;
    if (recorder == null || startedAt == null) return;
    // Geolocator can report a stale fix in the first emit before the
    // GPS warms up — guard against speed = NaN / negative.
    final speedMps = p.speed.isFinite && p.speed >= 0 ? p.speed : 0.0;
    final sample = TripSample(
      timestamp: p.timestamp,
      speedKmh: speedMps * 3.6,
      rpm: null, // #2692 C4-G — GPS-only has no engine signal.
      latitude: p.latitude.isFinite ? p.latitude : null,
      longitude: p.longitude.isFinite ? p.longitude : null,
      altitudeM: p.altitude.isFinite ? p.altitude : null,
      hAccuracyM: p.accuracy.isFinite ? p.accuracy : null,
      bearingDeg: p.heading.isFinite ? p.heading : null,
    );
    _samples.add(sample);
    // #3253 — fix-clock cadence diagnostic (OS batching stays visible).
    _gpsDiagnostics.record(now: p.timestamp);
    // #2760 — feed the latest GPS ground speed to the IMU detector so its
    // min-speed gate and accel-vs-brake direction classification track the
    // real vehicle speed (the inertial stream alone has no speed).
    _imuDetector?.currentSpeedKmh = sample.speedKmh;
    // #3319 — motion-gate the receiver (FGS-approved builds only).
    _gpsSource?.onSpeed(
        sample.speedKmh, DateTime.now().difference(startedAt));
    // #2653 — GPS-only speed is Doppler ground speed (differentiable, not
    // 1 km/h dead reckoning); tag it `gps` so harsh scoring stays gated-not-
    // suppressed (the `virtual` source's wholesale suppression isn't needed).
    recorder.onSample(sample, distanceSource: kDistanceSourceGps);
    final summary = recorder.buildSummary();
    _wal.onSample(_samples, summary); // #3248 — debounced WAL flush
    // #2389 / #2506 — fold the fix into the SHARED estimate + coaching folder
    // (also the OBD2 live path). It does its own accel low-pass + warm-up; the
    // figures are null at standstill / before warm-up, which is correct then.
    final estimate = _estimateFolder?.fold(sample) ?? GpsLiveEstimate.none;
    // #3329 — stamp the per-fix GPS fuel estimate (L/h) onto the sample so the
    // trip-path heatmap colours by consumption, not all-green.
    final instant = estimate.instantLPer100Km;
    if (instant != null && sample.speedKmh > 0 && _samples.isNotEmpty) {
      _samples[_samples.length - 1] =
          _samples.last.copyWithEstimatedFuelRate(instant / 100.0 * sample.speedKmh);
    }
    final coaching = estimate.coachingHint;
    _host.state = _host.state.copyWith(
      phase: TripRecordingPhase.recording,
      live: TripLiveReading(
        speedKmh: sample.speedKmh,
        distanceKmSoFar: summary.distanceKm,
        elapsed: DateTime.now().difference(startedAt),
        gpsEstimatedLPer100Km: estimate.instantLPer100Km,
        gpsEstimatedAvgLPer100Km: estimate.avgLPer100Km,
        gpsEstimatedFuelLitersSoFar: estimate.fuelLitersSoFar,
      ),
      gpsCoachingHint: coaching,
      clearGpsCoachingHint: coaching == null,
    );
  }

  @override
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    final recorder = _recorder;
    await _gpsSource?.cancel();
    _gpsSource = null;
    // #2760 — tear down the IMU stream alongside the GPS one so no inertial
    // subscription survives between trips (the battery / lifecycle bound).
    await _imuSub?.cancel();
    _imuSub = null;
    final imuDetector = _imuDetector;
    _imuDetector = null;
    _wal.clear(); // #3248 — trip is ending; drop the WAL (saved below).
    if (recorder == null) {
      _host.state = const TripRecordingState();
      return const StoppedTripResult.empty();
    }
    final samples = List<TripSample>.unmodifiable(_samples);
    // #2548 — staged save-progress: flip into the transient `saving` phase
    // so the recording screen shows the inline TripSaveProgress card
    // while the dongle-less trip is wrapped up. Building the summary
    // (+ #2080 GPS-fuel imputation) is the first beat. The GPS-only path
    // never uploads inline, so it has no `syncingToCloud` beat.
    _host.setSaveStage(TripSaveStage.finalizingSummary);
    // #2025 — derive `kind` from the actual sample stream rather than
    // hardcoding `gpsOnly`. If [appendObd2Sample] (or any future
    // mid-trip path) injected OBD2 samples into the buffer, the
    // resulting kind correctly flips to `gpsPlusObd2`.
    final kind = TripKind.fromSamples(samples);
    // #2760 — stamp the aggregate-only IMU event counts. THREE scalars; the
    // raw ~50 Hz inertial stream was folded into them in real time and is
    // never persisted.
    //
    // #2895 — PREFER the IMU counts for the `harshAccelerations` / `harshBrakes`
    // the driving score reads whenever the inertial sensor actually RAN —
    // INCLUDING when it counted zero. A direct inertial reading is the accurate
    // harsh-manoeuvre signal; the GPS speed-derivative the recorder used can
    // differentiate ~1 Hz Doppler noise into impossible >1 g spikes (the
    // #2895 Peugeot 107: IMU 0 vs GPS 16, maxAccelG 1.086). So a genuine IMU
    // zero must VETO the noisy GPS over-count — the old `(imuAccel > 0 ||
    // imuBrake > 0)` gate let the over-count win on exactly the smooth trip it
    // should have zeroed. We gate on the sensor having run, not on it being
    // non-zero, and on EITHER kind: the IMU detector runs in this dongle-less
    // pipeline regardless of whether OBD2 attached mid-trip (a gpsPlusObd2
    // trip that started dongle-less still has the accurate inertial counts).
    // `imuActive` is persisted so the trip-detail score recompute reconciles
    // the same way. When the sensor never ran (no IMU hardware / OBD2-from-the-
    // start), the (now physically-clamped) GPS-derived counts stay the source.
    final imuAccel = imuDetector?.hardAccelCount ?? 0;
    final imuBrake = imuDetector?.hardBrakeCount ?? 0;
    final imuCorners = imuDetector?.sharpCornerCount ?? 0;
    final imuActive = imuDetector?.isActive ?? false;
    var summary = recorder.buildSummary().copyWith(
          kind: kind,
          imuHardAccelCount: imuAccel,
          imuHardBrakeCount: imuBrake,
          sharpCornerCount: imuCorners,
          imuActive: imuActive,
          harshAccelerations: imuActive ? imuAccel : null,
          harshBrakes: imuActive ? imuBrake : null,
        );
    // #2080 — for GPS-only / hybrid trips (no OBD2 fuel-rate
    // coverage), feed the sample stream through GpsDrivingFeatures +
    // the active vehicle's GpsCalibrationMatrix to impute
    // `avgLPer100Km` and `fuelLitersConsumed`. The fields stay null
    // when no active vehicle exists, when the trajet has no
    // distance, or when the OBD2 path already populated them
    // (gpsPlusObd2 trips skip this branch — `summary.kind` is the
    // gate).
    if (summary.kind == TripKind.gpsOnly && summary.avgLPer100Km == null) {
      final features = GpsDrivingFeatures.from(samples);
      if (features != null) {
        final vehicle = tryReadActiveVehicleProfile(_ref,
        where: 'GpsOnlyRecordingPipeline: active vehicle unavailable');
        final matrix =
            vehicle?.gpsCalibration ?? GpsCalibrationMatrix.coldStart();
        final est = GpsFuelEstimator.estimate(
          matrix: matrix,
          features: features,
        );
        if (est != null) {
          summary = summary.copyWith(
            avgLPer100Km: est.lPer100Km,
            fuelLitersConsumed: est.lPer100Km * summary.distanceKm / 100, // #3252
          );
        }
      }
    }
    // #2548 — second beat: writing the finished trip to Hive history.
    _host.setSaveStage(TripSaveStage.savingToHistory);
    // #2509 — each GPS fix feeds one sample through the recorder, so the
    // GPS-fix count equals the captured-sample count here. Threaded so the
    // guard treats a genuinely-stationary GPS-only stop consistently and
    // the outcome can surface the "no movement" notice.
    final outcome = await _host.saveToHistory(
      summary,
      samples: samples,
      automatic: automatic,
      // #3253 — #1458 cadence diagnostics, OBD2 parity.
      gpsSampleDiagnostics: _gpsDiagnostics.snapshot,
      gpsFixCount: samples.length,
    );
    _recorder = null;
    _samples.clear();
    _gpsDiagnostics.clear();
    _startedAt = null;
    _estimateFolder = null;
    _host.state = const TripRecordingState();
    return StoppedTripResult(
      summary: summary,
      odometerStartKm: null,
      odometerLatestKm: null,
      // #2509 — surface a "no movement detected" notice when the
      // dongle-less trip was discarded as genuinely stationary.
      discardedNoMovement: outcome.isStationaryDiscard,
    );
  }

  /// #2025 — mid-trip upgrade hook. Appends an externally-built
  /// [TripSample] (carrying OBD2 telemetry) to the in-progress buffer +
  /// recorder so the final [TripSummary.kind] flips to `gpsPlusObd2` via
  /// [TripKind.fromSamples].
  ///
  /// No-op once the pipeline has stopped (the recorder is null). Future
  /// UX surface (banner: "OBD2 detected — attach to current trip?")
  /// drives this; until then it exists so the acceptance scenario is
  /// testable + the data layer supports it the moment any caller starts
  /// producing OBD2-flavoured samples. Reached only through the notifier's
  /// `@visibleForTesting` `debugAppendObd2SampleToGpsOnly`.
  void appendObd2Sample(TripSample sample) {
    final recorder = _recorder;
    if (recorder == null) return;
    _samples.add(sample);
    recorder.onSample(sample);
  }
}
