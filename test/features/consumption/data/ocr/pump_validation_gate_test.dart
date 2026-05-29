// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_validation_gate.dart';

/// Coverage for the domain-sanity validation gate (#2275): a read is
/// accepted only when it is in the country's ranges AND (when all three
/// are present) satisfies `litres × €/L ≈ total`.
void main() {
  const gate = PumpValidationGate();
  const fr = OcrLocaleProfile(
    country: 'FR',
    currency: 'EUR',
    decimalSeparator: ',',
    priceMin: 0.5,
    priceMax: 4.0,
    volumeMax: 200.0,
    totalMax: 500.0,
  );

  test('accepts a consistent, in-range FR read (9519)', () {
    final r = gate.evaluate(
        total: 79.91,
        volume: 36.06,
        pricePerLitre: 2.216,
        confidence: 1.0,
        profile: fr);
    expect(r.accepted, isTrue);
    expect(r.reason, 'consistent');
    expect(r.identityDelta, lessThan(0.05));
  });

  test('rejects when the arithmetic identity is violated', () {
    final r = gate.evaluate(
        total: 79.91,
        volume: 10.0, // 10 × 2.216 = 22.16, not 79.91
        pricePerLitre: 2.216,
        confidence: 1.0,
        profile: fr);
    expect(r.accepted, isFalse);
    expect(r.reason, 'identity-mismatch');
  });

  test('rejects a price out of the country range', () {
    final r = gate.evaluate(
        total: 79.91,
        volume: 36.06,
        pricePerLitre: 22.16, // mis-decoded — 10× too big
        confidence: 1.0,
        profile: fr);
    expect(r.accepted, isFalse);
    expect(r.reason, 'price-out-of-range');
  });

  test('rejects a low-confidence read even when in range', () {
    final r = gate.evaluate(
        total: 79.91,
        volume: 36.06,
        pricePerLitre: 2.216,
        confidence: 0.3,
        profile: fr);
    expect(r.accepted, isFalse);
    expect(r.reason, 'low-confidence');
  });

  test('rejects when fewer than two fields are present', () {
    final r = gate.evaluate(
        total: 50.0,
        volume: null,
        pricePerLitre: null,
        confidence: 1.0,
        profile: fr);
    expect(r.accepted, isFalse);
    expect(r.reason, 'too-few');
  });

  test('accepts a two-of-three partial read that is in range', () {
    final r = gate.evaluate(
        total: 30.02,
        volume: 13.43,
        pricePerLitre: null,
        confidence: 0.9,
        profile: fr);
    expect(r.accepted, isTrue);
    expect(r.reason, 'partial');
  });

  test('without a profile, range checks are skipped (still needs identity)',
      () {
    final r = gate.evaluate(
        total: 79.91,
        volume: 36.06,
        pricePerLitre: 2.216,
        confidence: 1.0,
        profile: null);
    expect(r.accepted, isTrue);
    expect(r.reason, 'consistent');
  });
}
