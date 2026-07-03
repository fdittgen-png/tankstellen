// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_trace_package.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/ocr/recognized_text_block.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser/receipt_orchestrator.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser/receipt_value_token.dart';

/// #3458 — the honest gate + value tokenizer.
///
/// The field failure's third defect: the gate DERIVED `totalCost` from
/// `liters × pricePerLiter` and then "verified" the identity on the
/// number it had just computed — a tautology that stamped confidence 1.0
/// on a scrambled read. These tests pin the replacement rules:
/// consistency counts only over independently-READ fields, a derived
/// field never raises confidence, and out-of-range values are rejected
/// instead of accepted.
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

  group('#3458 — derived-field tautology is dead', () {
    // Volume + Prix rows only — no total anywhere on the paper.
    final blocks = <RecognizedTextBlock>[
      block('Volume', l: 51, t: 645, r: 267, b: 694),
      block('41.39', l: 692, t: 638, r: 876, b: 693),
      block('Prix', l: 50, t: 708, r: 192, b: 752),
      block('€ 0,899/?', l: 616, t: 700, r: 956, b: 758),
    ];
    final text = blocks.map((b) => b.text).join('\n');

    test('2 read → third derived, flagged, at REDUCED confidence', () {
      final r = parser.parseBlocks(blocks, text);
      expect(r.liters, closeTo(41.39, 0.001));
      expect(r.pricePerLiter, closeTo(0.899, 0.0001));
      expect(r.totalCost, closeTo(37.21, 0.001));
      expect(r.derived, {'totalCost'});
      expect(r.confidence, closeTo(0.6, 0.0001),
          reason: '0.3 × 2 read fields — the derived total contributes '
              'NOTHING, and the identity bonus needs 3 READ fields');
      expect(r.validationReason, 'partial',
          reason: 'the gate never ran the identity check on a value it '
              'derived itself');
    });
  });

  group('#3458 — VAT / Net rows never win the total', () {
    final blocks = <RecognizedTextBlock>[
      block('Volume', l: 51, t: 645, r: 267, b: 694),
      block('41.39', l: 692, t: 638, r: 876, b: 693),
      block('Prix', l: 50, t: 708, r: 192, b: 752),
      block('€ 0,899/?', l: 616, t: 700, r: 956, b: 758),
      // No total label on the paper — only the tax decomposition.
      block('TVA', l: 38, t: 1057, r: 140, b: 1103),
      block('20,00 %', l: 325, t: 1054, r: 569, b: 1116),
      block('€ 6.20', l: 736, t: 1060, r: 970, b: 1112),
      block('Net', l: 36, t: 1119, r: 137, b: 1166),
      block('€ 31.01', l: 697, t: 1118, r: 973, b: 1180),
    ];
    final text = blocks.map((b) => b.text).join('\n');

    test('total is derived from the read pair — not the VAT/Net amount',
        () {
      final r = parser.parseBlocks(blocks, text);
      expect(r.totalCost, closeTo(37.21, 0.001));
      expect(r.totalCost, isNot(closeTo(6.20, 0.001)));
      expect(r.totalCost, isNot(closeTo(31.01, 0.001)));
      expect(r.derived, {'totalCost'});
    });
  });

  group('#3458 — currency-aware range rejection', () {
    // The Prix row carries an absurd bare 41,39 (the master failure's
    // mis-assigned magnitude) — volume and total read fine.
    final blocks = <RecognizedTextBlock>[
      block('Volume', l: 51, t: 645, r: 267, b: 694),
      block('38,20', l: 692, t: 638, r: 876, b: 693),
      block('Prix', l: 50, t: 708, r: 192, b: 752),
      block('€ 41,39', l: 616, t: 700, r: 956, b: 758),
      block('TOT TTC', l: 52, t: 828, r: 304, b: 918),
      block('€ 67,19', l: 770, t: 820, r: 963, b: 928),
    ];
    final text = blocks.map((b) => b.text).join('\n');

    test('41.39 €/L is rejected, never assigned as the read price', () {
      final trace = OcrTraceRecorder(kind: OcrTraceKind.receipt);
      final r = parser.parseBlocks(blocks, text, trace: trace);
      expect(r.pricePerLiter, isNot(closeTo(41.39, 0.001)),
          reason: '41.39 €/L is absurd in EUR — currency-aware ranges '
              'must reject the assignment instead of accepting it');
      expect(r.pricePerLiter, closeTo(1.759, 0.001),
          reason: 'derived honestly from the two read fields');
      expect(r.derived, {'pricePerLiter'});
      expect(r.confidence, closeTo(0.6, 0.0001));

      final rejected = trace
          .build()
          .pairings
          .where((p) => p.rule == 'rejected-out-of-range')
          .toList();
      expect(rejected, hasLength(1));
      expect(rejected.first.field, 'unitPrice');
      expect(rejected.first.value, closeTo(41.39, 0.001));
    });

    test('nothing plausible read → rejected to the manual-entry path', () {
      final absurd = <RecognizedTextBlock>[
        block('Volume', l: 51, t: 645, r: 267, b: 694),
        block('412,39', l: 692, t: 638, r: 876, b: 693),
        block('Prix', l: 50, t: 708, r: 192, b: 752),
        block('41,39', l: 616, t: 700, r: 956, b: 758),
        block('TOT TTC', l: 52, t: 828, r: 304, b: 918),
        block('9876,54', l: 770, t: 820, r: 963, b: 928),
      ];
      final r = orchestrateReceiptParse(
        blocks: absurd,
        text: absurd.map((b) => b.text).join('\n'),
        lines: [for (final b in absurd) b.text],
      );
      expect(r.validated, isFalse);
      expect(r.validationReason, 'too-few');
      expect(r.liters, isNull);
      expect(r.pricePerLiter, isNull);
      expect(r.totalCost, isNull);
      expect(r.hasData, isFalse,
          reason: 'no silent accept — the caller keeps its existing '
              'manual-entry flow');
    });
  });

  group('#3458 — 3-read identity mismatch rejects, keeps prefill', () {
    final blocks = <RecognizedTextBlock>[
      block('Volume', l: 51, t: 645, r: 267, b: 694),
      block('41.39', l: 692, t: 638, r: 876, b: 693),
      block('Prix', l: 50, t: 708, r: 192, b: 752),
      block('€ 0,899/?', l: 616, t: 700, r: 956, b: 758),
      block('TOT TTC', l: 52, t: 828, r: 304, b: 918),
      block('€ 50,00', l: 770, t: 820, r: 963, b: 928),
    ];
    final text = blocks.map((b) => b.text).join('\n');

    test('validated false, no derivation, read candidates preserved', () {
      final r = parser.parseBlocks(blocks, text);
      expect(r.validated, isFalse);
      expect(r.validationReason, 'identity-mismatch');
      expect(r.derived, isEmpty);
      expect(r.confidence, closeTo(0.9, 0.0001),
          reason: '3 read fields, NO consistency bonus');
      // The read values stay as assisted-manual-entry prefill candidates.
      expect(r.liters, closeTo(41.39, 0.001));
      expect(r.pricePerLiter, closeTo(0.899, 0.0001));
      expect(r.totalCost, closeTo(50.00, 0.001));
    });
  });

  group('#3458 — unit-suffix price detection (mangled /ℓ)', () {
    for (final suffix in const ['/?', '/l', '/1', '/L', '/']) {
      test('"€ 0,899$suffix" parses as a per-litre price', () {
        final token = parseReceiptValueToken(block('€ 0,899$suffix',
            l: 0, t: 0, r: 100, b: 20));
        expect(token, isNotNull);
        expect(token!.perLiter, isTrue);
        expect(token.value, closeTo(0.899, 0.0001));
        expect(token.currencyCode, 'EUR');
      });
    }

    test('percentages, dates, IDs and prose never tokenize', () {
      for (final text in const [
        '20,00 %',
        '02-07-2026 19:27:29',
        'Date 02-07-2026 19;29:12',
        'Pompe 2',
        '321976',
        '************D014',
      ]) {
        expect(parseReceiptValueToken(block(text, l: 0, t: 0, r: 100, b: 20)),
            isNull,
            reason: '"$text" must not become a value candidate');
      }
    });
  });
}
