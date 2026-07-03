// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_wedge_detector.dart';

import '../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();

  Obd2WedgeDetector detector([int threshold = 3]) =>
      Obd2WedgeDetector(threshold: threshold);

  void fail3(Obd2WedgeDetector d, {String strategy = 'exhausted'}) {
    for (var i = 0; i < 3; i++) {
      d.noteClassicConnectOutcome(mac: 'AA:BB', ok: false, strategy: strategy);
    }
  }

  group('Obd2WedgeDetector (#3422 — the N=3 wedge rule)', () {
    test('3 consecutive exhausted ladders latch LinkWedged with the mac', () {
      final d = detector();
      final flips = <bool>[];
      d.linkWedged.addListener(() => flips.add(d.linkWedged.value));

      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'exhausted');
      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'exhausted');
      expect(d.isWedged, isFalse, reason: 'streak of 2 must not latch');

      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'exhausted');
      expect(d.isWedged, isTrue);
      expect(d.wedgedMac, 'AA:BB');
      expect(flips, [true]);
    });

    test('budget-exhausted and the Dart connect-budget-timeout also carry '
        'the wedge signature', () {
      final d = detector();
      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'budget-exhausted');
      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'connect-budget-timeout');
      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'exhausted');
      expect(d.isWedged, isTrue);
    });

    test('a successful connect resets the streak', () {
      final d = detector();
      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'exhausted');
      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'exhausted');
      d.noteClassicConnectOutcome(mac: 'AA:BB', ok: true);
      fail3(d);
      // The success broke the first streak; only the fresh 3 latch.
      expect(d.isWedged, isTrue);
    });

    test('a non-signature failure (no-adapter / bad-address / unclassified '
        'throw) breaks the streak without latching', () {
      final d = detector();
      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'exhausted');
      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'no-adapter');
      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'exhausted');
      d.noteClassicConnectOutcome(mac: 'AA:BB', ok: false, strategy: null);
      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'exhausted');
      expect(d.isWedged, isFalse);
      expect(d.streak, 1);
    });

    test('a successful connect while wedged clears the wedge '
        '(the adapter reappeared)', () {
      final d = detector();
      fail3(d);
      expect(d.isWedged, isTrue);
      d.noteClassicConnectOutcome(mac: 'AA:BB', ok: true);
      expect(d.isWedged, isFalse);
      expect(d.wedgedMac, isNull);
    });

    test('noteRecovered (a recovery rung succeeded) clears the wedge and '
        'the streak', () {
      final d = detector();
      fail3(d);
      d.noteRecovered('rung-sdp-refresh');
      expect(d.isWedged, isFalse);
      expect(d.streak, 0);
    });

    test('onWedged fires exactly once per episode, with the mac; further '
        'failures while wedged do not re-fire', () {
      final d = detector();
      final macs = <String>[];
      d.onWedged = macs.add;
      fail3(d);
      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'exhausted');
      d.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'budget-exhausted');
      expect(macs, ['AA:BB']);
      expect(d.isWedged, isTrue);
    });

    test('a new episode after recovery fires onWedged again', () {
      final d = detector();
      final macs = <String>[];
      d.onWedged = macs.add;
      fail3(d);
      d.noteRecovered('rung-bt-cycle');
      fail3(d);
      expect(macs, ['AA:BB', 'AA:BB']);
    });

    test('a throwing onWedged callback never derails the detector '
        '(the stand-down still latches)', () {
      final d = detector();
      d.onWedged = (_) => throw StateError('ladder boot failure');
      expect(() => fail3(d), returnsNormally);
      expect(d.isWedged, isTrue);
    });

    test('the free-function funnel feeds the process-wide instance', () {
      Obd2WedgeDetector.instance.resetForTest();
      addTearDown(Obd2WedgeDetector.instance.resetForTest);
      for (var i = 0; i < 3; i++) {
        noteClassicLadderOutcome('CC:DD', ok: false, strategy: 'exhausted');
      }
      expect(Obd2WedgeDetector.instance.isWedged, isTrue);
      expect(Obd2WedgeDetector.instance.wedgedMac, 'CC:DD');
      noteClassicLadderOutcome('CC:DD', ok: true);
      expect(Obd2WedgeDetector.instance.isWedged, isFalse);
    });
  });
}
