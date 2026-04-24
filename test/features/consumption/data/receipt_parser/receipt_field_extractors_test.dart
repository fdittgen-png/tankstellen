import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser/receipt_field_extractors.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

void main() {
  group('extractFuelType', () {
    test('E85 via "E85" word boundary', () {
      expect(extractFuelType('42,35 X E85\nTOTAL 35,00 EUR'), FuelType.e85);
    });

    test('E85 via "SP95-E85" compound', () {
      expect(extractFuelType('Produit: SP95-E85'), FuelType.e85);
    });

    test('E85 via "bioéthanol" French label', () {
      expect(extractFuelType('Bioéthanol 35,00 L'), FuelType.e85);
    });

    test('E85 via "bio ethanol" (no accent, space)', () {
      expect(extractFuelType('BIO ETHANOL 35,00'), FuelType.e85);
    });

    test('E10 compound — SP95E10 without separator', () {
      // TotalEnergies emits SP95E10 with no separator.
      expect(
        extractFuelType('5,00 x SP95E10\nTOTAL 9,95 EUR'),
        FuelType.e10,
      );
    });

    test('E10 compound — SP95-E10 with hyphen', () {
      expect(extractFuelType('Produit: SP95-E10'), FuelType.e10);
    });

    test('E10 compound — SP95 E10 with space', () {
      expect(extractFuelType('Produit: SP95 E10'), FuelType.e10);
    });

    test('E10 standalone — "E10" word boundary', () {
      expect(extractFuelType('Volume 42,35 L\nE10\nTOT 58,42'), FuelType.e10);
    });

    test('E10 — "Super E10" German-style label', () {
      expect(extractFuelType('Super E10\n42,35 L'), FuelType.e10);
    });

    test('E10 beats E5 when both named (cross-reference table)', () {
      // Receipts that print a cross-reference table listing both codes
      // must still classify as E10 — the priority cascade puts E10
      // above E5.
      const text = 'Codes produits:\n- SP95 (E5)\n- SP95-E10\n'
          'Pompe: SP95-E10\nVolume 42,35 L';
      expect(extractFuelType(text), FuelType.e10);
    });

    test('E5 — SP95E5 compound', () {
      expect(
        extractFuelType('5,00 x SP95E5\nTOTAL 9,95 EUR'),
        FuelType.e5,
      );
    });

    test('E5 — "E5" word boundary', () {
      expect(extractFuelType('Volume 42,35 L\nE5\nTOT 58,42'), FuelType.e5);
    });

    test('E5 — SP95 alone (no E10 suffix)', () {
      // `sp95(?!\s*-?\s*e\s*10)` — SP95 without E10 suffix means E5.
      expect(extractFuelType('Pompe: SP95\n42,35 L'), FuelType.e5);
    });

    test('E5 — "Super E5"', () {
      expect(extractFuelType('Super E5\n42,35 L'), FuelType.e5);
    });

    test('E98 via "SP98"', () {
      expect(extractFuelType('SP98\n42,35 L'), FuelType.e98);
    });

    test('E98 via "E98" word boundary', () {
      expect(extractFuelType('Volume 42,35 L\nE98\nTOT 58,42'), FuelType.e98);
    });

    test('E98 via "Super 98"', () {
      expect(extractFuelType('SUPER 98\n42,35 L'), FuelType.e98);
    });

    test('dieselPremium — "diesel premium"', () {
      expect(
        extractFuelType('DIESEL PREMIUM\n42,35 L'),
        FuelType.dieselPremium,
      );
    });

    test('dieselPremium — "gazole premium" French', () {
      expect(
        extractFuelType('Gazole Premium\n42,35 L'),
        FuelType.dieselPremium,
      );
    });

    test('dieselPremium beats plain diesel on compound labels', () {
      // "Premium Diesel" on Shell V-Power Diesel receipts.
      expect(
        extractFuelType('PREMIUM DIESEL 42,35 L'),
        FuelType.dieselPremium,
      );
    });

    test('diesel — plain "diesel" label', () {
      expect(extractFuelType('DIESEL\n42,35 L'), FuelType.diesel);
    });

    test('diesel — French "Gazole"', () {
      expect(extractFuelType('GAZOLE\n42,35 L'), FuelType.diesel);
    });

    test('diesel — "B7" biodiesel code', () {
      expect(extractFuelType('B7\n42,35 L'), FuelType.diesel);
    });

    test('LPG via "GPL" French', () {
      expect(extractFuelType('GPL\n35,00 L\nTOT 25,00'), FuelType.lpg);
    });

    test('LPG via "LPG" English', () {
      expect(extractFuelType('LPG\n35,00 L'), FuelType.lpg);
    });

    test('CNG via "GNV" French', () {
      expect(extractFuelType('GNV\n12,50 kg'), FuelType.cng);
    });

    test('CNG via "CNG" English', () {
      expect(extractFuelType('CNG\n12,50 kg'), FuelType.cng);
    });

    test('returns null for text with no fuel code', () {
      expect(extractFuelType('Thank you for shopping\nGoodbye'), isNull);
    });

    test('returns null for empty string', () {
      expect(extractFuelType(''), isNull);
    });

    test('case-insensitive matching', () {
      expect(extractFuelType('gazole 42,35 l'), FuelType.diesel);
      expect(extractFuelType('GAZOLE 42,35 L'), FuelType.diesel);
    });
  });

  group('extractLiters', () {
    test('decimal-dot format "42.35 L"', () {
      expect(extractLiters('Volume 42.35 L'), closeTo(42.35, 0.001));
    });

    test('decimal-comma format "42,35 l"', () {
      expect(extractLiters('Volume 42,35 l'), closeTo(42.35, 0.001));
    });

    test('no space "5.24L"', () {
      expect(extractLiters('5.24L'), closeTo(5.24, 0.001));
    });

    test('suffix "litres" (French)', () {
      expect(extractLiters('42,35 litres'), closeTo(42.35, 0.001));
    });

    test('suffix "litre" (singular French)', () {
      expect(extractLiters('1,00 litre'), closeTo(1.00, 0.001));
    });

    test('U+2113 script ℓ symbol', () {
      // French thermal printers emit ℓ verbatim — Latin [lL] misses it.
      expect(extractLiters('5,24 ℓ'), closeTo(5.24, 0.001));
    });

    test('label "VOLUME : 42.35"', () {
      expect(extractLiters('VOLUME : 42.35'), closeTo(42.35, 0.001));
    });

    test('label "Volume: 42,35"', () {
      expect(extractLiters('Volume: 42,35'), closeTo(42.35, 0.001));
    });

    test('label "Quantité = 5.27"', () {
      expect(extractLiters('Quantité = 5.27'), closeTo(5.27, 0.001));
    });

    test('French line item "5,00 x SP95E5"', () {
      expect(extractLiters('5,00 x SP95E5'), closeTo(5.00, 0.001));
    });

    test('French line item "42,50 X GAZOLE" (uppercase X)', () {
      expect(extractLiters('42,50 X GAZOLE'), closeTo(42.50, 0.001));
    });

    test('French line item "10,00 × SP98" (Unicode multiplication sign)', () {
      expect(extractLiters('10,00 × SP98'), closeTo(10.00, 0.001));
    });

    test('French line item "10,00 x gpl"', () {
      expect(extractLiters('10,00 x gpl'), closeTo(10.00, 0.001));
    });

    test('filters out "TVA 20.00 %" (no L/volume anchor)', () {
      // "20.00" from "TVA 20.00 %" has no litre unit or volume label
      // and no `x FUELCODE` — must not match.
      expect(extractLiters('TVA 20.00 %'), isNull);
    });

    test('filters pathological values outside 0.1–300 L range', () {
      // "0.05 L" below 0.1 threshold.
      expect(extractLiters('volume 0.05 L'), isNull);
    });

    test('multi-line realistic Super U fragment', () {
      const text = 'SUPER U VERDUN\n'
          'Volume    5.24 L\n'
          'PU        1.999 €/L\n'
          'TOT TTC € 10.47';
      expect(extractLiters(text), closeTo(5.24, 0.001));
    });

    test('returns null when no volume anywhere', () {
      expect(extractLiters('THANK YOU\nGOODBYE'), isNull);
    });

    test('returns null for empty string', () {
      expect(extractLiters(''), isNull);
    });
  });

  group('extractTotalCost', () {
    test('labelled "TOTAL 58.42"', () {
      expect(extractTotalCost('TOTAL 58.42'), closeTo(58.42, 0.001));
    });

    test('labelled "MONTANT 58,42 EUR"', () {
      expect(
        extractTotalCost('MONTANT 58,42 EUR'),
        closeTo(58.42, 0.001),
      );
    });

    test('labelled "TOT TTC 10.47"', () {
      expect(extractTotalCost('TOT TTC 10.47'), closeTo(10.47, 0.001));
    });

    test('labelled "MONTANT REEL : 10.69"', () {
      expect(
        extractTotalCost('MONTANT REEL : 10.69'),
        closeTo(10.69, 0.001),
      );
    });

    test('labelled "MONTANT RÉEL = 10.69" (accented)', () {
      expect(
        extractTotalCost('MONTANT RÉEL = 10.69'),
        closeTo(10.69, 0.001),
      );
    });

    test('labelled "Gesamt: 58,42" (German)', () {
      expect(
        extractTotalCost('Gesamt: 58,42'),
        closeTo(58.42, 0.001),
      );
    });

    test('labelled "Betrag 58,42"', () {
      expect(
        extractTotalCost('Betrag 58,42'),
        closeTo(58.42, 0.001),
      );
    });

    test('labelled "Summe 58,42"', () {
      expect(
        extractTotalCost('Summe 58,42'),
        closeTo(58.42, 0.001),
      );
    });

    test('fallback — "€ 58.42" without label picks the amount', () {
      expect(extractTotalCost('€ 58.42'), closeTo(58.42, 0.001));
    });

    test('fallback — picks largest amount, ignores /L prices', () {
      // "€ 1.999/L" is unit price (has /L suffix → skipped), "€ 10.47"
      // should win.
      const text = '€ 1.999/L\n€ 10.47';
      expect(extractTotalCost(text), closeTo(10.47, 0.001));
    });

    test(
      'fallback — skips 3-decimal amounts <5 € (fuel price, not total)',
      () {
        // `1,990 €` is 3-decimal → treated as unit price, skipped.
        // `9,95 €` is 2-decimal → accepted as total.
        const text = '1,990 €\n9,95 €';
        expect(extractTotalCost(text), closeTo(9.95, 0.001));
      },
    );

    test('fallback — filters values under 1 € and over 10000 €', () {
      // 0.50 € and 20000 € would never be valid totals — skipped.
      expect(extractTotalCost('€ 0.50'), isNull);
      expect(extractTotalCost('€ 20000.00'), isNull);
    });

    test('prefers labelled over fallback', () {
      // Both a labelled TOTAL and a bare €-amount in text. Labelled wins.
      const text = '€ 999.99\nTOTAL 10.47';
      expect(extractTotalCost(text), closeTo(10.47, 0.001));
    });

    test('realistic Super U receipt', () {
      const text = 'SUPER U VERDUN\n'
          'Volume    5.24 L\n'
          'PU        1.999 €/L\n'
          'TOT TTC € 10.47';
      expect(extractTotalCost(text), closeTo(10.47, 0.001));
    });

    test('returns null for empty string', () {
      expect(extractTotalCost(''), isNull);
    });

    test('returns null when no price anywhere', () {
      expect(extractTotalCost('THANK YOU'), isNull);
    });
  });

  group('extractPricePerLiter', () {
    test('"1.899 €/L" dot decimal', () {
      expect(
        extractPricePerLiter('1.899 €/L'),
        closeTo(1.899, 0.001),
      );
    });

    test('"1,899 EUR/L" comma decimal', () {
      expect(
        extractPricePerLiter('1,899 EUR/L'),
        closeTo(1.899, 0.001),
      );
    });

    test('"€ 1.999/L" currency-first', () {
      expect(
        extractPricePerLiter('€ 1.999/L'),
        closeTo(1.999, 0.001),
      );
    });

    test('"EUR 1,999/L" currency-first comma', () {
      expect(
        extractPricePerLiter('EUR 1,999/L'),
        closeTo(1.999, 0.001),
      );
    });

    test('"1.999 €/ℓ" U+2113 script symbol', () {
      expect(
        extractPricePerLiter('1.999 €/ℓ'),
        closeTo(1.999, 0.001),
      );
    });

    test('label "PU: 1,899"', () {
      expect(
        extractPricePerLiter('PU: 1,899'),
        closeTo(1.899, 0.001),
      );
    });

    test('label "PRIX/L 1.899"', () {
      expect(
        extractPricePerLiter('PRIX/L 1.899'),
        closeTo(1.899, 0.001),
      );
    });

    test('label "Prix unit. = 2,028 EUR"', () {
      expect(
        extractPricePerLiter('Prix unit. = 2,028 EUR'),
        closeTo(2.028, 0.001),
      );
    });

    test('label "Prix unit 2,028"', () {
      expect(
        extractPricePerLiter('Prix unit 2,028'),
        closeTo(2.028, 0.001),
      );
    });

    test('label "Literpreis: 1.799" German', () {
      expect(
        extractPricePerLiter('Literpreis: 1.799'),
        closeTo(1.799, 0.001),
      );
    });

    test('label "Preis je Liter 1,799" German', () {
      expect(
        extractPricePerLiter('Preis je Liter 1,799'),
        closeTo(1.799, 0.001),
      );
    });

    test('label "Preis/L 1,799" German', () {
      expect(
        extractPricePerLiter('Preis/L 1,799'),
        closeTo(1.799, 0.001),
      );
    });

    test('bare 3-decimal euro fallback "1,990 €" (#801)', () {
      // TotalEnergies / independent French receipts: unit price printed
      // as bare `1,990 €` below the QTY x FUELCODE line.
      expect(
        extractPricePerLiter('1,990 €'),
        closeTo(1.990, 0.001),
      );
    });

    test('bare 3-decimal dot fallback "1.990 EUR"', () {
      expect(
        extractPricePerLiter('1.990 EUR'),
        closeTo(1.990, 0.001),
      );
    });

    test('fallback rejects 3-decimal amount outside 0.5–3.0 €/L range', () {
      // 4,500 € is outside plausible fuel-price range.
      expect(extractPricePerLiter('4,500 €'), isNull);
    });

    test('fallback does not grab 3-decimal amount followed by /L', () {
      // When followed by /L the *labelled* pattern already handled it.
      // The bare-fuel-price fallback must not double-match.
      final result = extractPricePerLiter('1,990 €/L');
      expect(result, closeTo(1.990, 0.001));
    });

    test('realistic Super U receipt', () {
      const text = 'SUPER U VERDUN\n'
          'Volume    5.24 L\n'
          'PU        1.999 €/L\n'
          'TOT TTC € 10.47';
      expect(extractPricePerLiter(text), closeTo(1.999, 0.001));
    });

    test('returns null when no price per litre', () {
      expect(extractPricePerLiter('THANK YOU'), isNull);
    });

    test('returns null for empty string', () {
      expect(extractPricePerLiter(''), isNull);
    });
  });

  group('extractDate', () {
    test('DD/MM/YYYY slash format', () {
      expect(extractDate('Date: 19/04/2026'), DateTime(2026, 4, 19));
    });

    test('DD.MM.YYYY dot format (German)', () {
      expect(extractDate('19.04.2026'), DateTime(2026, 4, 19));
    });

    test('DD-MM-YYYY dash format', () {
      expect(extractDate('19-04-2026'), DateTime(2026, 4, 19));
    });

    test('DD/MM/YY 2-digit year assumes 20xx', () {
      // Carrefour receipts use 2-digit year.
      expect(extractDate('19/04/26'), DateTime(2026, 4, 19));
    });

    test('DD.MM.YY 2-digit year dot format', () {
      expect(extractDate('19.04.26'), DateTime(2026, 4, 19));
    });

    test('prefers 4-digit year match over 2-digit on same line', () {
      // When both appear, the 4-digit regex runs first.
      expect(
        extractDate('Due: 19/04/26\nIssued: 20/04/2026'),
        DateTime(2026, 4, 20),
      );
    });

    test('skips phone-number-like DD.MM.YY fragments with day > 31', () {
      // Phone numbers can read as dates: "67.77.29.10" — 67 is invalid
      // month, 77 is invalid day, so calendar sanity check must reject.
      expect(extractDate('Tel: 04.67.77.29.10'), isNull);
    });

    test('continues past invalid day/month until valid date found', () {
      // "04.67.77.29" fails (67 > 12 as month, 77 > 31 as day). But
      // there's also an embedded valid DD.MM.YY "19.04.26".
      expect(
        extractDate('Tel: 04.67.77.29.10\nDate 19.04.26'),
        DateTime(2026, 4, 19),
      );
    });

    test('returns null for empty string', () {
      expect(extractDate(''), isNull);
    });

    test('returns null when no date anywhere', () {
      expect(extractDate('THANK YOU'), isNull);
    });

    test('realistic Carrefour receipt fragment', () {
      const text = 'CARREFOUR MARKET\n'
          'Caisse 03  19/04/26 14:35\n'
          'Volume 5.24 L\n'
          'TOTAL 10.47';
      expect(extractDate(text), DateTime(2026, 4, 19));
    });
  });

  group('buildDate', () {
    test('valid date returns DateTime', () {
      expect(buildDate('19', '04', '2026'), DateTime(2026, 4, 19));
    });

    test('invalid month (13) returns null', () {
      expect(buildDate('19', '13', '2026'), isNull);
    });

    test('invalid month (0) returns null', () {
      expect(buildDate('19', '0', '2026'), isNull);
    });

    test('invalid day (32) returns null', () {
      expect(buildDate('32', '04', '2026'), isNull);
    });

    test('invalid day (0) returns null', () {
      expect(buildDate('0', '04', '2026'), isNull);
    });

    test('non-numeric input is caught and returns null', () {
      // FormatException from int.parse must be caught → null.
      expect(buildDate('XX', '04', '2026'), isNull);
    });

    test('leap day 29/02 in leap year — DateTime normalizes', () {
      expect(buildDate('29', '02', '2024'), DateTime(2024, 2, 29));
    });
  });

  group('matchFirst', () {
    test('returns first successful captured group', () {
      final patterns = [
        RegExp(r'never-matches-(\d+)'),
        RegExp(r'second-(\d+\.\d+)'),
        RegExp(r'third-(\d+)'),
      ];
      expect(matchFirst('second-42.50 third-99', patterns), 42.50);
    });

    test('returns null when no pattern matches', () {
      final patterns = [RegExp(r'nope-(\d+)')];
      expect(matchFirst('nothing here', patterns), isNull);
    });

    test('returns null for empty pattern list', () {
      expect(matchFirst('anything', const []), isNull);
    });

    test('handles comma-decimal via parseDecimal', () {
      final patterns = [RegExp(r'val=(\d+,\d+)')];
      expect(matchFirst('val=3,14', patterns), closeTo(3.14, 0.0001));
    });
  });

  group('parseDecimal', () {
    test('dot-decimal "42.35"', () {
      expect(parseDecimal('42.35'), closeTo(42.35, 0.0001));
    });

    test('comma-decimal "42,35"', () {
      expect(parseDecimal('42,35'), closeTo(42.35, 0.0001));
    });

    test('integer string "42"', () {
      expect(parseDecimal('42'), 42.0);
    });

    test('returns null for non-numeric input', () {
      expect(parseDecimal('abc'), isNull);
    });

    test('returns null for empty string', () {
      expect(parseDecimal(''), isNull);
    });

    test('handles negative numbers', () {
      expect(parseDecimal('-1,5'), closeTo(-1.5, 0.0001));
    });
  });

  group('decimalDigitCount', () {
    test('returns 0 for integer string', () {
      expect(decimalDigitCount('42'), 0);
    });

    test('returns 2 for "58.42"', () {
      expect(decimalDigitCount('58.42'), 2);
    });

    test('returns 3 for "1.999"', () {
      expect(decimalDigitCount('1.999'), 3);
    });

    test('returns 3 for "1,990" (comma separator)', () {
      expect(decimalDigitCount('1,990'), 3);
    });

    test('returns 2 for comma-separated "9,95"', () {
      expect(decimalDigitCount('9,95'), 2);
    });

    test('returns 0 for empty string', () {
      expect(decimalDigitCount(''), 0);
    });

    test('uses LAST separator when both "." and "," are present', () {
      // European thousand-separator format "1.234,56" — the last
      // separator is the decimal point.
      expect(decimalDigitCount('1.234,56'), 2);
    });
  });
}
