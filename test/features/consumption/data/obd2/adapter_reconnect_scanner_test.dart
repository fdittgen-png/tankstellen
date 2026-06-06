// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_reconnect_scanner.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_connection_errors.dart';
import '../../../../helpers/silence_error_logger.dart';

/// Small real-wall-clock delays keep the suite under a few seconds
/// while still exercising the exponential-backoff math. The scanner
/// is deterministic against `Timer` — each cycle completes once
/// the wall clock elapses past [initialBackoff], so we can just
/// pump a few milliseconds and assert the doubling.
const _kInitial = Duration(milliseconds: 10);
const _kMax = Duration(milliseconds: 80);

/// Pumps real time until [cond] is true or [timeout] elapses. Needed
/// because `async.elapse` from `fake_async` is a transitive-only
/// dependency we don't want to import here; real timers work because
/// the scanner uses standard `Timer`.
Future<void> _waitFor(
  bool Function() cond, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!cond() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  silenceErrorLoggerSpool();
  group('AdapterReconnectScanner (#797 phase 3)', () {
    test('starts with initialBackoff and doubles on a missed probe',
        () async {
      var probeCalls = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'AA:BB:CC:DD:EE:FF',
        probe: (mac) async {
          probeCalls++;
          return false; // always a miss
        },
        connect: (_) async => true,
        onReconnect: () {},
        initialBackoff: _kInitial,
        firstProbeDelay: _kInitial,
        maxBackoff: _kMax,
      );
      await scanner.start();

      // Initial backoff is unchanged before the first tick.
      expect(scanner.currentBackoff, _kInitial);

      // Wait until the first probe AND the backoff doubling have
      // both landed — polling on the observable
      // `currentBackoff >= 2×initial` closes the race between the
      // probe's microtask and the scheduling of the next timer.
      await _waitFor(() =>
          probeCalls >= 1 && scanner.currentBackoff >= _kInitial * 2);
      expect(scanner.currentBackoff, _kInitial * 2,
          reason: 'a missed probe doubles the backoff');

      await _waitFor(() =>
          probeCalls >= 2 && scanner.currentBackoff >= _kInitial * 4);
      expect(scanner.currentBackoff, _kInitial * 4,
          reason: 'a second miss doubles again');

      await scanner.stop();
    });

    test('first probe fires at firstProbeDelay, not initialBackoff (#1991)',
        () async {
      var probeCalls = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'MAC',
        probe: (_) async {
          probeCalls++;
          return false;
        },
        connect: (_) async => false,
        onReconnect: () {},
        firstProbeDelay: const Duration(milliseconds: 10),
        // A deliberately long initialBackoff — if the first probe
        // waited for it, the assertion below would time out.
        initialBackoff: const Duration(seconds: 30),
        maxBackoff: const Duration(seconds: 60),
      );
      await scanner.start();

      // The first probe must land within the short firstProbeDelay —
      // far inside the controller's 6 s silent-reconnect grace window,
      // not after the 30 s initialBackoff.
      await _waitFor(() => probeCalls >= 1,
          timeout: const Duration(milliseconds: 500));
      expect(probeCalls, 1,
          reason: 'the first reconnect probe must fire at '
              'firstProbeDelay, not wait the full initialBackoff (#1991)');

      await scanner.stop();
    });

    test('caps backoff at maxBackoff', () async {
      var probeCalls = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'MAC',
        probe: (_) async {
          probeCalls++;
          return false;
        },
        connect: (_) async => false,
        onReconnect: () {},
        initialBackoff: _kInitial, // 10 ms
        firstProbeDelay: _kInitial,
        maxBackoff: _kMax, // 80 ms
      );
      await scanner.start();
      // Let enough wall-clock pass that the backoff walks 10 → 20 →
      // 40 → 80 and would otherwise step to 160. Cap must hold.
      await _waitFor(() => probeCalls >= 5, timeout: const Duration(seconds: 5));
      expect(scanner.currentBackoff, _kMax,
          reason: 'backoff must not exceed maxBackoff');
      await scanner.stop();
    });

    test(
        'on MAC in range → calls connect and onReconnect, then '
        'self-stops', () async {
      var connectCalls = 0;
      var reconnectCount = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'AA:BB',
        probe: (mac) async => mac == 'AA:BB',
        connect: (mac) async {
          connectCalls++;
          return true;
        },
        onReconnect: () => reconnectCount++,
        initialBackoff: _kInitial,
        firstProbeDelay: _kInitial,
      );
      await scanner.start();

      await _waitFor(() => reconnectCount > 0);
      expect(connectCalls, 1);
      expect(reconnectCount, 1);
      expect(scanner.isScanning, isFalse,
          reason: 'scanner must self-stop after a successful '
              'reconnect');
    });

    test('stop() cancels the scanner cleanly', () async {
      var probeCalls = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'MAC',
        probe: (_) async {
          probeCalls++;
          return false;
        },
        connect: (_) async => false,
        onReconnect: () {},
        initialBackoff: _kInitial,
        firstProbeDelay: _kInitial,
      );
      await scanner.start();
      expect(scanner.isScanning, isTrue);

      await scanner.stop();
      expect(scanner.isScanning, isFalse);

      // Sleep well past the initial backoff; probe must not fire.
      await Future<void>.delayed(_kInitial * 10);
      expect(probeCalls, 0,
          reason: 'stop() must cancel the pending timer so no '
              'probe runs after');
    });

    test(
        'connect failure doesn\'t blow up the scanner — it doubles '
        'backoff and retries on the next cycle', () async {
      var connectCalls = 0;
      var reconnectCount = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'MAC',
        probe: (_) async => true, // always in range
        connect: (_) async {
          connectCalls++;
          // First attempt fails; subsequent attempts succeed.
          return connectCalls >= 2;
        },
        onReconnect: () => reconnectCount++,
        initialBackoff: _kInitial,
        firstProbeDelay: _kInitial,
      );
      await scanner.start();

      await _waitFor(() => reconnectCount > 0,
          timeout: const Duration(seconds: 3));
      expect(connectCalls, greaterThanOrEqualTo(2));
      expect(reconnectCount, 1);
      expect(scanner.isScanning, isFalse,
          reason: 'successful reconnect must self-stop the scanner');
    });

    test(
        'probe throws → scanner swallows the error and treats it as '
        'a miss', () async {
      var probeCalls = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'MAC',
        probe: (_) async {
          probeCalls++;
          throw StateError('probe blew up');
        },
        connect: (_) async => true,
        onReconnect: () {},
        initialBackoff: _kInitial,
        firstProbeDelay: _kInitial,
      );
      await scanner.start();

      // Wait until the first throwing probe has been consumed AND
      // the next timer has been scheduled (which happens after the
      // throw clears the `_cycleInFlight` gate and `_scheduleNext`
      // doubles the backoff). The doubled backoff is the observable
      // signal — polling `currentBackoff` avoids the race between
      // the probe's microtask and the assertion.
      await _waitFor(() =>
          probeCalls >= 1 && scanner.currentBackoff >= _kInitial * 2);
      expect(scanner.isScanning, isTrue,
          reason: 'scanner must survive probe exceptions');
      expect(scanner.currentBackoff, greaterThanOrEqualTo(_kInitial * 2),
          reason: 'a thrown probe must be treated as a miss and '
              'double the backoff');

      await scanner.stop();
    });

    test('start() is idempotent — repeated calls do not double-tick',
        () async {
      var probeCalls = 0;
      final scanner = AdapterReconnectScanner(
        pinnedMac: 'MAC',
        probe: (_) async {
          probeCalls++;
          return false;
        },
        connect: (_) async => false,
        onReconnect: () {},
        initialBackoff: _kInitial,
        firstProbeDelay: _kInitial,
      );
      await scanner.start();
      await scanner.start();
      await scanner.start();

      await _waitFor(() => probeCalls >= 1);
      // The first tick should have fired exactly once; a quick nap
      // longer than the current window proves we only scheduled one
      // follow-up rather than three.
      final afterFirst = probeCalls;
      await Future<void>.delayed(_kInitial);
      expect(probeCalls - afterFirst, lessThanOrEqualTo(2),
          reason: 'triple start() must not enqueue three parallel '
              'timers — at most one follow-up tick should fire in '
              'the next window');

      await scanner.stop();
    });

    group('bounded scan → passive autoConnect wait (#2261 concern 2)', () {
      test('after the miss ceiling, switches to the passive connect path',
          () async {
        var activeConnectCalls = 0;
        var passiveConnectCalls = 0;
        final scanner = AdapterReconnectScanner(
          pinnedMac: 'MAC',
          // Probe always says in-range; the active connect always fails,
          // so every cycle is a miss and the ceiling is reached.
          probe: (_) async => true,
          connect: (_) async {
            activeConnectCalls++;
            return false;
          },
          passiveConnect: (_) async {
            passiveConnectCalls++;
            return false; // keep waiting so we can observe the mode
          },
          onReconnect: () {},
          missCeiling: 3,
          initialBackoff: _kInitial,
          firstProbeDelay: _kInitial,
          maxBackoff: _kMax,
        );
        await scanner.start();

        await _waitFor(() => scanner.isPassiveWaiting,
            timeout: const Duration(seconds: 3));
        expect(scanner.isPassiveWaiting, isTrue,
            reason: 'the scanner must flip to passive mode at the ceiling');
        expect(activeConnectCalls, 3,
            reason: 'exactly missCeiling active attempts before the switch');

        await _waitFor(() => passiveConnectCalls >= 1,
            timeout: const Duration(seconds: 2));
        expect(passiveConnectCalls, greaterThanOrEqualTo(1),
            reason: 'passive connect drives the remaining grace');
        await scanner.stop();
      });

      test('a passive connect success fires onReconnect and self-stops',
          () async {
        var passiveCalls = 0;
        var reconnects = 0;
        final scanner = AdapterReconnectScanner(
          pinnedMac: 'MAC',
          probe: (_) async => true,
          connect: (_) async => false,
          passiveConnect: (_) async {
            passiveCalls++;
            return true; // the parked car came back
          },
          onReconnect: () => reconnects++,
          missCeiling: 2,
          initialBackoff: _kInitial,
          firstProbeDelay: _kInitial,
          maxBackoff: _kMax,
        );
        await scanner.start();

        await _waitFor(() => reconnects > 0,
            timeout: const Duration(seconds: 3));
        expect(passiveCalls, 1);
        expect(reconnects, 1);
        expect(scanner.isScanning, isFalse,
            reason: 'a passive reconnect must self-stop the scanner');
        await scanner.stop();
      });

      test('with NO passiveConnect, stays in active-scan mode forever',
          () async {
        var activeConnectCalls = 0;
        final scanner = AdapterReconnectScanner(
          pinnedMac: 'MAC',
          probe: (_) async => true,
          connect: (_) async {
            activeConnectCalls++;
            return false;
          },
          onReconnect: () {},
          // No passiveConnect — pre-#2261 behaviour preserved.
          missCeiling: 2,
          initialBackoff: _kInitial,
          firstProbeDelay: _kInitial,
          maxBackoff: _kMax,
        );
        await scanner.start();

        await _waitFor(() => activeConnectCalls >= 4,
            timeout: const Duration(seconds: 3));
        expect(scanner.isPassiveWaiting, isFalse,
            reason: 'without a passiveConnect callback the scanner never '
                'switches — behaviour is unchanged from before #2261');
        await scanner.stop();
      });
    });

    group('re-arm active scan after the passive ceiling (#2767)', () {
      test(
          'after passiveReArmEvery timed-out passive waits, re-arms an active '
          'scan instead of staying passive forever', () async {
        var activeConnectCalls = 0;
        var passiveConnectCalls = 0;
        final scanner = AdapterReconnectScanner(
          pinnedMac: 'MAC',
          // In-range probe + an always-failing active connect drives the
          // ceiling; the passive wait always times out so we can observe the
          // re-arm cadence rather than a reconnect.
          probe: (_) async => true,
          connect: (_) async {
            activeConnectCalls++;
            return false;
          },
          passiveConnect: (_) async {
            passiveConnectCalls++;
            return false;
          },
          onReconnect: () {},
          missCeiling: 2,
          passiveReArmEvery: 2,
          initialBackoff: _kInitial,
          firstProbeDelay: _kInitial,
          maxBackoff: _kMax,
        );
        await scanner.start();

        // First reach passive mode (2 active misses).
        await _waitFor(() => scanner.isPassiveWaiting,
            timeout: const Duration(seconds: 3));
        expect(activeConnectCalls, 2,
            reason: 'missCeiling active attempts before the first passive flip');

        final activeAtCeiling = activeConnectCalls;
        // After 2 timed-out passive waits the scanner must re-arm an active
        // scan — observed as a fresh active connect attempt beyond the ceiling.
        await _waitFor(
            () =>
                passiveConnectCalls >= 2 &&
                activeConnectCalls > activeAtCeiling,
            timeout: const Duration(seconds: 4));
        expect(activeConnectCalls, greaterThan(activeAtCeiling),
            reason: 'the scanner must drop back to an active scan every '
                'passiveReArmEvery passive waits — never stuck passive forever '
                '(#2767)');
        await scanner.stop();
      });

      test(
          'a re-armed active scan that finds the adapter reconnects + '
          'self-stops', () async {
        var activeConnectCalls = 0;
        var reconnects = 0;
        final scanner = AdapterReconnectScanner(
          pinnedMac: 'MAC',
          probe: (_) async => true,
          // The adapter is dead through the ceiling + the first passive
          // window, then powers back up: the FIRST re-armed active connect
          // (the 3rd active call) lands.
          connect: (_) async {
            activeConnectCalls++;
            return activeConnectCalls >= 3;
          },
          passiveConnect: (_) async => false, // passive wait keeps timing out
          onReconnect: () => reconnects++,
          missCeiling: 2,
          passiveReArmEvery: 1, // re-arm after a single passive wait
          initialBackoff: _kInitial,
          firstProbeDelay: _kInitial,
          maxBackoff: _kMax,
        );
        await scanner.start();

        await _waitFor(() => reconnects > 0,
            timeout: const Duration(seconds: 4));
        expect(reconnects, 1,
            reason: 'the late adapter power-cycle is caught by the re-armed '
                'active scan, not missed (#2767)');
        expect(activeConnectCalls, greaterThanOrEqualTo(3),
            reason: 'reconnect landed on a re-armed active attempt past the '
                'ceiling, proving the scanner left passive mode');
        expect(scanner.isScanning, isFalse);
        await scanner.stop();
      });

      test(
          'fires onPassiveWait exactly once on the first passive flip, not on '
          'each re-arm', () async {
        var passiveWaitNotifications = 0;
        final scanner = AdapterReconnectScanner(
          pinnedMac: 'MAC',
          probe: (_) async => true,
          connect: (_) async => false,
          passiveConnect: (_) async => false,
          onReconnect: () {},
          onPassiveWait: () => passiveWaitNotifications++,
          missCeiling: 2,
          passiveReArmEvery: 1, // re-arm aggressively so we'd over-fire if buggy
          initialBackoff: _kInitial,
          firstProbeDelay: _kInitial,
          maxBackoff: _kMax,
        );
        await scanner.start();

        await _waitFor(() => passiveWaitNotifications >= 1,
            timeout: const Duration(seconds: 3));
        // Let several re-arm → passive flips elapse; the notification must
        // still have fired only once (the banner copy flips a single time).
        await Future<void>.delayed(_kMax * 3);
        expect(passiveWaitNotifications, 1,
            reason: 'onPassiveWait is a one-shot per drop — re-arm cycles must '
                'not re-fire it (#2767)');
        await scanner.stop();
      });
    });

    group('classic-direct reconnect pacing (#2565)', () {
      test(
          'repeated classic-direct failures still pace via the existing '
          'backoff (no flood) and self-stop on success', () async {
        // The scanner is transport-agnostic: it drives `connect`, which for a
        // classic drop is `ReconnectConnector.attempt` routing over
        // `connectByMacClassicDirect`. Repeated failures must NOT flood — the
        // existing exponential backoff paces them — and a later success must
        // self-stop the scanner exactly as the BLE path does.
        var connectCalls = 0;
        var reconnects = 0;
        final scanner = AdapterReconnectScanner(
          pinnedMac: 'cc:dd',
          probe: (_) async => true, // always in range
          connect: (_) async {
            connectCalls++;
            // First three classic-direct attempts fail; the fourth lands.
            return connectCalls >= 4;
          },
          onReconnect: () => reconnects++,
          initialBackoff: _kInitial,
          firstProbeDelay: _kInitial,
          maxBackoff: _kMax,
        );
        await scanner.start();

        // The backoff must escalate across the three failures (pacing /
        // no-flood) before the fourth attempt succeeds.
        await _waitFor(
            () => connectCalls >= 2 && scanner.currentBackoff >= _kInitial * 2,
            timeout: const Duration(seconds: 3));
        expect(scanner.currentBackoff, greaterThanOrEqualTo(_kInitial * 2),
            reason: 'repeated classic-direct failures must back off, not '
                'flood — the same bounded schedule as the BLE path');

        await _waitFor(() => reconnects > 0,
            timeout: const Duration(seconds: 3));
        expect(connectCalls, greaterThanOrEqualTo(4));
        expect(reconnects, 1);
        expect(scanner.isScanning, isFalse,
            reason: 'a successful classic-direct reconnect self-stops the '
                'scanner, exactly like BLE');
        await scanner.stop();
      });
    });

    // #2953 — `_connectSafely` / `_probeSafely` previously ERROR-spooled EVERY
    // caught failure at `ErrorLayer.storage` ({where: 'AdapterReconnectScanner
    // connect failed' / 'probe failed'}). The #2892/#2935/#2945 connect
    // de-noise never reached this scanner site, so an engine-off parked car
    // (the `connect` callback surfacing a typed transient) spooled an ERROR
    // every backoff cycle. They now route through `recordObd2ConnectTransient`:
    // an expected transient breadcrumbs; a genuine fault still spools.
    group('connect/probe transient de-noise (#2953)', () {
      late _CapturingRecorder rec;

      setUp(() {
        errorLogger.resetForTest();
        rec = _CapturingRecorder();
        errorLogger.testRecorderOverride = rec;
        BreadcrumbCollector.clear();
      });
      tearDown(errorLogger.resetForTest);

      test('an EXPECTED engine-off transient on connect breadcrumbs, NOT spool',
          () async {
        final scanner = AdapterReconnectScanner(
          pinnedMac: 'MAC',
          probe: (_) async => true,
          connect: (_) async =>
              throw const Obd2AdapterUnresponsive(), // parked car
          onReconnect: () {},
          initialBackoff: _kInitial,
          firstProbeDelay: _kInitial,
          maxBackoff: _kMax,
        );
        await scanner.start();
        await _waitFor(() => BreadcrumbCollector.snapshot().isNotEmpty);
        await scanner.stop();
        await Future<void>.delayed(Duration.zero);

        expect(rec.errors, isEmpty,
            reason: 'an expected engine-off transient must NOT spool an ERROR '
                'every backoff cycle (the field log #30 flood)');
        expect(
          BreadcrumbCollector.snapshot().map((b) => b.action),
          contains('OBD2 connect failed — expected transient'),
        );
      });

      test('a GENUINE fault on connect STILL spools an ERROR', () async {
        final scanner = AdapterReconnectScanner(
          pinnedMac: 'MAC',
          probe: (_) async => true,
          connect: (_) async => throw const Obd2PermissionDenied(),
          onReconnect: () {},
          initialBackoff: _kInitial,
          firstProbeDelay: _kInitial,
          maxBackoff: _kMax,
        );
        await scanner.start();
        await _waitFor(() => rec.errors.isNotEmpty);
        await scanner.stop();

        expect(rec.errors, isNotEmpty,
            reason: 'a real, actionable fault must stay a visible ERROR');
        expect(rec.errors.first.toString(),
            contains('AdapterReconnectScanner connect failed'));
      });

      test('an EXPECTED transient on probe breadcrumbs, NOT spool', () async {
        final scanner = AdapterReconnectScanner(
          pinnedMac: 'MAC',
          probe: (_) async => throw TimeoutException('probe'),
          connect: (_) async => false,
          onReconnect: () {},
          initialBackoff: _kInitial,
          firstProbeDelay: _kInitial,
          maxBackoff: _kMax,
        );
        await scanner.start();
        await _waitFor(() => BreadcrumbCollector.snapshot().isNotEmpty);
        await scanner.stop();
        await Future<void>.delayed(Duration.zero);

        expect(rec.errors, isEmpty);
        expect(
          BreadcrumbCollector.snapshot().map((b) => b.action),
          contains('OBD2 connect failed — expected transient'),
        );
      });
    });
  });
}

/// Captures `errorLogger.log` calls so a test can assert spool-vs-breadcrumb.
class _CapturingRecorder implements TraceRecorder {
  final errors = <Object>[];
  @override
  Future<void> record(Object error, StackTrace stackTrace,
      {ServiceChainSnapshot? serviceChainState}) async {
    errors.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
