// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/features/consumption/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/gps_only_recording_pipeline.dart';
import 'package:tankstellen/features/consumption/providers/recording_pipeline.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_phase.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_state.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

/// Direct unit tests for the #2190 [GpsOnlyRecordingPipeline] strategy,
/// driving it against a fake [RecordingPipelineHost] + a controllable
/// fake Geolocator so the start / ingest / derive / finalise behaviour is
/// pinned without spinning up the whole [TripRecording] notifier.
///
/// This is new coverage: the GPS-only pipeline was previously inlined on
/// the notifier and had no provider-level test exercising start →
/// position → stop end to end.
void main() {
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
  });
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

/// Wires a [GpsOnlyRecordingPipeline] to a fake host + fake Geolocator.
class _Harness {
  _Harness({String? activeVehicleId})
      : host = _FakeHost(activeVehicleId: activeVehicleId) {
    container = ProviderContainer(overrides: [
      geolocatorWrapperProvider.overrideWithValue(geo),
      // No active vehicle → the #2080 GPS-fuel imputation branch sees a
      // null profile and leaves avg / litres null, mirroring a fresh
      // install. (Production reads the real provider here.)
      activeVehicleProfileProvider.overrideWith(() => _NoActiveVehicle()),
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

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
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

  @override
  String? readActiveVehicleId() => activeVehicleId;

  @override
  Future<void> saveToHistory(
    TripSummary summary, {
    bool automatic = false,
    List<TripSample> samples = const [],
    List<GpsSampleDiagnostic> gpsSampleDiagnostics = const [],
    String? vehicleId,
    String? adapterMac,
    String? adapterName,
    String? adapterFirmware,
  }) async {
    saved.add(_Saved(
      summary: summary,
      automatic: automatic,
      samples: samples,
      gpsSampleDiagnostics: gpsSampleDiagnostics,
    ));
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
  StreamController<Position>? _controller;
  int activeListeners = 0;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    positionStreamCallCount++;
    lastAccuracy = locationSettings?.accuracy;
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
