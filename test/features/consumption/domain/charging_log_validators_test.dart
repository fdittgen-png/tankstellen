import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/charging_log_validators.dart';

/// Unit tests for the pure validators / parsers extracted from
/// `add_charging_log_screen.dart` (#563 refactor). Each rule is
/// covered for: blank/null input, unparseable input, boundary
/// values (zero, negative), and at least one happy-path case.
///
/// All tests pass `null` for [AppLocalizations] — the validators
/// must degrade to English fallbacks ("Required", "Invalid number")
/// when no localizations are in the tree, which is exactly the path
/// they take in widget tests that don't pump a MaterialApp with
/// AppLocalizations.delegate.
void main() {
  group('ChargingLogValidators.positiveNumber', () {
    test('returns Required when value is null', () {
      expect(
        ChargingLogValidators.positiveNumber(null, null),
        equals('Required'),
      );
    });

    test('returns Required when value is empty', () {
      expect(
        ChargingLogValidators.positiveNumber('', null),
        equals('Required'),
      );
    });

    test('returns Required when value is whitespace only', () {
      expect(
        ChargingLogValidators.positiveNumber('   ', null),
        equals('Required'),
      );
    });

    test('returns Invalid number when value is not numeric', () {
      expect(
        ChargingLogValidators.positiveNumber('abc', null),
        equals('Invalid number'),
      );
    });

    test('returns Invalid number when value is zero', () {
      expect(
        ChargingLogValidators.positiveNumber('0', null),
        equals('Invalid number'),
      );
    });

    test('returns Invalid number when value is negative', () {
      expect(
        ChargingLogValidators.positiveNumber('-1.5', null),
        equals('Invalid number'),
      );
    });

    test('accepts a positive double with dot decimal', () {
      expect(
        ChargingLogValidators.positiveNumber('12.5', null),
        isNull,
      );
    });

    test('accepts a positive double with comma decimal', () {
      expect(
        ChargingLogValidators.positiveNumber('12,5', null),
        isNull,
      );
    });

    test('accepts a positive integer string', () {
      expect(
        ChargingLogValidators.positiveNumber('42', null),
        isNull,
      );
    });
  });

  group('ChargingLogValidators.nonNegativeInt', () {
    test('returns Required when value is null', () {
      expect(
        ChargingLogValidators.nonNegativeInt(null, null),
        equals('Required'),
      );
    });

    test('returns Required when value is empty', () {
      expect(
        ChargingLogValidators.nonNegativeInt('', null),
        equals('Required'),
      );
    });

    test('returns Invalid number when value is not numeric', () {
      expect(
        ChargingLogValidators.nonNegativeInt('xx', null),
        equals('Invalid number'),
      );
    });

    test('returns Invalid number when value is negative', () {
      expect(
        ChargingLogValidators.nonNegativeInt('-3', null),
        equals('Invalid number'),
      );
    });

    test('accepts zero (a 0-minute charge session is valid)', () {
      expect(
        ChargingLogValidators.nonNegativeInt('0', null),
        isNull,
      );
    });

    test('accepts a positive integer', () {
      expect(
        ChargingLogValidators.nonNegativeInt('30', null),
        isNull,
      );
    });

    test('accepts a decimal by truncating to its integer part', () {
      // The validator parses the integer prefix only — "30.5" reads
      // as 30 and passes. This mirrors the behaviour the UI relied
      // on before the refactor.
      expect(
        ChargingLogValidators.nonNegativeInt('30.5', null),
        isNull,
      );
    });
  });

  group('ChargingLogValidators.parseDouble', () {
    test('parses dot decimal', () {
      expect(ChargingLogValidators.parseDouble('12.5'), closeTo(12.5, 1e-9));
    });

    test('parses comma decimal', () {
      expect(ChargingLogValidators.parseDouble('12,5'), closeTo(12.5, 1e-9));
    });

    test('parses an integer string', () {
      expect(ChargingLogValidators.parseDouble('42'), closeTo(42.0, 1e-9));
    });
  });

  group('ChargingLogValidators.parseInt', () {
    test('parses an integer string', () {
      expect(ChargingLogValidators.parseInt('42'), equals(42));
    });

    test('truncates a decimal value', () {
      expect(ChargingLogValidators.parseInt('42.9'), equals(42));
    });

    test('truncates a comma-decimal value', () {
      expect(ChargingLogValidators.parseInt('42,9'), equals(42));
    });
  });
}
