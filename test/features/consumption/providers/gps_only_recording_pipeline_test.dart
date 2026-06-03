// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/features/consumption/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/consumption/domain/entities/trip_save_stage.dart';
import 'package:tankstellen/features/consumption/domain/services/gps_fuel_estimator.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/gps_only_recording_pipeline.dart';
import 'package:tankstellen/features/consumption/providers/recording_pipeline.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_phase.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_state.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../helpers/empty_imu_source.dart';
import '../../../helpers/silence_error_logger.dart';

/// Direct unit tests for the #2190 [GpsOnlyRecordingPipeline] strategy,
/// driving it against a fake [RecordingPipelineHost] + a controllable
/// fake Geolocator so the start / ingest / derive / finalise behaviour is
/// pinned without spinning up the whole [TripRecording] notifier.
///
/// This is new coverage: the GPS-only pipeline was previously inlined on
/// the notifier and had no provider-level test exercising start →
/// position → stop end to end.
void main() {
  silenceErrorLoggerSpool();

  group('GpsOnlyRecordingPipeline (#2190)', () {
    test('isGpsOnly is true', () {
      final harness = _Harness();
      addTearDown(harness.dispose);
      expect(harness.pipeline.isGpsOnly, isTrue);
    });

    test('start() opens exactly one high-accuracy stream, seeds the '
        'recording state, and records last-trip identity', () {
      final harness = _Harness(activeVehicleId: 'veh-42');
      addTearDown(harness.dispose);

      harness.pipeline.start();

      expect(harness.geo.positionStreamCallCount, 1);
      expect(harness.geo.lastAccuracy, LocationAccuracy.high);
      expect(harness.host.state.phase, TripRecordingPhase.recording);
      expect(harness.host.state.live, isNotNull);
      expect(harness.host.state.live!.distanceKmSoFar, 0);
      // Identity bookkeeping is delegated back to the host.
      expect(harness.host.lastTripVehicleId, 'veh-42');
      expect(harness.host.lastTripStartedAt, isNotNull);
    });

    test(
        '#2766 — start() opens the SHARED source with the fine recording '
        'settings: Android foreground service + ~1 s interval reach the '
        'upstream so the OS stops the ~5 s background throttle', () {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final harness = _Harness();
      addTearDown(harness.dispose);

      harness.pipeline.start();

      // The recorder is the first (only) trip subscriber here, so the shared
      // upstream opens with its settings — and they must be the fine Android
      // recording settings, not a bare LocationSettings.
      final opened = harness.geo.lastSettings;
      expect(opened, isA<AndroidSettings>(),
          reason: 'recording opens with platform-specific Android settings');
      final android = opened! as AndroidSettings;
      expect(android.intervalDuration, const Duration(seconds: 1));
      expect(android.distanceFilter, 0);
      expect(android.foregroundNotificationConfig, isNotNull,
          reason: 'the foreground service is the un-throttle lever');
      expect(
        android.foregroundNotificationConfig!.notificationTitle,
        isNotEmpty,
        reason: 'ARB notification title carried into the config',
      );
    });

    test('each position fix is synthesised into a GPS sample (rpm 0, '
        'engine fields null) and pushed into the live state', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.pipeline.start();

      harness.geo.emit(_pos(43.4, 3.5, speedMps: 10.0, altitude: 120));
      await _pump();

      final live = harness.host.state.live;
      expect(live, isNotNull);
      // 10 m/s == 36 km/h.
      expect(live!.speedKmh, closeTo(36.0, 1e-9));
      expect(harness.host.state.phase, TripRecordingPhase.recording);
    });

    test('the very first fix carries a null GPS estimate (warm-up — no '
        'previous speed for the accel finite-diff yet) (#2389)', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.pipeline.start();

      harness.geo.emit(_pos(43.4, 3.5, speedMps: 15.0, at: DateTime(2026, 5, 30, 8)));
      await _pump();

      expect(harness.host.state.live!.gpsEstimatedLPer100Km, isNull,
          reason: 'no prior fix → estimator has no dt/accel basis yet');
    });

    test('a moving GPS-only trip carries a sane live GPS fuel estimate '
        'within the estimator clamps (#2389)', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.pipeline.start();

      // A steady ~72 km/h cruise: feed several 1 s-apart fixes so the
      // estimator's 3-sample accel low-pass warms up and emits an instant
      // figure. (The 1st fix primes prevSpeed; the 2nd onward produce it.)
      final t0 = DateTime(2026, 5, 30, 9);
      for (var i = 0; i < 5; i++) {
        harness.geo.emit(_pos(43.4 + i * 0.001, 3.5,
            speedMps: 20.0, at: t0.add(Duration(seconds: i))));
        await _pump();
      }

      final estimate = harness.host.state.live!.gpsEstimatedLPer100Km;
      expect(estimate, isNotNull,
          reason: 'a moving GPS-only trip must surface a live estimate');
      // Clamped to the same plausibility band the post-trip estimator uses.
      expect(estimate, greaterThanOrEqualTo(GpsFuelEstimator.minLPer100Km));
      expect(estimate, lessThanOrEqualTo(GpsFuelEstimator.maxLPer100Km));

      // #2391 — the recording-screen Avg + Fuel-used cards read the
      // smoother running figures off the same estimator state: a
      // running-average L/100 km (clamped) and a positive litres-so-far
      // integral. Both must be present once the trip is moving.
      final live = harness.host.state.live!;
      expect(live.gpsEstimatedAvgLPer100Km, isNotNull,
          reason: 'a moving GPS-only trip must surface a running average');
      expect(live.gpsEstimatedAvgLPer100Km,
          greaterThanOrEqualTo(GpsFuelEstimator.minLPer100Km));
      expect(live.gpsEstimatedAvgLPer100Km,
          lessThanOrEqualTo(GpsFuelEstimator.maxLPer100Km));
      expect(live.gpsEstimatedFuelLitersSoFar, isNotNull);
      expect(live.gpsEstimatedFuelLitersSoFar, greaterThan(0));
    });

    test('a stationary fix carries a null GPS estimate (no per-distance '
        'figure at a standstill) (#2389)', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.pipeline.start();

      final t0 = DateTime(2026, 5, 30, 10);
      // Two stopped fixes (0 m/s) — well below the estimator's move
      // threshold, so the instant figure is undefined.
      harness.geo.emit(_pos(43.4, 3.5, speedMps: 0.0, at: t0));
      await _pump();
      harness.geo.emit(_pos(43.4, 3.5,
          speedMps: 0.0, at: t0.add(const Duration(seconds: 1))));
      await _pump();

      expect(harness.host.state.live!.gpsEstimatedLPer100Km, isNull);
    });

    test('a negative / NaN stale first speed fix is clamped to 0', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.pipeline.start();

      harness.geo.emit(_pos(43.4, 3.5, speedMps: -1.0));
      await _pump();

      expect(harness.host.state.live!.speedKmh, 0.0);
    });

    test('stop() with no recorder activity returns empty + resets state',
        () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.pipeline.start();

      // No fix ever arrived — recorder exists but never got a sample.
      final result = await harness.pipeline.stop();

      // A 0-distance / 0-sample trajet is a stub: the summary holds 0 km
      // and the host's save path is the stub filter (asserted in the
      // notifier-level discard tests). State resets to idle.
      expect(result.summary.distanceKm, 0);
      expect(harness.host.state.phase, TripRecordingPhase.idle);
    });

    test('stop() builds a gpsOnly summary from the fixes and persists '
        'through the host', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.pipeline.start();

      // Two moving fixes 1 s apart → non-zero integrated distance.
      final t0 = DateTime(2026, 5, 29, 8);
      harness.geo.emit(_pos(43.4, 3.5, speedMps: 20.0, at: t0));
      await _pump();
      harness.geo.emit(_pos(43.41, 3.51, speedMps: 20.0,
          at: t0.add(const Duration(seconds: 1))));
      await _pump();

      final result = await harness.pipeline.stop(automatic: true);

      expect(harness.host.saved, hasLength(1));
      final saved = harness.host.saved.single;
      // Pure GPS samples (rpm 0, no fuel rate) → kind gpsOnly.
      expect(saved.summary.kind, TripKind.gpsOnly);
      expect(saved.automatic, isTrue);
      expect(saved.samples, isNotEmpty);
      // Result mirrors the persisted summary; no odometer for GPS-only.
      expect(result.summary.kind, TripKind.gpsOnly);
      expect(result.odometerStartKm, isNull);
      expect(result.odometerLatestKm, isNull);
      // State reset to idle after teardown.
      expect(harness.host.state.phase, TripRecordingPhase.idle);
      // #2548 — the GPS-only stop drives the two save stages (no cloud
      // sync beat — the GPS path never uploads inline), in order.
      expect(harness.host.saveStages, [
        TripSaveStage.finalizingSummary,
        TripSaveStage.savingToHistory,
      ]);
    });

    test('appendObd2Sample mid-trip flips the finalised kind to '
        'gpsPlusObd2', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.pipeline.start();

      final t0 = DateTime(2026, 5, 29, 9);
      harness.geo.emit(_pos(43.4, 3.5, speedMps: 20.0, at: t0));
      await _pump();
      // An externally-built OBD2-flavoured sample (rpm > 0) joins the
      // buffer — the #2025 mid-trip upgrade.
      harness.pipeline.appendObd2Sample(TripSample(
        timestamp: t0.add(const Duration(seconds: 1)),
        speedKmh: 72,
        rpm: 2000,
      ));

      await harness.pipeline.stop();

      expect(harness.host.saved.single.summary.kind, TripKind.gpsPlusObd2);
    });

    test('appendObd2Sample after stop is a no-op (recorder gone)',
        () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.pipeline.start();
      await harness.pipeline.stop();

      // Must not throw even though the recorder is null post-stop.
      harness.pipeline.appendObd2Sample(TripSample(
        timestamp: DateTime(2026, 5, 29, 10),
        speedKmh: 50,
        rpm: 1500,
      ));
    });

    test('stop() cancels the Geolocator subscription', () async {
      final harness = _Harness();
      addTearDown(harness.dispose);
      harness.pipeline.start();
      expect(harness.geo.activeListeners, 1);

      await harness.pipeline.stop();

      expect(harness.geo.activeListeners, 0);
    });

    test('stopping a moving GPS-only trip is safe when the active-vehicle '
        'read throws (#2228)', () async {
      final harness = _Harness(vehicleProviderThrows: true);
      addTearDown(harness.dispose);
      harness.pipeline.start();
      // Drive enough movement that GpsDrivingFeatures.from(samples) is
      // non-null, so the stop path reaches the #2080 imputation branch
      // that reads the active vehicle profile — the line that used to
      // throw with an unwired provider graph.
      final t0 = DateTime(2026, 5, 29, 9);
      harness.geo.emit(_pos(43.4, 3.5, speedMps: 25.0, at: t0));
      await _pump();
      harness.geo.emit(_pos(43.41, 3.51,
          speedMps: 27.0, at: t0.add(const Duration(seconds: 30))));
      await _pump();

      // Must not throw — the guarded read swallows the provider error and
      // falls back to the cold-start calibration matrix.
      final result = await harness.pipeline.stop();

      expect(harness.host.saved, hasLength(1),
          reason: 'the trip is still persisted despite the unwired '
              'vehicle provider — the read degrades to cold-start');
      expect(result.summary.kind, TripKind.gpsOnly);
    });
  });
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

/// Wires a [GpsOnlyRecordingPipeline] to a fake host + fake Geolocator.
class _Harness {
  _Harness({String? activeVehicleId, bool vehicleProviderThrows = false})
      : host = _FakeHost(activeVehicleId: activeVehicleId) {
    container = ProviderContainer(overrides: [
      geolocatorWrapperProvider.overrideWithValue(geo),
      // #2760 — the pipeline now attaches IMU fusion in start(); stub it with
      // an empty source so these GPS-focused tests don't touch the real
      // sensors_plus platform channel. (Dedicated IMU coverage lives in
      // gps_only_imu_fusion_test.dart + imu_event_detector_test.dart.)
      imuSensorSourceProvider.overrideWithValue(EmptyImuSource()),
      // #2766 — start() resolves AppLocalizations for the active language to
      // build the recording-notification copy; pin it to English so the test
      // doesn't pull in the Hive-backed storage / profile graph.
      activeLanguageProvider.overrideWith(_FixedActiveLanguage.new),
      // No active vehicle → the #2080 GPS-fuel imputation branch sees a
      // null profile and leaves avg / litres null, mirroring a fresh
      // install. (Production reads the real provider here.) When
      // [vehicleProviderThrows] is set, the read throws instead — the
      // #2228 regression: the stop path must degrade gracefully.
      activeVehicleProfileProvider.overrideWith(
        () => vehicleProviderThrows ? _ThrowingActiveVehicle() : _NoActiveVehicle(),
      ),
    ]);
    // A tiny capturing provider hands us a real Ref to feed the pipeline.
    pipeline = container.read(_pipelineProvider(host));
  }

  final _FakeHost host;
  final _RecordingGeolocator geo = _RecordingGeolocator();
  late final ProviderContainer container;
  late final GpsOnlyRecordingPipeline pipeline;

  void dispose() {
    container.dispose();
    geo.dispose();
  }
}

/// Family provider that constructs the pipeline with the provider's own
/// [Ref] so the unit test exercises the real Riverpod read path the
/// production notifier uses (geolocator wrapper + active-vehicle).
final _pipelineProvider =
    Provider.family<GpsOnlyRecordingPipeline, RecordingPipelineHost>(
  (ref, host) => GpsOnlyRecordingPipeline(ref: ref, host: host),
);

/// #2766 — pins the active language to English so `start()`'s ARB lookup for
/// the recording-notification copy resolves without the storage / profile
/// graph. Mirrors the `_FixedActiveLanguage` idiom in app_test.dart.
class _FixedActiveLanguage extends ActiveLanguage {
  @override
  AppLanguage build() => const AppLanguage('en', 'English', 'English');
}

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

/// #2228 — a vehicle provider whose read throws, standing in for a
/// test/widget harness without the full vehicle-active-profile graph.
class _ThrowingActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() =>
      throw StateError('vehicle provider graph not wired');
}

class _FakeHost implements RecordingPipelineHost {
  _FakeHost({this.activeVehicleId});

  final String? activeVehicleId;

  @override
  TripRecordingState state = const TripRecordingState();

  @override
  String? lastTripVehicleId;

  @override
  DateTime? lastTripStartedAt;

  final List<_Saved> saved = [];

  /// #2548 — the ordered save stages the pipeline drove through this host.
  final List<TripSaveStage> saveStages = [];

  @override
  String? readActiveVehicleId() => activeVehicleId;

  @override
  void setSaveStage(TripSaveStage stage) {
    saveStages.add(stage);
    state = state.copyWith(phase: TripRecordingPhase.saving, saveStage: stage);
  }

  @override
  Future<TripPersistOutcome> saveToHistory(
    TripSummary summary, {
    bool automatic = false,
    List<TripSample> samples = const [],
    List<GpsSampleDiagnostic> gpsSampleDiagnostics = const [],
    String? vehicleId,
    String? adapterMac,
    String? adapterName,
    String? adapterFirmware,
    int gpsFixCount = 0,
  }) async {
    saved.add(_Saved(
      summary: summary,
      automatic: automatic,
      samples: samples,
      gpsSampleDiagnostics: gpsSampleDiagnostics,
    ));
    // #2509 — this fake records every save unconditionally; report
    // `saved` so the pipeline's `discardedNoMovement` stays false.
    return TripPersistOutcome.saved;
  }
}

class _Saved {
  _Saved({
    required this.summary,
    required this.automatic,
    required this.samples,
    required this.gpsSampleDiagnostics,
  });

  final TripSummary summary;
  final bool automatic;
  final List<TripSample> samples;
  final List<GpsSampleDiagnostic> gpsSampleDiagnostics;
}

Position _pos(
  double lat,
  double lng, {
  double speedMps = 0,
  double altitude = 0,
  DateTime? at,
}) =>
    Position(
      latitude: lat,
      longitude: lng,
      timestamp: at ?? DateTime.now(),
      accuracy: 5,
      altitude: altitude,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: speedMps,
      speedAccuracy: 0,
    );

/// Controllable fake [GeolocatorWrapper] — mirrors the one in
/// trip_recording_provider_gps_test.dart.
class _RecordingGeolocator extends GeolocatorWrapper {
  int positionStreamCallCount = 0;
  LocationAccuracy? lastAccuracy;
  // #2766 — the settings the SHARED source opened the underlying stream with,
  // so a test can assert the recorder's fine (foreground-service) settings
  // reached the upstream.
  LocationSettings? lastSettings;
  StreamController<Position>? _controller;
  int activeListeners = 0;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    positionStreamCallCount++;
    lastAccuracy = locationSettings?.accuracy;
    lastSettings = locationSettings;
    final prev = _controller;
    if (prev != null && !prev.isClosed) prev.close();
    _controller = StreamController<Position>(
      onListen: () => activeListeners++,
      onCancel: () => activeListeners--,
    );
    return _controller!.stream;
  }

  void emit(Position p) => _controller?.add(p);
  void emitError(Object error) => _controller?.addError(error);

  Future<void> dispose() async {
    final c = _controller;
    if (c != null && !c.isClosed) await c.close();
  }
}
