import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';

void main() {
  group('PriceFormatter', () {
    test('formats price correctly', () {
      expect(PriceFormatter.formatPrice(1.459), contains('1,459'));
      expect(PriceFormatter.formatPrice(null), '--');
      expect(PriceFormatter.formatPrice(0), '--');
    });

    test('formats distance correctly', () {
      expect(PriceFormatter.formatDistance(2.3), contains('2,3'));
      expect(PriceFormatter.formatDistance(0.5), contains('500 m'));
      expect(PriceFormatter.formatDistance(null), '--');
    });

    test('returns fuel type name', () {
      expect(PriceFormatter.fuelTypeName('e5'), 'Super E5');
      expect(PriceFormatter.fuelTypeName('e10'), 'Super E10');
      expect(PriceFormatter.fuelTypeName('diesel'), 'Diesel');
      expect(PriceFormatter.fuelTypeName('all'), 'Alle');
    });
  });
}
