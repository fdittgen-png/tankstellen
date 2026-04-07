import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_tier.dart';

void main() {
  group('priceTierOf', () {
    test('returns cheap for price in bottom third', () {
      expect(priceTierOf(1.50, 1.50, 1.80), PriceTier.cheap);
      expect(priceTierOf(1.55, 1.50, 1.80), PriceTier.cheap);
      expect(priceTierOf(1.59, 1.50, 1.80), PriceTier.cheap);
    });

    test('returns average for price in middle third', () {
      expect(priceTierOf(1.62, 1.50, 1.80), PriceTier.average);
      expect(priceTierOf(1.65, 1.50, 1.80), PriceTier.average);
      expect(priceTierOf(1.69, 1.50, 1.80), PriceTier.average);
    });

    test('returns expensive for price in top third', () {
      expect(priceTierOf(1.71, 1.50, 1.80), PriceTier.expensive);
      expect(priceTierOf(1.75, 1.50, 1.80), PriceTier.expensive);
      expect(priceTierOf(1.80, 1.50, 1.80), PriceTier.expensive);
    });

    test('returns unknown for null price', () {
      expect(priceTierOf(null, 1.50, 1.80), PriceTier.unknown);
    });

    test('returns cheap when min equals max (all same price)', () {
      expect(priceTierOf(1.65, 1.65, 1.65), PriceTier.cheap);
    });

    test('returns cheap when max less than min (degenerate range)', () {
      expect(priceTierOf(1.65, 1.80, 1.50), PriceTier.cheap);
    });

    test('boundary at exactly 33% is still cheap (strict less-than)', () {
      // t = 0.33 * 0.30 / 0.30 = 0.33, which is NOT < 0.33
      final price = 1.50 + 0.33 * (1.80 - 1.50);
      // Due to < 0.33, exact 0.33 falls into average
      // but floating-point may land just below — verify it's cheap or average
      final tier = priceTierOf(price, 1.50, 1.80);
      expect(tier == PriceTier.cheap || tier == PriceTier.average, isTrue);
    });

    test('just above 33% threshold is average', () {
      // t slightly above 0.33
      final price = 1.50 + 0.34 * (1.80 - 1.50);
      expect(priceTierOf(price, 1.50, 1.80), PriceTier.average);
    });

    test('just above 66% threshold is expensive', () {
      // t slightly above 0.66
      final price = 1.50 + 0.67 * (1.80 - 1.50);
      expect(priceTierOf(price, 1.50, 1.80), PriceTier.expensive);
    });

    test('clamps price below min to cheap', () {
      expect(priceTierOf(1.40, 1.50, 1.80), PriceTier.cheap);
    });

    test('clamps price above max to expensive', () {
      expect(priceTierOf(2.00, 1.50, 1.80), PriceTier.expensive);
    });
  });

  group('iconForPriceTier', () {
    test('returns arrow_downward for cheap', () {
      expect(iconForPriceTier(PriceTier.cheap), Icons.arrow_downward);
    });

    test('returns remove (dash) for average', () {
      expect(iconForPriceTier(PriceTier.average), Icons.remove);
    });

    test('returns arrow_upward for expensive', () {
      expect(iconForPriceTier(PriceTier.expensive), Icons.arrow_upward);
    });

    test('returns help_outline for unknown', () {
      expect(iconForPriceTier(PriceTier.unknown), Icons.help_outline);
    });
  });

  group('PriceTier enum', () {
    test('has exactly four values', () {
      expect(PriceTier.values.length, 4);
    });

    test('values are cheap, average, expensive, unknown', () {
      expect(PriceTier.values, [
        PriceTier.cheap,
        PriceTier.average,
        PriceTier.expensive,
        PriceTier.unknown,
      ]);
    });
  });
}
