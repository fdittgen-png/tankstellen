// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/recognized_text_block.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';

/// #3458 — multi-locale spatial receipt fixtures.
///
/// Synthetic block sets with REALISTIC two-column receipt geometry (left
/// label column ~x 40-300, right value column ~x 600-960, ~60 px rows —
/// the proportions of the recorded FR field receipts), NOT echo fakes:
/// every expected number exists only inside a value block that the
/// parser must claim through row pairing, and every fixture carries a
/// VAT/Net trap line that must never win the total.
void main() {
  RecognizedTextBlock block(
    String text, {
    required double l,
    required double t,
    required double r,
    required double b,
  }) =>
      RecognizedTextBlock(
          text: text, box: OcrBox(left: l, top: t, right: r, bottom: b));

  const parser = ReceiptParser();

  group('#3458 — DE receipt (Menge / Preis / Summe + MwSt trap)', () {
    final blocks = <RecognizedTextBlock>[
      block('TANKSTELLE BERLIN', l: 60, t: 40, r: 640, b: 95),
      block('Super E10', l: 60, t: 520, r: 350, b: 575),
      block('Menge', l: 60, t: 600, r: 250, b: 652),
      block('38,20 L', l: 700, t: 596, r: 930, b: 650),
      block('Preis', l: 60, t: 660, r: 235, b: 712),
      block('1,759 EUR/l', l: 620, t: 656, r: 958, b: 710),
      block('Summe', l: 60, t: 720, r: 262, b: 774),
      block('67,19 EUR', l: 680, t: 718, r: 952, b: 772),
      block('MwSt 19,00 %', l: 60, t: 840, r: 430, b: 894),
      block('10,73 EUR', l: 690, t: 836, r: 950, b: 890),
      block('Netto', l: 60, t: 900, r: 240, b: 954),
      block('56,46 EUR', l: 688, t: 898, r: 950, b: 952),
    ];
    final text = blocks.map((b) => b.text).join('\n');

    test('reads the triple by row pairing, MwSt/Netto never the total', () {
      final r = parser.parseBlocks(blocks, text);
      expect(r.liters, closeTo(38.20, 0.001));
      expect(r.pricePerLiter, closeTo(1.759, 0.0001));
      expect(r.totalCost, closeTo(67.19, 0.001),
          reason: 'Summe wins — never the MwSt (10.73) or Netto (56.46) row');
      expect(r.derived, isEmpty);
      expect(r.validated, isTrue,
          reason: '38.20 × 1.759 = 67.19 over READ fields');
      expect(r.brandLayout, 'fuel_station');
    });
  });

  group('#3458 — IT receipt (Litri / Prezzo / Totale + IVA trap)', () {
    final blocks = <RecognizedTextBlock>[
      block('STAZIONE DI SERVIZIO', l: 50, t: 30, r: 700, b: 88),
      block('Benzina', l: 50, t: 500, r: 290, b: 556),
      block('Litri', l: 50, t: 580, r: 200, b: 634),
      block('32,51', l: 720, t: 576, r: 930, b: 632),
      block('Prezzo', l: 50, t: 640, r: 260, b: 696),
      // `/ℓ` mangled to `/1` — still a per-litre price.
      block('€ 1,839/1', l: 620, t: 638, r: 950, b: 694),
      block('Totale', l: 50, t: 700, r: 255, b: 756),
      block('€ 59,79', l: 700, t: 698, r: 946, b: 754),
      block('IVA 22,00 %', l: 50, t: 820, r: 390, b: 876),
      block('€ 10,78', l: 706, t: 818, r: 948, b: 874),
    ];
    final text = blocks.map((b) => b.text).join('\n');

    test('reads the triple, IVA never the total, mangled /1 suffix reads',
        () {
      final r = parser.parseBlocks(blocks, text);
      expect(r.liters, closeTo(32.51, 0.001));
      expect(r.pricePerLiter, closeTo(1.839, 0.0001));
      expect(r.totalCost, closeTo(59.79, 0.001),
          reason: 'Totale wins — never the IVA row (10.78)');
      expect(r.derived, isEmpty);
      expect(r.validated, isTrue);
    });
  });

  group('#3458 — ES receipt (Litros / Precio / Importe + IVA trap)', () {
    final blocks = <RecognizedTextBlock>[
      block('ESTACION DE SERVICIO', l: 55, t: 36, r: 720, b: 92),
      block('Litros', l: 55, t: 560, r: 240, b: 614),
      block('28,40', l: 730, t: 556, r: 936, b: 612),
      block('Precio', l: 55, t: 620, r: 250, b: 674),
      block('1,659 €/L', l: 640, t: 618, r: 950, b: 672),
      block('Importe', l: 55, t: 680, r: 280, b: 734),
      block('47,12 €', l: 710, t: 678, r: 944, b: 732),
      block('IVA 21,00 %', l: 55, t: 800, r: 400, b: 854),
      block('8,18 €', l: 730, t: 798, r: 940, b: 852),
    ];
    final text = blocks.map((b) => b.text).join('\n');

    test('reads the triple, IVA never the importe', () {
      final r = parser.parseBlocks(blocks, text);
      expect(r.liters, closeTo(28.40, 0.001));
      expect(r.pricePerLiter, closeTo(1.659, 0.0001));
      expect(r.totalCost, closeTo(47.12, 0.001));
      expect(r.derived, isEmpty);
      expect(r.validated, isTrue);
    });
  });

  group('#3458 — CZ receipt (Množství / Cena / Celkem, Kč ranges)', () {
    final blocks = <RecognizedTextBlock>[
      block('CERPACI STANICE', l: 48, t: 30, r: 620, b: 86),
      block('Natural 95', l: 48, t: 500, r: 360, b: 556),
      block('Množství', l: 48, t: 580, r: 320, b: 634),
      block('32,51 l', l: 720, t: 576, r: 930, b: 632),
      block('Cena', l: 48, t: 640, r: 200, b: 694),
      block('34,90 Kč/l', l: 620, t: 638, r: 952, b: 692),
      block('Celkem', l: 48, t: 700, r: 268, b: 754),
      block('1 134,60 Kč', l: 640, t: 698, r: 950, b: 752),
      block('DPH 21,00 %', l: 48, t: 820, r: 400, b: 874),
      block('196,90 Kč', l: 690, t: 818, r: 946, b: 872),
    ];
    final text = blocks.map((b) => b.text).join('\n');

    test('Kč selects CZK plausibility — 34.90/L is a VALID price here', () {
      final r = parser.parseBlocks(blocks, text);
      expect(r.pricePerLiter, closeTo(34.90, 0.001),
          reason: '34.90 Kč/L is plausible in CZK (absurd in EUR — the '
              'range table must be currency-aware)');
      expect(r.liters, closeTo(32.51, 0.001));
      expect(r.totalCost, closeTo(1134.60, 0.01),
          reason: 'Celkem (space-grouped thousands) wins — never the DPH row');
      expect(r.derived, isEmpty);
      expect(r.validated, isTrue,
          reason: '32.51 × 34.90 = 1134.60 over READ fields');
    });
  });
}
