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
}
