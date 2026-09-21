// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';

import '../../../helpers/empty_imu_source.dart';

/// Drives a REAL [TripRecording] notifier through a recording (#4162):
/// the OBD2 pipeline on a fake ELM327 transport, or the GPS-only pipeline
/// on a controllable fake Geolocator. Only the platform seams are fake.
class RecordingSessionDriver {
  RecordingSessionDriver({List<Override> overrides = const []})
      : geo = FakeGeolocator(),
        _extra = overrides;

  final FakeGeolocator geo;
  final List<Override> _extra;

  /// The overrides every container in a test uses — the old "process"
  /// and the relaunched one alike.
  List<Override> get overrides => [
        geolocatorWrapperProvider.overrideWithValue(geo),
        imuSensorSourceProvider.overrideWithValue(EmptyImuSource()),
        activeLanguageProvider.overrideWith(_FixedActiveLanguage.new),
        activeVehicleProfileProvider.overrideWith(_NoActiveVehicle.new),
        ..._extra,
      ];

  ProviderContainer container() => ProviderContainer(overrides: overrides);

  /// Start an OBD2 trip on [transport] (a fresh healthy adapter by
  /// default) and return its notifier.
  static Future<TripRecording> startObd2(
    ProviderContainer container, {
    SlowOdometerTransport? transport,
  }) async {
    final service = Obd2Service(transport ?? SlowOdometerTransport());
    await service.connect();
    final notifier = container.read(tripRecordingProvider.notifier);
    await notifier.start(service);
    return notifier;
  }

  /// Start a GPS-only trip and return its notifier.
  static Future<TripRecording> startGpsOnly(
      ProviderContainer container) async {
    final notifier = container.read(tripRecordingProvider.notifier);
    await notifier.startGpsOnly();
    return notifier;
  }

  /// Feed [count] one-second samples into the live OBD2 controller — its
  /// capture buffer (what the WAL persists) and its recorder (what makes
  /// the finished trip a drive rather than a #2509 no-movement discard) —
  /// starting at [tripStart].
  static void captureObd2Samples(TripRecording notifier, int count) {
    final ctl = notifier.debugController!;
    for (var i = 0; i < count; i++) {
      final at = tripStart.add(Duration(seconds: i));
      ctl
        ..debugInjectSample(
            speedKmh: 40 + i.toDouble(), rpm: 1800, at: at, fuelRateLPerHour: 5.5)
        ..debugCaptureSample(TripSample(
          timestamp: at,
          speedKmh: 40 + i.toDouble(),
          rpm: 1800 + i * 5,
          fuelRateLPerHour: 5.5,
        ));
    }
  }

  /// A fix now, moving at [speedMps].
  void emitFix({double speedMps = 15, int index = 0}) => geo.emit(Position(
        latitude: 43.4 + index * 0.001,
        longitude: 3.5,
        timestamp: const SystemClock().now(),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: speedMps,
        speedAccuracy: 0,
      ));

  Future<void> dispose() => geo.dispose();

  /// A fixed mid-month instant the captured samples are stamped from.
  static final DateTime tripStart = DateTime.utc(2026, 9, 16, 8);
}

/// A healthy fake ELM327 whose odometer read ([kOdometerCommand]) can be
/// made slow — an OBD2 stop awaits that read before it saves, which is the
/// window the live loop used to republish `recording` in (#4311).
class SlowOdometerTransport extends FakeObd2Transport {
  SlowOdometerTransport()
      : super(const {
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          kOdometerCommand: '41 A6 00 01 6A 2C>',
        });

  static const String kOdometerCommand = '01A6';

  /// Set before a stop to hold the odometer refresh this long.
  Duration odometerDelay = Duration.zero;

  @override
  Future<String> sendCommand(String command) async {
    if (command.trim() == kOdometerCommand && odometerDelay > Duration.zero) {
      await Future<void>.delayed(odometerDelay);
    }
    return super.sendCommand(command);
  }
}

/// Controllable fake Geolocator.
class FakeGeolocator extends GeolocatorWrapper {
  StreamController<Position>? _controller;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    final prev = _controller;
    if (prev != null && !prev.isClosed) unawaited(prev.close());
    _controller = StreamController<Position>();
    return _controller!.stream;
  }

  void emit(Position p) => _controller?.add(p);
  void emitError(Object error) => _controller?.addError(error);

  Future<void> dispose() async {
    final c = _controller;
    if (c != null && !c.isClosed) await c.close();
  }
}

class _FixedActiveLanguage extends ActiveLanguage {
  @override
  AppLanguage build() => const AppLanguage('en', 'English', 'English');
}

class _NoActiveVehicle extends ActiveVehicleProfile {
  @override
  VehicleProfile? build() => null;
}
