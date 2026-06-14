// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/obd2/data/last_good_adapter_store.dart';
import 'package:tankstellen/features/obd2/data/obd2_reconnect_controller.dart';
import '../../../helpers/silence_error_logger.dart';

/// #3346 — pins the reconnect-EPISODE breadcrumb sink on
/// [Obd2ReconnectController]. The orchestration the per-attempt connect-trace
/// ring can't see (drop reason, each attempt's path/outcome/latency, backoff,
/// terminal) must reach `onTrace` so the provider can fan it into the exported
/// telemetry channels.
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
  late List<({String event, Map<String, Object?> data})> events;

  setUp(() {
    storage = _FakeSettingsStorage();
    pinStore = LastGoodAdapterStore(storage);
    events = [];
  });

  Obd2ReconnectController build({
    required Future<Obd2ReconnectAttemptResult> Function(LastGoodAdapter) pinned,
    required Future<Obd2ReconnectAttemptResult> Function(LastGoodAdapter?)
        rescan,
    int maxAttempts = 4,
  }) {
    return Obd2ReconnectController(
      pinStore: pinStore,
      pinnedConnect: pinned,
      rescanConnect: rescan,
      onTrace: (e, d) => events.add((event: e, data: d)),
      maxAttempts: maxAttempts,
      initialBackoff: _fast,
      maxBackoff: const Duration(milliseconds: 40),
      firstAttemptDelay: _fast,
    );
  }

  List<String> names() => events.map((e) => e.event).toList();

  group('Obd2ReconnectController episode breadcrumbs (#3346)', () {
    test('a successful pinned reconnect traces drop→attempt→connected, '
        'carrying the drop reason', () async {
      await pinStore
          .record(const LastGoodAdapter(mac: 'AA', transportKind: 'classic'));
      final c = build(
        pinned: (_) async => Obd2ReconnectAttemptResult.connected,
        rescan: (_) async => Obd2ReconnectAttemptResult.notFound,
      );

      c.notifyDropped(reason: 'classic-socket-error', transportKind: 'classic');
      await _waitFor(() => c.state == Obd2ReconnectState.connected);

      expect(names(),
          containsAllInOrder(['drop-received', 'attempt-start', 'connected']));
      final drop = events.firstWhere((e) => e.event == 'drop-received');
      expect(drop.data['reason'], 'classic-socket-error');
      expect(drop.data['transport'], 'classic');
      expect(drop.data['hadPin'], isTrue);
      // The pinned hit must record a pinned-result, and never a rescan-result.
      expect(names(), contains('pinned-result'));
      expect(names(), isNot(contains('rescan-result')));
      c.stop();
    });

    test('a pinned miss records both pinned-result and rescan-result', () async {
      await pinStore
          .record(const LastGoodAdapter(mac: 'AA', transportKind: 'classic'));
      final c = build(
        pinned: (_) async => Obd2ReconnectAttemptResult.notFound,
        rescan: (_) async => Obd2ReconnectAttemptResult.connected,
      );

      c.notifyDropped(reason: 'classic-socket-done');
      await _waitFor(() => c.state == Obd2ReconnectState.connected);

      final pinnedRes = events.firstWhere((e) => e.event == 'pinned-result');
      expect(pinnedRes.data['result'], 'notFound');
      expect(pinnedRes.data['transport'], 'classic');
      final rescanRes = events.firstWhere((e) => e.event == 'rescan-result');
      expect(rescanRes.data['result'], 'connected');
      c.stop();
    });

    test('exhausting the bound traces backoff-scheduled then terminal-failed',
        () async {
      final c = build(
        pinned: (_) async => Obd2ReconnectAttemptResult.notFound,
        rescan: (_) async => Obd2ReconnectAttemptResult.notFound,
        maxAttempts: 2,
      );

      c.notifyDropped(reason: 'ble-disconnect-edge');
      await _waitFor(() => c.state == Obd2ReconnectState.terminalFailed);

      expect(names(), contains('backoff-scheduled'));
      final terminal = events.firstWhere((e) => e.event == 'terminal-failed');
      expect(terminal.data['attempts'], 2);
      expect(terminal.data['episodeMs'], isA<int>());
      c.stop();
    });

    test('a confirmed engine-off traces terminal-engine-off', () async {
      await pinStore
          .record(const LastGoodAdapter(mac: 'AA', transportKind: 'ble'));
      final c = build(
        pinned: (_) async => Obd2ReconnectAttemptResult.engineOff,
        rescan: (_) async => Obd2ReconnectAttemptResult.notFound,
      );

      c.notifyDropped(reason: 'ble-disconnect-edge');
      await _waitFor(() => c.state == Obd2ReconnectState.terminalEngineOff);

      expect(names(), contains('terminal-engine-off'));
      c.stop();
    });

    test('a second drop while reconnecting is traced but does not restart',
        () async {
      final c = build(
        pinned: (_) async => Obd2ReconnectAttemptResult.notFound,
        rescan: (_) async => Obd2ReconnectAttemptResult.notFound,
        maxAttempts: 6,
      );

      c.notifyDropped(reason: 'ble-disconnect-edge');
      c.notifyDropped(reason: 'ble-disconnect-edge'); // duplicate signal
      await _waitFor(() => c.attempts >= 1);

      expect(names().where((e) => e == 'drop-received'), hasLength(1),
          reason: 'only the first drop starts an episode');
      expect(names(), contains('drop-ignored-already-reconnecting'));
      c.stop();
    });

    test('a throwing onTrace sink never wedges the loop', () async {
      await pinStore
          .record(const LastGoodAdapter(mac: 'AA', transportKind: 'ble'));
      final c = Obd2ReconnectController(
        pinStore: pinStore,
        pinnedConnect: (_) async => Obd2ReconnectAttemptResult.connected,
        rescanConnect: (_) async => Obd2ReconnectAttemptResult.notFound,
        onTrace: (_, _) => throw StateError('buggy collector'),
        initialBackoff: _fast,
        firstAttemptDelay: _fast,
      );

      c.notifyDropped(reason: 'classic-socket-error');
      await _waitFor(() => c.state == Obd2ReconnectState.connected);

      expect(c.state, Obd2ReconnectState.connected,
          reason: 'observability must never derail the reconnect');
      c.stop();
    });
  });
}
