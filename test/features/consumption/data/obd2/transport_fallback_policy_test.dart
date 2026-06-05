// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/adapter_registry.dart';
import 'package:tankstellen/features/consumption/data/obd2/transport_fallback_policy.dart';

/// Pure decision for the Classic↔BLE transport fallback (#2908).
void main() {
  group('alternateReconnectTransport (#2908)', () {
    test('a Classic drop falls back to BLE (always available)', () {
      expect(
        alternateReconnectTransport(
          droppedTransport: 'classic',
          hasClassicFacade: true,
        ),
        BluetoothTransport.ble,
      );
      // BLE is mandatory, so the Classic→BLE fallback is offered even when no
      // Classic facade is otherwise relevant.
      expect(
        alternateReconnectTransport(
          droppedTransport: 'classic',
          hasClassicFacade: false,
        ),
        BluetoothTransport.ble,
      );
    });

    test('a BLE drop falls back to Classic ONLY when a Classic facade is wired',
        () {
      expect(
        alternateReconnectTransport(
          droppedTransport: 'ble',
          hasClassicFacade: true,
        ),
        BluetoothTransport.classic,
      );
      expect(
        alternateReconnectTransport(
          droppedTransport: 'ble',
          hasClassicFacade: false,
        ),
        isNull,
        reason: 'a BLE-only build has no alternate transport',
      );
    });

    test('an unknown / null live transport conservatively tries Classic', () {
      expect(
        alternateReconnectTransport(
          droppedTransport: null,
          hasClassicFacade: true,
        ),
        BluetoothTransport.classic,
      );
      expect(
        alternateReconnectTransport(
          droppedTransport: 'something-else',
          hasClassicFacade: true,
        ),
        BluetoothTransport.classic,
      );
      expect(
        alternateReconnectTransport(
          droppedTransport: null,
          hasClassicFacade: false,
        ),
        isNull,
      );
    });

    test('the classic match is case-insensitive', () {
      expect(
        alternateReconnectTransport(
          droppedTransport: 'CLASSIC',
          hasClassicFacade: true,
        ),
        BluetoothTransport.ble,
      );
    });
  });
}
