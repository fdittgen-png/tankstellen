// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/pump_display_parse_result.dart';
import 'package:tankstellen/features/consumption/data/pump_scan_disposition.dart';

void main() {
  group('pumpScanDispositionFor (#2827/#2828)', () {
    test('fewer than two fields → unreadable', () {
      const r = PumpDisplayParseResult(totalCost: 50.00);
      expect(pumpScanDispositionFor(r), PumpScanDisposition.unreadable);
    });

    test(
        'profile-validated read that FAILED the gate → inconsistent '
        '(the #2828 fix — was auto-filled before)', () {
      // Three fields present but the gate rejected them (e.g. the numbers
      // do not reconcile): hasUsableData is true, validationApplied is true,
      // validated is false.
      const r = PumpDisplayParseResult(
        totalCost: 50.00,
        liters: 10.00,
        pricePerLiter: 1.299, // 10 * 1.299 = 12.99 != 50.00 → gate rejects
        validated: false,
        validationApplied: true,
        validationReason: 'identity-mismatch',
      );
      expect(pumpScanDispositionFor(r), PumpScanDisposition.inconsistent);
    });

    test('profile-validated read that PASSED the gate → autofill', () {
      const r = PumpDisplayParseResult(
        totalCost: 12.99,
        liters: 10.00,
        pricePerLiter: 1.299,
        validated: true,
        validationApplied: true,
        validationReason: 'consistent',
      );
      expect(pumpScanDispositionFor(r), PumpScanDisposition.autofill);
    });

    test(
        'no profile (gate could not range-check) → autofill on two fields '
        '(non-regressive for profile-less regions)', () {
      const r = PumpDisplayParseResult(
        totalCost: 50.00,
        liters: 38.50,
        validated: false,
        validationApplied: false,
      );
      expect(pumpScanDispositionFor(r), PumpScanDisposition.autofill);
    });

    test('profile-validated partial (two in-range fields) → autofill', () {
      // The gate accepts a 2-of-3 in-range read as a partial; it is
      // validated and should still prefill (the user verifies).
      const r = PumpDisplayParseResult(
        totalCost: 50.00,
        liters: 38.50,
        validated: true,
        validationApplied: true,
        validationReason: 'partial',
      );
      expect(pumpScanDispositionFor(r), PumpScanDisposition.autofill);
    });
  });
}
