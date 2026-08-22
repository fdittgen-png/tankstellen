// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr/ocr_trace_package.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr/ocr_trace_recorder.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr/recognized_text_block.dart';

/// Coverage for the #2517 `OcrTraceRecorder` side-channel.
///
/// The receipt pipeline feeds this recorder through its typed sinks
/// (input / blocks / classify / pairing / confidence / crossCheck /
/// gateCheck / brand / reconcile / result); these tests drive the same
/// sinks directly — pure Dart, no platform channel — and assert the
/// built [OcrTracePackage] mirrors every recorded stage. (#3765
/// removed the pump-display pipeline that once drove parts of this
/// suite; the recorder itself is unchanged.)
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

  List<RecognizedTextBlock> sampleBlocks() => <RecognizedTextBlock>[
        block('Volume', l: 40, t: 100, r: 130, b: 130),
        block('23,30', l: 300, t: 100, r: 400, b: 130),
        block('TOT TTC', l: 40, t: 160, r: 150, b: 190),
        block('18,59', l: 300, t: 160, r: 400, b: 190),
      ];

  group('stage log', () {
    test('records stages in call order', () {
      final recorder = OcrTraceRecorder(kind: OcrTraceKind.receipt);
      recorder.blocks('flat', sampleBlocks());
      recorder.classify('Volume', 'label', field: 'volume');
      recorder.confidence(
          hasTotal: true,
          hasVolume: true,
          hasPrice: false,
          isConsistent: false,
          total: 0.6);
      recorder.result(totalCost: 18.59, liters: 23.30);

      expect(
          recorder.stages,
          containsAllInOrder([
            OcrTraceStage.mlkit,
            OcrTraceStage.classify,
            OcrTraceStage.confidence,
            OcrTraceStage.result,
          ]));
    });

    test('consecutive classify calls collapse into one stage entry', () {
      final recorder = OcrTraceRecorder(kind: OcrTraceKind.receipt);
      recorder.classify('Volume', 'label', field: 'volume');
      recorder.classify('23,30', 'value', value: 23.30, decimals: 2);
      recorder.classify('noise', 'noise');

      expect(recorder.stages.where((s) => s == OcrTraceStage.classify),
          hasLength(1));
      expect(recorder.build().classification, hasLength(3));
    });
  });

  group('build() mirrors the recorded chain', () {
    test('blocks carry text + geometry', () {
      final recorder = OcrTraceRecorder(kind: OcrTraceKind.receipt);
      recorder.blocks('Volume 23,30', sampleBlocks());
      final mlkit = recorder.build().mlkit!;
      expect(mlkit.flatText, 'Volume 23,30');
      expect(mlkit.blocks, hasLength(sampleBlocks().length));
      expect(mlkit.blocks.first.text, 'Volume');
      expect(mlkit.blocks.first.left, 40);
      expect(mlkit.blocks.first.bottom, 130);
    });

    test('pairing decisions log under the anchor stage (#3458)', () {
      final recorder = OcrTraceRecorder(kind: OcrTraceKind.receipt);
      recorder.pairing(const OcrTracePairing(
        field: 'volume',
        labelText: 'Volume',
        labelBox: [40, 100, 130, 130],
        valueText: '23,30',
        valueBox: [300, 100, 400, 130],
        rule: 'same-row',
      ));
      expect(recorder.stages, contains(OcrTraceStage.anchor));
      final pkg = recorder.build();
      expect(pkg.pairings, hasLength(1));
      expect(pkg.pairings.single.rule, 'same-row');
    });

    test('crossCheck records the derivation branch + computed value', () {
      final recorder = OcrTraceRecorder(kind: OcrTraceKind.receipt);
      recorder.crossCheck(
          total: 18.59,
          volume: 23.30,
          derivedPath: 'pricePerLitre',
          computed: 0.798);
      final cc = recorder.build().crossCheck!;
      expect(cc.derivedPath, 'pricePerLitre');
      expect(cc.computed, closeTo(0.798, 0.001));
      expect(cc.price, isNull, reason: 'price was not read — it is derived');
    });

    test('gate + confidence + result snapshot into the package', () {
      final recorder = OcrTraceRecorder(kind: OcrTraceKind.receipt);
      recorder.confidence(
          hasTotal: true,
          hasVolume: true,
          hasPrice: true,
          isConsistent: true,
          total: 1.0);
      recorder.gateCheck(
        checks: const [
          OcrTraceGateCheck(name: 'enough-fields', passed: true),
          OcrTraceGateCheck(name: 'identity', passed: true),
        ],
        reason: 'consistent',
        accepted: true,
        identityDelta: 0.01,
      );
      recorder.result(
          totalCost: 18.59,
          liters: 23.30,
          pricePerLiter: 0.798,
          confidence: 1.0,
          validated: true);

      final pkg = recorder.build();
      expect(pkg.confidence!.isConsistent, isTrue);
      expect(pkg.gate!.accepted, isTrue);
      expect(pkg.gate!.reason, 'consistent');
      expect(pkg.gate!.checks.map((c) => c.name),
          containsAll(['enough-fields', 'identity']));
      expect(pkg.result!.totalCost, closeTo(18.59, 0.001));
      expect(pkg.result!.validated, isTrue);
    });

    test('receipt brand + reconcile accumulate into one receipt section', () {
      final recorder = OcrTraceRecorder(kind: OcrTraceKind.receipt);
      recorder.brand('super_u', 'brand_layout');
      recorder.overrideField(
          field: 'liters', pattern: r'Vol\s+(\d+)', match: 'Vol 23', value: 23);
      recorder.reconcile(
          read: 18.59, derived: 18.59, predictedTotal: 18.59, delta: 0.0);
      final receipt = recorder.build().receipt!;
      expect(receipt.brand, 'super_u');
      expect(receipt.layout, 'brand_layout');
      expect(receipt.overrides, hasLength(1));
      expect(receipt.reconcile!.delta, 0.0);
    });

    test('an empty recorder builds a minimal package without sections', () {
      final pkg = OcrTraceRecorder(kind: OcrTraceKind.receipt).build();
      expect(pkg.mlkit, isNull);
      expect(pkg.gate, isNull);
      expect(pkg.result, isNull);
      expect(pkg.classification, isEmpty);
      expect(pkg.pairings, isEmpty);
    });
  });
}
