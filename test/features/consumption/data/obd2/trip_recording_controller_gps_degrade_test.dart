// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_reconnect_scanner.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/paused_trip_repository.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_recording_controller.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';

/// #2565 — the GPS-DEGRADE half: an OBD2 drop on a healthy-GPS drive must
/// keep RECORDING (GPS-only) instead of pausing, and only escalate to
/// "paused" when GPS ALSO dies. Drives the real
/// [TripRecordingController] against a fake transport + a hand-driven
/// reconnect scanner + a controllable clock so the gpsAlive window + the
/// degrade emit loop are exercised deterministically.
void main() {
  group('TripRecordingController GPS-only degrade (#2565)', () {
    late Directory tmpDir;
    late Box<String> pausedBox;
    late Box<String> historyBox;
    late PausedTripRepository pausedRepo;
    late TripHistoryRepository historyRepo;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('gps_degrade_test_');
      Hive.init(tmpDir.path);
      pausedBox = await Hive.openBox<String>(
        'paused_${DateTime.now().microsecondsSinceEpoch}',
      );
      historyBox = await Hive.openBox<String>(
        'history_${DateTime.now().microsecondsSinceEpoch}',
      );
      pausedRepo = PausedTripRepository(box: pausedBox);
      historyRepo = TripHistoryRepository(box: historyBox);
    });

    tearDown(() async {
      await pausedBox.deleteFromDisk();
      await historyBox.deleteFromDisk();
      await Hive.close();
      tmpDir.deleteSync(recursive: true);
    });

    Map<String, String> initResponses() => {
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          '01A6': 'NO DATA>',
        };

    test('OBD2 transport drop on a live-GPS drive degrades to GPS-only '
        '(NOT paused); the emit loop keeps building GPS samples — no gap; '
        'NO grace timer', () async {
      var clock = DateTime(2026, 6, 1, 9);
      final transport = FakeObd2Transport(initResponses());
      await transport.connect();
      var scannerStarts = 0;
      VoidCallback? capturedOnReconnect;

      final ctl = TripRecordingController(
        service: Obd2Service(transport),
        pollInterval: const Duration(minutes: 1), // emit only on demand.
        now: () => clock,
        vehicleId: 'car-degrade',
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        // A short grace so a wrongly-armed timer would auto-finalise fast.
        pauseGraceWindow: const Duration(milliseconds: 30),
        silentReconnectWindow: const Duration(seconds: 6),
        pinnedAdapterMac: 'AA:BB',
        reconnectScannerFactory: (mac, onReconnect) {
          capturedOnReconnect = onReconnect;
          return _ObservableScanner(
            pinnedMac: mac,
            onReconnect: onReconnect,
            onStart: () => scannerStarts++,
            onStop: () {},
          );
        },
      );

      await ctl.start();

      // A real GPS fix lands → gpsAlive == true, latest GPS speed 85 km/h.
      ctl.updateGpsFix(
        latitude: 48.0,
        longitude: 7.0,
        altitudeM: 200,
        speedKmh: 85,
      );

      final readings = <TripLiveReading>[];
      final sub = ctl.live.listen(readings.add);

      // The OBD2 transport drops mid-trip.
      ctl.debugTriggerDrop();

      expect(ctl.currentState, TripRecordingControllerState.degradedGpsOnly,
          reason: 'an OBD2 drop on a live-GPS drive must degrade to '
              'GPS-only recording, not pause');
      expect(scannerStarts, 1,
          reason: 'the reconnect scanner must probe so OBD2 can re-attach');
      expect(capturedOnReconnect, isNotNull);

      final samplesAtDrop = ctl.capturedSamples.length;

      // Several emit ticks fire while degraded, each ~1 s apart so the
      // capture buffer's 950 ms decimation admits them.
      for (var i = 1; i <= 3; i++) {
        clock = clock.add(const Duration(seconds: 1));
        // Re-latch a fresh GPS fix every tick so gpsAlive stays true.
        ctl.updateGpsFix(
          latitude: 48.0 + i * 0.001,
          longitude: 7.0,
          altitudeM: 200,
          speedKmh: 85,
        );
        ctl.debugEmitNow();
      }
      // The live stream is a broadcast controller — its events are
      // delivered asynchronously, so let the microtask queue drain
      // before asserting on the collected readings.
      await Future<void>.delayed(Duration.zero);

      expect(ctl.capturedSamples.length, greaterThan(samplesAtDrop),
          reason: 'the trip must keep capturing GPS samples across the '
              'OBD2 drop — no recording gap');
      // The degraded sample is GPS-only: speed ~85, NO engine signal, no
      // fuel rate. #2692 C4-G — a GPS-only sample now carries rpm null
      // (rather than faking idle with 0) so the recorder never inflates
      // maxRpm / high-RPM / idle time from a drive with no OBD2 link.
      final degradedSample = ctl.capturedSamples.last;
      expect(degradedSample.speedKmh, closeTo(85, 0.001));
      expect(degradedSample.rpm, isNull);
      expect(degradedSample.fuelRateLPerHour, isNull);
      // The live reading carries the genuine live GPS speed (not frozen).
      expect(readings.where((r) => r.speedKmh == 85), isNotEmpty,
          reason: 'the metric cards must show the live GPS speed, not a '
              'frozen pre-drop reading');

      // A degraded trip must NEVER auto-finalise — no grace timer is armed.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(historyRepo.loadAll(), isEmpty,
          reason: 'a degraded trip is actively recording — it must never '
              'auto-finalise/discard via a grace timer');
      expect(ctl.currentState, TripRecordingControllerState.degradedGpsOnly);

      await sub.cancel();
      await ctl.stop();
    });

    test('scanner reconnect while degraded returns to recording; OBD2 '
        'speed is read again', () async {
      final transport = FakeObd2Transport(initResponses());
      await transport.connect();
      VoidCallback? capturedOnReconnect;

      final ctl = TripRecordingController(
        service: Obd2Service(transport),
        pollInterval: const Duration(milliseconds: 40),
        schedulerTickRate: const Duration(milliseconds: 10),
        vehicleId: 'car-degrade-reconnect',
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        pinnedAdapterMac: 'AA:BB',
        reconnectScannerFactory: (mac, onReconnect) {
          capturedOnReconnect = onReconnect;
          return _ObservableScanner(
            pinnedMac: mac,
            onReconnect: onReconnect,
            onStart: () {},
            onStop: () {},
          );
        },
      );

      await ctl.start();
      ctl.updateGpsFix(latitude: 48, longitude: 7, speedKmh: 60);
      ctl.debugTriggerDrop();
      expect(ctl.currentState, TripRecordingControllerState.degradedGpsOnly);

      // The reconnect builds a BRAND-NEW healthy transport (the
      // production flow — `ReconnectConnector` → `replaceService`).
      final liveTransport = FakeObd2Transport({
        ...initResponses(),
        '010D': '41 0D 32>', // 50 km/h
        '010C': '41 0C 0E A6>', // ~937 rpm
      });
      await liveTransport.connect();
      ctl.replaceService(Obd2Service(liveTransport));
      capturedOnReconnect!.call();
      expect(ctl.currentState, TripRecordingControllerState.recording,
          reason: 'an OBD2 reconnect must drop back to full recording');

      // The scheduler restarted on the LIVE service: OBD2 PID speed
      // (50 km/h) flows again and wins over the GPS latch.
      final readings = <TripLiveReading>[];
      final sub = ctl.live.listen(readings.add);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(readings.any((r) => r.speedKmh == 50), isTrue,
          reason: 'after reconnect the OBD2 speed PID (50 km/h) must win '
              'again over the GPS latch');

      await sub.cancel();
      await ctl.stop();
    });

    test('a drop with NO recent GPS fix still goes silent → pausedDueToDrop '
        '(regression-lock for the dead-GPS path)', () async {
      final clock = DateTime(2026, 6, 1, 11);
      final transport = FakeObd2Transport(initResponses());
      await transport.connect();

      final ctl = TripRecordingController(
        service: Obd2Service(transport),
        pollInterval: const Duration(minutes: 1),
        now: () => clock,
        vehicleId: 'car-no-gps',
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        // Tiny silent window so the escalation fires fast.
        silentReconnectWindow: const Duration(milliseconds: 40),
        pinnedAdapterMac: 'AA:BB',
        reconnectScannerFactory: (mac, onReconnect) => _ObservableScanner(
          pinnedMac: mac,
          onReconnect: onReconnect,
          onStart: () {},
          onStop: () {},
        ),
      );

      await ctl.start();
      // NO GPS fix pushed → gpsAlive is false.
      ctl.debugTriggerDrop();

      // The drop entered the invisible silent window (still 'recording').
      expect(ctl.currentState, TripRecordingControllerState.recording);
      expect(ctl.debugSilentlyReconnecting, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(ctl.currentState, TripRecordingControllerState.pausedDueToDrop,
          reason: 'with no live GPS, the OBD2 drop must pause exactly as '
              'before — the silent window escalates to the pause banner');

      await ctl.stop();
    });

    test('while degraded, GPS stalling past the gap-cap window escalates '
        'degradedGpsOnly → pausedDueToDrop (both sources gone)', () async {
      var clock = DateTime(2026, 6, 1, 12);
      final transport = FakeObd2Transport(initResponses());
      await transport.connect();

      final ctl = TripRecordingController(
        service: Obd2Service(transport),
        pollInterval: const Duration(minutes: 1),
        now: () => clock,
        vehicleId: 'car-gps-also-dies',
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        pauseGraceWindow: const Duration(hours: 1),
        pinnedAdapterMac: 'AA:BB',
        reconnectScannerFactory: (mac, onReconnect) => _ObservableScanner(
          pinnedMac: mac,
          onReconnect: onReconnect,
          onStart: () {},
          onStop: () {},
        ),
      );

      await ctl.start();
      ctl.updateGpsFix(latitude: 48, longitude: 7, speedKmh: 70);
      ctl.debugTriggerDrop();
      expect(ctl.currentState, TripRecordingControllerState.degradedGpsOnly);

      // No further GPS fix lands; the clock advances PAST the 15 s
      // gps-alive window. The next degraded emit sees GPS is dead too.
      clock = clock.add(const Duration(seconds: 20));
      ctl.debugEmitNow();

      expect(ctl.currentState, TripRecordingControllerState.pausedDueToDrop,
          reason: 'when GPS also dies past the gap-cap window, BOTH sources '
              'are gone → the trip must finally pause');

      await ctl.stop();
    });
  });
}

/// A fake scanner that records `start()` / `stop()` invocations and lets a
/// test fire its [onReconnect] manually — mirrors the one in
/// `trip_recording_controller_reconnect_test.dart`.
class _ObservableScanner implements AdapterReconnectScanner {
  _ObservableScanner({
    required this.pinnedMac,
    required this.onReconnect,
    required this.onStart,
    required this.onStop,
  });

  @override
  final String pinnedMac;

  final VoidCallback onReconnect;
  final VoidCallback onStart;
  final VoidCallback onStop;

  bool _scanning = false;

  @override
  bool get isScanning => _scanning;

  @override
  bool get isPassiveWaiting => false;

  @override
  VoidCallback? onPassiveWait;

  @override
  int get consecutiveMisses => 0;

  @override
  Duration get currentBackoff => const Duration(seconds: 5);

  @override
  Future<void> start() async {
    _scanning = true;
    onStart();
  }

  @override
  Future<void> stop() async {
    _scanning = false;
    onStop();
  }
}
