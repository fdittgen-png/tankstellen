// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3529 (Epic #3527) — the Obd2Reconnect provider as the app-wide owner
// of THE Obd2LinkSupervisor. The old #3019 semantics this file used to
// lock (stand-down while a recording holds a lease, terminal-failed
// caps, mid-loop handover) were DELETED by design: there is exactly one
// reconnect authority now and it has no dead ends, so these tests lock
// the new contract instead.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_supervisor.dart';
import 'package:tankstellen/features/obd2/providers/obd2_reconnect_provider.dart';
import 'package:tankstellen/features/obd2/data/last_good_adapter_store.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import '../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();

  group('Obd2Reconnect provider (#3529 / Epic #3527)', () {
    test(
        'builds + returns idle even when the Bluetooth/settings graph is '
        'not bootstrapped (degrades, never crashes the shell)', () {
      // A bare container has no Hive settings box / Bluetooth graph wired,
      // so the DIAL's dependency reads throw. The provider MUST tolerate
      // that — the app shell watches it — and the supervisor's dial
      // degrades to a miss rather than propagating the error.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(obd2ReconnectProvider),
        returnsNormally,
      );
      expect(container.read(obd2ReconnectProvider), Obd2LinkState.idle);
    });

    test('exposes THE supervisor for interactive dial routing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(obd2ReconnectProvider);

      final supervisor =
          container.read(obd2ReconnectProvider.notifier).supervisor;

      // The same instance every time — one reconnect owner app-wide.
      expect(
        identical(
            supervisor,
            container.read(obd2ReconnectProvider.notifier).supervisor),
        isTrue,
      );
      expect(supervisor.userRequestedDisconnect, isFalse);
    });

    test(
        'a production drop signal starts the reconnect loop on the '
        'degraded graph WITHOUT throwing, and the state surfaces it',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(obd2ReconnectProvider), Obd2LinkState.idle);

      expect(
        () => Obd2LinkDropSignal.instance.notifyDrop(
            transportKind: 'classic', reason: 'classic-socket-error'),
        returnsNormally,
      );
      // The drop is delivered async over the broadcast stream.
      await pumpEventQueue();

      // The dial can't succeed on a bare graph (dependency reads throw →
      // classified as a miss) — the supervisor must be RECONNECTING, not
      // crashed and not in any terminal state (no dead ends, #3527).
      expect(
        container.read(obd2ReconnectProvider),
        Obd2LinkState.reconnecting,
      );
    });

    test('user disconnect parks the loop — a later drop is ignored',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(obd2ReconnectProvider);
      final supervisor =
          container.read(obd2ReconnectProvider.notifier).supervisor;

      await supervisor.disconnect();
      await pumpEventQueue();
      expect(
        container.read(obd2ReconnectProvider),
        Obd2LinkState.userDisconnected,
      );

      Obd2LinkDropSignal.instance
          .notifyDrop(transportKind: 'ble', reason: 'disconnect-edge');
      await pumpEventQueue();

      expect(
        container.read(obd2ReconnectProvider),
        Obd2LinkState.userDisconnected,
        reason: 'intent wins — no auto-dial while user-parked',
      );
      expect(supervisor.userRequestedDisconnect, isTrue);
    });

    test('engine-off parks the loop; wake() re-arms it', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(obd2ReconnectProvider);
      final supervisor =
          container.read(obd2ReconnectProvider.notifier).supervisor;

      supervisor.noteEngineOff();
      await pumpEventQueue();
      expect(
          container.read(obd2ReconnectProvider), Obd2LinkState.engineOff);

      Obd2LinkDropSignal.instance
          .notifyDrop(transportKind: 'classic', reason: 'socket-done');
      await pumpEventQueue();
      expect(
        container.read(obd2ReconnectProvider),
        Obd2LinkState.engineOff,
        reason: 'no dialing a sleeping car',
      );

      supervisor.wake();
      await pumpEventQueue();
      expect(
        container.read(obd2ReconnectProvider),
        Obd2LinkState.reconnecting,
        reason: 'wake exits the parked state and dials',
      );
    });
  });

  group('default dial adapter identity (#3553)', () {
    ProviderContainer buildContainer({
      required _FakeConnection connection,
      required LastGoodAdapter? pinned,
      required VehicleProfile? vehicle,
    }) {
      final container = ProviderContainer(overrides: [
        obd2ConnectionProvider.overrideWith((_) => connection),
        lastGoodAdapterStoreProvider.overrideWithValue(_FakePinStore(pinned)),
        activeVehicleProfileProvider.overrideWith(() => _StubVehicle(vehicle)),
      ]);
      addTearDown(container.dispose);
      return container;
    }

    test(
        'the ACTIVE vehicle adapter is dialed FIRST when it differs from '
        'the stale last-good pin — the pin/rescan stay the fallbacks', () async {
      final connection = _FakeConnection();
      final container = buildContainer(
        connection: connection,
        pinned: const LastGoodAdapter(
            mac: 'D4:OLD', transportKind: 'classic', name: 'vLinker FS'),
        vehicle: const VehicleProfile(
          id: 'veh-2',
          name: 'Second car',
          obd2AdapterMac: 'DC:NEW',
          obd2AdapterName: 'vLinker BM-Android',
        ),
      );
      final sup = container.read(obd2ReconnectProvider.notifier).supervisor;

      final got = await sup.connect();

      expect(got, isNull, reason: 'every fake dial misses');
      expect(connection.calls.first, 'transport-aware:DC:NEW',
          reason: 'vehicle intent is authoritative — dialed before the pin');
      expect(connection.calls, contains('classic-direct:D4:OLD'),
          reason: 'the last-good pin remains the fallback');
    });

    test(
        'when the vehicle adapter and the pin AGREE, no extra dial is '
        'added — the pinned fast path runs first as before', () async {
      final connection = _FakeConnection();
      final container = buildContainer(
        connection: connection,
        pinned: const LastGoodAdapter(
            mac: 'D4:SAME', transportKind: 'classic', name: 'vLinker FS'),
        vehicle: const VehicleProfile(
          id: 'veh-1',
          name: 'Clio',
          obd2AdapterMac: 'D4:SAME',
        ),
      );
      final sup = container.read(obd2ReconnectProvider.notifier).supervisor;

      await sup.connect();

      expect(connection.calls.first, 'classic-direct:D4:SAME');
      expect(
        connection.calls.where((c) => c.startsWith('transport-aware:')),
        isEmpty,
        reason: 'an agreeing pin keeps the single pinned fast path',
      );
    });
  });
}

/// Records every dial in order; all dials miss (return null) so the
/// #3553 ordering is observable without a live link.
class _FakeConnection implements Obd2ConnectionService {
  final List<String> calls = [];

  @override
  Future<Obd2Service?> connectByMacTransportAware(
    String mac, {
    String? adapterName,
    bool fallbackToScan = true,
  }) async {
    calls.add('transport-aware:$mac');
    return null;
  }

  @override
  Future<Obd2Service?> connectByMacClassicDirect(String mac,
      {String? adapterName}) async {
    calls.add('classic-direct:$mac');
    return null;
  }

  @override
  Future<Obd2Service?> connectByMacDirect(
    String mac, {
    Duration? timeout,
    bool fallbackToScan = true,
    String? adapterName,
  }) async {
    calls.add('ble-direct:$mac');
    return null;
  }

  @override
  Future<Obd2Service?> connectByMac(
    String mac, {
    Duration timeout = const Duration(seconds: 5),
    String? adapterName,
  }) async {
    calls.add('rescan:$mac');
    return null;
  }

  @override
  Future<Obd2Service?> connectBest() async {
    calls.add('connect-best');
    return null;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pin store returning a fixed recall; writes are ignored.
class _FakePinStore implements LastGoodAdapterStore {
  _FakePinStore(this._pinned);
  final LastGoodAdapter? _pinned;

  @override
  LastGoodAdapter? recall() => _pinned;

  @override
  Future<void> record(LastGoodAdapter adapter) async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubVehicle extends ActiveVehicleProfile {
  _StubVehicle(this._v);
  final VehicleProfile? _v;
  @override
  VehicleProfile? build() => _v;
}
