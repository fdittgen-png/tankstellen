// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/ev/ev_price.dart';

/// Pins `EvPrice.parse` (#1785) — the heuristic parser that turns
/// OpenChargeMap's free-form `usageCost` string into a typed price.
void main() {
  group('EvPrice.parse — per-kWh tariffs', () {
    test('"0.49 EUR/kWh" → perKwh 0.49 EUR', () {
      final p = EvPrice.parse('0.49 EUR/kWh');
      expect(p.kind, EvPriceKind.perKwh);
      expect(p.amount, 0.49);
      expect(p.currency, 'EUR');
    });

    test('decimal comma is normalised — "€0,50/kWh"', () {
      final p = EvPrice.parse('€0,50/kWh');
      expect(p.kind, EvPriceKind.perKwh);
      expect(p.amount, 0.50);
      expect(p.currency, 'EUR');
    });

    test('"0.45 EUR per kWh" (spaced unit) → perKwh', () {
      expect(EvPrice.parse('0.45 EUR per kWh').kind, EvPriceKind.perKwh);
    });

    test('a non-EUR currency is detected — "0.30 GBP/kWh"', () {
      expect(EvPrice.parse('0.30 GBP/kWh').currency, 'GBP');
    });
  });

  group('EvPrice.parse — per-session tariffs', () {
    test('"5 EUR/session" → perSession 5 EUR', () {
      final p = EvPrice.parse('5 EUR/session');
      expect(p.kind, EvPriceKind.perSession);
      expect(p.amount, 5);
      expect(p.currency, 'EUR');
    });

    test('"3.50 EUR flat charge fee" → perSession', () {
      expect(EvPrice.parse('3.50 EUR flat charge fee').kind,
          EvPriceKind.perSession);
    });
  });

  group('EvPrice.parse — free', () {
    test('"Free" → free', () {
      expect(EvPrice.parse('Free').kind, EvPriceKind.free);
    });

    test('localised free words — Gratis / Kostenlos / Gratuit', () {
      expect(EvPrice.parse('Gratis').kind, EvPriceKind.free);
      expect(EvPrice.parse('Kostenlos').kind, EvPriceKind.free);
      expect(EvPrice.parse('Gratuit').kind, EvPriceKind.free);
    });

    test('a bare "0" with no unit → free', () {
      expect(EvPrice.parse('0').kind, EvPriceKind.free);
    });

    test('a per-kWh price beats a stray "free" word — '
        '"Free parking, 0.79 EUR/kWh"', () {
      final p = EvPrice.parse('Free parking, 0.79 EUR/kWh');
      expect(p.kind, EvPriceKind.perKwh);
      expect(p.amount, 0.79);
    });
  });

  group('EvPrice.parse — unknown / degrade to raw', () {
    test('unclassifiable text → unknown, raw preserved', () {
      final p = EvPrice.parse('Ask the operator');
      expect(p.kind, EvPriceKind.unknown);
      expect(p.raw, 'Ask the operator');
    });

    test('null → unknown with empty raw', () {
      final p = EvPrice.parse(null);
      expect(p.kind, EvPriceKind.unknown);
      expect(p.raw, '');
    });

    test('blank string → unknown', () {
      expect(EvPrice.parse('   ').kind, EvPriceKind.unknown);
    });
  });

  group('EvPrice.label', () {
    test('per-kWh renders amount + currency + unit', () {
      final label = EvPrice.parse('0.49 EUR/kWh')
          .label(perKwhUnit: '/kWh', perSessionUnit: '/session');
      expect(label, '0.49 EUR/kWh');
    });

    test('an integer amount drops the trailing .0', () {
      final label = EvPrice.parse('5 EUR/session')
          .label(perKwhUnit: '/kWh', perSessionUnit: '/session');
      expect(label, '5 EUR/session');
    });

    test('free and unknown have no structured label (caller shows raw)',
        () {
      const units = (perKwhUnit: '/kWh', perSessionUnit: '/session');
      expect(
        EvPrice.parse('Free')
            .label(perKwhUnit: units.perKwhUnit, perSessionUnit: units.perSessionUnit),
        isNull,
      );
      expect(
        EvPrice.parse('Ask operator')
            .label(perKwhUnit: units.perKwhUnit, perSessionUnit: units.perSessionUnit),
        isNull,
      );
    });

    test('a missing currency still renders amount + unit', () {
      final label = EvPrice.parse('0.55/kWh')
          .label(perKwhUnit: '/kWh', perSessionUnit: '/session');
      expect(label, '0.55/kWh');
    });
  });
}
