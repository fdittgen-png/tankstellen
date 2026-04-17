import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/pump_display_parser.dart';

/// Tests drive the parser with realistic OCR outputs — the kind of
/// text Google ML Kit actually returns for photos of German pump
/// displays (see sample set in docs). Some inputs include common
/// 7-segment misreads (B↔8, O↔0, I/l↔1) and label OCR noise
/// ("Betraq", "Ab9abe") so the parser proves robust end-to-end.
void main() {
  const parser = PumpDisplayParser();

  group('PumpDisplayParser — clean German labels', () {
    test('parses a standard Betrag / Abgabe / Preis/Liter block', () {
      // Arithmetically consistent: 31.65 * 1.846 = 58.4259 ≈ 58.43
      // (the pump rounds each value independently to its displayed
      // precision, so exact cent-level agreement is typical).
      const ocr = '''
Betrag
€ 58,43
Abgabe
L 31,65
Preis/Liter
€/L 1,846
''';
      final r = parser.parse(ocr);
      expect(r.totalCost, closeTo(58.43, 0.001));
      expect(r.liters, closeTo(31.65, 0.001));
      expect(r.pricePerLiter, closeTo(1.846, 0.001));
      expect(r.isConsistent, isTrue);
      expect(r.hasUsableData, isTrue);
      expect(r.confidence, greaterThanOrEqualTo(0.95));
    });

    test('parses compact single-line layout', () {
      final r = parser.parse(
          'Betrag 42.18 € Abgabe 23.45 L Preis/Liter 1.799');
      expect(r.totalCost, closeTo(42.18, 0.001));
      expect(r.liters, closeTo(23.45, 0.001));
      expect(r.pricePerLiter, closeTo(1.799, 0.001));
    });

    test('parses CT cents-per-litre layout (German pumps)', () {
      // Some pumps show the price as "CT 184,9" (= 1.849 €/L).
      final r = parser.parse('Betrag € 50,00\nAbgabe L 27,05\nCT 184,9');
      expect(r.pricePerLiter, closeTo(1.849, 0.001));
    });

    test('extracts the pump number when it appears alone', () {
      final r = parser.parse('8\nBetrag € 0,00\nAbgabe L 0,00\nCT 0,0');
      expect(r.pumpNumber, 8);
    });

    test('does not treat a digit inside a larger number as a pump id', () {
      final r = parser.parse('Betrag € 42,18\nAbgabe L 23,45');
      expect(r.pumpNumber, isNull);
    });
  });

  group('PumpDisplayParser — OCR noise tolerance', () {
    test('fixes 7-segment digit misreads inside numbers', () {
      // "B.OO" should become "8.00", "1O.SO" → "10.50".
      // "1,B49" should become "1.849".
      final r = parser.parse(
          'Betrag € B.OO\nAbgabe L 1O.SO\nPreis/Liter 1,B49');
      expect(r.totalCost, closeTo(8.00, 0.001));
      expect(r.liters, closeTo(10.50, 0.001));
      expect(r.pricePerLiter, closeTo(1.849, 0.001));
    });

    test('does not corrupt real words while fixing digits', () {
      // 'Diesel' contains 'e', 's', 'l' — none should be rewritten.
      // Pump number '3' is a real digit token.
      final r = parser.parse('Diesel\n3\nBetrag € 58,42\nAbgabe L 31,65');
      expect(r.totalCost, closeTo(58.42, 0.001));
      expect(r.pumpNumber, 3);
    });

    test('handles "Betraq" OCR misread of Betrag', () {
      final r = parser.parse('Betraq € 72,50\nAbqabe L 40,05');
      expect(r.totalCost, closeTo(72.50, 0.001));
      expect(r.liters, closeTo(40.05, 0.001));
    });

    test('parses comma-decimal (DE) and dot-decimal (fallback)', () {
      final r1 = parser.parse('Betrag € 58,42\nAbgabe L 31,65');
      final r2 = parser.parse('Betrag € 58.42\nAbgabe L 31.65');
      expect(r1.totalCost, closeTo(58.42, 0.001));
      expect(r2.totalCost, closeTo(58.42, 0.001));
      expect(r1.liters, closeTo(31.65, 0.001));
      expect(r2.liters, closeTo(31.65, 0.001));
    });
  });

  group('PumpDisplayParser — positional fallback', () {
    test('infers the triple when labels are missing', () {
      // Unlabelled display showing 3 numbers in the canonical
      // (total, liters, price) order. The parser buckets by
      // magnitude.
      final r = parser.parse('58,42\n31,65\n1,849');
      expect(r.totalCost, closeTo(58.42, 0.001));
      expect(r.liters, closeTo(31.65, 0.001));
      expect(r.pricePerLiter, closeTo(1.849, 0.001));
    });

    test('picks the 3-decimal number as price-per-litre', () {
      // Total first, volume second, price last — but any order:
      // the 3-decimal number still wins as price.
      final r = parser.parse('1,849\n58,42\n31,65');
      expect(r.pricePerLiter, closeTo(1.849, 0.001));
      expect(r.totalCost, closeTo(58.42, 0.001));
      expect(r.liters, closeTo(31.65, 0.001));
    });

    test('does not invent a price-per-litre outside plausible range', () {
      // Only two numbers, neither in the 0.5–5 price band.
      final r = parser.parse('58,42\n31,65');
      expect(r.pricePerLiter, isNull);
    });

    test('returns empty result for gibberish', () {
      final r = parser.parse('Messanlage mit Tankautomat\nDiesel\nSuper');
      expect(r.hasUsableData, isFalse);
      expect(r.confidence, 0);
    });
  });

  group('PumpDisplayParser — consistency check', () {
    test('isConsistent when total ≈ liters * price within 2 cents', () {
      final r = parser.parse(
          'Betrag € 58,42\nAbgabe L 31,65\nPreis/Liter € 1,846');
      // 31.65 * 1.846 = 58.4259 — within 2c of 58.42.
      expect(r.isConsistent, isTrue);
    });

    test('not consistent when numbers disagree by more than 2 cents', () {
      // 10.00 * 1.500 = 15.00 — the displayed total 30.00 is way off.
      final r = parser.parse(
          'Betrag € 30,00\nAbgabe L 10,00\nPreis/Liter € 1,500');
      expect(r.isConsistent, isFalse);
    });

    test('isConsistent is false when any field is missing', () {
      final r = parser.parse('Betrag € 58,42\nAbgabe L 31,65');
      expect(r.isConsistent, isFalse);
    });
  });

  group('PumpDisplayParser — degenerate inputs', () {
    test('empty string produces empty result', () {
      final r = parser.parse('');
      expect(r.hasUsableData, isFalse);
      expect(r.totalCost, isNull);
      expect(r.liters, isNull);
      expect(r.pricePerLiter, isNull);
      expect(r.pumpNumber, isNull);
      expect(r.confidence, 0);
    });

    test('whitespace-only string produces empty result', () {
      expect(parser.parse('   \n\n\t').hasUsableData, isFalse);
    });

    test('rejects implausible large totals', () {
      final r = parser.parse('Betrag € 99999,99');
      // 99999.99 is outside (< 10000) and should be rejected.
      expect(r.totalCost, isNull);
    });

    test('rejects implausible price-per-litre values', () {
      // €/L 42 is way above the 10 EUR/L guard.
      final r = parser.parse('Preis/Liter € 42,000');
      expect(r.pricePerLiter, isNull);
    });
  });

  group('PumpDisplayParser — real-world sample fidelity', () {
    test('German ZOV pump ("Messanlage mit Tankautomat") at idle', () {
      // Matches photos 1 and 11 in the fixture set: pump 1, Diesel,
      // display reads zero.
      const ocr = '''
Messanlage mit Tankautomat
1
Betrag
€ 0,00
Abgabe
L 0,00
CT 0,0
Preis/Liter
Diesel
''';
      final r = parser.parse(ocr);
      expect(r.totalCost, closeTo(0.00, 0.001));
      expect(r.liters, closeTo(0.00, 0.001));
      expect(r.pumpNumber, 1);
    });

    test('post-fill readout: 31.65 L Diesel for 58.43 EUR at 1.846/L', () {
      const ocr = '''
3
Betrag
€ 58,43
Abgabe
L 31,65
Preis/Liter
€/L 1,846
Diesel
''';
      final r = parser.parse(ocr);
      expect(r.totalCost, closeTo(58.43, 0.001));
      expect(r.liters, closeTo(31.65, 0.001));
      expect(r.pricePerLiter, closeTo(1.846, 0.001));
      expect(r.pumpNumber, 3);
      expect(r.isConsistent, isTrue);
      expect(r.confidence, greaterThanOrEqualTo(0.9));
    });

    test('degraded-OCR readout of the same display still recoverable', () {
      // Simulate ML Kit mangling a few chars under glare:
      // 'S' instead of '5', 'B' for '8', 'l' for '1'.
      const ocr = '''
3
Betrag
€ SB,43
Abgabe
L 31,6S
Preis/Liter
€/L l,846
Diesel
''';
      final r = parser.parse(ocr);
      expect(r.totalCost, closeTo(58.43, 0.001));
      expect(r.liters, closeTo(31.65, 0.001));
      expect(r.pricePerLiter, closeTo(1.846, 0.001));
    });
  });
}
