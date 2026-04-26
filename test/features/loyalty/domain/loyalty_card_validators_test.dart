import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/loyalty/domain/loyalty_card_validators.dart';

void main() {
  group('parseDiscountInput', () {
    test('returns null for null input', () {
      expect(parseDiscountInput(null), isNull);
    });

    test('returns null for an empty string', () {
      expect(parseDiscountInput(''), isNull);
    });

    test('returns null for whitespace-only input', () {
      expect(parseDiscountInput('   '), isNull);
    });

    test('parses a plain dot-decimal number', () {
      expect(parseDiscountInput('0.05'), 0.05);
    });

    test('parses a comma-decimal number (French/German keyboard)', () {
      expect(parseDiscountInput('0,05'), 0.05);
    });

    test('trims surrounding whitespace before parsing', () {
      expect(parseDiscountInput('  0.12  '), 0.12);
    });

    test('returns null for a non-numeric input', () {
      expect(parseDiscountInput('abc'), isNull);
    });

    test('returns null for trailing characters after the number', () {
      // double.tryParse rejects "0.05€" — confirms no permissive fallback.
      expect(parseDiscountInput('0.05€'), isNull);
    });
  });

  group('isValidDiscountInput', () {
    test('rejects null', () {
      expect(isValidDiscountInput(null), isFalse);
    });

    test('rejects an empty string', () {
      expect(isValidDiscountInput(''), isFalse);
    });

    test('rejects zero', () {
      expect(isValidDiscountInput('0'), isFalse);
      expect(isValidDiscountInput('0.0'), isFalse);
    });

    test('rejects a negative number', () {
      expect(isValidDiscountInput('-0.05'), isFalse);
    });

    test('accepts a positive dot-decimal number', () {
      expect(isValidDiscountInput('0.05'), isTrue);
    });

    test('accepts a positive comma-decimal number', () {
      expect(isValidDiscountInput('0,05'), isTrue);
    });

    test('rejects a non-numeric input', () {
      expect(isValidDiscountInput('abc'), isFalse);
    });
  });
}
