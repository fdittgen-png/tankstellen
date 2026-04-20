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
        expect(result.brandLayout, 'super_u');
      });

      test(
          'parses Carrefour Market France receipt with Quantite = / '
          'Prix unit. = / MONTANT REEL', () {
        // Real Carrefour Market Marseillan receipt (#713): labels are
        // "Quantite = 5.27 L", "Prix unit. = 2,028 EUR", and
        // "MONTANT REEL : 10.69 EUR", with the date in 2-digit-year
        // form ("19/04/26").
        const receipt = '''
Carrefour market
Station Carrefour Market
SAS PLANE
34340 MARSEILLAN
Tel:04.67.77.29.10
CREDIT AGRICOLE
LANGUEDOC
A00000000421010
CB COMPTANT
Le : 19/04/26 a : 11:03:35
CARREFOUR MARKET
MARSEILLAN
34340
No AUTO : 143525
MONTANT REEL : 10.69 EUR
Ticket No :
008407 00019 00 06 0433 5409
No pompe    = 6
Carburant   = SP95
Quantite    = 5.27 L
Prix unit.  = 2,028 EUR
TVA 20.00%  = 1.78 EUR
''';
        final result = parser.parse(receipt);
        expect(result.liters, closeTo(5.27, 0.01));
        expect(result.totalCost, closeTo(10.69, 0.01));
        expect(result.pricePerLiter, closeTo(2.028, 0.001));
        expect(result.date, DateTime(2026, 4, 19));
        expect(result.stationName?.toLowerCase(), contains('carrefour'));
        expect(result.fuelType, FuelType.e5,
            reason: 'SP95 alone (not SP95-E10) is the E5 fuel in France');
        expect(result.brandLayout, 'carrefour');
      });
    });

    group('cross-field reconciliation (#713)', () {
      test('derives liters from total + pricePerLiter when liters missing',
          () {
        // OCR lost the "5.24 L" — only the labelled total + unit price
        // survived. liters should be derived: 10.47 / 1.999 = 5.24.
        const receipt = '''
SUPER U
Prix € 1.999/L
TOT TTC € 10.47
''';
        final result = parser.parse(receipt);
        expect(result.liters, closeTo(5.24, 0.02));
        expect(result.totalCost, closeTo(10.47, 0.01));
        expect(result.pricePerLiter, closeTo(1.999, 0.001));
      });

      test('derives total from liters + pricePerLiter when total missing',
          () {
        const receipt = 'Volume 5.24 L\nPrix € 1.999/L\n';
        final result = parser.parse(receipt);
        expect(result.totalCost, closeTo(10.47, 0.02));
      });

      test(
          'overrides a bogus total when liters × pricePerLiter disagrees '
          'by more than 15 %', () {
        // Simulate the Super U "2 € instead of 10.47 €" bug: the
        // fallback picked up the unit price as the total. The
        // reconcile step should notice 5.24 × 1.999 ≠ 2.00 and rewrite.
        const receipt = '''
Volume 5.24 L
Prix € 1.999/L
2.00 EUR
''';
        final result = parser.parse(receipt);
        expect(result.totalCost, closeTo(10.47, 0.02));
      });
    });

    group('total cost heuristic fallback', () {
      test(
          'picks the LARGEST € amount when no label matches — avoids the '
          'unit-price-as-total bug when OCR drops the /L suffix', () {
        // Real-world failure mode: OCR produced "€ 1.999 ... € 10.47 ... € 1.74"
        // without the /L on the unit price line. The old "first match"
        // picked 1.999 as the total. New behaviour: largest wins.
        const receipt = 'brand X Volume 5.24 L € 1.999 € 10.47 € 1.74';
        final result = parser.parse(receipt);
        expect(result.totalCost, closeTo(10.47, 0.01));
      });

      test('ignores amounts < 1 € and > 10 000 € as implausible totals', () {
        const receipt = 'ERROR 0.25 € JACKPOT 99999 € REAL 34.50 €';
        final result = parser.parse(receipt);
        expect(result.totalCost, closeTo(34.50, 0.01));
      });
    });

    group('liter extraction robustness', () {
      test('accepts "5.24L" with no space between number and L', () {
        final result = parser.parse('SP95-E10 5.24L');
        expect(result.liters, closeTo(5.24, 0.01));
      });

      test('skips the "20.00" from "TVA 20.00 %" in liter extraction', () {
        final result = parser.parse('TVA 20.00 % 1.74 EUR\nVolume 5.24 L');
        expect(result.liters, closeTo(5.24, 0.01));
      });

      // User report 2026-04-20: Super U Pomerols receipt came back with
      // liters empty even though the paper clearly showed "Volume 5.24 ℓ".
      // French receipts use the typography U+2113 (ℓ, "script small l")
      // for the unit symbol, and ML Kit OCR passes it through verbatim.
      // Our regex only accepted Latin l/L, so Volume extraction — and
      // the price-per-liter-based reconcile fallback — both silently
      // returned null.
      test('accepts the typographic ℓ (U+2113) as the litre unit symbol',
          () {
        final result = parser.parse('SP95-E10 5.24 ℓ');
        expect(result.liters, closeTo(5.24, 0.01));
      });

      test('Super U receipt with ℓ extracts liters, not null (regression)',
          () {
        const receipt = '''
SUPER U
CHEMIN DU PORTROU
34810 POMEROLS
QUITTANCE COPIE
Date 19-04-2026 15:19:27
* Pompe 3      SP95-E10
  Volume         5.24 ℓ
  Prix     € 1.999/ℓ
  TOT TTC  € 10.47
* TVA 20.00 %    € 1.74
  Net            € 8.73
''';
        final result = parser.parse(receipt);
        expect(result.liters, closeTo(5.24, 0.01));
        expect(result.totalCost, closeTo(10.47, 0.01));
        expect(result.pricePerLiter, closeTo(1.999, 0.001));
        expect(result.brandLayout, 'super_u');
      });
    });

    group('brand layout dispatch', () {
      test('unknown brand falls through to generic extractor', () {
        final result = parser.parse('RANDOM STATION\n42.35 L\nTOTAL 58.42');
        expect(result.brandLayout, 'generic');
      });

      test('Super U text always dispatches to the super_u layout', () {
        final result = parser.parse('SUPER U\nVolume 10 L\nTOT TTC € 19.99');
        expect(result.brandLayout, 'super_u');
      });

      test('Carrefour text always dispatches to the carrefour layout', () {
        final result = parser.parse(
          'Carrefour market\nQuantite = 10 L\nMONTANT REEL : 19.99 EUR',
        );
        expect(result.brandLayout, 'carrefour');
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
