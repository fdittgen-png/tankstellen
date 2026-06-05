// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/sensors/imu_sample.dart';
import 'package:tankstellen/core/sensors/imu_sensor_source.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/consumption/domain/entities/trip_save_stage.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/gps_only_recording_pipeline.dart';
import 'package:tankstellen/features/consumption/providers/recording_pipeline.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_phase.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_state.dart';
import 'package:tankstellen/features/driving/providers/live_harsh_event_bus_provider.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../helpers/silence_error_logger.dart';

/// #2760 — GPS+IMU sensor-fusion integration tests for the dongle-optional
/// pipeline. Drives the real [GpsOnlyRecordingPipeline] against a fake
/// [ImuSensorSource] emitting a fixed synthetic [ImuSample] stream (NOT a
/// request-echoing fake) and a real [TripHistoryRepository], proving the four
/// binding behaviours: debounced aggregate counts persist, NO raw IMU samples
/// reach disk, the inertial subscription opens once / cancels on stop / never
/// survives between trips, and confirmed episodes reach the live harsh-event
/// bus.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<String> box;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('gps_imu_test_');
    Hive.init(tmpDir.path);
    box = await Hive.openBox<String>(
      'imu_${DateTime.now().microsecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  group('GPS+IMU fusion in GpsOnlyRecordingPipeline (#2760)', () {
    test('NO-RAW-PERSISTENCE: a recorded trip carries the debounced IMU '
        'counts AND the JSON holds ONLY the 3 scalar keys (no raw array)',
        () async {
      final repo = TripHistoryRepository(box: box);
      // One sustained 2 s hard-accel burst (speed rising) → exactly ONE
      // accel episode, NOT one per ~50 Hz sample.
      final imu = _FakeImuSource(_accelBurst(
        start: DateTime(2026, 6, 1, 8),
        seconds: 2.0,
        mag: 4.0,
      ));
      final harness = _Harness(repo: repo, imu: imu);
      addTearDown(harness.dispose);

      harness.pipeline.start();
      final t0 = DateTime(2026, 6, 1, 8);
      // First fix: detector speed = 72 km/h (moving, above the 5 km/h gate).
      // The burst's start-speed anchor is captured here.
      harness.geo.emit(_pos(43.4, 3.5, speedMps: 20.0, at: t0));
      await _pump();
      final half = harness.imu.sampleCount ~/ 2;
      harness.imu.emitBurst(0, half);
      await _pump();
      // Second fix mid-burst: speed rises to 90 km/h → the net speed change
      // over the strong stretch is +18 km/h, so it classifies as a HARD
      // ACCEL, not a brake. Non-zero integrated distance too.
      harness.geo.emit(_pos(43.41, 3.51,
          speedMps: 25.0, at: t0.add(const Duration(seconds: 1))));
      await _pump();
      harness.imu.emitBurst(half);
      await _pump();

      await harness.pipeline.stop();

      // (a) the round-tripped summary carries the debounced count.
      final entries = repo.loadAll();
      expect(entries, hasLength(1));
      final summary = entries.single.summary;
      expect(summary.imuHardAccelCount, 1,
          reason: 'one sustained episode, not ~100 raw samples');
      expect(summary.imuHardBrakeCount, 0);

      // (b) the persisted JSON holds ONLY the 3 scalar keys — never a raw
      // per-sample IMU array. The byte cost is O(bytes), not O(seconds×50).
      final raw = box.get(entries.single.id)!;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final summaryJson = decoded['summary'] as Map<String, dynamic>;
      expect(summaryJson['iha'], 1, reason: 'the one accel count, as a scalar');
      // No raw-IMU payload of any plausible shape leaked in anywhere.
      for (final k in ['imu', 'imuSamples', 'samplesImu', 'imuRaw']) {
        expect(summaryJson.containsKey(k), isFalse,
            reason: 'no raw IMU key "$k" in the summary');
        expect(decoded.containsKey(k), isFalse,
            reason: 'no raw IMU key "$k" at the entry root');
      }
      // The persisted size is dominated by the trip's GPS samples + a handful
      // of scalars — NOT ~100 IMU sample objects. A 2 s 50 Hz raw dump would
      // be ~100 entries; the encoded payload here is tiny.
      expect(raw.length, lessThan(4096),
          reason: 'aggregate-only — no O(seconds×50) raw-IMU payload');
      // No value anywhere in the JSON is a list of > 50 elements (a smoking
      // gun for a per-sample dump). The only lists are bounded aggregates.
      _assertNoLargeArray(decoded);
    });

    test('LIFECYCLE: exactly one IMU subscription opens on start, is '
        'cancelled on stop, and none exists between trips', () async {
      final imu = _FakeImuSource(const []);
      final harness = _Harness(repo: TripHistoryRepository(box: box), imu: imu);
      addTearDown(harness.dispose);

      expect(imu.activeListeners, 0, reason: 'none before start');

      harness.pipeline.start();
      await _pump();
      expect(imu.activeListeners, 1, reason: 'exactly one opens on start');
      // Mirror the GPS _sub assertion: the geolocator stream is also open.
      expect(harness.geo.activeListeners, 1);

      await harness.pipeline.stop();
      expect(imu.activeListeners, 0, reason: 'cancelled on stop');
      expect(harness.geo.activeListeners, 0);

      // A second trip re-opens exactly one and tears it down again — none
      // ever survives between trips.
      harness.pipeline.start();
      await _pump();
      expect(imu.activeListeners, 1);
      await harness.pipeline.stop();
      expect(imu.activeListeners, 0);
      expect(imu.totalSubscriptions, 2, reason: 'one per trip, no leak');
    });

    test('BUS WIRING: each confirmed IMU accel/brake episode pushes a '
        'HarshEvent onto LiveHarshEventBus', () async {
      final imu = _FakeImuSource(_accelBurst(
        start: DateTime(2026, 6, 1, 9),
        seconds: 2.0,
        mag: 4.0,
      ));
      final harness = _Harness(repo: TripHistoryRepository(box: box), imu: imu);
      addTearDown(harness.dispose);

      // Subscribe to the bus before the trip drives any event.
      final events = <HarshEvent>[];
      final busSub = harness.container
          .read(liveHarshEventBusProvider.notifier)
          .stream
          .listen(events.add);
      addTearDown(busSub.cancel);

      harness.pipeline.start();
      final t0 = DateTime(2026, 6, 1, 9);
      // Rising GPS speed across the burst so it classifies as a hard accel.
      harness.geo.emit(_pos(43.4, 3.5, speedMps: 15.0, at: t0));
      await _pump();
      final half = harness.imu.sampleCount ~/ 2;
      harness.imu.emitBurst(0, half);
      await _pump();
      harness.geo.emit(_pos(43.41, 3.51,
          speedMps: 25.0, at: t0.add(const Duration(seconds: 1))));
      await _pump();
      harness.imu.emitBurst(half);
      await _pump();

      expect(events, isNotEmpty,
          reason: 'a confirmed IMU episode must reach the coaching bus');
      expect(events.first.type, HarshEventType.acceleration);

      await harness.pipeline.stop();
    });

    test('#2895 IMU ZERO VETO: the inertial sensor ran and saw NO hard events '
        'while a noisy GPS speed jump would manufacture one — the persisted '
        'summary marks imuActive AND zeroes harshAccelerations so the score '
        'reflects the accurate inertial zero, not the GPS over-count',
        () async {
      // The IMU emits CALM samples (~0 m/s² horizontal) — a smooth driver — so
      // the detector confirms zero hard accels but IS active (it ran).
      final calm = <ImuSample>[
        for (var i = 0; i < 40; i++)
          ImuSample(
            t: DateTime(2026, 6, 5, 9).add(Duration(milliseconds: i * 50)),
            axMps2: 0.2,
            ayMps2: 0.1,
            azMps2: 0,
            gyroZRadPerSec: 0,
          ),
      ];
      final imu = _FakeImuSource(calm);
      final repo = TripHistoryRepository(box: box);
      final harness = _Harness(repo: repo, imu: imu);
      addTearDown(harness.dispose);

      harness.pipeline.start();
      final t0 = DateTime(2026, 6, 5, 9);
      // A GPS speed jump the speed-derivative would otherwise read as a hard
      // accel (18 → 30 m/s over 1 s = +12 m/s² ≈ 1.2 g — exactly the kind of
      // impossible spike #2895 over-counted). With the clamp this no longer
      // counts anyway, and the IMU-active zero is the authoritative figure.
      harness.geo.emit(_pos(43.4, 3.5, speedMps: 18.0, at: t0));
      await _pump();
      harness.imu.emitBurst(0, 20);
      await _pump();
      harness.geo.emit(_pos(43.41, 3.51,
          speedMps: 30.0, at: t0.add(const Duration(seconds: 1))));
      await _pump();
      harness.imu.emitBurst(20);
      await _pump();
      // A couple more calm fixes so the trip has plausible distance/duration.
      harness.geo.emit(_pos(43.42, 3.52,
          speedMps: 28.0, at: t0.add(const Duration(seconds: 2))));
      await _pump();

      await harness.pipeline.stop();

      final entries = repo.loadAll();
      expect(entries, hasLength(1));
      final summary = entries.single.summary;
      expect(summary.imuActive, isTrue,
          reason: 'the sensor ran, so its zero is authoritative');
      expect(summary.imuHardAccelCount, 0);
      expect(summary.harshAccelerations, 0,
          reason: 'the IMU zero is preferred over the noisy GPS count');
      expect(summary.harshBrakes, 0);

      // And it round-trips through the on-disk JSON (the display recompute
      // reads imuActive from there).
      final raw = box.get(entries.single.id)!;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final summaryJson = decoded['summary'] as Map<String, dynamic>;
      expect(summaryJson['ima'], true, reason: 'imuActive persisted (key ima)');
    });
  });
}

/// Builds a 50 ms-cadence accel burst: [seconds] of 4.0 m/s² horizontal
/// magnitude on the X axis, gravity-removed, no yaw.
List<ImuSample> _accelBurst({
  required DateTime start,
  required double seconds,
  required double mag,
}) {
  final out = <ImuSample>[];
  final n = (seconds / 0.05).round();
  var t = start;
  for (var i = 0; i < n; i++) {
    out.add(ImuSample(
      t: t,
      axMps2: mag,
      ayMps2: 0,
      azMps2: 0,
      gyroZRadPerSec: 0,
    ));
    t = t.add(const Duration(milliseconds: 50));
  }
  return out;
}

/// Recursively assert no list deeper in [json] has > 50 elements — a
/// per-sample IMU dump of a 2 s trip would be ~40-100. Bounded aggregates
/// (harshEvents, diagnostics) are far smaller.
void _assertNoLargeArray(Object? node) {
  if (node is List) {
    expect(node.length, lessThanOrEqualTo(50),
        reason: 'a >50-element array smells like a raw per-sample dump');
    for (final e in node) {
      _assertNoLargeArray(e);
    }
  } else if (node is Map) {
    for (final v in node.values) {
      _assertNoLargeArray(v);
    }
  }
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

/// A fake [ImuSensorSource] that replays a FIXED synthetic sample list (no
/// request-echoing) and tracks listener lifecycle so the pipeline's
/// subscribe-once / cancel-on-stop contract is observable.
///
/// The burst is NOT auto-emitted on listen — the test calls [emitBurst] AFTER
/// it has fed the first GPS fix, so the detector's GPS-fed speed is set before
/// the inertial burst is classified (the same ordering the live pipeline sees:
/// GPS fixes and ~50 Hz IMU samples interleave continuously). The held
/// samples then flow onto the current subscription's controller.
class _FakeImuSource extends ImuSensorSource {
  _FakeImuSource(this._samples);

  final List<ImuSample> _samples;
  int activeListeners = 0;
  int totalSubscriptions = 0;
  StreamController<ImuSample>? _ctl;

  @override
  Stream<ImuSample> stream() {
    // The consumer (the pipeline) cancels this subscription on stop; the
    // controller is single-use per trip and dropped with the harness.
    // ignore: close_sinks
    final ctl = StreamController<ImuSample>(
      onListen: () {
        activeListeners++;
        totalSubscriptions++;
      },
      onCancel: () => activeListeners--,
    );
    _ctl = ctl;
    return ctl.stream;
  }

  /// Push a slice [from, to) of the fixed synthetic burst onto the live
  /// subscription. The test interleaves slices with GPS-speed bumps so the
  /// detector's net-speed-change direction logic sees a rising / falling
  /// trend across the burst, exactly as the live ~50 Hz IMU vs ~1 Hz GPS
  /// streams interleave.
  void emitBurst([int? from, int? to]) {
    final ctl = _ctl;
    if (ctl == null || ctl.isClosed) return;
    final slice = _samples.sublist(from ?? 0, to ?? _samples.length);
    for (final s in slice) {
      ctl.add(s);
    }
  }

  int get sampleCount => _samples.length;
}

/// Wires a real [GpsOnlyRecordingPipeline] to a real [TripHistoryRepository]
/// (via a host that persists) + a fake Geolocator + a fake IMU source.
class _Harness {
  _Harness({required TripHistoryRepository repo, required this.imu})
      : host = _PersistingHost(repo: repo) {
    container = ProviderContainer(overrides: [
      geolocatorWrapperProvider.overrideWithValue(geo),
      imuSensorSourceProvider.overrideWithValue(imu),
      activeVehicleProfileProvider.overrideWith(_NoActiveVehicle.new),
      // #2766 — start() resolves AppLocalizations for the recording
      // notification; pin the language so it stays off the storage graph.
      activeLanguageProvider.overrideWith(_FixedActiveLanguage.new),
    ]);
    pipeline = container.read(_pipelineProvider(host));
  }

  final _PersistingHost host;
  final _FakeImuSource imu;
  final _RecordingGeolocator geo = _RecordingGeolocator();
  late final ProviderContainer container;
  late final GpsOnlyRecordingPipeline pipeline;

  void dispose() {
    container.dispose();
    geo.dispose();
  }
}

final _pipelineProvider =
    Provider.family<GpsOnlyRecordingPipeline, RecordingPipelineHost>(
  (ref, host) => GpsOnlyRecordingPipeline(ref: ref, host: host),
);

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

/// #2766 — pins the active language so `start()`'s recording-notification
/// ARB lookup resolves without the storage / profile graph.
class _FixedActiveLanguage extends ActiveLanguage {
  @override
  AppLanguage build() => const AppLanguage('en', 'English', 'English');
}

/// A host that writes the finished summary to a REAL repository, so the
/// no-raw-persistence test inspects the actual on-disk JSON.
class _PersistingHost implements RecordingPipelineHost {
  _PersistingHost({required this.repo});

  final TripHistoryRepository repo;

  @override
  TripRecordingState state = const TripRecordingState();

  @override
  String? lastTripVehicleId;

  @override
  DateTime? lastTripStartedAt;

  @override
  String? readActiveVehicleId() => null;

  @override
  void setSaveStage(TripSaveStage stage) {
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
    final start = summary.startedAt ?? lastTripStartedAt ?? DateTime.now();
    await repo.save(TripHistoryEntry(
      id: start.toIso8601String(),
      vehicleId: vehicleId,
      summary: summary,
    ));
    return TripPersistOutcome.saved;
  }
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
/// gps_only_recording_pipeline_test.dart, overriding the SHARED source the
/// pipeline subscribes to.
class _RecordingGeolocator extends GeolocatorWrapper {
  int positionStreamCallCount = 0;
  LocationAccuracy? lastAccuracy;
  StreamController<Position>? _controller;
  int activeListeners = 0;

  @override
  Stream<Position> sharedPositionStream({
    LocationSettings? locationSettings,
    bool recording = false,
  }) {
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

  Future<void> dispose() async {
    final c = _controller;
    if (c != null && !c.isClosed) await c.close();
  }
}
