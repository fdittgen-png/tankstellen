// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/obd2/data/active_trip_repository.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../helpers/empty_imu_source.dart';
import '../../../helpers/silence_error_logger.dart';

/// #3438 (Epic #3417) — end-to-end through the [TripRecording] notifier:
/// the app-backgrounded lifecycle hook must force-flush a GPS-only
/// recording's WAL to disk (previously only the OBD2 snapshot flushed —
/// an OS kill right after backgrounding lost the whole debounce window).
///
/// Drives the REAL notifier → GpsOnlyRecordingPipeline → GpsOnlyTripWal →
/// ActiveTripRepository chain against a real on-disk Hive box (the same
/// box launch recovery reads), with only the platform seams faked
/// (Geolocator, IMU, language).
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;
  late Box<String> box;
  late ActiveTripRepository repo;
  late _RecordingGeolocator geo;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('gps_bg_flush_test_');
    Hive.init(tmpDir.path);
    // The REAL box name — the production WAL resolves it by name.
    box = await Hive.openBox<String>(ActiveTripRepository.boxName);
    repo = ActiveTripRepository(box: box);
    geo = _RecordingGeolocator();
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
    unawaited(geo.dispose());
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(overrides: [
      geolocatorWrapperProvider.overrideWithValue(geo),
      imuSensorSourceProvider.overrideWithValue(EmptyImuSource()),
      activeLanguageProvider.overrideWith(_FixedActiveLanguage.new),
      activeVehicleProfileProvider.overrideWith(_NoActiveVehicle.new),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('backgrounding mid GPS-only trip force-flushes the WAL to disk',
      () async {
    final container = buildContainer();
    final notifier = container.read(tripRecordingProvider.notifier);

    expect(await notifier.startGpsOnly(), StartTripOutcome.started);
    addTearDown(() async {
      await notifier.stop();
    });
    geo.emit(_pos(43.4, 3.5, speedMps: 20.0));
    await _pump();

    // The #3248 seed wrote a 0-sample snapshot; the single fix is still
    // inside the WAL's 5 s / 10-sample debounce window.
    final before = repo.loadSnapshot();
    expect(before, isNotNull, reason: 'startGpsOnly must seed the WAL');
    expect(before!.samples, isEmpty,
        reason: 'one fix right after the seed stays inside the debounce '
            'window — this is exactly what a kill would lose');

    await notifier.onAppBackgrounded();
    await _pump();

    final after = repo.loadSnapshot();
    expect(after, isNotNull);
    expect(after!.samples, hasLength(1),
        reason: 'the lifecycle hook must force the GPS-only WAL past its '
            'debounce so an OS kill after backgrounding loses nothing');
  });

  test('backgrounding with no active recording writes nothing', () async {
    final container = buildContainer();
    final notifier = container.read(tripRecordingProvider.notifier);

    await notifier.onAppBackgrounded();
    await _pump();

    expect(repo.loadSnapshot(), isNull,
        reason: 'the hook fires on EVERY app pause — without an active '
            'recording it must stay a pure no-op');
  });
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

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
