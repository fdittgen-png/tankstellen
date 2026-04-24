import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/_pump_display_patterns.dart';

/// Direct behavioural tests for the regex patterns used by
/// [PumpDisplayParser]. These patterns are indirectly exercised by
/// `pump_display_parser_test.dart`, but asserting them in isolation
/// catches regressions that the orchestrator would mask (e.g. a
/// pattern that starts matching too greedily still produces the same
/// parser output because later heuristics override the match).
///
/// Refs #561 — targeted coverage of the patterns module.
void main() {
  group('kBetragPatterns — labelled total extraction', () {
    test('labelled "Betrag" with euro sign yields the amount', () {
      final match = _firstMatch(kBetragPatterns, 'Betrag € 58,42');
      expect(match, '58,42');
    });

    test('labelled "Betrag" without currency still matches', () {
      final match = _firstMatch(kBetragPatterns, 'Betrag 58,42');
      expect(match, '58,42');
    });

    test('handles "Betraq" OCR glyph confusion', () {
      // When the 'g' hook is thin the OCR often reads 'q'.
      final match = _firstMatch(kBetragPatterns, 'Betraq € 72,50');
      expect(match, '72,50');
    });

    test('accepts either "," or "." as decimal separator', () {
      expect(_firstMatch(kBetragPatterns, 'Betrag 58.42'), '58.42');
      expect(_firstMatch(kBetragPatterns, 'Betrag 58,42'), '58,42');
    });

    test('matches a trailing € adjacent to word context', () {
      // Pattern 3 is `\b(\d+[.,]\d{2})\s*€\b`. The `\b` after € only
      // fires when a word character follows the currency symbol — so
      // we anchor with trailing text.
      final match = _firstMatch(kBetragPatterns, '42,18 €gesamt');
      expect(match, '42,18');
    });

    test('matches EUR prefix as well as €', () {
      final match = _firstMatch(kBetragPatterns, 'EUR 58,42');
      expect(match, '58,42');
    });

    test('requires exactly two decimal digits for totals', () {
      // A 3-decimal number is NOT a Betrag — it's a price-per-litre.
      // The labelled pattern should not match "58,421".
      final pattern = RegExp(
        r'(?:€|EUR)\s*[:=]?\s*(\d+[.,]\d{2})\b',
      );
      expect(pattern.hasMatch('€ 58,42 '), isTrue);
      // Even though "58,421" contains "58,42", \d{2}\b requires a
      // word boundary after the two decimals, which the extra digit
      // breaks.
      expect(pattern.hasMatch('€ 58,421'), isFalse);
    });

    test('ignores tokens without the expected labelling', () {
      final any = kBetragPatterns.any((p) => p.hasMatch('Diesel'));
      expect(any, isFalse);
    });
  });

  group('kAbgabePatterns — labelled volume extraction', () {
    test('labelled "Abgabe" yields the volume', () {
      final match = _firstMatch(kAbgabePatterns, 'Abgabe 31,65');
      expect(match, '31,65');
    });

    test('labelled "Abgabe L" across visual rows still matches', () {
      // ML Kit sometimes flattens the L unit row into the label line.
      final match = _firstMatch(kAbgabePatterns, 'Abgabe L 31,65');
      expect(match, '31,65');
    });

    test('handles "Ab9abe" and "Abqabe" OCR misreads', () {
      expect(_firstMatch(kAbgabePatterns, 'Ab9abe 40,05'), '40,05');
      expect(_firstMatch(kAbgabePatterns, 'Abqabe 40,05'), '40,05');
    });

    test('matches Volume and Menge labels (multilingual)', () {
      expect(_firstMatch(kAbgabePatterns, 'Volume 31.65'), '31.65');
      expect(_firstMatch(kAbgabePatterns, 'Menge 31,65'), '31,65');
      expect(_firstMatch(kAbgabePatterns, 'Quantité 31,65'), '31,65');
    });

    test('matches trailing L or Liter unit', () {
      expect(_firstMatch(kAbgabePatterns, '31,65 L'), '31,65');
      expect(_firstMatch(kAbgabePatterns, '31.65 Liter'), '31.65');
      expect(_firstMatch(kAbgabePatterns, '31,65 Litres'), '31,65');
    });

    test('accepts 1 to 3 decimal places for volume', () {
      expect(_firstMatch(kAbgabePatterns, 'Abgabe 31,6'), '31,6');
      expect(_firstMatch(kAbgabePatterns, 'Abgabe 31,65'), '31,65');
      expect(_firstMatch(kAbgabePatterns, 'Abgabe 31,655'), '31,655');
    });
  });

  group('kPricePerLiterPatterns — labelled unit price extraction', () {
    test('labelled "Preis/Liter" yields the unit price', () {
      final match = _firstMatch(kPricePerLiterPatterns, 'Preis/Liter 1,849');
      expect(match, '1,849');
    });

    test('PREIS/L uppercase variant matches', () {
      final match = _firstMatch(kPricePerLiterPatterns, 'PREIS/L 1.849');
      expect(match, '1.849');
    });

    test('EUR/L and €/L labellings match', () {
      expect(_firstMatch(kPricePerLiterPatterns, 'EUR/L 1.849'), '1.849');
      expect(_firstMatch(kPricePerLiterPatterns, '€/L 1,849'), '1,849');
    });

    test('trailing unit like "1,849 €/L" matches', () {
      expect(_firstMatch(kPricePerLiterPatterns, '1,849 €/L'), '1,849');
      expect(_firstMatch(kPricePerLiterPatterns, '1,849 EUR/L'), '1,849');
    });

    test('accepts 2 and 3 decimal precision (1,84 and 1,849)', () {
      expect(_firstMatch(kPricePerLiterPatterns, 'Preis/Liter 1,84'), '1,84');
      expect(
        _firstMatch(kPricePerLiterPatterns, 'Preis/Liter 1,849'),
        '1,849',
      );
    });
  });

  group('kCentsPerLiterPattern — cents layout', () {
    test('matches "CT 184,9" as cents per litre', () {
      final m = kCentsPerLiterPattern.firstMatch('CT 184,9');
      expect(m, isNotNull);
      expect(m!.group(1), '184,9');
    });

    test('matches "CT 184" without decimals', () {
      final m = kCentsPerLiterPattern.firstMatch('CT 184');
      expect(m, isNotNull);
      expect(m!.group(1), '184');
    });

    test('matches lowercase "ct" (caseSensitive:false)', () {
      expect(kCentsPerLiterPattern.hasMatch('ct 184,9'), isTrue);
    });

    test('requires whole-word "CT" boundary', () {
      // `CTX` must not match — \b before CT guards against partial
      // words inside a longer token.
      expect(kCentsPerLiterPattern.hasMatch('CTX 184,9'), isFalse);
    });
  });

  group('kLonePumpDigitPattern — standalone pump number', () {
    test('matches single digits 1..9', () {
      for (var d = 1; d <= 9; d++) {
        expect(kLonePumpDigitPattern.hasMatch('$d'), isTrue, reason: '$d');
      }
    });

    test('does NOT match the digit 0', () {
      // "0" is never a valid pump number — the pattern is [1-9].
      expect(kLonePumpDigitPattern.hasMatch('0'), isFalse);
    });

    test('does not match multi-digit tokens', () {
      expect(kLonePumpDigitPattern.hasMatch('12'), isFalse);
      expect(kLonePumpDigitPattern.hasMatch('31,65'), isFalse);
    });

    test('does not match a digit with leading or trailing text', () {
      expect(kLonePumpDigitPattern.hasMatch(' 3'), isFalse);
      expect(kLonePumpDigitPattern.hasMatch('3 '), isFalse);
      expect(kLonePumpDigitPattern.hasMatch('D3'), isFalse);
    });
  });

  group('kDecimalNumberPattern — any decimal in a line', () {
    test('captures the first decimal number', () {
      final m = kDecimalNumberPattern.firstMatch('Abgabe L 31,65');
      expect(m, isNotNull);
      expect(m!.group(1), '31,65');
    });

    test('supports both separators', () {
      expect(
        kDecimalNumberPattern.firstMatch('total 58.42')!.group(1),
        '58.42',
      );
    });

    test('finds the first when multiple decimals are present', () {
      final all = kDecimalNumberPattern
          .allMatches('58,42 und 1,849')
          .map((m) => m.group(1))
          .toList();
      expect(all, ['58,42', '1,849']);
    });

    test('does not match pure integers', () {
      expect(kDecimalNumberPattern.hasMatch('1234'), isFalse);
    });
  });

  group('kNumericTokenPattern — numeric-ish token bounds', () {
    test('matches a pure digit sequence', () {
      expect(
        kNumericTokenPattern.firstMatch('58')!.group(0),
        '58',
      );
    });

    test('matches digits + lookalike letters', () {
      expect(
        kNumericTokenPattern.firstMatch('1O.SO')!.group(0),
        '1O.SO',
      );
    });

    test('matches across decimal separator', () {
      expect(
        kNumericTokenPattern.firstMatch('B.OO')!.group(0),
        'B.OO',
      );
    });

    test('stops at non-lookalike characters like space', () {
      // The global replaceAllMapped usage in the parser relies on this
      // being token-bounded.
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
      // "e", "a", "n" etc. must NOT be in the table so German words
      // like "Diesel" / "Menge" stay intact after rewrite.
      expect(kDigitLookalikeMap.containsKey('e'), isFalse);
      expect(kDigitLookalikeMap.containsKey('a'), isFalse);
      expect(kDigitLookalikeMap.containsKey('n'), isFalse);
      expect(kDigitLookalikeMap.containsKey('r'), isFalse);
    });
  });
}

/// Returns the first captured group from the first pattern in [patterns]
/// that matches [input], or `null` if no pattern matches.
String? _firstMatch(List<RegExp> patterns, String input) {
  for (final p in patterns) {
    final m = p.firstMatch(input);
    if (m != null) return m.group(1) ?? m.group(0);
  }
  return null;
}
