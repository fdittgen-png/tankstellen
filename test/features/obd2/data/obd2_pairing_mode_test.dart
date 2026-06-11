// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_pairing_mode.dart';

/// #3181 — first-connect pairing mode: budget selection + the
/// pairing-wait UI flag.
void main() {
  setUp(Obd2PairingMode.resetForTest);
  tearDown(Obd2PairingMode.resetForTest);

  group('Obd2PairingMode — first-connect budget selection (#3181)', () {
    test('an UNMARKED deviceId keeps the platform-default setNotify budget',
        () {
      expect(
        Obd2PairingMode.setNotifyBudgetSecsFor('AA:BB:CC:DD:EE:01',
            platformDefaultSecs: 4),
        4,
        reason: 'steady-state connects must keep the tight #3014/#3118 bound',
      );
    });

    test('a MARKED first-connect deviceId gets the generous 30 s budget', () {
      Obd2PairingMode.markFirstConnect('AA:BB:CC:DD:EE:01');
      expect(
        Obd2PairingMode.setNotifyBudgetSecsFor('AA:BB:CC:DD:EE:01',
            platformDefaultSecs: 4),
        Obd2PairingMode.firstConnectSetNotifySecs,
      );
      expect(Obd2PairingMode.firstConnectSetNotifySecs, 30,
          reason: 'the pairing budget must cover the human pairing-dialog tap');
    });

    test('deviceId matching is case-insensitive (iOS UUIDs vs Android MACs)',
        () {
      Obd2PairingMode.markFirstConnect('aa:bb:cc:dd:ee:01');
      expect(Obd2PairingMode.isFirstConnect('AA:BB:CC:DD:EE:01'), isTrue);
      Obd2PairingMode.clearFirstConnect('AA:bb:CC:dd:EE:01');
      expect(Obd2PairingMode.isFirstConnect('aa:bb:cc:dd:ee:01'), isFalse);
    });

    test('clearFirstConnect disarms only the cleared id', () {
      Obd2PairingMode.markFirstConnect('ID-1');
      Obd2PairingMode.markFirstConnect('ID-2');
      Obd2PairingMode.clearFirstConnect('ID-1');
      expect(Obd2PairingMode.isFirstConnect('ID-1'), isFalse);
      expect(Obd2PairingMode.isFirstConnect('ID-2'), isTrue);
    });

    test('an empty id is never marked', () {
      Obd2PairingMode.markFirstConnect('   ');
      expect(Obd2PairingMode.isFirstConnect(''), isFalse);
      expect(Obd2PairingMode.isFirstConnect('   '), isFalse);
    });
  });

  group('Obd2PairingMode.pairingWaitPending (#3181 UI hint)', () {
    test('started/ended flips the listenable for the picker hint', () {
      final seen = <bool>[];
      Obd2PairingMode.pairingWaitPending
          .addListener(() => seen.add(Obd2PairingMode.pairingWaitPending.value));

      Obd2PairingMode.notePairingWaitStarted();
      Obd2PairingMode.notePairingWaitEnded();

      expect(seen, [true, false]);
    });

    test('a throwing listener never derails the connect path (#1103)', () {
      Obd2PairingMode.pairingWaitPending
          .addListener(() => throw StateError('UI listener blew up'));
      expect(Obd2PairingMode.notePairingWaitStarted, returnsNormally);
      expect(Obd2PairingMode.notePairingWaitEnded, returnsNormally);
    });
  });
}
