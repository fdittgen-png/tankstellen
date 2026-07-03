// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/elm327_parsers.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';

/// #3426 — pins the PID 0x44 equivalence-ratio convention against SAE
/// J1979 with REAL frame bytes driven through the real parser (no echo
/// fake — the raw `41 44 …` transcript is what a live ELM327 emits).
///
/// SAE J1979 / J1979-DA: PID 0x44 is the *Fuel–Air commanded equivalence
/// ratio* φ = (F/A)/(F/A)stoich, encoded `(256·A + B) × 2 / 65536`.
/// φ < 1 = LEAN commanded (DFCO-approach), φ > 1 = RICH (power
/// enrichment); λ = 1/φ. The verified verdict: the estimator's math
/// (`effAFR = stoich / value`) was already correct for the φ wire value —
/// only the λ naming (and one parser doc claiming `stoichAFR × λ`) was
/// inverted. These tests make the direction unfakeable: a future
/// "fix" that flips the division breaks them.
void main() {
  group('PID 0x44 frame → φ (SAE J1979 wire encoding)', () {
    test('41 44 66 66 → φ ≈ 0.7999 (lean commanded, DFCO-approach)', () {
      final phi =
          Elm327Parsers.parseCommandedEquivalenceRatio('41 44 66 66>');
      expect(phi, isNotNull);
      // (0x6666 = 26214) × 2 / 65536 = 0.79998…
      expect(phi, closeTo(0.7999, 0.0005));
    });

    test('41 44 80 00 → φ = 1.0 (stoichiometry)', () {
      final phi =
          Elm327Parsers.parseCommandedEquivalenceRatio('41 44 80 00>');
      expect(phi, closeTo(1.0, 1e-9));
    });

    test('41 44 99 9A → φ ≈ 1.2 (rich, WOT power enrichment)', () {
      final phi =
          Elm327Parsers.parseCommandedEquivalenceRatio('41 44 99 9A>');
      expect(phi, closeTo(1.2, 0.001));
    });
  });

  group('φ direction through the estimator (#3426 acceptance)', () {
    test('LEAN frame (φ ≈ 0.8) → HIGHER effective AFR → LOWER fuel', () {
      final phi =
          Elm327Parsers.parseCommandedEquivalenceRatio('41 44 66 66>');
      final effAfr = effectiveAfrForPhi(kPetrolAfr, phi);
      // Lean: more air per unit fuel → the AFR must RISE above stoich.
      expect(effAfr, greaterThan(kPetrolAfr));
      expect(effAfr, closeTo(kPetrolAfr / 0.7999, 0.01));

      // And the MAF fuel math (fuel ∝ 1/AFR) must therefore DROP.
      const mafGPerS = 10.24;
      const stoichRate =
          mafGPerS * 3600.0 / (kPetrolAfr * kPetrolDensityGPerL);
      final leanRate = mafGPerS * 3600.0 / (effAfr * kPetrolDensityGPerL);
      expect(leanRate, lessThan(stoichRate));
      expect(leanRate / stoichRate, closeTo(0.7999, 0.001));
    });

    test('RICH frame (φ ≈ 1.2) → LOWER effective AFR → MORE fuel', () {
      final phi =
          Elm327Parsers.parseCommandedEquivalenceRatio('41 44 99 9A>');
      final effAfr = effectiveAfrForPhi(kPetrolAfr, phi);
      expect(effAfr, lessThan(kPetrolAfr));
      expect(effAfr, closeTo(kPetrolAfr / 1.2, 0.01));
    });

    test('stoich frame (φ = 1.0) leaves the AFR untouched', () {
      final phi =
          Elm327Parsers.parseCommandedEquivalenceRatio('41 44 80 00>');
      expect(effectiveAfrForPhi(kPetrolAfr, phi),
          closeTo(kPetrolAfr, 1e-9));
    });
  });

  group('full pull path: raw 0x44 transcript → readFuelRateLPerHour', () {
    const initResponses = {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
    };
    // MAF branch fixture: PID 10 = 10.24 g/s, mass PIDs + 5E + wideband +
    // trims all NO DATA, so ONLY the 0x44 frame differs between cases.
    const mafBase = {
      '019D': 'NO DATA>',
      '01A2': 'NO DATA>',
      '015E': 'NO DATA>',
      '0166': 'NO DATA>',
      '0110': '41 10 04 00>', // 10.24 g/s
      '0124': 'NO DATA>',
      '0152': 'NO DATA>',
      '0106': 'NO DATA>',
      '0107': 'NO DATA>',
    };

    Future<double?> rateWith0x44(String frame) async {
      final transport = FakeObd2Transport({
        ...initResponses,
        ...mafBase,
        '0144': frame,
      });
      final service = Obd2Service(transport);
      await service.connect();
      return service.readFuelRateLPerHour();
    }

    test(
        'lean commanded (41 44 66 66) yields ~20 % LESS fuel than stoich '
        '(41 44 80 00) — the SAE direction, end to end', () async {
      final lean = await rateWith0x44('41 44 66 66>');
      final stoich = await rateWith0x44('41 44 80 00>');
      expect(lean, isNotNull);
      expect(stoich, isNotNull);
      expect(lean!, lessThan(stoich!));
      expect(lean / stoich, closeTo(0.7999, 0.005));
    });

    test(
        'rich commanded (41 44 99 9A) yields ~20 % MORE fuel than stoich',
        () async {
      final rich = await rateWith0x44('41 44 99 9A>');
      final stoich = await rateWith0x44('41 44 80 00>');
      expect(rich! / stoich!, closeTo(1.2, 0.005));
    });
  });
}
