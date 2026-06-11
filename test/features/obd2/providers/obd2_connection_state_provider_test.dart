// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/providers/obd2_connection_state_provider.dart';

void main() {
  group('Obd2ConnectionStatus state machine (#784)', () {
    test('initial state is idle with no adapter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final s = container.read(obd2ConnectionStatusProvider);
      expect(s.state, Obd2ConnectionState.idle);
      expect(s.adapterName, isNull);
      expect(s.adapterMac, isNull);
      expect(s.hasVisibleIndicator, isFalse);
    });

    test('markIdle clears everything — "forget adapter" flow', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(obd2ConnectionStatusProvider.notifier);
      notifier.markConnected(
        adapterName: 'vLinker FS',
        adapterMac: 'AA:BB',
      );
      expect(
        container.read(obd2ConnectionStatusProvider).hasVisibleIndicator,
        isTrue,
      );
      notifier.markIdle();
      final s = container.read(obd2ConnectionStatusProvider);
      expect(s.state, Obd2ConnectionState.idle);
      expect(s.adapterName, isNull);
      expect(s.hasVisibleIndicator, isFalse);
    });

    test('markConnected with name + MAC stamps both fields', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(obd2ConnectionStatusProvider.notifier);
      notifier.markConnected(
        adapterName: 'vLinker FS',
        adapterMac: 'AA:BB',
      );
      final s = container.read(obd2ConnectionStatusProvider);
      expect(s.state, Obd2ConnectionState.connected);
      expect(s.adapterName, 'vLinker FS');
      expect(s.adapterMac, 'AA:BB');
    });

    test('permissionDenied is its own terminal state with visible '
        'indicator so the user sees the system-settings CTA', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(obd2ConnectionStatusProvider.notifier);
      notifier.markConnected(
        adapterName: 'vLinker FS',
        adapterMac: 'AA:BB',
      );
      notifier.markPermissionDenied();
      final s = container.read(obd2ConnectionStatusProvider);
      expect(s.state, Obd2ConnectionState.permissionDenied);
      expect(s.hasVisibleIndicator, isTrue);
    });
  });
}
