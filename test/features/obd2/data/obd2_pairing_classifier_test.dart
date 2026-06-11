// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_classifier.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace.dart';
import 'package:tankstellen/features/obd2/data/obd2_connection_errors.dart';

/// #3181 — pairing classification. The OBDLink CX initiates BLE pairing
/// via the first CCCD subscribe; auth/encryption/bond error strings — and
/// a setNotify TIMEOUT on a FIRST-connect deviceId — must classify as
/// [Obd2ConnectOutcome.pairingRequired] so the user gets the power-cycle
/// guidance instead of a generic timeout.
void main() {
  group('classifyBleOpenOutcome — pairing markers (#3181)', () {
    test('authentication / encryption / pairing / bond strings → '
        'pairingRequired', () {
      // Android GATT layer wordings.
      expect(
        classifyBleOpenOutcome(
            Exception('GATT_INSUFFICIENT_AUTHENTICATION (status 5)')),
        Obd2ConnectOutcome.pairingRequired,
      );
      expect(
        classifyBleOpenOutcome(Exception('GATT_INSUFFICIENT_ENCRYPTION')),
        Obd2ConnectOutcome.pairingRequired,
      );
      // iOS CoreBluetooth wordings.
      expect(
        classifyBleOpenOutcome(
            Exception('Peer removed pairing information')),
        Obd2ConnectOutcome.pairingRequired,
      );
      expect(
        classifyBleOpenOutcome(
            Exception('Authentication is insufficient')),
        Obd2ConnectOutcome.pairingRequired,
      );
      // Clone / stack wording.
      expect(
        classifyBleOpenOutcome(StateError('device not bonded')),
        Obd2ConnectOutcome.pairingRequired,
      );
    });

    test('the typed Obd2PairingRequired maps to pairingRequired', () {
      expect(
        classifyBleOpenOutcome(const Obd2PairingRequired()),
        Obd2ConnectOutcome.pairingRequired,
      );
    });

    test('non-pairing buckets are untouched (gatt133 / timeout / '
        'service-not-found)', () {
      expect(classifyBleOpenOutcome(StateError('GATT_ERROR 133')),
          Obd2ConnectOutcome.gatt133);
      expect(classifyBleOpenOutcome(TimeoutException('Timed out after 4s')),
          Obd2ConnectOutcome.gattTimeout);
      expect(
        classifyBleOpenOutcome(
            StateError('BLE device has no ELM327 service 0000fff0')),
        Obd2ConnectOutcome.serviceNotFound,
      );
    });
  });

  group('classifySetNotifyFailure — first-connect timeout is likely-pairing '
      '(#3181)', () {
    test('a setNotify TIMEOUT on a FIRST-connect deviceId → pairingRequired',
        () {
      // The field signature: the CX blocks setNotify on the OS pairing
      // dialog (never-bonded phone) or silently refuses the bond (powered
      // >5 min) — both surface as a plain timeout.
      expect(
        classifySetNotifyFailure(
          TimeoutException('Timed out after 30s'),
          firstConnect: true,
        ),
        Obd2ConnectOutcome.pairingRequired,
      );
    });

    test('the SAME timeout on a known (already-bonded) deviceId stays '
        'gattTimeout', () {
      expect(
        classifySetNotifyFailure(
          TimeoutException('Timed out after 4s'),
          firstConnect: false,
        ),
        Obd2ConnectOutcome.gattTimeout,
      );
    });

    test('explicit pairing strings classify pairingRequired on ANY connect',
        () {
      expect(
        classifySetNotifyFailure(
          Exception('GATT_INSUFFICIENT_AUTHENTICATION'),
          firstConnect: false,
        ),
        Obd2ConnectOutcome.pairingRequired,
      );
    });

    test('a non-timeout, non-pairing failure keeps its bucket even on a '
        'first connect', () {
      expect(
        classifySetNotifyFailure(StateError('GATT_ERROR 133'),
            firstConnect: true),
        Obd2ConnectOutcome.gatt133,
      );
    });
  });

  group('classifyObd2ConnectError — typed pairing error (#3181)', () {
    test('Obd2PairingRequired → pairingRequired', () {
      expect(classifyObd2ConnectError(const Obd2PairingRequired()),
          Obd2ConnectOutcome.pairingRequired);
    });

    test('Obd2PairingRequired is an EXPECTED user condition (breadcrumb, '
        'not ERROR trace)', () {
      expect(const Obd2PairingRequired().isExpectedUserCondition, isTrue);
    });
  });
}
