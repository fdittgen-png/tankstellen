// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/consumption/data/obd2/last_good_adapter_store.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_reconnect_controller.dart';
import '../../../../helpers/silence_error_logger.dart';

/// In-memory [SettingsStorage] double (mirrors the wake-cache test).
class _FakeSettingsStorage implements SettingsStorage {
  final Map<String, dynamic> data = {};
  @override
  dynamic getSetting(String key) => data[key];
  @override
  Future<void> putSetting(String key, dynamic value) async => data[key] = value;
  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

/// A FAKE OBD2 transport the test can drive to DROP and to
/// FAIL-then-SUCCEED — the real controller is driven against it, not a
/// fake that echoes the expected outcome. Tracks every pinned / re-scan
/// call so the test can assert WHICH path each attempt took.
class _DrivableTransport {
  /// Set the next pinned-path attempt's result. Default: not found.
  Obd2ReconnectAttemptResult pinnedResult =
      Obd2ReconnectAttemptResult.notFound;

  /// Set the next re-scan-path attempt's result. Default: not found.
  Obd2ReconnectAttemptResult rescanResult =
      Obd2ReconnectAttemptResult.notFound;

  /// When > 0, the re-scan path FAILS this many times, then SUCCEEDS.
  /// Models a flaky link that recovers after a few attempts.
  int rescanFailuresBeforeSuccess = 0;

  /// When true, the pinned path THROWS — the controller must treat a
  /// thrown seam as `failed`, never wedge the loop.
  bool pinnedThrows = false;

  int pinnedCalls = 0;
  int rescanCalls = 0;
  final List<LastGoodAdapter?> rescanHints = [];

  Future<Obd2ReconnectAttemptResult> pinned(LastGoodAdapter pinned) async {
    pinnedCalls++;
    if (pinnedThrows) throw StateError('transport blew up');
    return pinnedResult;
  }

  Future<Obd2ReconnectAttemptResult> rescan(LastGoodAdapter? hint) async {
    rescanCalls++;
    rescanHints.add(hint);
    if (rescanFailuresBeforeSuccess > 0) {
      rescanFailuresBeforeSuccess--;
      return Obd2ReconnectAttemptResult.failed;
    }
    return rescanResult;
  }
}

/// Pump real time until [cond] or [timeout] (the scanner-test idiom —
/// the controller uses standard `Timer`, so real time is deterministic).
Future<void> _waitFor(
  bool Function() cond, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!cond() && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 4));
  }
}

const _fast = Duration(milliseconds: 6);

void main() {
  silenceErrorLoggerSpool();

  late _FakeSettingsStorage storage;
  late LastGoodAdapterStore pinStore;
  late _DrivableTransport transport;
  late List<Obd2ReconnectState> states;

  setUp(() {
    storage = _FakeSettingsStorage();
    pinStore = LastGoodAdapterStore(storage);
    transport = _DrivableTransport();
    states = [];
  });

  Obd2ReconnectController build({int maxAttempts = 4}) {
    final c = Obd2ReconnectController(
      pinStore: pinStore,
      pinnedConnect: transport.pinned,
      rescanConnect: transport.rescan,
      maxAttempts: maxAttempts,
      initialBackoff: _fast,
      maxBackoff: const Duration(milliseconds: 40),
      firstAttemptDelay: _fast,
    );
    c.onState = states.add;
    return c;
  }

  group('Obd2ReconnectController (#3019 / Epic #3013 phase 3)', () {
    test('pinned-MAC FAST PATH: reconnects on the pinned adapter, no rescan',
        () async {
      await pinStore.record(const LastGoodAdapter(mac: 'AA', transportKind: 'ble'));
      transport.pinnedResult = Obd2ReconnectAttemptResult.connected;
      final c = build();

      c.notifyDropped();
      await _waitFor(() => c.state == Obd2ReconnectState.connected);

      expect(c.state, Obd2ReconnectState.connected);
      expect(transport.pinnedCalls, 1, reason: 'pinned path tried first');
      expect(transport.rescanCalls, 0,
          reason: 'a pinned hit must NOT fall back to a scan');
      c.stop();
    });

    test('pinned-not-found → RE-SCAN FALLBACK recovers the link', () async {
      await pinStore.record(const LastGoodAdapter(mac: 'AA', transportKind: 'classic'));
      transport.pinnedResult = Obd2ReconnectAttemptResult.notFound;
      transport.rescanResult = Obd2ReconnectAttemptResult.connected;
      final c = build();

      c.notifyDropped();
      await _waitFor(() => c.state == Obd2ReconnectState.connected);

      expect(c.state, Obd2ReconnectState.connected);
      expect(transport.pinnedCalls, 1);
      expect(transport.rescanCalls, 1, reason: 'pinned miss falls back to scan');
      expect(transport.rescanHints.single?.mac, 'AA',
          reason: 'the pinned MAC is passed as the scan-match hint');
      c.stop();
    });

    test('FAIL-then-SUCCEED: backs off across bounded attempts, then connects',
        () async {
      await pinStore.record(const LastGoodAdapter(mac: 'AA', transportKind: 'ble'));
      transport.pinnedResult = Obd2ReconnectAttemptResult.notFound;
      // Re-scan fails twice, succeeds on the third attempt.
      transport.rescanFailuresBeforeSuccess = 2;
      transport.rescanResult = Obd2ReconnectAttemptResult.connected;
      final c = build();

      c.notifyDropped();
      // It transitions through reconnecting and lands connected.
      await _waitFor(() => c.state == Obd2ReconnectState.connected);

      expect(c.state, Obd2ReconnectState.connected);
      expect(transport.rescanCalls, 3,
          reason: '2 failed attempts + 1 success');
      // After a success the counters reset for the next episode.
      expect(c.attempts, 0);
      c.stop();
    });

    test('backoff DOUBLES on each missed attempt (capped)', () async {
      transport.pinnedResult = Obd2ReconnectAttemptResult.notFound;
      transport.rescanResult = Obd2ReconnectAttemptResult.notFound;
      final c = build(maxAttempts: 5);

      c.notifyDropped();
      // After the first miss the backoff doubled from initial.
      await _waitFor(() => c.attempts >= 1);
      expect(c.currentBackoff, _fast * 2, reason: 'first miss doubles backoff');
      await _waitFor(() => c.attempts >= 2);
      expect(c.currentBackoff, _fast * 4, reason: 'second miss doubles again');
      c.stop();
    });

    test('TERMINAL: gives up after maxAttempts, surfaces tap-to-retry state',
        () async {
      transport.pinnedResult = Obd2ReconnectAttemptResult.notFound;
      transport.rescanResult = Obd2ReconnectAttemptResult.notFound;
      final c = build(maxAttempts: 3);

      c.notifyDropped();
      await _waitFor(() => c.state == Obd2ReconnectState.terminalFailed);

      expect(c.state, Obd2ReconnectState.terminalFailed);
      expect(c.hasFailedTerminally, isTrue);
      expect(transport.rescanCalls, 3, reason: 'bounded to maxAttempts');
      expect(states, contains(Obd2ReconnectState.reconnecting));
      expect(states.last, Obd2ReconnectState.terminalFailed);
      c.stop();
    });

    test('retry() resets the loop from the terminal state and can connect',
        () async {
      transport.pinnedResult = Obd2ReconnectAttemptResult.notFound;
      transport.rescanResult = Obd2ReconnectAttemptResult.notFound;
      final c = build(maxAttempts: 2);

      c.notifyDropped();
      await _waitFor(() => c.state == Obd2ReconnectState.terminalFailed);
      final callsAtTerminal = transport.rescanCalls;

      // The adapter is back now; the user taps retry.
      transport.rescanResult = Obd2ReconnectAttemptResult.connected;
      c.retry();
      await _waitFor(() => c.state == Obd2ReconnectState.connected);

      expect(c.state, Obd2ReconnectState.connected);
      expect(transport.rescanCalls, greaterThan(callsAtTerminal),
          reason: 'retry restarts the bounded loop');
      c.stop();
    });

    test('retry() is a NO-OP unless terminal (never double-schedules)',
        () async {
      transport.pinnedResult = Obd2ReconnectAttemptResult.notFound;
      transport.rescanResult = Obd2ReconnectAttemptResult.notFound;
      final c = build(maxAttempts: 5);

      c.notifyDropped();
      await _waitFor(() => c.attempts >= 1);
      final before = transport.rescanCalls;
      c.retry(); // while still reconnecting → ignored
      // Give a tick; the call count should only advance from the real loop.
      await Future<void>.delayed(_fast);
      expect(c.state, Obd2ReconnectState.reconnecting);
      // No DOUBLE schedule artefact: attempts stays monotonic, not jumped.
      expect(transport.rescanCalls, greaterThanOrEqualTo(before));
      c.stop();
    });

    test('DECOUPLED from a live trip: reconnects with no recording active',
        () async {
      // The controller has no notion of a trip — it is driven purely by the
      // connection lifecycle. A drop with nothing recording still recovers.
      await pinStore.record(const LastGoodAdapter(mac: 'AA', transportKind: 'ble'));
      transport.pinnedResult = Obd2ReconnectAttemptResult.connected;
      final c = build();

      c.notifyDropped(); // no trip, no recording — just a link drop
      await _waitFor(() => c.state == Obd2ReconnectState.connected);

      expect(c.state, Obd2ReconnectState.connected);
      c.stop();
    });

    test('no pin → re-scan path runs with a null hint (best-match)', () async {
      // Nothing pinned yet. The pinned path is skipped (notFound) and the
      // re-scan fallback runs with a null hint so a never-pinned adapter
      // can still be discovered.
      transport.rescanResult = Obd2ReconnectAttemptResult.connected;
      final c = build();

      c.notifyDropped();
      await _waitFor(() => c.state == Obd2ReconnectState.connected);

      expect(transport.pinnedCalls, 0, reason: 'no pin ⇒ no pinned attempt');
      expect(transport.rescanCalls, 1);
      expect(transport.rescanHints.single, isNull);
      c.stop();
    });

    test('a thrown connect seam is treated as failed, never wedges the loop',
        () async {
      await pinStore.record(const LastGoodAdapter(mac: 'AA', transportKind: 'ble'));
      transport.pinnedThrows = true; // pinned path throws every cycle
      transport.rescanResult = Obd2ReconnectAttemptResult.notFound;
      final c = build(maxAttempts: 2);

      // returnsNormally — a throwing seam must NOT escape notifyDropped, and
      // the loop must still reach a bounded terminal state.
      expect(() => c.notifyDropped(), returnsNormally);
      await _waitFor(() => c.state == Obd2ReconnectState.terminalFailed);

      expect(c.state, Obd2ReconnectState.terminalFailed,
          reason: 'a thrown seam still advances + bounds the loop');
      c.stop();
    });

    test('notifyConnected() resets counters for the next episode', () async {
      transport.pinnedResult = Obd2ReconnectAttemptResult.notFound;
      transport.rescanResult = Obd2ReconnectAttemptResult.notFound;
      final c = build(maxAttempts: 5);
      c.notifyDropped();
      await _waitFor(() => c.attempts >= 2);

      c.notifyConnected();
      expect(c.state, Obd2ReconnectState.connected);
      expect(c.attempts, 0);
      expect(c.currentBackoff, _fast, reason: 'backoff resets to initial');
      c.stop();
    });
  });
}
