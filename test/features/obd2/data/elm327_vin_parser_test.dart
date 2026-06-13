// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/elm327_vin_parser.dart';

/// #3278 — the framing-aware Mode 09 VIN decoder. These pin the EXACT decoded
/// VIN (not just its length), which is what catches the real multiline bug the
/// old "last 17 chars" heuristic masked.
void main() {
  String hex(String s) => s.codeUnits
      .map((c) => c.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');

  group('Elm327VinParser.parse', () {
    test('decodes the EXACT VIN from a real Peugeot 308 multi-frame response',
        () {
      // Captured from a real Peugeot 308 (2014). The old last-17 heuristic
      // returned "3LCBMB2CS26189239" (wrong — slid into the trailing 39 +
      // padding); the correct VIN is the 17 bytes right after `49 02 01`.
      const response = '014\r\n0: 49 02 01 56 46 33\r\n'
          '1: 4C 43 42 4D 42 32 43\r\n'
          '2: 53 32 36 31 38 39 32\r\n'
          '3: 33 39 00 00 00 00 00\r\n>';
      expect(Elm327VinParser.parse(response), 'VF3LCBMB2CS261892');
    });

    test('single-frame response after the 49 02 01 echo', () {
      const vin = 'WVWZZZ1KZ8W123456';
      expect(Elm327VinParser.parse('49 02 01 ${hex(vin)}>'), vin);
    });

    test('decodes a VIN whose 2nd byte is 0x41 (A) — the old 41-anchored '
        'cleaner would have truncated it', () {
      // An Audi-style WA1… VIN: byte 2 is 0x41. Elm327Parsers.cleanResponse
      // anchors on the first "41" and would drop the leading "57" (W); the
      // VIN-safe cleaner here keeps the whole frame.
      const vin = 'WA1ABCDEFGH123456'; // 17 chars, no I/O/Q
      expect(Elm327VinParser.parse('49 02 01 ${hex(vin)}>'), vin);
    });

    test('ignores trailing padding after the 17 VIN bytes', () {
      const vin = 'JH4KA8260MC123456';
      expect(
        Elm327VinParser.parse('49 02 01 ${hex(vin)} 00 00 00 00>'),
        vin,
      );
    });

    test('returns null on NO DATA', () {
      expect(Elm327VinParser.parse('NO DATA\r\n>'), isNull);
    });

    test('returns null when fewer than 17 VIN chars follow the echo', () {
      expect(Elm327VinParser.parse('49 02 01 41 42 43 44 45>'), isNull);
    });

    test('skips I/O/Q and non-VIN bytes between echo and VIN', () {
      const vin = '12345678901234567';
      expect(
        Elm327VinParser.parse('49 02 01 40 4F 51 ${hex(vin)}>'),
        vin,
      );
    });
  });

  group('Elm327VinParser.parseUds (22 F1 90)', () {
    test('decodes the VIN after the 62 F1 90 echo (#3278)', () {
      // ISO 14229 ReadDataByIdentifier response: `62 F1 90 <17 ASCII>`.
      const vin = 'ZFA31200003456789'; // Fiat-style, 17 chars, no I/O/Q
      expect(Elm327VinParser.parseUds('62 F1 90 ${hex(vin)}>'), vin);
    });

    test('decodes a multi-frame UDS response with trailing padding', () {
      const vin = 'ZFA31200003456789';
      const response = '014\r\n0: 62 F1 90 5A 46 41\r\n'
          '1: 33 31 32 30 30 30 30\r\n'
          '2: 33 34 35 36 37 38 39\r\n'
          '3: 00 00 00 00 00 00 00\r\n>';
      expect(Elm327VinParser.parseUds(response), vin);
    });

    test('returns null on NO DATA (ECU lacks the UDS DID too)', () {
      expect(Elm327VinParser.parseUds('NO DATA\r\n>'), isNull);
    });

    test('a Mode 09 (49 02) response is NOT matched by the UDS echo', () {
      // Guards the anchor: the UDS parser must not accidentally decode a
      // Mode 09 reply (no 62 F1 90 echo) — it scans from 0 and would need 17
      // VIN chars; here the 49 02 echo bytes are non-VIN so it still works,
      // but a too-short one returns null.
      expect(Elm327VinParser.parseUds('62 F1 90 41 42 43>'), isNull);
    });
  });
}
