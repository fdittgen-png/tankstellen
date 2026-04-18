import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/domain/entities/price_stats.dart';

void main() {
  group('PriceStats', () {
    test('defaults to all-null prices and stable trend', () {
      // PriceStats is the charting adapter — a "we have no data" instance
      // must render as an empty card without throwing, so the default
      // construction has to yield a safe no-data value.
      const stats = PriceStats();
      expect(stats.min, isNull);
      expect(stats.max, isNull);
      expect(stats.avg, isNull);
      expect(stats.current, isNull);
      expect(stats.trend, PriceTrend.stable);
    });

    test('preserves all provided fields', () {
      const stats = PriceStats(
        min: 1.499,
        max: 1.799,
        avg: 1.649,
        current: 1.579,
        trend: PriceTrend.down,
      );
      expect(stats.min, 1.499);
      expect(stats.max, 1.799);
      expect(stats.avg, 1.649);
      expect(stats.current, 1.579);
      expect(stats.trend, PriceTrend.down);
    });

    test('is const-constructible — stable for const contexts', () {
      // Many callers build these in const lists for comparison widgets;
      // pinning const-ness guards against accidental instance-field adds.
      const a = PriceStats(current: 1.60);
      const b = PriceStats(current: 1.60);
      expect(identical(a, b), isTrue);
    });
  });

  group('PriceTrend', () {
    test('enumerates up, down, stable in that order', () {
      // Order is load-bearing for UI (arrows) — pin it.
      expect(PriceTrend.values,
          [PriceTrend.up, PriceTrend.down, PriceTrend.stable]);
    });
  });
}
