import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  const parser = ReceiptParser();

  group('ReceiptParser', () {
    group('liters extraction', () {
      test('parses "42.35 L" format', () {
        final result = parser.parse('GAZOLE B7\n42.35 L\nTOTAL 58.42 EUR');
        expect(result.liters, closeTo(42.35, 0.01));
      });

      test('parses "42,35 l" with comma', () {
        final result = parser.parse('SP95 42,35 l');
        expect(result.liters, closeTo(42.35, 0.01));
      });

      test('parses "VOLUME : 42.35"', () {
        final result = parser.parse('VOLUME : 42.35');
        expect(result.liters, closeTo(42.35, 0.01));
      });

      test('parses "litres" suffix', () {
        final result = parser.parse('38.50 litres');
        expect(result.liters, closeTo(38.50, 0.01));
      });
    });

    group('total cost extraction', () {
      test('parses "TOTAL 58.42" format', () {
        final result = parser.parse('TOTAL 58.42');
        expect(result.totalCost, closeTo(58.42, 0.01));
      });

      test('parses "MONTANT 58,42 EUR"', () {
        final result = parser.parse('MONTANT 58,42 EUR');
        expect(result.totalCost, closeTo(58.42, 0.01));
      });

      test('parses "€ 58.42"', () {
        final result = parser.parse('€ 58.42');
        expect(result.totalCost, closeTo(58.42, 0.01));
      });

      test('parses "58.42 €"', () {
        final result = parser.parse('58.42 €');
        expect(result.totalCost, closeTo(58.42, 0.01));
      });

      test('parses German "BETRAG 58,42"', () {
        final result = parser.parse('BETRAG 58,42');
        expect(result.totalCost, closeTo(58.42, 0.01));
      });
    });

    group('price per liter extraction', () {
      test('parses "1.899 €/L"', () {
        final result = parser.parse('1.899 €/L');
        expect(result.pricePerLiter, closeTo(1.899, 0.001));
      });

      test('parses "PRIX/L: 1,899"', () {
        final result = parser.parse('PRIX/L: 1,899');
        expect(result.pricePerLiter, closeTo(1.899, 0.001));
      });

      test('parses "PU: 1.459"', () {
        final result = parser.parse('PU: 1.459');
        expect(result.pricePerLiter, closeTo(1.459, 0.001));
      });
    });

    group('date extraction', () {
      test('parses DD/MM/YYYY', () {
        final result = parser.parse('12/04/2026');
        expect(result.date, DateTime(2026, 4, 12));
      });

      test('parses DD.MM.YYYY', () {
        final result = parser.parse('12.04.2026');
        expect(result.date, DateTime(2026, 4, 12));
      });

      test('parses DD-MM-YYYY', () {
        final result = parser.parse('12-04-2026');
        expect(result.date, DateTime(2026, 4, 12));
      });
    });

    group('station name extraction', () {
      test('finds TotalEnergies', () {
        final result = parser.parse(
            'TOTALENERGIES\nStation Paris Nord\n42.35 L\nTOTAL 58.42');
        expect(result.stationName, 'TOTALENERGIES');
      });

      test('finds Intermarché', () {
        final result = parser.parse(
            'INTERMARCHE SUPER\nPÉZENAS\n42.35 L\nTOTAL 58.42');
        expect(result.stationName, 'INTERMARCHE SUPER');
      });

      test('returns null for unknown brand', () {
        final result = parser.parse('UNKNOWN STATION\n42.35 L\nMONTANT 58.42');
        expect(result.stationName, isNull);
      });
    });

    group('full receipt', () {
      test('parses typical French receipt', () {
        const receipt = '''
TOTALENERGIES
Station N°1234
12/04/2026 14:32
GAZOLE B7
42.35 L
PU: 1.459
TOTAL 61.79 EUR
CB **** 4321
''';
        final result = parser.parse(receipt);
        expect(result.liters, closeTo(42.35, 0.01));
        expect(result.totalCost, closeTo(61.79, 0.01));
        expect(result.pricePerLiter, closeTo(1.459, 0.001));
        expect(result.date, DateTime(2026, 4, 12));
        expect(result.stationName, 'TOTALENERGIES');
        expect(result.hasData, isTrue);
      });

      test('parses typical German receipt', () {
        const receipt = '''
ARAL
Tankstelle Hamburg
12.04.2026
Super E10
38,50 L
Literpreis: 1,799
BETRAG 69,26
''';
        final result = parser.parse(receipt);
        expect(result.liters, closeTo(38.50, 0.01));
        expect(result.totalCost, closeTo(69.26, 0.01));
        expect(result.pricePerLiter, closeTo(1.799, 0.001));
        expect(result.stationName, contains('ARAL'));
      });

      test('hasData false for empty text', () {
        final result = parser.parse('');
        expect(result.hasData, isFalse);
      });

      test('parses Super U France receipt with TOT TTC + "€ x.xxx/L"', () {
        // Real Super U Pomerols receipt (#713): price-per-liter has
        // currency BEFORE the number and total is labelled "TOT TTC".
        // Previously the generic "€ <amount>" fallback grabbed the unit
        // price as the total.
        const receipt = '''
SUPER U
CHEMIN DU PORTROU
34810 POMEROLS
04 67 00 86 80
QUITTANCE COPIE
TRANSACTION ACCEPTEE
Date 19-04-2026 15:19:27
*
Pompe 3    SP95-E10
Volume     5.24 L
Prix       € 1.999/L
TOT TTC    € 10.47
*
TVA 20.00 %   € 1.74
Net           € 8.73
''';
        final result = parser.parse(receipt);
        expect(result.liters, closeTo(5.24, 0.01));
        expect(result.totalCost, closeTo(10.47, 0.01));
        expect(result.pricePerLiter, closeTo(1.999, 0.001));
        expect(result.date, DateTime(2026, 4, 19));
        expect(result.stationName, 'SUPER U');
        expect(result.fuelType, FuelType.e10);
      });
    });

    group('fuel type detection', () {
      test('recognises SP95-E10 → FuelType.e10', () {
        expect(parser.parse('Pompe 3 SP95-E10').fuelType, FuelType.e10);
      });

      test('recognises Gazole / Diesel / B7 → FuelType.diesel', () {
        expect(parser.parse('GAZOLE B7\n42 L').fuelType, FuelType.diesel);
        expect(parser.parse('Diesel 50L').fuelType, FuelType.diesel);
      });

      test('recognises Super 98 / E98 → FuelType.e98', () {
        expect(parser.parse('SP98').fuelType, FuelType.e98);
      });

      test('recognises E85 / Bioéthanol → FuelType.e85', () {
        expect(parser.parse('Bioéthanol E85').fuelType, FuelType.e85);
      });

      test('returns null for an unrecognised product string', () {
        expect(parser.parse('Kerosene jet').fuelType, isNull);
      });
    });
  });
}
