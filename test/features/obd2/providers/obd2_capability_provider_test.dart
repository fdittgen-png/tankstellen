// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/adapter_capability.dart';
import 'package:tankstellen/features/obd2/providers/obd2_capability_provider.dart';
import 'package:tankstellen/features/obd2/providers/obd2_connection_state_provider.dart';

void main() {
  group('currentObd2CapabilityProvider (#1401 phase 6)', () {
    test('returns null on the initial idle snapshot — no adapter, no card',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(currentObd2CapabilityProvider), isNull);
    });

    test(
        'returns the stamped capability once the producer flips to '
        'connected with a value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(obd2ConnectionStatusProvider.notifier);
      notifier.markConnected(
        adapterName: 'OBDLink MX+',
        adapterMac: 'AA:BB',
        capability: Obd2AdapterCapability.passiveCanCapable,
      );
      expect(
        container.read(currentObd2CapabilityProvider),
        Obd2AdapterCapability.passiveCanCapable,
      );
    });

    test('returns null when connected but no capability was stamped — '
        'older producers that haven\'t opted in must not show stale '
        'data from an earlier session', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(obd2ConnectionStatusProvider.notifier);
      notifier.markConnected(
        adapterName: 'Generic ELM327',
        adapterMac: 'AA:BB',
        // capability omitted — null on the snapshot.
      );
      expect(container.read(currentObd2CapabilityProvider), isNull);
    });

    test('returns null after markIdle — forget adapter clears '
        'everything', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier =
          container.read(obd2ConnectionStatusProvider.notifier);
      notifier.markConnected(
        adapterName: 'OBDLink MX+',
        adapterMac: 'AA:BB',
        capability: Obd2AdapterCapability.passiveCanCapable,
      );
      notifier.markIdle();
      expect(container.read(currentObd2CapabilityProvider), isNull);
    });

    test('reports each tier independently — standardOnly / oemPidsCapable '
        '/ passiveCanCapable round-trip through the provider', () {
      for (final tier in Obd2AdapterCapability.values) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.read(obd2ConnectionStatusProvider.notifier).markConnected(
              adapterName: 'tier=$tier',
              adapterMac: 'AA:BB',
              capability: tier,
            );
        expect(container.read(currentObd2CapabilityProvider), tier,
            reason: 'tier $tier did not survive the snapshot round-trip');
      }
    });
  });
}
