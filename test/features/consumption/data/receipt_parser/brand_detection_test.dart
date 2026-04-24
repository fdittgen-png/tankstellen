import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser/brand_detection.dart';

void main() {
  group('detectBrand', () {
    test('returns super_u for "super u"', () {
      expect(detectBrand(const [], 'welcome to super u receipt'), 'super_u');
    });

    test('returns super_u for "système u" (accent)', () {
      expect(detectBrand(const [], 'Système U - Castelnau'), 'super_u');
    });

    test('returns super_u for "systeme u" (no accent)', () {
      expect(detectBrand(const [], 'SYSTEME U PEZENAS'), 'super_u');
    });

    test('returns carrefour', () {
      expect(detectBrand(const [], 'CARREFOUR MARKET'), 'carrefour');
    });

    test('returns total for "totalenergies"', () {
      expect(detectBrand(const [], 'TOTALENERGIES station'), 'total');
    });

    test('returns total for "total " (trailing space)', () {
      expect(detectBrand(const [], 'TOTAL STATION'), 'total');
    });

    test('does NOT return total for "total" without trailing space only', () {
      // "total" alone (no space, no "total ") should not match the "total "
      // branch. And without "totalenergies" either, returns null.
      expect(detectBrand(const [], 'total'), isNull);
    });

    test('returns intermarche for "intermarché" (accent)', () {
      expect(detectBrand(const [], 'Intermarché Super'), 'intermarche');
    });

    test('returns intermarche for "intermarche" (no accent)', () {
      expect(detectBrand(const [], 'INTERMARCHE CONTACT'), 'intermarche');
    });

    test('returns leclerc', () {
      expect(detectBrand(const [], 'E.LECLERC station service'), 'leclerc');
    });

    test('returns shell', () {
      expect(detectBrand(const [], 'SHELL A9'), 'shell');
    });

    test('returns esso', () {
      expect(detectBrand(const [], 'ESSO express'), 'esso');
    });

    test('returns aral', () {
      expect(detectBrand(const [], 'ARAL Autobahn'), 'aral');
    });

    test('returns null when no brand matches', () {
      expect(detectBrand(const [], 'generic fuel station'), isNull);
    });

    test('returns null for empty string', () {
      expect(detectBrand(const [], ''), isNull);
    });

    test('matching is case-insensitive (uppercase input)', () {
      expect(detectBrand(const [], 'SUPER U'), 'super_u');
      expect(detectBrand(const [], 'CARREFOUR'), 'carrefour');
      expect(detectBrand(const [], 'SHELL'), 'shell');
    });

    test('dispatch order: super_u before total even if both match', () {
      // Both super u AND total energies in text — super_u checked first.
      expect(
        detectBrand(const [], 'super u — partenaire TotalEnergies'),
        'super_u',
      );
    });

    test('dispatch order: carrefour before total', () {
      expect(
        detectBrand(const [], 'carrefour partenaire totalenergies'),
        'carrefour',
      );
    });

    test('dispatch order: total before intermarche', () {
      expect(
        detectBrand(const [], 'totalenergies — concurrent intermarché'),
        'total',
      );
    });

    test('ignores the lines list (only fullText matters)', () {
      // Lines contain SHELL, but fullText does not — should return null.
      expect(detectBrand(const ['SHELL'], 'no brand here'), isNull);
    });
  });

  group('extractStationName', () {
    test('matches whole-line equal to brand', () {
      expect(extractStationName(const ['Total']), 'Total');
    });

    test('matches line starting with brand + space', () {
      expect(
        extractStationName(const ['Total Station Castelnau']),
        'Total Station Castelnau',
      );
    });

    test('matches line starting with brand + tab', () {
      expect(
        extractStationName(const ['Total\tStation Castelnau']),
        'Total\tStation Castelnau',
      );
    });

    test('is case-insensitive but returns original line', () {
      expect(
        extractStationName(const ['TOTAL Station']),
        'TOTAL Station',
      );
    });

    test('trims whitespace before matching', () {
      expect(
        extractStationName(const ['  shell highway  ']),
        '  shell highway  ',
      );
    });

    test('only looks at the first 5 lines', () {
      final lines = [
        'Ticket de caisse',
        'Date: 2024-01-01',
        'Ref: ABC',
        'Lorem ipsum',
        'Dolor sit amet',
        'Total Station', // 6th line — should be ignored
      ];
      expect(extractStationName(lines), isNull);
    });

    test('matches within the first 5 lines', () {
      final lines = [
        'Ticket de caisse',
        'Date',
        'Total Station', // 3rd line — within first 5
        'x',
        'y',
      ];
      expect(extractStationName(lines), 'Total Station');
    });

    test('returns null when no brand appears in first 5 lines', () {
      expect(
        extractStationName(const ['Ticket', 'Date', 'Ref', 'x', 'y']),
        isNull,
      );
    });

    test('returns null for empty list', () {
      expect(extractStationName(const []), isNull);
    });

    test('does not match when brand is substring but not at start', () {
      // "TOTAL" is in the middle, not at start
      expect(
        extractStationName(const ['Merci pour votre visite TOTAL']),
        isNull,
      );
    });

    test('matches Intermarché with accent', () {
      expect(
        extractStationName(const ['Intermarché Super']),
        'Intermarché Super',
      );
    });

    test('matches intermarche without accent', () {
      expect(
        extractStationName(const ['intermarche contact']),
        'intermarche contact',
      );
    });

    test('matches super u as brand', () {
      expect(extractStationName(const ['Super U Pezenas']), 'Super U Pezenas');
    });

    test('matches systeme u without accent', () {
      expect(
        extractStationName(const ['systeme u marché']),
        'systeme u marché',
      );
    });

    test('matches système u with accent', () {
      expect(
        extractStationName(const ['Système U Distrib']),
        'Système U Distrib',
      );
    });

    test('matches totalenergies', () {
      expect(
        extractStationName(const ['TotalEnergies A75']),
        'TotalEnergies A75',
      );
    });

    test('matches bp, aral, esso, avia, jet, elf, agip, q8, omv, mol, orlen',
        () {
      expect(extractStationName(const ['BP Station']), 'BP Station');
      expect(extractStationName(const ['Aral 123']), 'Aral 123');
      expect(extractStationName(const ['Esso Express']), 'Esso Express');
      expect(extractStationName(const ['Avia XPress']), 'Avia XPress');
      expect(extractStationName(const ['Jet Auto']), 'Jet Auto');
      expect(extractStationName(const ['Elf Station']), 'Elf Station');
      expect(extractStationName(const ['Agip IP']), 'Agip IP');
      expect(extractStationName(const ['Q8 Kuwait']), 'Q8 Kuwait');
      expect(extractStationName(const ['OMV Austria']), 'OMV Austria');
      expect(extractStationName(const ['MOL Magyar']), 'MOL Magyar');
      expect(extractStationName(const ['Orlen Polska']), 'Orlen Polska');
    });

    test('matches leclerc, carrefour, auchan, casino', () {
      expect(extractStationName(const ['Leclerc A9']), 'Leclerc A9');
      expect(
        extractStationName(const ['Carrefour Market']),
        'Carrefour Market',
      );
      expect(extractStationName(const ['Auchan Drive']), 'Auchan Drive');
      expect(extractStationName(const ['Casino Shop']), 'Casino Shop');
    });
  });
}
