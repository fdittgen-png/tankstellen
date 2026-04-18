import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/cross_border_comparison.dart';

void main() {
  group('CrossBorderComparison', () {
    test('stores neighbor identity, currency, and comparison metrics', () {
      const comparison = CrossBorderComparison(
        neighborCode: 'FR',
        neighborName: 'France',
        neighborFlag: '🇫🇷',
        neighborCurrency: '€',
        currentAvgPrice: 1.679,
        borderDistanceKm: 42.3,
        stationCount: 27,
      );
      expect(comparison.neighborCode, 'FR');
      expect(comparison.neighborName, 'France');
      expect(comparison.neighborFlag, '🇫🇷');
      expect(comparison.neighborCurrency, '€');
      expect(comparison.currentAvgPrice, 1.679);
      expect(comparison.borderDistanceKm, 42.3);
      expect(comparison.stationCount, 27);
    });

    test('is const-constructible', () {
      // The banner widget receives this by value; const-ness keeps
      // rebuilds stable when the surrounding widget re-runs.
      const a = CrossBorderComparison(
        neighborCode: 'LU',
        neighborName: 'Luxembourg',
        neighborFlag: '🇱🇺',
        neighborCurrency: '€',
        currentAvgPrice: 1.499,
        borderDistanceKm: 12.0,
        stationCount: 8,
      );
      const b = CrossBorderComparison(
        neighborCode: 'LU',
        neighborName: 'Luxembourg',
        neighborFlag: '🇱🇺',
        neighborCurrency: '€',
        currentAvgPrice: 1.499,
        borderDistanceKm: 12.0,
        stationCount: 8,
      );
      expect(identical(a, b), isTrue);
    });

    test('supports non-euro neighbors (GBP, CHF)', () {
      // Border regions like CH↔DE / UK↔FR must surface non-euro currencies
      // cleanly — pin that the symbol is a pass-through string, not
      // implicitly euro.
      const toUk = CrossBorderComparison(
        neighborCode: 'GB',
        neighborName: 'United Kingdom',
        neighborFlag: '🇬🇧',
        neighborCurrency: '£',
        currentAvgPrice: 1.75,
        borderDistanceKm: 35,
        stationCount: 14,
      );
      expect(toUk.neighborCurrency, '£');

      const toCh = CrossBorderComparison(
        neighborCode: 'CH',
        neighborName: 'Switzerland',
        neighborFlag: '🇨🇭',
        neighborCurrency: 'CHF',
        currentAvgPrice: 1.85,
        borderDistanceKm: 3,
        stationCount: 6,
      );
      expect(toCh.neighborCurrency, 'CHF');
    });
  });
}
