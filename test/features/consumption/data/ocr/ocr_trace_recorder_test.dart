// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/label_anchored_extractor.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_display_orchestrator.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_validation_gate.dart';
import 'package:tankstellen/features/consumption/data/ocr/recognized_text_block.dart';

/// Coverage for the #2517 `OcrTraceRecorder` side-channel.
///
/// ML Kit can't run in `flutter test`, so (exactly as the label-anchored
/// extractor's own suite does) we replay the FR Tokheim sample-photo block
/// list — pure Dart, no platform channel — through `extractByLabelAnchor`
/// and `orchestratePumpDisplayParse` with a real recorder, then assert the
/// recorder captured every reasoning stage. The HARD invariant is the last
/// group: passing `trace: null` must produce a result IDENTICAL to before,
/// so production (which always passes null) is byte-for-byte unchanged.
void main() {
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

  // Upright FR Tokheim readout: PRIX 18,59 / VOLUME 23,30 / PRIX DU LITRE
  // 0,798, each label above its value, plus pollution blocks to ignore.
  List<RecognizedTextBlock> samplePhotoBlocks() => <RecognizedTextBlock>[
        block('PRIX', l: 40, t: 100, r: 130, b: 130),
        block('18,59', l: 40, t: 140, r: 200, b: 185),
        block('VOLUME', l: 40, t: 220, r: 170, b: 250),
        block('23,30', l: 40, t: 260, r: 200, b: 305),
        block('PRIX DU LITRE', l: 40, t: 340, r: 230, b: 370),
        block('0,798', l: 40, t: 380, r: 180, b: 420),
        block('Note du service de la Métrologie', l: 400, t: 20, r: 720, b: 50),
        block('TOKHEIM', l: 300, t: 600, r: 460, b: 660),
        block('Vmin = 5L', l: 700, t: 20, r: 820, b: 55),
      ];

  group('extractByLabelAnchor records the full reasoning chain', () {
    test('classify / anchor candidates / cross-check stages all fire', () {
      final recorder = OcrTraceRecorder();
      extractByLabelAnchor(samplePhotoBlocks(),
          profile: frProfile, trace: recorder);

      expect(recorder.stages, contains(OcrTraceStage.classify));
      expect(recorder.stages, contains(OcrTraceStage.anchor));
      expect(recorder.stages, contains(OcrTraceStage.crossCheck));

      final pkg = recorder.build();
      // Every block is classified, with the three labels and three values.
      expect(pkg.classification, hasLength(samplePhotoBlocks().length));
      final labels =
          pkg.classification.where((c) => c.kind == 'label').toList();
      final numerics =
          pkg.classification.where((c) => c.kind == 'numeric').toList();
      final noise =
          pkg.classification.where((c) => c.kind == 'noise').toList();
      expect(labels, hasLength(3));
      expect(numerics, hasLength(3));
      expect(noise.map((c) => c.text), contains('TOKHEIM'));
      // PRIX DU LITRE classified as the unit-price label (heaviest weight).
      final ppl = labels.firstWhere((c) => c.text == 'PRIX DU LITRE');
      expect(ppl.field, 'pricePerLiter');
      expect(ppl.weight, 30);
    });

    test('anchor candidates carry every leftover numeric + a single chosen',
        () {
      final recorder = OcrTraceRecorder();
      extractByLabelAnchor(samplePhotoBlocks(),
          profile: frProfile, trace: recorder);
      final pkg = recorder.build();

      expect(pkg.anchors, isNotEmpty);
      // The heaviest label (PRIX DU LITRE) anchors first; among its
      // candidates exactly one is flagged chosen.
      final pplAnchors =
          pkg.anchors.where((a) => a.labelField == 'pricePerLiter').toList();
      expect(pplAnchors, isNotEmpty);
      expect(pplAnchors.where((a) => a.chosen), hasLength(1));
      // The chosen candidate is the geometrically nearest (the 0.798 value).
      final chosen = pplAnchors.firstWhere((a) => a.chosen);
      expect(chosen.numericValue, closeTo(0.798, 0.001));
      // Distances are recorded for ranking.
      expect(pplAnchors.every((a) => a.sqDistance >= 0), isTrue);
    });

    test('cross-check derives the dropped unit price + records the path', () {
      final recorder = OcrTraceRecorder();
      final blocks = samplePhotoBlocks()
          .where((b) => b.text != '0,798' && b.text != 'PRIX DU LITRE')
          .toList();
      extractByLabelAnchor(blocks, profile: frProfile, trace: recorder);
      final cc = recorder.build().crossCheck!;
      expect(cc.derivedPath, 'pricePerLitre');
      expect(cc.computed, closeTo(0.798, 0.001));
      expect(cc.price, isNull, reason: 'price was not read — it is derived');
    });

    test('magnitude fallback records each bucket decision', () {
      final recorder = OcrTraceRecorder();
      // Three bare numbers, no labels → all bound by magnitude fallback.
      final blocks = <RecognizedTextBlock>[
        block('18,59', l: 40, t: 140, r: 200, b: 185),
        block('23,30', l: 40, t: 260, r: 200, b: 305),
        block('0,798', l: 40, t: 380, r: 180, b: 420),
      ];
      extractByLabelAnchor(blocks, profile: frProfile, trace: recorder);
      final fb = recorder.build().magnitudeFallback;
      expect(recorder.stages, contains(OcrTraceStage.fallback));
      expect(fb.map((f) => f.field), containsAll(['pricePerLiter']));
      expect(fb.every((f) => f.reason.isNotEmpty), isTrue);
    });
  });

  group('orchestrator records confidence + gate + result', () {
    test('per-component confidence, ordered gate checks, and final read', () {
      final recorder = OcrTraceRecorder();
      orchestratePumpDisplayParse(
        blocks: samplePhotoBlocks(),
        text: '',
        profile: frProfile,
        gate: const PumpValidationGate(),
        trace: recorder,
      );
      final pkg = recorder.build();

      expect(recorder.stages, contains(OcrTraceStage.confidence));
      expect(recorder.stages, contains(OcrTraceStage.gate));
      expect(recorder.stages, contains(OcrTraceStage.result));

      expect(pkg.confidence!.hasTotal, isTrue);
      expect(pkg.confidence!.hasVolume, isTrue);
      expect(pkg.confidence!.hasPrice, isTrue);
      expect(pkg.confidence!.isConsistent, isTrue);

      // The ordered gate checks ran through to the identity check, accepted.
      expect(pkg.gate!.accepted, isTrue);
      expect(pkg.gate!.reason, 'consistent');
      expect(pkg.gate!.checks.map((c) => c.name),
          containsAll(['enough-fields', 'confidence', 'identity']));
      expect(pkg.gate!.checks.every((c) => c.passed), isTrue);

      // The final read mirrors the validated triple, nothing derived.
      expect(pkg.result!.totalCost, closeTo(18.59, 0.001));
      expect(pkg.result!.liters, closeTo(23.30, 0.001));
      expect(pkg.result!.pricePerLiter, closeTo(0.798, 0.001));
      expect(pkg.result!.derived, isEmpty);
      expect(pkg.result!.validated, isTrue);
    });

    test('an out-of-range price records a failing gate check + reason', () {
      final recorder = OcrTraceRecorder();
      // A mis-decoded 7,98 €/L anchors but fails the FR price range.
      final blocks = <RecognizedTextBlock>[
        block('PRIX', l: 40, t: 100, r: 130, b: 130),
        block('18,59', l: 40, t: 140, r: 200, b: 185),
        block('VOLUME', l: 40, t: 220, r: 170, b: 250),
        block('23,30', l: 40, t: 260, r: 200, b: 305),
        block('PRIX DU LITRE', l: 40, t: 340, r: 230, b: 370),
        block('7,980', l: 40, t: 380, r: 180, b: 420),
      ];
      orchestratePumpDisplayParse(
        blocks: blocks,
        text: '',
        profile: frProfile,
        trace: recorder,
      );
      final gate = recorder.build().gate!;
      expect(gate.accepted, isFalse);
      expect(gate.reason, 'price-out-of-range');
      final priceCheck =
          gate.checks.firstWhere((c) => c.name == 'price-in-range');
      expect(priceCheck.passed, isFalse);
    });
  });

  group('HARD: the null-recorder path is byte-for-byte unchanged', () {
    test('extractByLabelAnchor produces the identical result with/without trace',
        () {
      final withoutTrace =
          extractByLabelAnchor(samplePhotoBlocks(), profile: frProfile);
      final withTrace = extractByLabelAnchor(samplePhotoBlocks(),
          profile: frProfile, trace: OcrTraceRecorder());

      expect(withTrace.totalCost, withoutTrace.totalCost);
      expect(withTrace.liters, withoutTrace.liters);
      expect(withTrace.pricePerLiter, withoutTrace.pricePerLiter);
      expect(withTrace.derived, withoutTrace.derived);
      expect(withTrace.isConsistent, withoutTrace.isConsistent);
    });

    test('orchestratePumpDisplayParse is identical with/without trace', () {
      final a = orchestratePumpDisplayParse(
          blocks: samplePhotoBlocks(), text: '', profile: frProfile);
      final b = orchestratePumpDisplayParse(
          blocks: samplePhotoBlocks(),
          text: '',
          profile: frProfile,
          trace: OcrTraceRecorder());
      expect(b.totalCost, a.totalCost);
      expect(b.liters, a.liters);
      expect(b.pricePerLiter, a.pricePerLiter);
      expect(b.confidence, a.confidence);
      expect(b.validated, a.validated);
      expect(b.validationReason, a.validationReason);
      expect(b.derived, a.derived);
    });
  });
}
