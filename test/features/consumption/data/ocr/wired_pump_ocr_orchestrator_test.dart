// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tankstellen/features/consumption/data/ocr/ocr_image_preprocessor.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_display_orchestrator.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/consumption/data/ocr/recognized_text_block.dart';
import 'package:tankstellen/features/consumption/data/pump_scan_disposition.dart';

/// End-to-end WIRED-path integration test for the pump-OCR scan (#2823).
///
/// Unlike `fr_tokheim_18_59eur_23_30l_fixture_test.dart` (which replays the
/// baked blocks through the bare `extractByLabelAnchor`), this drives the
/// **production** entry point [orchestratePumpDisplayParse] exactly as
/// `ReceiptScanService.parsePumpDisplayImage` wires it (PR #2840 / #2830):
///
///   blocks + flatText  ──▶ label-anchored read  ──▶ validation gate
///                          + flat-string fallback     ──▶ #2830 recognizer
///                                                          source merge
///
/// It supplies BOTH a real decoded reticle-cropped frame AND the live
/// FR/Tokheim `pumpDisplay` ROIs from the shipped `assets/ocr_config`, so
/// the strictly-additive 3rd source ([mergeRecognizerSource]) actually
/// executes on the wired path — proving the wiring runs end-to-end and is
/// **non-regressive**: the clean-render label-anchored read (the
/// production-default winner) still yields the committed
/// `fr_tokheim_18_59eur_23_30l.ocrpkg.json` triple and gate-validates,
/// and the final disposition is [PumpScanDisposition.autofill] (so the
/// scan would prefill the form, never the `?`/inconsistent reject path).
///
/// The source of truth is the promoted package itself: blocks, flat text
/// and profile are parsed from the committed `.ocrpkg.json`, so a future
/// re-promotion automatically keeps this test honest.
void main() {
  const pkgPath =
      'test/fixtures/pump_displays/fr_tokheim/fr_tokheim_18_59eur_23_30l.ocrpkg.json';
  const jpgPath =
      'test/fixtures/pump_displays/fr_tokheim/fr_tokheim_18_59eur_23_30l.jpg';

  late Map<String, dynamic> pkg;
  late List<RecognizedTextBlock> blocks;
  late String flatText;
  late OcrLocaleProfile profile;
  late OcrPumpFieldSpec recognizerFields;

  setUpAll(() {
    pkg = jsonDecode(File(pkgPath).readAsStringSync()) as Map<String, dynamic>;
    final mlkit = pkg['mlkit'] as Map<String, dynamic>;
    flatText = mlkit['flatText'] as String;
    blocks = (mlkit['blocks'] as List)
        .cast<Map<String, dynamic>>()
        .map((b) {
          final box = (b['box'] as List).cast<num>();
          return RecognizedTextBlock(
            text: b['text'] as String,
            box: OcrBox(
              left: box[0].toDouble(),
              top: box[1].toDouble(),
              right: box[2].toDouble(),
              bottom: box[3].toDouble(),
            ),
          );
        })
        .toList();

    final p = (pkg['input'] as Map<String, dynamic>)['profile']
        as Map<String, dynamic>;
    profile = OcrLocaleProfile(
      country: p['country'] as String,
      currency: p['currency'] as String,
      decimalSeparator: p['decimalSeparator'] as String,
      priceMin: (p['priceMin'] as num).toDouble(),
      priceMax: (p['priceMax'] as num).toDouble(),
      volumeMax: (p['volumeMax'] as num).toDouble(),
      totalMax: (p['totalMax'] as num).toDouble(),
    );

    // The live FR/Tokheim ROIs the production scan path resolves (the only
    // template carrying `pumpDisplay` ROIs today) — supplying these turns
    // ON the wired 3rd source for the orchestrator call below.
    final config = PumpOcrConfig.fromJsonString(
        File('assets/ocr_config/index.json').readAsStringSync());
    recognizerFields =
        config.templateFor(country: 'FR', brand: 'tokheim')!.pumpDisplay!;
  });

  group('#2823 wired orchestrator — promoted Tokheim package', () {
    test('reads 18.59 € / 23.30 L / 0.798 €/L through the wired path', () {
      final result = orchestratePumpDisplayParse(
        blocks: blocks,
        text: flatText,
        profile: profile,
        recognizerFields: recognizerFields,
        frame: img.decodeJpg(File(jpgPath).readAsBytesSync()),
      );

      expect(result.totalCost, closeTo(18.59, 0.001));
      expect(result.liters, closeTo(23.30, 0.001));
      expect(result.pricePerLiter, closeTo(0.798, 0.001));
    });

    test('the wired read passes the FR validation gate', () {
      final result = orchestratePumpDisplayParse(
        blocks: blocks,
        text: flatText,
        profile: profile,
        recognizerFields: recognizerFields,
        frame: img.decodeJpg(File(jpgPath).readAsBytesSync()),
      );

      expect(result.validationApplied, isTrue,
          reason: 'an FR profile was supplied, so the gate must run');
      expect(result.validated, isTrue,
          reason: '52.77×… aside — 23.30 × 0.798 = 18.59 reconciles, '
              'so the read is identity-consistent and gate-accepted');
      expect(result.isConsistent, isTrue);
    });

    test('the wired result autofills (never the inconsistent/unread path)',
        () {
      final result = orchestratePumpDisplayParse(
        blocks: blocks,
        text: flatText,
        profile: profile,
        recognizerFields: recognizerFields,
        frame: img.decodeJpg(File(jpgPath).readAsBytesSync()),
      );

      // The #2828 gate-aware disposition: a validated 3-field read prefills
      // the form; an unread / identity-inconsistent read would NOT.
      expect(pumpScanDispositionFor(result), PumpScanDisposition.autofill);
    });

    test('supplying the recognizer source is non-regressive vs. unwired', () {
      // Same blocks WITHOUT the 3rd-source inputs (the production path for
      // every non-FR/Tokheim region) must produce the identical winner —
      // proving the wired recognizer merge is strictly additive on a clean
      // frame the label-anchored source already reads.
      final wired = orchestratePumpDisplayParse(
        blocks: blocks,
        text: flatText,
        profile: profile,
        recognizerFields: recognizerFields,
        frame: img.decodeJpg(File(jpgPath).readAsBytesSync()),
      );
      final unwired = orchestratePumpDisplayParse(
        blocks: blocks,
        text: flatText,
        profile: profile,
      );

      expect(wired.totalCost, unwired.totalCost);
      expect(wired.liters, unwired.liters);
      expect(wired.pricePerLiter, unwired.pricePerLiter);
      expect(wired.validated, unwired.validated);
    });

    test('a decode-failing frame degrades to the two-source winner', () {
      // The recognizer-source guard must never let a bad frame regress the
      // existing read: an empty/garbage frame yields no usable LED read, so
      // the label-anchored winner stands.
      final result = orchestratePumpDisplayParse(
        blocks: blocks,
        text: flatText,
        profile: profile,
        recognizerFields: recognizerFields,
        frame: img.Image(width: 4, height: 4),
      );
      expect(result.totalCost, closeTo(18.59, 0.001));
      expect(result.liters, closeTo(23.30, 0.001));
      expect(result.pricePerLiter, closeTo(0.798, 0.001));
      expect(result.validated, isTrue);
    });
  });

  test('the promoted package + its source frame are committed', () {
    expect(File(pkgPath).existsSync(), isTrue);
    expect(File(jpgPath).existsSync(), isTrue);
    // Cheap sanity that the committed JPEG is decodable by the real
    // pipeline's preprocessor entry (EXIF-bake is what the scan does).
    const pp = OcrImagePreprocessor();
    final decoded = img.decodeJpg(File(jpgPath).readAsBytesSync());
    expect(decoded, isNotNull);
    expect(pp.toGrayscale(img.bakeOrientation(decoded!)), isNotNull);
  });
}
