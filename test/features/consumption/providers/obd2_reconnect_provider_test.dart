// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_reconnect_controller.dart';
import 'package:tankstellen/features/consumption/providers/obd2_reconnect_provider.dart';
import '../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();

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
  });
}
