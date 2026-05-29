// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/consumption/data/pump_display_parser.dart';

/// The pump parser rebuilt onto the config-driven validation gate
/// (#2275): the same labelled OCR text now carries a `validated` flag
/// that reflects the per-country ranges + the `litres × €/L ≈ total`
/// identity, replacing the old "any number wins" behaviour.
void main() {
  const parser = PumpDisplayParser();
  const fr = OcrLocaleProfile(
    country: 'FR',
    currency: 'EUR',
    decimalSeparator: ',',
    priceMin: 0.5,
    priceMax: 4.0,
    volumeMax: 200.0,
    totalMax: 500.0,
  );

  const validOcr = '''
PRIX
€ 79,91
VOLUME
36,06 LITRES
PRIX DU LITRE
€/L 2,216
''';

  test('a consistent, in-range FR read is marked validated', () {
    final r = parser.parse(validOcr, profile: fr);
    expect(r.totalCost, closeTo(79.91, 0.001));
    expect(r.liters, closeTo(36.06, 0.001));
    expect(r.pricePerLiter, closeTo(2.216, 0.001));
    expect(r.validated, isTrue);
    expect(r.validationReason, 'consistent');
  });

  test('without a profile the read is never auto-validated', () {
    final r = parser.parse(validOcr);
    expect(r.hasUsableData, isTrue);
    expect(r.validated, isFalse,
        reason: 'no country profile ⇒ no range check ⇒ stay conservative');
  });

  test('an out-of-range price fails the gate (validated == false)', () {
    // 4,99 €/L is above the FR priceMax (4,0) — a plausible-looking but
    // out-of-country-range read the gate must reject. (It also breaks
    // the identity: 36,06 × 4,99 ≈ 180, not 79,91.)
    const badOcr = '''
PRIX
€ 79,91
VOLUME
36,06 LITRES
PRIX DU LITRE
€/L 4,99
''';
    final r = parser.parse(badOcr, profile: fr);
    expect(r.pricePerLiter, closeTo(4.99, 0.001),
        reason: 'the parser still extracts it; the gate is what rejects');
    expect(r.validated, isFalse);
  });

  test('a UK profile applies GBP ranges (no EUR hardcoding)', () {
    const ukProfile = OcrLocaleProfile(
      country: 'GB',
      currency: 'GBP',
      decimalSeparator: '.',
      priceMin: 0.8,
      priceMax: 3.0,
      volumeMax: 200.0,
      totalMax: 500.0,
    );
    // £1.459/L, 30.00 L, £43.77 — sane for the UK.
    const ukOcr = '''
PRIX
43.77
VOLUME
30.00 L
PRIX DU LITRE
1.459
''';
    final r = parser.parse(ukOcr, profile: ukProfile);
    expect(r.pricePerLiter, closeTo(1.459, 0.001));
    expect(r.validated, isTrue);
  });
}
