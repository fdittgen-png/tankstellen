// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/location/geolocator_wrapper.dart';
import '../../../core/logging/error_logger.dart';
import '../../vehicle/domain/entities/gps_calibration_matrix.dart';
import '../../vehicle/domain/entities/vehicle_profile.dart';
import '../../vehicle/providers/vehicle_providers.dart';
import '../data/obd2/trip_live_reading.dart';
import '../domain/entities/trip_save_stage.dart';
import '../domain/gps_driving_features.dart';
import '../domain/services/gps_fuel_estimator.dart';
import '../domain/services/gps_live_estimate_folder.dart';
import '../domain/trip_recorder.dart';
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
/// ## What this owns (moved off the notifier verbatim)
///
///   * the [TripRecorder] accumulator,
///   * the Geolocator position [StreamSubscription],
///   * the raw [TripSample] buffer + the trip-start timestamp,
///   * the per-fix ingest ([_onPosition]) that synthesises a sample,
///     feeds the recorder, and publishes the live reading + GPS coaching
///     hint, and
///   * the stop path that builds the final summary, runs the #2080
///     GPS-fuel imputation, and persists.
///
/// ## What it deliberately does NOT own
///
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
  })  : _ref = ref,
        _host = host;

  final Ref _ref;
  final RecordingPipelineHost _host;

  @override
  bool get isGpsOnly => true;

  /// GPS-only recording has no live engine loop to pause — the position
  /// stream keeps running. Returns false so the notifier leaves the
  /// phase untouched (#2227).
  @override
  bool pause() => false;

  @override
  bool resume() => false;

  /// Pure accumulator — same recorder the OBD2 path uses, so the
  /// distance / harsh-event / idle integration is byte-identical.
  TripRecorder? _recorder;
  StreamSubscription<Position>? _sub;
  final List<TripSample> _samples = [];
  DateTime? _startedAt;

  /// #2389 / #2506 — shared GPS-physics live-estimate + coaching folder.
  /// Turns the same GPS speed stream into a live L/100 km figure (instant
  /// + running-average + litres) and the GPS coaching hint, folding both
  /// the OBD2 [TripRecordingController] and this pipeline through one
  /// implementation so they can't diverge (#2506). Resolved once at [start]
  /// from the active vehicle + its calibration matrix; null between trips.
  GpsLiveEstimateFolder? _estimateFolder;

  /// Open the Geolocator stream, prime the recorder, and seed the
  /// recording state. Returns true once the stream is opened.
  ///
  /// Moved verbatim from `TripRecording.startGpsOnly`'s body — the
  /// re-entrancy guard + `alreadyActive` short-circuit stay on the
  /// notifier (they read `state.isActive` / `_startInProgress`, which
  /// are notifier concerns), so this entry point assumes it is clear to
  /// start.
  void start() {
    _recorder = TripRecorder(maxIntegrationGapSeconds: 30);
    _samples.clear();
    _startedAt = DateTime.now();
    _host.lastTripStartedAt = DateTime.now();
    _host.lastTripVehicleId = _host.readActiveVehicleId();
    // #2389 / #2506 — build the shared live physics estimate + coaching
    // folder from the active vehicle + its calibration matrix (physicsScale
    // #2388). A null vehicle / matrix falls back to the population-default
    // class + cold-start scale, so the estimate still flows on a fresh
    // install — it just isn't yet OBD2-anchored.
    final vehicle = _tryReadActiveVehicle();
    final matrix = vehicle?.gpsCalibration;
    _estimateFolder = GpsLiveEstimateFolder.forVehicle(vehicle, matrix);
    // Subscribe to the position stream at high accuracy — the
    // post-trip map polyline + confidence-tier UX both want ~10 m
    // precision. Permission failure is non-fatal: the stream errors
    // and we log; the user sees an unmoving recording until they
    // grant permission or stop.
    final geo = _ref.read(geolocatorWrapperProvider);
    _sub = geo
        .getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        )
        .listen(
          _onPosition,
          onError: (Object e, StackTrace st) {
            unawaited(errorLogger.log(ErrorLayer.providers, e, st,
                context: const {
                  'where': 'GpsOnlyRecordingPipeline.start: stream error'
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
      rpm: 0,
      latitude: p.latitude.isFinite ? p.latitude : null,
      longitude: p.longitude.isFinite ? p.longitude : null,
      altitudeM: p.altitude.isFinite ? p.altitude : null,
      hAccuracyM: p.accuracy.isFinite ? p.accuracy : null,
      bearingDeg: p.heading.isFinite ? p.heading : null,
    );
    _samples.add(sample);
    recorder.onSample(sample);
    final summary = recorder.buildSummary();
    // #2389 / #2506 — fold this fix into the SHARED estimate + coaching
    // folder (also used by the OBD2 live path). The folder does its own
    // 3-sample accel low-pass + warm-up and a bounded coaching window, so
    // we just hand it the GPS-stamped sample. The estimate figures return
    // null at a standstill / before warm-up, which is exactly what the
    // live reading should carry then; the #2391 Avg + Fuel-used cards read
    // the smoother running figures it carries.
    final estimate = _estimateFolder?.fold(sample) ?? GpsLiveEstimate.none;
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
    await _sub?.cancel();
    _sub = null;
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
    var summary = recorder.buildSummary().copyWith(
          kind: TripKind.fromSamples(samples),
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
        final vehicle = _tryReadActiveVehicle();
        final matrix =
            vehicle?.gpsCalibration ?? GpsCalibrationMatrix.coldStart();
        final est = GpsFuelEstimator.estimate(
          matrix: matrix,
          features: features,
        );
        if (est != null) {
          summary = summary.copyWith(
            avgLPer100Km: est.lPer100Km,
            fuelLitersConsumed: est.litersConsumed,
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
      gpsFixCount: samples.length,
    );
    _recorder = null;
    _samples.clear();
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

  /// #2228 — read the active vehicle profile for the #2080 GPS-fuel
  /// imputation, swallowing provider-wiring errors the same way the OBD2
  /// path's `_tryReadActiveVehicle` does. Before this, the stop path read
  /// `activeVehicleProfileProvider` unguarded, so stopping a moving
  /// GPS-only trip in a test/widget harness that lacks the vehicle
  /// provider graph would throw (latent in production, where the graph is
  /// wired). Returns null on error → the matrix falls back to cold-start.
  VehicleProfile? _tryReadActiveVehicle() {
    try {
      return _ref.read(activeVehicleProfileProvider);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.providers, e, st, context: const {
        'where': 'GpsOnlyRecordingPipeline: active vehicle unavailable'
      }));
      return null;
    }
  }
}
