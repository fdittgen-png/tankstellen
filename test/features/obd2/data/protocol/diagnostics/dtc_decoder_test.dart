// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/protocol/diagnostics/dtc_decoder.dart';

/// #4550 — the DTC decoder behind the trace's readable `dtc` marks.
void main() {
  test('complete DTC replies preserve compact, empty, legacy and multi-frame shapes', () {
    for (final reply in ['43 00>', '4300', '43 01 71', '43 01 03 01>', '43 01 01 71 00 00',
      '00A\r0: 43 04 01 33 02 44\r1: 03 01 07 30 00 00>']) {
      expect(isCompleteDtcReply('03', reply), isTrue, reason: reply);
    }
    expect(decodeDtcReply('03', '43 01 01 71 00 00'), ['P0171']);
    expect(decodeDtcReply('03', '430101710000'), ['P0171']);
    for (final reply in ['43', '43 01', '43 02 01 71', 'NO DATA', '43 ZZ']) {
      expect(isCompleteDtcReply('03', reply), isFalse, reason: reply);
      expect(decodeDtcReply('03', reply), isEmpty);
    }
  });

  group('formatDtc', () {
    test('system letter, first digit and the three hex digits', () {
      expect(formatDtc(0x01, 0x33), 'P0133');
      expect(formatDtc(0x03, 0x01), 'P0301');
      expect(formatDtc(0x47, 0x00), 'C0700');
      expect(formatDtc(0x82, 0x34), 'B0234');
      expect(formatDtc(0xC1, 0x00), 'U0100');
      expect(formatDtc(0x17, 0x30), 'P1730');
    });

    test('0000 is padding', () => expect(formatDtc(0, 0), isNull));
  });

  group('decodeDtcReply', () {
    test('legacy bus: three slots per line, zero padding dropped', () {
      expect(decodeDtcReply('03', '43 01 33 02 44 00 00\r>'),
          ['P0133', 'P0244']);
    });

    test('CAN single frame: the count byte is not a code', () {
      expect(decodeDtcReply('03', '43 02 01 33 07 30>'), ['P0133', 'P0730']);
    });

    test('a code byte equal to the echo is still a code (P0343)', () {
      expect(decodeDtcReply('03', '43 01 03 43>'), ['P0343']);
    });

    test('zero codes, NO DATA and garbage decode to nothing', () {
      expect(decodeDtcReply('03', '43 00>'), isEmpty);
      expect(decodeDtcReply('07', 'NO DATA>'), isEmpty);
      expect(decodeDtcReply('0A', 'SEARCHING...\rUNABLE TO CONNECT>'),
          isEmpty);
    });

    test('pending (47) and permanent (4A) echoes', () {
      expect(decodeDtcReply('07', '47 01 03 01>'), ['P0301']);
      expect(decodeDtcReply('0A', '4A 01 07 30>'), ['P0730']);
    });

    test('multi-frame ISO-TP reply is reassembled', () {
      const reply = '00A\r0: 43 04 01 33 02 44\r1: 03 01 07 30 00 00>';
      expect(decodeDtcReply('03', reply),
          ['P0133', 'P0244', 'P0301', 'P0730']);
    });

    test('two ECUs answering are united, de-duplicated', () {
      expect(decodeDtcReply('03', '43 01 03 01\r43 02 03 01 07 30>'),
          ['P0301', 'P0730']);
    });

    test('freeze-frame DTC (Mode 02 PID 02)', () {
      expect(decodeDtcReply('020200', '42 02 00 03 01>'), ['P0301']);
    });

    test('never throws on arbitrary input (fault injection)', () {
      for (final junk in ['', '>', '4', '43 ZZ', '0: 43', '\u0000ÿ', '43 05 01']) {
        expect(() => decodeDtcReply('03', junk), returnsNormally);
      }
      expect(() => decodeDtcReply('', '43 01 33'), returnsNormally);
    });
  });
}
