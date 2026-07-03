// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_arbiter.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/obd2_reconnect_controller.dart';
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
  });
}
