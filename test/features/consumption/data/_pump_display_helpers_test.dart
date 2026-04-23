import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/_pump_display_helpers.dart';

void main() {
  group('parseDecimalFromOcr', () {
    test('accepts both "," and "." as decimal separator', () {
      expect(parseDecimalFromOcr('58,42'), 58.42);
      expect(parseDecimalFromOcr('58.42'), 58.42);
    });

    test('returns null on malformed input', () {
      expect(parseDecimalFromOcr('abc'), isNull);
      expect(parseDecimalFromOcr(''), isNull);
    });
  });

  group('isLikelyNumeric', () {
    test('accepts pure digit sequences', () {
      expect(isLikelyNumeric('8'), isTrue);
      expect(isLikelyNumeric('31'), isTrue);
    });

    test('accepts OCR-corrupted numeric tokens with a separator', () {
      expect(isLikelyNumeric('B.OO'), isTrue);
      expect(isLikelyNumeric('1O.SO'), isTrue);
    });

    test('rejects words and single lookalike letters', () {
      expect(isLikelyNumeric('Diesel'), isFalse);
      expect(isLikelyNumeric('D'), isFalse);
      expect(isLikelyNumeric(''), isFalse);
    });
  });

  group('normaliseDigits', () {
    test('rewrites lookalikes inside numeric tokens only', () {
      // "Diesel" must survive untouched.
      final out = normaliseDigits('Diesel B.OO');
      expect(out, contains('Diesel'));
      expect(out, contains('8.00'));
    });
  });

  group('scorePumpDisplayConfidence', () {
    test('awards 0.3 per extracted field', () {
      expect(
        scorePumpDisplayConfidence(total: null, liters: null, price: null),
        0.0,
      );
      expect(
        scorePumpDisplayConfidence(total: 50, liters: null, price: null),
        closeTo(0.3, 1e-9),
      );
    });

    test('awards +0.1 bonus when all three agree within 2 cents', () {
      final s = scorePumpDisplayConfidence(
        total: 58.40,
        liters: 32,
        price: 1.825,
      );
      // 32 * 1.825 = 58.4 exactly — all three present + consistent.
      expect(s, closeTo(1.0, 1e-9));
    });

    test('clamps to [0, 1]', () {
      final s = scorePumpDisplayConfidence(
        total: 100,
        liters: 50,
        price: 2,
      );
      // 50 * 2 = 100 — consistent. 0.9 + 0.1 = 1.0 exactly.
      expect(s, lessThanOrEqualTo(1.0));
      expect(s, greaterThanOrEqualTo(0.0));
    });
  });
}
