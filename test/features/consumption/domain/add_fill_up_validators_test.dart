import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/add_fill_up_validators.dart';

/// Unit tests for the pure validators / parsers extracted from
/// `add_fill_up_screen.dart` (#563 refactor). Each rule is covered
/// for: blank/null input, unparseable input, boundary values (zero,
/// negative), and at least one happy-path case.
///
/// All tests pass `null` for [AppLocalizations] — the validators
/// must degrade to English fallbacks ("Required", "Invalid number")
/// when no localizations are in the tree, which is exactly the path
/// they take in widget tests that don't pump a MaterialApp with
/// AppLocalizations.delegate.
void main() {
  group('AddFillUpValidators.positiveNumber', () {
    test('returns Required when value is null', () {
      expect(
        AddFillUpValidators.positiveNumber(null, null),
        equals('Required'),
      );
    });

    test('returns Required when value is empty', () {
      expect(
        AddFillUpValidators.positiveNumber('', null),
        equals('Required'),
      );
    });

    test('returns Required when value is whitespace only', () {
      expect(
        AddFillUpValidators.positiveNumber('   ', null),
        equals('Required'),
      );
    });

    test('returns Invalid number when value is not numeric', () {
      expect(
        AddFillUpValidators.positiveNumber('abc', null),
        equals('Invalid number'),
      );
    });

    test('returns Invalid number when value is zero', () {
      expect(
        AddFillUpValidators.positiveNumber('0', null),
        equals('Invalid number'),
      );
    });

    test('returns Invalid number when value is negative', () {
      expect(
        AddFillUpValidators.positiveNumber('-1', null),
        equals('Invalid number'),
      );
    });

    test('returns null on a positive integer', () {
      expect(
        AddFillUpValidators.positiveNumber('40', null),
        isNull,
      );
    });

    test('returns null on a positive decimal with dot', () {
      expect(
        AddFillUpValidators.positiveNumber('1.859', null),
        isNull,
      );
    });

    test('returns null on a positive decimal with comma (FR/DE locale)', () {
      // The form is bilingual — French / German users type a comma
      // separator. The validator must accept both.
      expect(
        AddFillUpValidators.positiveNumber('1,859', null),
        isNull,
      );
    });

    test('returns null on a tiny positive value', () {
      // The validator's lower bound is "> 0", not ">= 0.01". A 0.01 L
      // dribble is implausible but not invalid.
      expect(
        AddFillUpValidators.positiveNumber('0.01', null),
        isNull,
      );
    });
  });

  group('AddFillUpValidators.parseDouble', () {
    test('parses a plain integer string', () {
      expect(AddFillUpValidators.parseDouble('40'), 40.0);
    });

    test('parses a dot-decimal string', () {
      expect(AddFillUpValidators.parseDouble('1.859'), 1.859);
    });

    test('parses a comma-decimal string by replacing comma with dot', () {
      // The screen relies on this so the FR/DE-typed values save
      // correctly to a [FillUp].
      expect(AddFillUpValidators.parseDouble('1,859'), 1.859);
    });

    test('throws on unparseable input', () {
      // Callers must validate before parsing — parseDouble is a
      // post-validation helper and must not silently swallow garbage.
      expect(
        () => AddFillUpValidators.parseDouble('abc'),
        throwsFormatException,
      );
    });
  });
}
