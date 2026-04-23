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

/// Exercises the #797 phase 3 wiring between the controller's
/// drop-detection path and the auto-reconnect scanner. Uses an
/// in-memory Hive box so the paused-trips / history state is
/// observable, and a hand-crafted scanner factory so the test
/// controls exactly when "the MAC is in range".
void main() {
  group('TripRecordingController × AdapterReconnectScanner (#797 phase 3)',
      () {
    late Directory tmpDir;
    late Box<String> pausedBox;
    late Box<String> historyBox;
    late PausedTripRepository pausedRepo;
    late TripHistoryRepository historyRepo;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('reconnect_test_');
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

    test(
        'drop starts the reconnect scanner; scanner reconnect fires '
        'resume and cancels the grace timer', () async {
      final transport = FakeObd2Transport(initResponses());
      await transport.connect();
      // Capture the pinned MAC passed to the factory + the
      // onReconnect callback so the test can drive them directly.
      String? capturedPinnedMac;
      VoidCallback? capturedOnReconnect;
      var scannerStartCount = 0;
      var scannerStopCount = 0;
      AdapterReconnectScanner? builtScanner;

      final ctl = TripRecordingController(
        service: Obd2Service(transport),
        pollInterval: const Duration(minutes: 1),
        vehicleId: 'car-reconnect',
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        // Long grace so we can prove the scanner's resume beats
        // the grace-window auto-finalise.
        pauseGraceWindow: const Duration(hours: 1),
        pinnedAdapterMac: 'AA:BB:CC:DD:EE:FF',
        reconnectScannerFactory: (mac, onReconnect) {
          capturedPinnedMac = mac;
          capturedOnReconnect = onReconnect;
          // Build a scanner whose probe is pinned "not yet" so
          // the scheduled ticks don't race with the manual
          // fire below. The test drives the reconnect path by
          // invoking the captured onReconnect directly — that's
          // the contract the scanner's docstring promises.
          builtScanner = _ObservableScanner(
            pinnedMac: mac,
            onReconnect: onReconnect,
            onStart: () => scannerStartCount++,
            onStop: () => scannerStopCount++,
          );
          return builtScanner;
        },
      );

      await ctl.start();

      ctl.debugInjectSample(
        speedKmh: 55,
        rpm: 1900,
        at: DateTime(2026, 4, 22, 13),
      );
      ctl.debugTriggerDrop();

      expect(
        ctl.currentState,
        TripRecordingControllerState.pausedDueToDrop,
        reason: 'drop must flip the state immediately',
      );
      expect(capturedPinnedMac, 'AA:BB:CC:DD:EE:FF');
      expect(capturedOnReconnect, isNotNull);
      expect(scannerStartCount, 1,
          reason: 'the controller must call scanner.start() on drop');
      expect(pausedRepo.loadAll(), hasLength(1));

      // Simulate the scanner fire-ing onReconnect (the production
      // scanner self-stops, fires the callback, and that's the
      // contract the controller relies on).
      capturedOnReconnect!.call();
      // onReconnect flows into resume() synchronously.

      expect(
        ctl.currentState,
        TripRecordingControllerState.recording,
        reason: 'scanner reconnect must flip us back to recording',
      );
      expect(pausedRepo.loadAll(), isEmpty,
          reason: 'resume must clear the paused-trips row so a '
              'subsequent drop writes a fresh snapshot');
      expect(historyRepo.loadAll(), isEmpty,
          reason: 'grace-window auto-finalise must NOT fire once the '
              'scanner beats it to the punch');

      // Controller's reference to the scanner is released after a
      // successful reconnect.
      expect(ctl.debugReconnectScanner, isNull);

      await ctl.stop();
    });

    test(
        'no pinned MAC → scanner factory is never called; the '
        'grace-window path remains the sole recovery', () async {
      final transport = FakeObd2Transport(initResponses());
      await transport.connect();
      var factoryCalls = 0;
      final ctl = TripRecordingController(
        service: Obd2Service(transport),
        pollInterval: const Duration(minutes: 1),
        vehicleId: 'car-no-pin',
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        pauseGraceWindow: const Duration(milliseconds: 50),
        // pinnedAdapterMac omitted — null.
        reconnectScannerFactory: (mac, onReconnect) {
          factoryCalls++;
          return null;
        },
      );
      await ctl.start();
      ctl.debugInjectSample(
        speedKmh: 40,
        rpm: 1500,
        at: DateTime(2026, 4, 22, 14),
      );
      ctl.debugTriggerDrop();

      expect(factoryCalls, 0,
          reason: 'factory must not be called when the vehicle has '
              'no pinned adapter MAC');

      // Wait for grace window to fire and finalise.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(historyRepo.loadAll(), hasLength(1),
          reason: 'without a scanner the grace-window auto-finalise '
              'is the only recovery path');
    });

    test(
        'stop() tears down the reconnect scanner so no ticks leak '
        'past the trip', () async {
      final transport = FakeObd2Transport(initResponses());
      await transport.connect();
      var stopCalls = 0;
      final ctl = TripRecordingController(
        service: Obd2Service(transport),
        pollInterval: const Duration(minutes: 1),
        vehicleId: 'car-teardown',
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        pauseGraceWindow: const Duration(hours: 1),
        pinnedAdapterMac: 'AA:BB',
        reconnectScannerFactory: (mac, onReconnect) => _ObservableScanner(
          pinnedMac: mac,
          onReconnect: onReconnect,
          onStart: () {},
          onStop: () => stopCalls++,
        ),
      );
      await ctl.start();
      ctl.debugTriggerDrop();
      expect(ctl.debugReconnectScanner, isNotNull);
      await ctl.stop();
      expect(stopCalls, greaterThanOrEqualTo(1),
          reason: 'stop() must cancel the auto-reconnect scanner');
    });

    test(
        'grace-window elapse stops the scanner before finalising so '
        'a late reconnect cannot race a finalised trip', () async {
      final transport = FakeObd2Transport(initResponses());
      await transport.connect();
      var stopCalls = 0;
      final ctl = TripRecordingController(
        service: Obd2Service(transport),
        pollInterval: const Duration(minutes: 1),
        vehicleId: 'car-race',
        pausedRepo: pausedRepo,
        historyRepo: historyRepo,
        pauseGraceWindow: const Duration(hours: 1),
        pinnedAdapterMac: 'MAC',
        reconnectScannerFactory: (mac, onReconnect) => _ObservableScanner(
          pinnedMac: mac,
          onReconnect: onReconnect,
          onStart: () {},
          onStop: () => stopCalls++,
        ),
      );
      await ctl.start();
      ctl.debugInjectSample(
        speedKmh: 30,
        rpm: 1400,
        at: DateTime(2026, 4, 22, 15),
      );
      ctl.debugTriggerDrop();
      expect(stopCalls, 0, reason: 'scanner still running during '
          'grace window');
      await ctl.debugExpireGraceWindow();
      expect(stopCalls, 1,
          reason: 'grace expiry must stop the scanner BEFORE '
              'finalising so a late reconnect cannot race');
      expect(historyRepo.loadAll(), hasLength(1));
    });
  });
}

/// A fake scanner that records `start()` / `stop()` invocations so
/// the trip-controller tests can assert lifecycle coupling without
/// actually driving timers. Purely an observation hook — the real
/// scanner's backoff math is covered by
/// `adapter_reconnect_scanner_test.dart`.
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
