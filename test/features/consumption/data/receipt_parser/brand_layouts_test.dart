import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser/brand_layouts.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser/receipt_parse_result.dart';

/// Splits a receipt body into the `lines` argument the per-brand layouts
/// expect (the real `ReceiptParser` produces both a flat `text` and a
/// `lines` list — the tests here mirror that split).
List<String> _lines(String text) =>
    text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

void main() {
  group('parseSuperU', () {
    test('brandLayout is "super_u"', () {
      const text = '''
SUPER U VERDUN
Volume    5.24 L
Prix €1.999/L
TOT TTC € 10.47
''';
      final result = parseSuperU(text, _lines(text));
      expect(result.brandLayout, 'super_u');
    });

    test('the specialised "TOT TTC" regex beats the generic total extractor',
        () {
      // Generic extractTotalCost would find "Sous-total € 100.00" first
      // (the `total` branch in its labelled regex), so 100.00 would win
      // if dispatch used the generic path. The Super U-specific "TOT TTC"
      // regex runs AHEAD of the generic extractor via `??`, and only
      // matches the 10.47 line — proving dispatch reached parseSuperU.
      const text = '''
SUPER U VERDUN
Volume    5.24 L
Prix €1.999/L
Sous-total € 100.00
TOT TTC € 10.47
''';
      final result = parseSuperU(text, _lines(text));
      expect(result.totalCost, 10.47);
      expect(result.liters, 5.24);
      expect(result.pricePerLiter, 1.999);
      expect(result.brandLayout, 'super_u');
    });

    test('falls back to generic extractTotalCost when TOT/TOTAL TTC is absent',
        () {
      const text = '''
SUPER U VERDUN
Volume    5.24 L
Prix €1.999/L
€ 10.47
''';
      final result = parseSuperU(text, _lines(text));
      // No "TOT TTC" or "TOTAL TTC" label; fallback finds the largest
      // non-unit-price € amount.
      expect(result.totalCost, 10.47);
      expect(result.brandLayout, 'super_u');
    });
  });

  group('parseCarrefour', () {
    test('brandLayout is "carrefour"', () {
      const text = '''
CARREFOUR MARKET
No pompe    = 6
Carburant   = SP95
Quantite    = 5.27
Prix unit.  = 2,028 EUR
MONTANT REEL : 10.69 EUR
''';
      final result = parseCarrefour(text, _lines(text));
      expect(result.brandLayout, 'carrefour');
    });

    test('Quantite / Montant reel / Prix unit. labels beat generic extractors',
        () {
      // To prove the Carrefour-specific regexes ran, use values that
      // would NOT be reachable from the generic extractors:
      //
      // - `Quantite = 5.27` (no "L" unit suffix) — the generic liters
      //   regex has a pattern that catches "Quantité ... 5,27" too, so
      //   values match in this case, but the Carrefour regex runs first.
      // - `MONTANT REEL : 10.69 EUR` with a larger decoy € amount
      //   elsewhere ("€ 45.00 FIDELITE") proves specialised dispatch:
      //   the generic total-cost fallback would pick 45.00 as "largest",
      //   the Carrefour-specific `montant\s*reel` regex picks 10.69.
      const text = '''
CARREFOUR MARKET
No pompe    = 6
Carburant   = SP95
Quantite    = 5.27
Prix unit.  = 2,028 EUR
MONTANT REEL : 10.69 EUR
FIDELITE € 45.00
''';
      final result = parseCarrefour(text, _lines(text));
      expect(result.liters, 5.27);
      expect(result.pricePerLiter, 2.028);
      expect(result.totalCost, 10.69);
      expect(result.brandLayout, 'carrefour');
    });

    test('falls back to generic extractors when Carrefour labels are absent',
        () {
      const text = '''
CARREFOUR EXPRESS
Volume 5.27 L
€ 2.028 /L
€ 10.69
''';
      final result = parseCarrefour(text, _lines(text));
      // No Quantite/Prix unit./MONTANT labels — every field comes from
      // the generic extractors via the `??` fallback arm.
      expect(result.liters, 5.27);
      expect(result.pricePerLiter, 2.028);
      expect(result.totalCost, 10.69);
      expect(result.brandLayout, 'carrefour');
    });
  });

  group('parseGeneric', () {
    test('brandLayout defaults to "generic" and all extractors populate', () {
      const text = '''
RANDOM FUEL STATION
Volume 42.35 L
Prix 1.899 €/L
TOTAL 80.40
19/04/2026
Diesel
''';
      final result = parseGeneric(text, _lines(text));
      expect(result.brandLayout, 'generic');
      expect(result.liters, 42.35);
      expect(result.pricePerLiter, 1.899);
      expect(result.totalCost, 80.40);
      expect(result.date, DateTime(2026, 4, 19));
      // extractFuelType resolves "Diesel" → FuelType.diesel.
      expect(result.fuelType, isNotNull);
    });

    test('returns empty-ish result when nothing matches', () {
      const text = 'HELLO WORLD';
      final result = parseGeneric(text, _lines(text));
      expect(result.brandLayout, 'generic');
      expect(result.liters, isNull);
      expect(result.totalCost, isNull);
      expect(result.pricePerLiter, isNull);
      expect(result.hasData, isFalse);
    });
  });

  group('reconcile', () {
    const epsilon = 0.001;

    test('(a) fills in missing liters when total + ppl are known', () {
      // 10.47 / 1.999 ≈ 5.2376... → rounded to 2 digits → 5.24.
      const r = ReceiptParseResult(
        totalCost: 10.47,
        pricePerLiter: 1.999,
      );
      final reconciled = reconcile(r);
      expect(reconciled.liters, closeTo(5.24, epsilon));
      expect(reconciled.totalCost, 10.47); // unchanged
      expect(reconciled.pricePerLiter, 1.999); // unchanged
    });

    test('(b) fills in missing total when liters + ppl are known', () {
      // 5.24 * 1.999 ≈ 10.47 (10.47476 → rounded to 2 digits → 10.47).
      const r = ReceiptParseResult(
        liters: 5.24,
        pricePerLiter: 1.999,
      );
      final reconciled = reconcile(r);
      expect(reconciled.totalCost, closeTo(10.47, epsilon));
      expect(reconciled.liters, 5.24); // unchanged
      expect(reconciled.pricePerLiter, 1.999); // unchanged
    });

    test('(c) fills in missing ppl when liters + total are known', () {
      // 10.47 / 5.24 ≈ 1.998 (1.99809... → rounded to 3 digits → 1.998).
      const r = ReceiptParseResult(
        liters: 5.24,
        totalCost: 10.47,
      );
      final reconciled = reconcile(r);
      expect(reconciled.pricePerLiter, closeTo(1.998, epsilon));
      expect(reconciled.liters, 5.24); // unchanged
      expect(reconciled.totalCost, 10.47); // unchanged
    });

    test('(d) when all 3 disagree by >15%, recomputes total from liters × ppl',
        () {
      // liters × ppl = 5.24 × 1.999 ≈ 10.47 → expected.
      // declared total = 1.999 (OCR grabbed unit price as total — 81%
      // off expected, well beyond the 15% window). Reconcile should
      // overwrite totalCost with 10.47.
      const r = ReceiptParseResult(
        liters: 5.24,
        pricePerLiter: 1.999,
        totalCost: 1.999,
      );
      final reconciled = reconcile(r);
      expect(reconciled.totalCost, closeTo(10.47, epsilon));
      expect(reconciled.liters, 5.24);
      expect(reconciled.pricePerLiter, 1.999);
    });

    test('(e) when all 3 agree within 15%, returns result unchanged', () {
      // 5.24 × 1.999 = 10.47476 → declared total 10.47 is within 0.1%.
      // reconcile should be a no-op.
      const r = ReceiptParseResult(
        liters: 5.24,
        pricePerLiter: 1.999,
        totalCost: 10.47,
      );
      final reconciled = reconcile(r);
      expect(reconciled.liters, 5.24);
      expect(reconciled.pricePerLiter, 1.999);
      expect(reconciled.totalCost, 10.47);
    });

    test('(f) when only 1 field is known, nothing is overwritten', () {
      const litersOnly = ReceiptParseResult(liters: 5.24);
      final rl = reconcile(litersOnly);
      expect(rl.liters, 5.24);
      expect(rl.totalCost, isNull);
      expect(rl.pricePerLiter, isNull);

      const totalOnly = ReceiptParseResult(totalCost: 10.47);
      final rt = reconcile(totalOnly);
      expect(rt.liters, isNull);
      expect(rt.totalCost, 10.47);
      expect(rt.pricePerLiter, isNull);

      const pplOnly = ReceiptParseResult(pricePerLiter: 1.999);
      final rp = reconcile(pplOnly);
      expect(rp.liters, isNull);
      expect(rp.totalCost, isNull);
      expect(rp.pricePerLiter, 1.999);
    });

    test('(g) when ppl == 0, the liters-fill branch does not divide-by-zero',
        () {
      // liters missing, total present, ppl == 0. The `ppl > 0` guard
      // in reconcile must skip the division and return the input
      // unchanged (no infinity, no NaN).
      const r = ReceiptParseResult(
        totalCost: 10.47,
        pricePerLiter: 0,
      );
      final reconciled = reconcile(r);
      expect(reconciled.liters, isNull);
      expect(reconciled.totalCost, 10.47);
      expect(reconciled.pricePerLiter, 0);
    });

    test('reconcile preserves stationName, date, fuelType, brandLayout', () {
      final date = DateTime(2026, 4, 19);
      final r = ReceiptParseResult(
        liters: 5.24,
        pricePerLiter: 1.999,
        date: date,
        stationName: 'SUPER U VERDUN',
        brandLayout: 'super_u',
      );
      final reconciled = reconcile(r);
      // totalCost filled in (branch b), non-numeric fields carry over.
      expect(reconciled.totalCost, closeTo(10.47, 0.001));
      expect(reconciled.date, date);
      expect(reconciled.stationName, 'SUPER U VERDUN');
      expect(reconciled.brandLayout, 'super_u');
    });
  });
}
