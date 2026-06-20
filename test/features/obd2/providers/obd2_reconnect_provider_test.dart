// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/obd2_recording_link_ownership.dart';
import 'package:tankstellen/features/obd2/data/obd2_reconnect_controller.dart';
import 'package:tankstellen/features/obd2/providers/obd2_reconnect_provider.dart';
import '../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();

  setUp(Obd2RecordingLinkOwnership.instance.resetForTest);
  tearDown(Obd2RecordingLinkOwnership.instance.resetForTest);

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

    test('reportDropped on the degraded provider stays bounded + safe', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // The notifier exists; driving a drop is safe (the no-op connector just
      // can't connect, so the bounded loop will eventually go terminal — but
      // it never throws).
      expect(
        () => container.read(obd2ReconnectProvider.notifier).reportDropped(),
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
      Obd2RecordingLinkOwnership.instance.claim();
      Obd2LinkDropSignal.instance
          .notifyDrop(transportKind: 'classic', reason: 'classic-socket-error');
      await pumpEventQueue();

      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle,
          reason: 'two reconnectors on one adapter ping-pong forever — #3019 '
              'must defer to the in-trip DroppedSessionManager');

      // Release: the very next idle drop is handled again as before.
      Obd2RecordingLinkOwnership.instance.release();
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
      Obd2RecordingLinkOwnership.instance.claim();
      await pumpEventQueue();
      expect(container.read(obd2ReconnectProvider), Obd2ReconnectState.idle,
          reason: 'a recording claiming the link must stop the app-wide loop');
    });
  });
}
