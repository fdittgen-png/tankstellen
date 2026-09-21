// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/protocol/elm327_parsers.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';

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

  // The end-to-end raw-frame direction (lean ≈ 0.8×, rich ≈ 1.2× the
  // stoich rate) runs through the live snapshot since #4315:
  // `live_sample_snapshot_fuel_chain_test.dart`.
}
