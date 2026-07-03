// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/elm327_precision_pids.dart';

/// Epic #3416 — parsers for the consumption-precision PID families, driven
/// with real ELM327 frame bytes (same `41 <pid> …>` wire format the
/// existing `elm327_parsers_test.dart` fixtures use).
void main() {
  group('wideband equivalence ratio φ (0x24–0x2B / 0x34–0x3B) — #3427', () {
    test('0x66 0x66 ratio bytes decode to φ ≈ 0.7999 (lean commanded)', () {
      // (0x6666 = 26214) × 2 / 65536 = 0.79998…
      final phi = Elm327PrecisionPids.parseEquivalenceRatioPhi(
          '41 24 66 66 32 DD>', 0x24);
      expect(phi, isNotNull);
      expect(phi, closeTo(0.7999, 0.0005));
    });

    test('0x80 0x00 decodes to exactly 1.0 (stoichiometry)', () {
      final phi = Elm327PrecisionPids.parseEquivalenceRatioPhi(
          '41 24 80 00 33 00>', 0x24);
      expect(phi, closeTo(1.0, 1e-9));
    });

    test('current-family PID 0x34 uses the same A/B encoding', () {
      // 0x999A × 2 / 65536 ≈ 1.20001 (rich, WOT enrichment).
      final phi = Elm327PrecisionPids.parseEquivalenceRatioPhi(
          '41 34 99 9A 80 05>', 0x34);
      expect(phi, closeTo(1.2, 0.001));
    });

    test('ratio-only frame (adapter clipped the C/D bytes) still parses',
        () {
      final phi =
          Elm327PrecisionPids.parseEquivalenceRatioPhi('41 26 80 00>', 0x26);
      expect(phi, closeTo(1.0, 1e-9));
    });

    test('all-zero ratio is "not available", not a real mixture → null', () {
      expect(
        Elm327PrecisionPids.parseEquivalenceRatioPhi(
            '41 24 00 00 33 00>', 0x24),
        isNull,
      );
    });

    test('wrong PID echo / NO DATA → null', () {
      expect(
        Elm327PrecisionPids.parseEquivalenceRatioPhi(
            '41 25 80 00 33 00>', 0x24),
        isNull,
      );
      expect(
        Elm327PrecisionPids.parseEquivalenceRatioPhi('NO DATA>', 0x24),
        isNull,
      );
    });

    test('widebandCommand builds the Mode 01 request string', () {
      expect(Elm327PrecisionPids.widebandCommand(0x24), '0124\r');
      expect(Elm327PrecisionPids.widebandCommand(0x3B), '013B\r');
    });
  });

  group('MAF sensor PID 0x66 — #3428', () {
    test('sensor A only: (256·B + C) / 32 g/s', () {
      // Bitmap 0x01 → sensor A; 0x0540 = 1344 / 32 = 42.0 g/s.
      final maf = Elm327PrecisionPids.parseMafSensorGramsPerSecond(
          '41 66 01 05 40>');
      expect(maf, closeTo(42.0, 1e-9));
    });

    test('both sensors flagged: readings are SUMMED (per-bank metering)',
        () {
      // A = 42.0 g/s, B = 0x02A0 = 672 / 32 = 21.0 g/s → total 63.0.
      final maf = Elm327PrecisionPids.parseMafSensorGramsPerSecond(
          '41 66 03 05 40 02 A0>');
      expect(maf, closeTo(63.0, 1e-9));
    });

    test('sensor B only: bytes D/E are used', () {
      final maf = Elm327PrecisionPids.parseMafSensorGramsPerSecond(
          '41 66 02 00 00 02 A0>');
      expect(maf, closeTo(21.0, 1e-9));
    });

    test('no sensor flagged → null', () {
      expect(
        Elm327PrecisionPids.parseMafSensorGramsPerSecond(
            '41 66 00 05 40 02 A0>'),
        isNull,
      );
    });

    test('NO DATA / wrong PID → null', () {
      expect(Elm327PrecisionPids.parseMafSensorGramsPerSecond('NO DATA>'),
          isNull);
      expect(
        Elm327PrecisionPids.parseMafSensorGramsPerSecond('41 10 04 00>'),
        isNull,
      );
    });
  });

  group('engine fuel rate PID 0x9D — #3428', () {
    test('engine channel A/B × 0.02 g/s; vehicle channel C/D ignored', () {
      // A/B = 0x01F4 = 500 × 0.02 = 10.0 g/s. C/D deliberately different
      // (0x0300 = 768 → 15.36) to prove the channels are not summed.
      final gps = Elm327PrecisionPids.parseEngineFuelRateGramsPerSecond(
          '41 9D 01 F4 03 00>');
      expect(gps, closeTo(10.0, 1e-9));
    });

    test('engine-channel-only frame still parses', () {
      final gps = Elm327PrecisionPids.parseEngineFuelRateGramsPerSecond(
          '41 9D 00 64>'); // 100 × 0.02 = 2.0 g/s
      expect(gps, closeTo(2.0, 1e-9));
    });

    test('NO DATA / wrong PID → null', () {
      expect(
        Elm327PrecisionPids.parseEngineFuelRateGramsPerSecond('NO DATA>'),
        isNull,
      );
      expect(
        Elm327PrecisionPids.parseEngineFuelRateGramsPerSecond(
            '41 5E 01 F4>'),
        isNull,
      );
    });
  });

  group('cylinder fuel rate PID 0xA2 — #3428', () {
    test('(256·A + B) / 32 mg/stroke', () {
      // 0x0280 = 640 / 32 = 20.0 mg/stroke.
      final mg = Elm327PrecisionPids.parseCylinderFuelRateMgPerStroke(
          '41 A2 02 80>');
      expect(mg, closeTo(20.0, 1e-9));
    });

    test('NO DATA → null', () {
      expect(
        Elm327PrecisionPids.parseCylinderFuelRateMgPerStroke('NO DATA>'),
        isNull,
      );
    });
  });

  group('ethanol percent PID 0x52 — #3429', () {
    test('A × 100 / 255: 0x80 ≈ 50.2 %', () {
      final pct = Elm327PrecisionPids.parseEthanolPercent('41 52 80>');
      expect(pct, closeTo(50.196, 0.001));
    });

    test('0x00 → 0 % (straight petrol), 0xFF → 100 %', () {
      expect(Elm327PrecisionPids.parseEthanolPercent('41 52 00>'),
          closeTo(0.0, 1e-9));
      expect(Elm327PrecisionPids.parseEthanolPercent('41 52 FF>'),
          closeTo(100.0, 1e-9));
    });

    test('NO DATA / wrong PID → null', () {
      expect(Elm327PrecisionPids.parseEthanolPercent('NO DATA>'), isNull);
      expect(Elm327PrecisionPids.parseEthanolPercent('41 51 04>'), isNull);
    });
  });
}
