// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/features/obd2/data/adapter_registry.dart';
import 'package:tankstellen/features/obd2/data/bluetooth_facade.dart';
import 'package:tankstellen/features/obd2/data/elm_byte_channel.dart';
import 'package:tankstellen/features/obd2/data/last_good_adapter_store.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_arbiter.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/obd2_permissions.dart';
import 'package:tankstellen/features/obd2/data/obd2_reconnect_controller.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/obd2/providers/obd2_reconnect_provider.dart';
import '../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();

  // #3424 — the latch shim was deleted; a recording lease is taken/released
  // directly on the arbiter (exactly what the shim delegated to).
  setUp(Obd2LinkArbiter.instance.resetForTest);
  tearDown(Obd2LinkArbiter.instance.resetForTest);

  group('Obd2Reconnect provider (#3019 / Epic #3013 phase 3)', () {
    test(
        'builds + returns idle even when the Bluetooth/settings graph is '
        'not bootstrapped (degrades, never crashes the shell)', () {
      // A bare container has no Hive settings box / Bluetooth graph wired, so
      // the dependency reads in build() throw. The provider MUST tolerate that
      // — the app shell watches it — and degrade to an inert idle state with a
      // no-op connector rather than propagating the error.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // returnsNormally — reading the provider must not throw even though its
      // dependencies do.
      expect(
        () => container.read(obd2ReconnectProvider),
        returnsNormally,
      );
      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle);
    });

    test('a drop routed to the degraded provider stays bounded + safe', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Build the notifier so its arbiter idle policy is registered, then
      // drive a drop the PRODUCTION way — through the link-drop signal the
      // arbiter routes (#3424 deleted the reportDropped bypass). The no-op
      // connector just can't connect, so the bounded loop will eventually go
      // terminal — but it never throws.
      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle);
      expect(
        () => Obd2LinkDropSignal.instance.notifyDrop(
            transportKind: 'classic', reason: 'classic-socket-error'),
        returnsNormally,
      );
    });

    test(
        '#3386 — STANDS DOWN while a recording owns the adapter: a drop signal '
        'does NOT start the reconnect loop (the trip DroppedSessionManager '
        'owns it)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle);

      // A recording owns the link → #3019 must ignore the drop signal.
      final lease = Obd2LinkArbiter.instance
          .tryAcquire('recording', Obd2LinkPriority.recording);
      expect(lease, isNotNull);
      Obd2LinkDropSignal.instance
          .notifyDrop(transportKind: 'classic', reason: 'classic-socket-error');
      await pumpEventQueue();

      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle,
          reason: 'two reconnectors on one adapter ping-pong forever — #3019 '
              'must defer to the in-trip DroppedSessionManager');

      // Release: the very next idle drop is handled again as before.
      lease!.release();
      Obd2LinkDropSignal.instance
          .notifyDrop(transportKind: 'classic', reason: 'classic-socket-error');
      await pumpEventQueue();

      expect(container.read(obd2ReconnectProvider),
          Obd2ReconnectState.reconnecting,
          reason: 'an idle / between-trips drop still recovers (#3019 charter)');
    });

    test(
        '#3386 — claiming the link mid-loop hands over immediately: an '
        'in-flight reconnect is stopped so it can\'t tear down the recording\'s '
        'socket', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Read once so the keepAlive provider builds + subscribes to the signal.
      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle);

      // An idle drop starts the loop (no recording yet).
      Obd2LinkDropSignal.instance
          .notifyDrop(transportKind: 'classic', reason: 'classic-socket-error');
      await pumpEventQueue();
      expect(container.read(obd2ReconnectProvider),
          Obd2ReconnectState.reconnecting);

      // The user hits Start: the recording claims the link → #3019 stops.
      expect(
          Obd2LinkArbiter.instance
              .tryAcquire('recording', Obd2LinkPriority.recording),
          isNotNull);
      await pumpEventQueue();
      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle,
          reason: 'a recording claiming the link must stop the app-wide loop');
    });

    test(
        '#3495 F4 — a pinned connect that resolves AFTER stop() is '
        'disconnected, not leaked as an unowned open session', () async {
      // Pin a Classic adapter so the loop's first move is the pinned direct
      // connect (which the fake connection blocks until told to resolve).
      final settings = _MapSettings();
      await LastGoodAdapterStore(settings).recordFrom(
        mac: 'AA:BB:CC:DD:EE:FF',
        transportKind: 'classic',
        name: 'vLinker FS',
      );
      final connection = _BlockingClassicConnection();
      final container = ProviderContainer(overrides: [
        obd2ConnectionProvider.overrideWith((ref) => connection),
        lastGoodAdapterStoreProvider
            .overrideWith((ref) => LastGoodAdapterStore(settings)),
      ]);
      addTearDown(container.dispose);
      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle);

      // An idle drop starts the bounded loop; its first cycle reaches the
      // fake's pinned Classic connect and blocks there.
      Obd2LinkDropSignal.instance.notifyDrop(
          transportKind: 'classic',
          mac: 'AA:BB:CC:DD:EE:FF',
          reason: 'classic-socket-error');
      await pumpEventQueue();
      expect(container.read(obd2ReconnectProvider),
          Obd2ReconnectState.reconnecting);
      await connection.dialled.future;

      // A recording lease grant stands the loop down MID-CONNECT — the
      // production race: `_runCycle` only notices after the seam resolves.
      final lease = Obd2LinkArbiter.instance
          .tryAcquire('recording', Obd2LinkPriority.recording);
      expect(lease, isNotNull);
      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle);

      // The in-flight connect NOW lands a live session.
      final svc = await connection.resolveWithLiveSession();
      await pumpEventQueue();

      expect(svc.isConnected, isFalse,
          reason: 'the just-established session belongs to a loop that was '
              'stopped — leaving it open leaks the adapter\'s single SPP '
              'channel (#3495 F4)');
      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle,
          reason: 'the stopped loop must not resurrect as connected');
      lease!.release();
    });
  });
}

/// Minimal in-memory [SettingsStorage] backing the pin store in tests.
class _MapSettings implements SettingsStorage {
  final Map<String, dynamic> _map = {};
  @override
  dynamic getSetting(String key) => _map[key];
  @override
  Future<void> putSetting(String key, dynamic value) async => _map[key] = value;
  @override
  bool get isSetupComplete => false;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

/// Fake connection whose pinned Classic direct connect BLOCKS until the test
/// resolves it — reproducing the seam-still-in-flight window stop() races.
class _BlockingClassicConnection extends Obd2ConnectionService {
  _BlockingClassicConnection()
      : super(
          registry: Obd2AdapterRegistry.defaults(),
          permissions: _GrantedPermissions(),
          bluetooth: _UnusedBluetoothFacade(),
        );

  /// Completes when the loop's pinned connect reaches the fake.
  final Completer<void> dialled = Completer<void>();
  final Completer<Obd2Service?> _gate = Completer<Obd2Service?>();

  /// Let the blocked connect resolve with a freshly-connected live session,
  /// returned so the test can assert its post-abandon state.
  Future<Obd2Service> resolveWithLiveSession() async {
    final service = Obd2Service(FakeObd2Transport({
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      'ATI': 'ELM327 v1.5>',
      'ATRV': '12.4V>',
      '0100': '41 00 BE 3F A8 13>',
    }))
      ..adapterMac = 'AA:BB:CC:DD:EE:FF'
      ..linkKind = 'classic';
    await service.connect();
    _gate.complete(service);
    return service;
  }

  @override
  Future<Obd2Service?> connectByMacClassicDirect(String mac,
      {String? adapterName}) {
    if (!dialled.isCompleted) dialled.complete();
    return _gate.future;
  }
}

class _GrantedPermissions implements Obd2Permissions {
  @override
  Future<Obd2PermissionState> current() async => Obd2PermissionState.granted;
  @override
  Future<Obd2PermissionState> request() async => Obd2PermissionState.granted;
  @override
  Future<bool> requestNotifications() async => true;
}

class _UnusedBluetoothFacade implements BluetoothFacade {
  @override
  Stream<List<Obd2AdapterCandidate>> scan({
    required Set<String> serviceUuids,
    Duration timeout = const Duration(seconds: 8),
  }) async* {}
  @override
  Future<void> stopScan() async {}
  @override
  ElmByteChannel channelFor(String deviceId, Obd2AdapterProfile profile) =>
      throw UnimplementedError();
  @override
  ElmByteChannel channelForDirect(
    String mac, {
    Duration connectTimeout = const Duration(seconds: 4),
    bool autoConnect = false,
  }) =>
      throw UnimplementedError();
}
