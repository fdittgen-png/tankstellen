// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Coverage for the OCR digit-normalisation helpers shared by the
// receipt parsers — salvaged from the removed pump-display parser
// tests (#3765): the receipt value tokenizer still routes every OCR'd
// number candidate through this pass.

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr_numeric_normalization.dart';

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

  group('kNumericTokenPattern — numeric-ish token bounds', () {
    test('matches a pure digit sequence', () {
      expect(kNumericTokenPattern.firstMatch('58')!.group(0), '58');
    });

    test('matches digits + lookalike letters', () {
      expect(kNumericTokenPattern.firstMatch('1O.SO')!.group(0), '1O.SO');
    });

    test('matches across decimal separator', () {
      expect(kNumericTokenPattern.firstMatch('B.OO')!.group(0), 'B.OO');
    });

    test('stops at non-lookalike characters like space', () {
      // The global replaceAllMapped usage in the tokenizer relies on
      // this being token-bounded.
      final match = kNumericTokenPattern.firstMatch('B.OO andere');
      expect(match!.group(0), 'B.OO');
    });
  });

  group('kDigitLookalikePattern — single-char predicate', () {
    test('matches digits 0-9', () {
      for (var d = 0; d <= 9; d++) {
        expect(kDigitLookalikePattern.hasMatch('$d'), isTrue);
      }
    });

    test('matches all mapped lookalike letters', () {
      for (final letter in kDigitLookalikeMap.keys) {
        expect(
          kDigitLookalikePattern.hasMatch(letter),
          isTrue,
          reason: 'expected $letter to match lookalike predicate',
        );
      }
    });

    test('rejects non-lookalike letters', () {
      for (final ch in ['e', 'a', 'r', 'N', 'X', '@', '#']) {
        expect(kDigitLookalikePattern.hasMatch(ch), isFalse);
      }
    });

    test('rejects empty and multi-char inputs', () {
      expect(kDigitLookalikePattern.hasMatch(''), isFalse);
      expect(kDigitLookalikePattern.hasMatch('12'), isFalse);
      expect(kDigitLookalikePattern.hasMatch('OO'), isFalse);
    });
  });

  group('kDigitLookalikeMap — rewrite table', () {
    test('maps each known lookalike to the intended digit', () {
      expect(kDigitLookalikeMap['O'], '0');
      expect(kDigitLookalikeMap['o'], '0');
      expect(kDigitLookalikeMap['D'], '0');
      expect(kDigitLookalikeMap['I'], '1');
      expect(kDigitLookalikeMap['l'], '1');
      expect(kDigitLookalikeMap['B'], '8');
      expect(kDigitLookalikeMap['b'], '8');
      expect(kDigitLookalikeMap['S'], '5');
      expect(kDigitLookalikeMap['s'], '5');
      expect(kDigitLookalikeMap['Z'], '2');
      expect(kDigitLookalikeMap['z'], '2');
      expect(kDigitLookalikeMap['g'], '9');
    });

    test('every mapped key is recognised by the single-char predicate', () {
      // Guarantees the rewrite table and the predicate stay in sync.
      for (final key in kDigitLookalikeMap.keys) {
        expect(kDigitLookalikePattern.hasMatch(key), isTrue);
      }
    });

    test('does not contain stray mappings for regular letters', () {
      // "e", "a", "n" etc. must NOT be in the table so words like
      // "Diesel" / "Menge" stay intact after rewrite.
      expect(kDigitLookalikeMap.containsKey('e'), isFalse);
      expect(kDigitLookalikeMap.containsKey('a'), isFalse);
      expect(kDigitLookalikeMap.containsKey('n'), isFalse);
      expect(kDigitLookalikeMap.containsKey('r'), isFalse);
    });
  });
}
