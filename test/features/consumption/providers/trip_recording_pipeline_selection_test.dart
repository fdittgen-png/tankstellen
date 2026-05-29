// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tankstellen/core/location/geolocator_wrapper.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

import '../../../helpers/silence_error_logger.dart';

/// #2190 — pins which recording strategy the [TripRecording] notifier
/// selects, and that the selection condition is unchanged: the dongle-
/// less `startGpsOnly` entry point installs the GPS-only pipeline, while
/// the OBD2 `start(service)` entry point runs the inline controller path
/// (no alternate pipeline).
void main() {
  silenceErrorLoggerSpool();

  group('TripRecording strategy selection (#2190)', () {
    test('startGpsOnly selects the GPS-only pipeline (no OBD2 controller)',
        () async {
      final fakeGeo = _FakeGeo();
      final container = ProviderContainer(overrides: [
        geolocatorWrapperProvider.overrideWithValue(fakeGeo),
      ]);
      addTearDown(container.dispose);
      addTearDown(fakeGeo.dispose);

      final notifier = container.read(tripRecordingProvider.notifier);
      final outcome = await notifier.startGpsOnly();

      expect(outcome, StartTripOutcome.started);
      expect(notifier.debugIsGpsOnlyActive, isTrue,
          reason: 'startGpsOnly must install the GPS-only pipeline');
      // The OBD2 controller path is NOT taken — no controller exists.
      expect(notifier.debugController, isNull);
      expect(container.read(tripRecordingProvider).isActive, isTrue);

      await notifier.stop();
      // After stop the alternate pipeline is cleared.
      expect(notifier.debugIsGpsOnlyActive, isFalse);
    });

    test('start(service) runs the inline OBD2 path (no GPS-only pipeline)',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);

      expect(notifier.debugIsGpsOnlyActive, isFalse,
          reason: 'the OBD2 start path must not install an alternate '
              'pipeline');
      expect(notifier.debugController, isNotNull);
      expect(container.read(tripRecordingProvider).isActive, isTrue);

      await notifier.stop();
    });

    test('startGpsOnly is a no-op while an OBD2 trip is already active',
        () async {
      final fakeGeo = _FakeGeo();
      final container = ProviderContainer(overrides: [
        geolocatorWrapperProvider.overrideWithValue(fakeGeo),
      ]);
      addTearDown(container.dispose);
      addTearDown(fakeGeo.dispose);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();
      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);

      final outcome = await notifier.startGpsOnly();

      expect(outcome, StartTripOutcome.alreadyActive);
      // The OBD2 trip is untouched — still the controller path.
      expect(notifier.debugIsGpsOnlyActive, isFalse);
      expect(notifier.debugController, isNotNull);

      await notifier.stop();
    });
  });
}

Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };

/// Controllable fake [GeolocatorWrapper]. Copies the proven shape from
/// trip_recording_provider_gps_test.dart — the `emit` / `emitError`
/// helpers keep the `close_sinks` analyzer happy by giving the field a
/// traced sink consumer, and [dispose] closes the controller from the
/// test's tearDown.
class _FakeGeo extends GeolocatorWrapper {
  StreamController<Position>? _controller;
  int activeListeners = 0;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    final prev = _controller;
    if (prev != null && !prev.isClosed) {
      prev.close();
    }
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
