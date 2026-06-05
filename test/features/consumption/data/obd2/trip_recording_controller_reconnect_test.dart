// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_reconnect_scanner.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_record_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_errors.dart';
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
        // This test exercises the visible-drop + grace + scanner
        // wiring directly; disable the #1904 silent reconnect window
        // so a drop flips straight to pausedDueToDrop.
        silentReconnectWindow: Duration.zero,
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
        // #1904 — disable the silent reconnect window so the drop is
        // visible immediately and the grace path runs as before.
        silentReconnectWindow: Duration.zero,
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
        // #1904 — disable the silent reconnect window so the drop goes
        // straight to the visible grace-window path under test.
        silentReconnectWindow: Duration.zero,
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

    group('connection reliability — #1904', () {
      test(
          'silent reconnect stays invisible — a transport drop the '
          'scanner clears within the window never reaches the banner',
          () async {
        final transport = FakeObd2Transport(initResponses());
        await transport.connect();
        VoidCallback? capturedOnReconnect;
        var scannerStartCount = 0;

        final ctl = TripRecordingController(
          service: Obd2Service(transport),
          pollInterval: const Duration(minutes: 1),
          vehicleId: 'car-silent-reconnect',
          pausedRepo: pausedRepo,
          historyRepo: historyRepo,
          // Default 6 s silent-reconnect window — long enough that the
          // manual onReconnect below lands well inside it.
          pinnedAdapterMac: 'AA:BB:CC:DD:EE:FF',
          reconnectScannerFactory: (mac, onReconnect) {
            capturedOnReconnect = onReconnect;
            return _ObservableScanner(
              pinnedMac: mac,
              onReconnect: onReconnect,
              onStart: () => scannerStartCount++,
              onStop: () {},
            );
          },
        );

        await ctl.start();
        ctl.debugInjectSample(
          speedKmh: 50,
          rpm: 1800,
          at: DateTime(2026, 5, 18, 9),
        );
        ctl.debugTriggerDrop();

        // The drop entered the invisible reconnect window: the user
        // still sees `recording`, the scanner is probing.
        expect(ctl.currentState, TripRecordingControllerState.recording,
            reason: 'a transport drop must NOT flip the visible state '
                'while the silent reconnect window is open');
        expect(ctl.debugSilentlyReconnecting, isTrue,
            reason: 'the controller must report it is silently '
                'reconnecting after a transport drop');
        expect(scannerStartCount, 1,
            reason: 'the reconnect scanner must start during the '
                'silent window');

        // The scanner finds the adapter inside the window.
        capturedOnReconnect!.call();

        expect(ctl.currentState, TripRecordingControllerState.recording,
            reason: 'a silent reconnect must keep the state at '
                'recording — the user never saw a pause');
        expect(ctl.debugSilentlyReconnecting, isFalse,
            reason: 'a successful reconnect must clear the silent '
                'reconnect flag');
        expect(pausedRepo.loadAll(), isEmpty,
            reason: 'a silent reconnect must clear the paused-trips '
                'row so the user never sees a stranded partial trip');

        await ctl.stop();
      });

      test(
          'no reconnect escalates to the visible banner once the '
          'silent window elapses', () async {
        final transport = FakeObd2Transport(initResponses());
        await transport.connect();

        final ctl = TripRecordingController(
          service: Obd2Service(transport),
          pollInterval: const Duration(minutes: 1),
          vehicleId: 'car-no-reconnect',
          pausedRepo: pausedRepo,
          historyRepo: historyRepo,
          // Tiny silent window so the escalation fires fast in-test.
          silentReconnectWindow: const Duration(milliseconds: 50),
          pinnedAdapterMac: 'AA:BB:CC:DD:EE:FF',
          // A scanner that never calls onReconnect — the adapter is
          // genuinely gone.
          reconnectScannerFactory: (mac, onReconnect) => _ObservableScanner(
            pinnedMac: mac,
            onReconnect: onReconnect,
            onStart: () {},
            onStop: () {},
          ),
        );

        await ctl.start();
        ctl.debugTriggerDrop();

        // Immediately after the drop the state is still invisible.
        expect(ctl.currentState, TripRecordingControllerState.recording,
            reason: 'the drop is invisible while the silent window is '
                'still open');

        // Wait past the 50 ms silent window.
        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(
          ctl.currentState,
          TripRecordingControllerState.pausedDueToDrop,
          reason: 'when the silent window elapses with no reconnect '
              'the controller must escalate to the visible pause banner',
        );

        await ctl.stop();
      });

      test(
          'a silentFailure drop is visible immediately — no silent '
          'reconnect window', () async {
        final transport = FakeObd2Transport(initResponses());
        await transport.connect();

        final ctl = TripRecordingController(
          service: Obd2Service(transport),
          pollInterval: const Duration(minutes: 1),
          vehicleId: 'car-silent-failure',
          pausedRepo: pausedRepo,
          historyRepo: historyRepo,
          // Default 6 s silent-reconnect window — proves a
          // silentFailure drop bypasses it entirely.
          pinnedAdapterMac: 'AA:BB:CC:DD:EE:FF',
          reconnectScannerFactory: (mac, onReconnect) => _ObservableScanner(
            pinnedMac: mac,
            onReconnect: onReconnect,
            onStart: () {},
            onStop: () {},
          ),
        );

        await ctl.start();
        ctl.debugTriggerDrop(reason: TripDropReason.silentFailure);

        expect(
          ctl.currentState,
          TripRecordingControllerState.pausedDueToDrop,
          reason: 'a silentFailure drop — the ECU stopped answering — '
              'cannot be cleared by a Bluetooth reconnect, so it must '
              'go straight to the visible pause banner',
        );
        expect(ctl.debugSilentlyReconnecting, isFalse,
            reason: 'a silentFailure drop must NOT enter the silent '
                'reconnect window');

        await ctl.stop();
      });

      test(
          'a single transient transport error is retried, not counted '
          'as a drop', () async {
        // First fake: throws once for 010D, then succeeds. The #1904
        // single retry should absorb the transient error.
        final transientFake = _FlakyTransport(failuresPerCommand: 1);
        await transientFake.connect();
        final ctlRetry = TripRecordingController(
          service: Obd2Service(transientFake),
          pollInterval: const Duration(minutes: 1),
        );

        final retried = await ctlRetry.debugRunTransport('010D\r');
        expect(retried, _FlakyTransport.successResponse,
            reason: 'the #1904 single retry must absorb a transient '
                'transport error and return the success response');
        expect(transientFake.callCount('010D\r'), 2,
            reason: 'one failed try + one retry = exactly 2 calls');

        // Second fake: throws on every call. The retry exhausts and
        // the error propagates.
        final brokenFake = _FlakyTransport(failuresPerCommand: 1 << 20);
        await brokenFake.connect();
        final ctlBroken = TripRecordingController(
          service: Obd2Service(brokenFake),
          pollInterval: const Duration(minutes: 1),
        );

        await expectLater(
          ctlBroken.debugRunTransport('010D\r'),
          throwsA(isA<StateError>()),
          reason: 'a failure that survives the retry must propagate',
        );
        expect(brokenFake.callCount('010D\r'), 2,
            reason: 'the retrying path makes exactly 2 attempts before '
                'giving up — one try + one retry');
      });

      test(
          'the silent-reconnect window emits nothing — no phantom '
          'integration from a stale snapshot (#1912)', () async {
        // Speed + RPM PIDs so live telemetry actually flows before the
        // drop. The default scheduler is used (no override) so it
        // really polls; a short pollInterval keeps the emit timer
        // ticking inside the test window.
        final transport = FakeObd2Transport({
          ...initResponses(),
          '010D': '41 0D 32>', // 50 km/h
          '010C': '41 0C 0E A6>', // ~937 rpm
        });
        await transport.connect();
        final ctl = TripRecordingController(
          service: Obd2Service(transport),
          pollInterval: const Duration(milliseconds: 40),
          vehicleId: 'car-1912',
          pausedRepo: pausedRepo,
          historyRepo: historyRepo,
          pinnedAdapterMac: 'AA:BB',
          // A scanner that never auto-reconnects, so the trip stays in
          // the silent window for the whole test.
          reconnectScannerFactory: (mac, onReconnect) => _ObservableScanner(
            pinnedMac: mac,
            onReconnect: onReconnect,
            onStart: () {},
            onStop: () {},
          ),
        );

        final readings = <Object>[];
        final sub = ctl.live.listen(readings.add);
        await ctl.start();
        // Live telemetry flows normally before the drop.
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(readings, isNotEmpty,
            reason: 'the emit timer must produce readings while the '
                'trip is genuinely recording');

        // Transport drop → enters the invisible reconnect window.
        ctl.debugTriggerDrop();
        expect(ctl.debugSilentlyReconnecting, isTrue);
        final countAtDrop = readings.length;

        // Several emit-timer ticks elapse while still inside the
        // silent window (the scanner never reconnects here).
        await Future<void>.delayed(const Duration(milliseconds: 250));

        expect(readings.length, countAtDrop,
            reason: '#1912 — _emit must be gated during the silent '
                'reconnect window: the scheduler is stopped, so emitting '
                'the stale snapshot would integrate phantom distance / '
                'fuel from a frozen speed over real elapsed time');

        await sub.cancel();
        await ctl.stop();
      });
    });

    // ── #2524 — reconnect must swap the controller onto the LIVE service ──
    //
    // The existing #797/#1904 tests above reuse ONE healthy fake transport,
    // so they never exercise the swap: a real in-trip reconnect builds a
    // BRAND-NEW Obd2Service + transport. Without `replaceService` the
    // recording loop keeps polling the DEAD old transport forever — every
    // poll times out, a stranded `_pending` trips the concurrent-sendCommand
    // guard, both flood the error log, and the rest of the drive records
    // nothing.
    group('reconnect builds a NEW transport — controller swap (#2524)', () {
      // Capture errorLogger.log calls so we can assert NO concurrent-
      // sendCommand StateError reaches the spool.
      late _CaptureRecorder recorder;
      setUp(() {
        recorder = _CaptureRecorder();
        errorLogger.resetForTest();
        errorLogger.testRecorderOverride = recorder;
      });
      tearDown(errorLogger.resetForTest);

      test(
          'after replaceService the recording loop polls the LIVE transport '
          '(samples flow), the OLD service is disconnected + its stranded '
          'pending failed, and no concurrent StateError is error-logged',
          () async {
        // The OLD service: a half-dead transport. It answers the init /
        // odometer / VIN reads (so trip-start completes), NO-DATAs other
        // PIDs, but strands `010C` in _pending — the #2524 leak the swap
        // must fail cleanly on disconnect.
        final oldTransport =
            _DeadTransport(initResponses(), strandCommand: '010C');
        await oldTransport.connect();
        // Strand a pending command on the dead transport (never resolves
        // until disconnect fails it).
        final stranded = oldTransport.sendCommand('010C');
        var strandedFailed = false;
        unawaited(stranded.then(
          (_) {},
          onError: (_) => strandedFailed = true,
        ));

        // The NEW, healthy transport built by the (simulated) reconnect.
        final liveTransport = _LiveTransport({
          ...initResponses(),
          '010D': '41 0D 32>', // 50 km/h
          '010C': '41 0C 0E A6>', // ~937 rpm
        });
        await liveTransport.connect();
        final liveService = Obd2Service(liveTransport);

        VoidCallback? capturedOnReconnect;
        final ctl = TripRecordingController(
          service: Obd2Service(oldTransport),
          pollInterval: const Duration(milliseconds: 40),
          schedulerTickRate: const Duration(milliseconds: 10),
          vehicleId: 'car-2524',
          pausedRepo: pausedRepo,
          historyRepo: historyRepo,
          pinnedAdapterMac: 'AA:BB',
          // A scanner whose onReconnect we fire manually; on fire it stands
          // in for ReconnectConnector.onConnected → ctl.replaceService.
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
        // Drop → enters the silent reconnect window. handleDrop tears down
        // the OLD service (#2524), which fails its stranded _pending.
        ctl.debugTriggerDrop();
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(strandedFailed, isTrue,
            reason: 'the drop must disconnect the dead service so its '
                'stranded _pending is failed cleanly, not left hanging');
        expect(oldTransport.disconnectCount, greaterThanOrEqualTo(1),
            reason: 'the OLD service must be disconnected on drop');

        // Simulate the reconnect landing a NEW live service: this is what
        // ReconnectConnector.onConnected → Obd2RecordingPipeline does.
        ctl.replaceService(liveService);
        capturedOnReconnect!.call();
        expect(ctl.currentState, TripRecordingControllerState.recording,
            reason: 'a silent reconnect keeps the state at recording');

        // Collect live readings from the NEW transport. Before the fix the
        // loop kept polling the dead old transport and nothing flowed.
        final readings = <TripLiveReading>[];
        final sub = ctl.live.listen(readings.add);
        await Future<void>.delayed(const Duration(milliseconds: 250));

        expect(readings.any((r) => r.speedKmh == 50), isTrue,
            reason: '#2524 — after replaceService the scheduler must poll '
                'the LIVE transport: the 50 km/h sample only exists there');
        expect(liveTransport.pidPollCount, greaterThan(0),
            reason: 'the live transport must actually receive PID polls');

        // No concurrent-sendCommand StateError reached the error logger.
        final stateErrors = recorder.calls.where((e) {
          final s = e.toString().toLowerCase();
          return e is StateError && s.contains('concurrent');
        });
        expect(stateErrors, isEmpty,
            reason: 'the concurrent-sendCommand guard must never reach the '
                'error logger as a raw StateError (#2524)');

        await sub.cancel();
        await ctl.stop();
      });

      test(
          'replaceService is idempotent — passing the current service is a '
          'no-op and does not disconnect it', () async {
        final transport = _LiveTransport(initResponses());
        await transport.connect();
        final service = Obd2Service(transport);
        final ctl = TripRecordingController(
          service: service,
          pollInterval: const Duration(minutes: 1),
          vehicleId: 'car-2524-idem',
          pausedRepo: pausedRepo,
          historyRepo: historyRepo,
        );
        await ctl.start();

        ctl.replaceService(service); // same instance
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(transport.disconnectCount, 0,
            reason: 'replaceService(currentService) must be a no-op');

        await ctl.stop();
      });
    });

    group('long-gap reconnect — passive-waiting then late power-cycle (#2767)',
        () {
      test(
          'scanner gives up active scanning → reconnectPassiveWaiting surfaces '
          '+ a trace entry; a LATE reconnect still resumes OBD2', () async {
        AutoRecordTraceLog.clear();
        var clock = DateTime(2026, 6, 1, 9);
        final transport = FakeObd2Transport(initResponses());
        await transport.connect();
        VoidCallback? capturedOnReconnect;
        _ObservableScanner? builtScanner;

        final ctl = TripRecordingController(
          service: Obd2Service(transport),
          pollInterval: const Duration(minutes: 1),
          now: () => clock,
          vehicleId: 'car-longgap',
          pausedRepo: pausedRepo,
          historyRepo: historyRepo,
          // No grace timer fires in degraded GPS-only mode, but keep it long
          // anyway so nothing auto-finalises mid-test.
          pauseGraceWindow: const Duration(hours: 1),
          silentReconnectWindow: const Duration(seconds: 6),
          pinnedAdapterMac: 'AA:BB',
          reconnectScannerFactory: (mac, onReconnect) {
            capturedOnReconnect = onReconnect;
            builtScanner = _ObservableScanner(
              pinnedMac: mac,
              onReconnect: onReconnect,
              onStart: () {},
              onStop: () {},
            );
            return builtScanner;
          },
        );

        await ctl.start();
        // A live GPS fix so the OBD2 drop degrades (keeps recording) rather
        // than pausing — the path where the never-resolving banner lived.
        ctl.updateGpsFix(
          latitude: 48.0,
          longitude: 7.0,
          altitudeM: 200,
          speedKmh: 70,
        );
        ctl.debugTriggerDrop();
        expect(ctl.currentState, TripRecordingControllerState.degradedGpsOnly);
        expect(ctl.reconnectPassiveWaiting, isFalse,
            reason: 'still active-scanning right after the drop');

        // The adapter stays away long enough that the scanner exhausts its
        // active-scan ceiling and drops to a passive wait. The real scanner
        // fires onPassiveWait; the fake reproduces that contract.
        builtScanner!.isPassiveWaiting = true;
        builtScanner!.onPassiveWait?.call();

        expect(ctl.reconnectPassiveWaiting, isTrue,
            reason: 'once the scanner gives up active scanning the controller '
                'must surface the passive-waiting signal so the UI swaps the '
                'banner copy (#2767)');
        expect(
          AutoRecordTraceLog.snapshot()
              .map((e) => e.kind)
              .contains(AutoRecordEventKind.reconnectPassiveWaiting),
          isTrue,
          reason: 'the passive-waiting transition must be traced for the '
              'exportable diagnostic log',
        );
        // Still recording — passive-waiting is NOT a pause.
        expect(ctl.currentState, TripRecordingControllerState.degradedGpsOnly);

        // A LATE adapter power-cycle (dropped early, back much later): the
        // scanner — having re-armed an active scan from passive mode — finds
        // it and fires onReconnect. OBD2 recording must resume cleanly.
        clock = clock.add(const Duration(minutes: 14));
        builtScanner!.isPassiveWaiting = false;
        capturedOnReconnect!.call();

        expect(ctl.currentState, TripRecordingControllerState.recording,
            reason: 'a late reconnect after passive-waiting must resume full '
                'OBD2 recording, not be missed (#2767)');
        expect(ctl.reconnectPassiveWaiting, isFalse,
            reason: 'the passive-waiting flag clears the moment OBD2 is back');

        await ctl.stop();
        AutoRecordTraceLog.clear();
      });
    });
  });
}

/// Captures every `errorLogger.log` call routed through the foreground
/// recorder seam (#2524 assertion (c)). Mirrors the fake in
/// `pid_scheduler_test.dart`.
class _CaptureRecorder implements TraceRecorder {
  final calls = <Object>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    calls.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// The OLD transport after a drop: its channel is dead but `_connected`
/// stays true. It answers scripted commands (so trip-start's odometer /
/// VIN reads complete) and NO-DATAs everything else, EXCEPT the single
/// [strandCommand], which never resolves — modelling a command stranded
/// in the half-dead instance's `_pending` until [disconnect] fails it (the
/// #2524 leak the controller must tear down on reconnect).
class _DeadTransport implements Obd2Transport {
  _DeadTransport(this._responses, {this.strandCommand});

  final Map<String, String> _responses;
  final String? strandCommand;
  bool _connected = false;
  int disconnectCount = 0;
  final List<Completer<String>> _stranded = <Completer<String>>[];

  @override
  Future<void> connect() async => _connected = true;

  @override
  bool get isConnected => _connected;

  @override
  Future<String> sendCommand(String command) {
    if (!_connected) {
      return Future.error(StateError('Not connected'));
    }
    final cmd = command.trim();
    if (strandCommand != null && cmd == strandCommand) {
      // Never resolves — stranded in _pending until disconnect fails it.
      final c = Completer<String>();
      _stranded.add(c);
      return c.future;
    }
    return Future<String>.value(_responses[cmd] ?? 'NO DATA>');
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    disconnectCount++;
    for (final c in _stranded) {
      if (!c.isCompleted) {
        c.completeError(const Obd2DisconnectedException('link torn down'));
      }
    }
    _stranded.clear();
  }
}

/// The NEW, healthy transport built by a real reconnect: answers PIDs from
/// a scripted map and counts live-PID polls so the test can prove the
/// scheduler is hitting THIS transport after the swap (#2524).
class _LiveTransport implements Obd2Transport {
  _LiveTransport(this._responses);

  final Map<String, String> _responses;
  bool _connected = false;
  int disconnectCount = 0;
  int pidPollCount = 0;

  @override
  Future<void> connect() async => _connected = true;

  @override
  bool get isConnected => _connected;

  @override
  Future<String> sendCommand(String command) async {
    if (!_connected) throw StateError('Not connected');
    final cmd = command.trim();
    if (cmd == '010D' || cmd == '010C') pidPollCount++;
    return _responses[cmd] ?? 'NO DATA>';
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    disconnectCount++;
  }
}

/// Test-local transport whose [sendCommand] throws for the first
/// [failuresPerCommand] calls of any given command, then succeeds.
/// Tracks a per-command call count so the #1904 single-retry tests
/// can assert exactly how many attempts the retrying transport path
/// made.
class _FlakyTransport implements Obd2Transport {
  _FlakyTransport({required this.failuresPerCommand});

  /// Response returned once a command's failure budget is exhausted.
  static const String successResponse = '41 0D 32>';

  final int failuresPerCommand;
  final Map<String, int> _counts = <String, int>{};
  bool _connected = false;

  int callCount(String command) => _counts[command.trim()] ?? 0;

  @override
  Future<void> connect() async => _connected = true;

  @override
  Future<void> disconnect() async => _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<String> sendCommand(String command) async {
    final key = command.trim();
    final priorCalls = _counts[key] ?? 0;
    _counts[key] = priorCalls + 1;
    if (priorCalls < failuresPerCommand) {
      throw StateError('Transport closed');
    }
    return successResponse;
  }
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

  /// #2767 — mutable so a test can flip the fake into passive-waiting (then
  /// invoke [onPassiveWait]) to drive the manager's re-emit + the
  /// controller's `reconnectPassiveWaiting` flag.
  @override
  bool isPassiveWaiting = false;

  @override
  VoidCallback? onPassiveWait;

  @override
  int get consecutiveMisses => 0;

  @override
  Duration get currentBackoff => const Duration(seconds: 5);

  @override
  int get currentAttemptNumber => 1;

  @override
  int get currentBackoffMs => 5000;

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
