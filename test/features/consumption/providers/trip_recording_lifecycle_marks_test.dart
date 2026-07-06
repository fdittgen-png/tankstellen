// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/recording_lifecycle_mark.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../helpers/empty_imu_source.dart';
import '../../../helpers/silence_error_logger.dart';

/// #3465 — recording lifecycle marks must reach the persisted
/// [TripHistoryEntry] from BOTH recording pipelines through the shared
/// notifier save path, and round-trip through the JSON codec:
///   1. `TripHistoryEntry` round-trips the marks list (compact 'lcm' key).
///   2. Legacy entries (no 'lcm' key) deserialise to an empty list.
///   3. An OBD2 trip that was backgrounded mid-recording persists the
///      transition marks (mirrors the #1458 diagnostics persistence test).
///   4. A GPS-only trip does too (the same notifier hook serves both
///      pipelines — the #3438 backgrounding-flush harness, extended).
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('lifecycle_marks_test_');
    Hive.init(tmpDir.path);
    await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
  });

  tearDown(() async {
    await Hive.box<String>(HiveBoxes.obd2TripHistory).deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  test('TripHistoryEntry round-trips the lifecycle marks list', () {
    final start = DateTime(2026, 7, 1, 8);
    final entry = TripHistoryEntry(
      id: start.toIso8601String(),
      vehicleId: 'veh-1',
      summary: TripSummary(
        distanceKm: 1.2,
        maxRpm: 2000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: start,
        endedAt: start.add(const Duration(minutes: 5)),
      ),
      lifecycleMarks: [
        RecordingLifecycleMark(at: start, backgrounded: false),
        RecordingLifecycleMark(
            at: start.add(const Duration(minutes: 1)), backgrounded: true),
        RecordingLifecycleMark(
            at: start.add(const Duration(minutes: 3)), backgrounded: false),
      ],
    );

    final restored = TripHistoryEntry.fromJson(entry.toJson());

    expect(restored.lifecycleMarks, hasLength(3));
    expect(restored.lifecycleMarks[0].at, start);
    expect(restored.lifecycleMarks[0].backgrounded, isFalse);
    expect(restored.lifecycleMarks[1].backgrounded, isTrue);
    expect(restored.lifecycleMarks[1].at,
        start.add(const Duration(minutes: 1)));
    expect(restored.lifecycleMarks[2].backgrounded, isFalse);
    // copyWith must carry the marks (the η_v recompute path).
    expect(entry.copyWith().lifecycleMarks, hasLength(3));
  });

  test('legacy entries without the lcm key deserialise to an empty list',
      () {
    final legacy = <String, dynamic>{
      'id': 'legacy-3465',
      'vehicleId': 'veh-1',
      'summary': <String, dynamic>{
        'distanceKm': 12.0,
        'maxRpm': 3000.0,
        'highRpmSeconds': 0.0,
        'idleSeconds': 0.0,
        'harshBrakes': 0,
        'harshAccelerations': 0,
        'distanceSource': 'virtual',
      },
    };
    final restored = TripHistoryEntry.fromJson(legacy);
    expect(restored.lifecycleMarks, isEmpty);
  });

  test('a marks-free trip serialises WITHOUT the lcm key (zero bytes '
      'added for legacy shapes)', () {
    const entry = TripHistoryEntry(
      id: 'no-marks',
      vehicleId: null,
      summary: TripSummary(
        distanceKm: 1,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
      ),
    );
    expect(entry.toJson().containsKey('lcm'), isFalse);
  });

  test(
    'OBD2 pipeline — a mid-trip backgrounding lands as marks on the '
    'saved entry',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);
      final ctl = notifier.debugController;
      expect(ctl, isNotNull);

      // Drive the recorder past the no-movement discard floor (the same
      // recipe as the #1458 diagnostics persistence test).
      final start = DateTime.now();
      for (int i = 0; i < 4; i++) {
        ctl!.debugInjectSample(
          speedKmh: 40 + i.toDouble(),
          rpm: 1800 + i * 5,
          at: start.add(Duration(seconds: i)),
          fuelRateLPerHour: 5.5,
        );
        ctl.debugRecordSpeedSample(
          speedKmh: 40 + i.toDouble(),
          at: start.add(Duration(seconds: i)),
        );
        ctl.debugCaptureSample(TripSample(
          timestamp: start.add(Duration(seconds: i)),
          speedKmh: 40 + i.toDouble(),
          rpm: 1800 + i * 5,
          fuelRateLPerHour: 5.5,
        ));
      }

      // The user backgrounds the app mid-trip, then comes back — the
      // same wiring app.dart drives on every lifecycle transition.
      notifier.onAppLifecycleStateChanged(AppLifecycleState.paused);
      notifier.onAppLifecycleStateChanged(AppLifecycleState.resumed);

      await notifier.stop();

      final repo = container.read(tripHistoryRepositoryProvider);
      final saved = repo!.loadAll().first;
      expect(saved.lifecycleMarks.length, greaterThanOrEqualTo(3),
          reason: 'leading foreground anchor + backgrounded + resumed');
      expect(saved.lifecycleMarks.first.backgrounded, isFalse,
          reason: 'the trip started foregrounded (the anchor mark)');
      expect(saved.lifecycleMarks.any((m) => m.backgrounded), isTrue,
          reason: 'the mid-trip backgrounding must be durable');
      expect(saved.lifecycleMarks.last.backgrounded, isFalse);
    },
  );

  test(
    'GPS-only pipeline — the same notifier hook persists marks for a '
    'dongle-less trip',
    () async {
      final geo = _RecordingGeolocator();
      addTearDown(() => unawaited(geo.dispose()));
      final container = ProviderContainer(overrides: [
        geolocatorWrapperProvider.overrideWithValue(geo),
        imuSensorSourceProvider.overrideWithValue(EmptyImuSource()),
        activeLanguageProvider.overrideWith(_FixedActiveLanguage.new),
        activeVehicleProfileProvider.overrideWith(_NoActiveVehicle.new),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(tripRecordingProvider.notifier);
      expect(await notifier.startGpsOnly(), StartTripOutcome.started);

      geo.emit(_pos(43.40, 3.50, speedMps: 20.0));
      await _pump();
      geo.emit(_pos(43.41, 3.51, speedMps: 20.0));
      await _pump();

      notifier.onAppLifecycleStateChanged(AppLifecycleState.paused);
      notifier.onAppLifecycleStateChanged(AppLifecycleState.resumed);

      geo.emit(_pos(43.42, 3.52, speedMps: 20.0));
      await _pump();

      await notifier.stop();

      final repo = container.read(tripHistoryRepositoryProvider);
      final history = repo!.loadAll();
      expect(history, isNotEmpty,
          reason: 'the moving GPS-only trip must persist');
      final saved = history.first;
      expect(saved.lifecycleMarks.any((m) => m.backgrounded), isTrue,
          reason: 'the mid-trip backgrounding must reach the GPS-only '
              'save path through the shared notifier hook');
      expect(saved.lifecycleMarks.first.backgrounded, isFalse);
    },
  );
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };

/// Pins the active language to English so `startGpsOnly()`'s ARB lookup
/// resolves without the storage / profile graph (the #2766 idiom).
class _FixedActiveLanguage extends ActiveLanguage {
  @override
  AppLanguage build() => const AppLanguage('en', 'English', 'English');
}

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}

Position _pos(
  double lat,
  double lng, {
  double speedMps = 0,
}) =>
    Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: speedMps,
      speedAccuracy: 0,
    );

/// Controllable fake [GeolocatorWrapper] — mirrors the one in
/// gps_only_recording_pipeline_test.dart.
class _RecordingGeolocator extends GeolocatorWrapper {
  StreamController<Position>? _controller;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    final prev = _controller;
    if (prev != null && !prev.isClosed) unawaited(prev.close());
    _controller = StreamController<Position>();
    return _controller!.stream;
  }

  void emit(Position p) => _controller?.add(p);

  Future<void> dispose() async {
    final c = _controller;
    if (c != null && !c.isClosed) await c.close();
  }
}
