// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/consumption/data/ocr/recognized_text_block.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';

/// Label-anchored fuel-RECEIPT extraction — issue #2848.
///
/// ## Ground-truth source
///
/// A recorded FR fuel-receipt trace (2026-06-04). ML Kit read the receipt
/// fine, but the parser classified it `layout: generic` and extracted ONLY
/// `totalCost = 25.36` (no volume, no price, confidence 0, validated
/// false). The Volume / Prix (€/L) values sit in a RIGHT column,
/// row-aligned with their left-column labels — exactly the geometry the
/// pump-display path already solves but the receipt path didn't use.
///
/// ML Kit can't run in `flutter test`, so (as with the #2478 pump
/// fixtures) we hand-build the block list a real photo produced from ONLY
/// the fuel-relevant blocks in the trace. The card number, transaction /
/// edition IDs and the raw receipt image are deliberately NOT committed.
///
/// Real ML Kit blocks (text @ [left, top, right, bottom]):
///   "Pompe 2"     @ [34, 787, 306, 852]
///   "Volume"      @ [36, 856, 266, 909]  → "30.96 !"  @ [730, 823, 1007, 892]
///   "Prix"        @ [38, 922, 188, 973]  → "€ 0,819/" @ [650, 886, 993, 960]
///   "TOT TTC"     @ [42,1045, 313,1147]  → "€ 25,36"  @ [772,1011,1027,1153]
///   "TVA 20.00 %" @ [49,1288, 614,1348]  → "€ 4.2"    @ [788,1267,1029,1340]
///   "Net"         @ [48,1360, 162,1412]  → "€ 21.13"  @ [748,1338,1031,1404]
///
/// 30.96 × 0.819 = 25.36 ✓ — once all three read, the identity gate marks
/// the read validated.
void main() {
  // FR profile mirroring the shipped config (priceMin 0.5 / priceMax 4.0).
  const frProfile = OcrLocaleProfile(
    country: 'FR',
    currency: 'EUR',
    decimalSeparator: ',',
    priceMin: 0.5,
    priceMax: 4.0,
    volumeMax: 200.0,
    totalMax: 500.0,
  );

  RecognizedTextBlock block(
    String text, {
    required double l,
    required double t,
    required double r,
    required double b,
  }) =>
      RecognizedTextBlock(
          text: text, box: OcrBox(left: l, top: t, right: r, bottom: b));

  /// The fuel-relevant blocks from the recorded FR trace (sanitised — no
  /// card number, no transaction / edition IDs, no raw image).
  List<RecognizedTextBlock> frReceiptBlocks() => <RecognizedTextBlock>[
        block('Pompe 2', l: 34, t: 787, r: 306, b: 852),
        block('Volume', l: 36, t: 856, r: 266, b: 909),
        block('30.96 !', l: 730, t: 823, r: 1007, b: 892),
        block('Prix', l: 38, t: 922, r: 188, b: 973),
        block('€ 0,819/', l: 650, t: 886, r: 993, b: 960),
        block('TOT TTC', l: 42, t: 1045, r: 313, b: 1147),
        block('€ 25,36', l: 772, t: 1011, r: 1027, b: 1153),
        block('TVA 20.00 %', l: 49, t: 1288, r: 614, b: 1348),
        block('€ 4.2', l: 788, t: 1267, r: 1029, b: 1340),
        block('Net', l: 48, t: 1360, r: 162, b: 1412),
        block('€ 21.13', l: 748, t: 1338, r: 1031, b: 1404),
      ];

  /// Flat OCR text the same receipt produces — ML Kit emits a two-column
  /// receipt COLUMN-GROUPED (the whole left label column, then the whole
  /// right value column), NOT row-interleaved. That column-grouped order is
  /// exactly why master's flat-string parse couldn't row-align Volume/Prix
  /// to their values and read only the total.
  String frReceiptText() => const [
        // left column — labels, top to bottom
        'Pompe 2', 'Volume', 'Prix', 'TOT TTC', 'TVA 20.00 %', 'Net',
        // right column — values, top to bottom
        '30.96 !', '€ 0,819/', '€ 25,36', '€ 4.2', '€ 21.13',
      ].join('\n');

  const parser = ReceiptParser();

  group('#2848 — fuel-station receipt label-anchored read', () {
    test('reads Volume + Prix + TOT TTC by row alignment, validated', () {
      final r = parser.parseBlocks(
        frReceiptBlocks(),
        frReceiptText(),
        profile: frProfile,
      );

      expect(r.liters, closeTo(30.96, 0.001),
          reason: 'Volume → 30.96 L (trailing "!" OCR noise stripped)');
      expect(r.pricePerLiter, closeTo(0.819, 0.001),
          reason: 'Prix → 0.819 €/L (€ prefix + trailing "/" stripped, '
              'comma decimal)');
      expect(r.totalCost, closeTo(25.36, 0.001),
          reason: 'TOT TTC → 25.36 € (comma decimal)');
      expect(r.validated, isTrue,
          reason: '30.96 × 0.819 = 25.36 → identity gate accepts');
      expect(r.brandLayout, 'fuel_station');
      expect(r.derived, isEmpty,
          reason: 'all three read directly, nothing derived');
      expect(r.confidence, greaterThanOrEqualTo(0.9));
    });

    test('does NOT mistake TVA / Net rows for the transaction values', () {
      final r = parser.parseBlocks(
        frReceiptBlocks(),
        frReceiptText(),
        profile: frProfile,
      );
      // The TVA (4.2) and Net (21.13) rows must not leak into the total.
      expect(r.totalCost, closeTo(25.36, 0.001));
      expect(r.liters, closeTo(30.96, 0.001));
    });

    test('RED-on-master proof: the flat-string parse reads ONLY the total',
        () {
      // On master the receipt path runs `parse(text)` (flat string) and
      // grabs the biggest currency amount as the total but cannot bind
      // Volume / Prix — the exact #2848 failure this PR fixes.
      final flat = parser.parse(frReceiptText(), profile: frProfile);
      expect(flat.totalCost, isNotNull);
      expect(flat.liters, isNull,
          reason: 'flat string cannot row-align Volume → no litres');
      expect(flat.pricePerLiter, isNull,
          reason: 'flat string cannot row-align Prix → no €/L');
      expect(flat.validated, isFalse);
    });
  });
}
