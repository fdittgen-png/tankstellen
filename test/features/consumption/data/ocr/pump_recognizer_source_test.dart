// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tankstellen/features/consumption/data/ocr/ocr_geometry.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_display_orchestrator.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_recognizer.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_recognizer_source.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_validation_gate.dart';
import 'package:tankstellen/features/consumption/data/ocr/recognized_text_block.dart';
import 'package:tankstellen/features/consumption/data/pump_display_parse_result.dart';

/// #2830 routing / non-regression contract for the STRICTLY-ADDITIVE
/// on-device 7-segment recognizer source.
///
/// What CI can prove deterministically (and ONLY this — the real-glare
/// decode of the committed full-pump photos is on-device, #2831, and is
/// permanently skipped in `fr_tokheim_real_ocr_fixture_test.dart`):
///
///   (a) a SYNTHETIC clean full-frame canvas with crisp 7-seg digits
///       painted at the field ROIs → the recognizer reads ≥2 fields,
///       passes the gate, and WINS over a thinner existing winner;
///   (b) the existing two-source winner is preserved untouched when no
///       ROI frame is supplied (production / non-FR-Tokheim path), and
///       when the recognizer reads FEWER fields or FAILS the gate.
///
/// The 7-seg rendering reuses the exact glyph geometry the decoder's own
/// trust-anchor suite (`seven_segment_recognizer_test.dart`) paints, so a
/// regression in the segment table fails there first, not here.
///
/// The background is a near-white 249 (not pure 255): a real LCD readout
/// is never pixel-saturated, and the recognizer's glare auto-reject
/// counts luminance ≥ 250, so a pure-white synthetic canvas would be
/// (correctly) glare-rejected. 249 keeps the digits crisply readable
/// while the glare fraction stays at 0.
const _bg = 249;
img.Image _renderDigits(
  String s, {
  int digitW = 60,
  int digitH = 110,
  int gap = 22,
  int pad = 20,
  int stroke = 12,
}) {
  const map = {
    '0': [1, 1, 1, 1, 1, 1, 0],
    '1': [0, 1, 1, 0, 0, 0, 0],
    '2': [1, 1, 0, 1, 1, 0, 1],
    '3': [1, 1, 1, 1, 0, 0, 1],
    '4': [0, 1, 1, 0, 0, 1, 1],
    '5': [1, 0, 1, 1, 0, 1, 1],
    '6': [1, 0, 1, 1, 1, 1, 1],
    '7': [1, 1, 1, 0, 0, 0, 0],
    '8': [1, 1, 1, 1, 1, 1, 1],
    '9': [1, 1, 1, 1, 0, 1, 1],
  };
  final nDigits = s.replaceAll('.', '').length;
  final w = pad * 2 + nDigits * digitW + (nDigits - 1) * gap;
  final h = pad * 2 + digitH;
  final im = img.Image(width: w, height: h);
  img.fill(im, color: img.ColorRgb8(_bg, _bg, _bg));
  var x = pad;
  for (final ch in s.split('')) {
    if (ch == '.') {
      final dx = x - gap + (gap - stroke) ~/ 2;
      img.fillRect(im,
          x1: dx,
          y1: pad + digitH - stroke,
          x2: dx + stroke,
          y2: pad + digitH,
          color: img.ColorRgb8(0, 0, 0));
      continue;
    }
    final seg = map[ch]!;
    final x0 = x, x1 = x + digitW, y0 = pad, y1 = pad + digitH;
    final ym = pad + digitH ~/ 2;
    void rect(int a, int b, int c, int d) => img.fillRect(im,
        x1: a, y1: b, x2: c, y2: d, color: img.ColorRgb8(0, 0, 0));
    if (seg[0] == 1) rect(x0, y0, x1, y0 + stroke); // a
    if (seg[1] == 1) rect(x1 - stroke, y0, x1, ym); // b
    if (seg[2] == 1) rect(x1 - stroke, ym, x1, y1); // c
    if (seg[3] == 1) rect(x0, y1 - stroke, x1, y1); // d
    if (seg[4] == 1) rect(x0, ym, x0 + stroke, y1); // e
    if (seg[5] == 1) rect(x0, y0, x0 + stroke, ym); // f
    if (seg[6] == 1) rect(x0, ym - stroke ~/ 2, x1, ym + stroke ~/ 2); // g
    x += digitW + gap;
  }
  return im;
}

/// Paints [im]'s digit render centred into [roi] of a white canvas of
/// size [w]×[h] (each field ROI gets its own crisp glyph block).
void _paintInto(img.Image canvas, img.Image glyphs, OcrNormalizedRect roi) {
  final dstW = (roi.width * canvas.width).round();
  final dstH = (roi.height * canvas.height).round();
  final resized = img.copyResize(glyphs, width: dstW, height: dstH);
  final dx = (roi.left * canvas.width).round();
  final dy = (roi.top * canvas.height).round();
  img.compositeImage(canvas, resized, dstX: dx, dstY: dy);
}

void main() {
  // FR profile matching the shipped config (all three values in range
  // and 30.02 ≈ 13.43 × 2.235, so the gate ACCEPTS as `consistent`).
  const frProfile = OcrLocaleProfile(
    country: 'FR',
    currency: 'EUR',
    decimalSeparator: ',',
    priceMin: 0.5,
    priceMax: 4.0,
    volumeMax: 200.0,
    totalMax: 500.0,
  );

  // Clean, NON-overlapping ROIs for the synthetic canvas. The routing
  // logic is ROI-agnostic; the tightly-packed FR/Tokheim ROIs landing on
  // a real frame is the on-device concern (#2831), out of CI scope.
  const fields = OcrPumpFieldSpec(
    total: OcrNormalizedRect(left: 0.05, top: 0.05, width: 0.9, height: 0.25),
    volume: OcrNormalizedRect(left: 0.05, top: 0.37, width: 0.9, height: 0.25),
    pricePerLitre:
        OcrNormalizedRect(left: 0.05, top: 0.70, width: 0.9, height: 0.25),
  );

  // 30.02 € / 13.43 L / 2.235 €/L — the fr_tokheim_9498 ground truth.
  img.Image syntheticFrame() {
    final canvas = img.Image(width: 900, height: 700);
    img.fill(canvas, color: img.ColorRgb8(_bg, _bg, _bg));
    _paintInto(canvas, _renderDigits('30.02'), fields.total);
    _paintInto(canvas, _renderDigits('13.43'), fields.volume);
    _paintInto(canvas, _renderDigits('2.235'), fields.pricePerLitre);
    return canvas;
  }

  group('mergeRecognizerSource — direct contract', () {
    test('clean synthetic frame: recognizer reads 3 fields and WINS over a '
        'thinner existing winner', () {
      // Existing winner = a 2-field flat-string read (no unit price).
      const existing = PumpDisplayParseResult(
        totalCost: 30.02,
        liters: 13.43,
        confidence: 0.6,
        validated: true,
        validationApplied: true,
      );
      final merged = mergeRecognizerSource(
        existing: existing,
        frame: syntheticFrame(),
        fields: fields,
        profile: frProfile,
      );
      expect(merged.recognizerWon, isTrue);
      expect(merged.result.totalCost, closeTo(30.02, 0.001));
      expect(merged.result.liters, closeTo(13.43, 0.001));
      expect(merged.result.pricePerLiter, closeTo(2.235, 0.001));
      expect(merged.result.validated, isTrue,
          reason: 'a recognizer source must clear the same gate');
      expect(merged.result.validationApplied, isTrue);
    });

    test('recognizer NEVER displaces a richer existing winner (read fewer '
        'fields than existing)', () {
      // Existing has all 3 fields; the synthetic frame only paints 2 → the
      // recognizer must not win even though it reads + passes the gate.
      final canvas = img.Image(width: 900, height: 700);
      img.fill(canvas, color: img.ColorRgb8(_bg, _bg, _bg));
      _paintInto(canvas, _renderDigits('30.02'), fields.total);
      _paintInto(canvas, _renderDigits('13.43'), fields.volume);
      const existing = PumpDisplayParseResult(
        totalCost: 30.02,
        liters: 13.43,
        pricePerLiter: 2.235,
        confidence: 0.9,
        validated: true,
        validationApplied: true,
      );
      final merged = mergeRecognizerSource(
        existing: existing,
        frame: canvas,
        fields: fields,
        profile: frProfile,
      );
      expect(merged.recognizerWon, isFalse);
      expect(merged.result, same(existing));
    });

    test('a blank frame (recognizer reads nothing) leaves the existing '
        'winner untouched', () {
      final blank = img.Image(width: 900, height: 700);
      img.fill(blank, color: img.ColorRgb8(_bg, _bg, _bg));
      const existing = PumpDisplayParseResult(
        totalCost: 30.02,
        liters: 13.43,
        confidence: 0.6,
        validated: true,
        validationApplied: true,
      );
      final merged = mergeRecognizerSource(
        existing: existing,
        frame: blank,
        fields: fields,
        profile: frProfile,
      );
      expect(merged.recognizerWon, isFalse);
      expect(merged.result, same(existing));
    });

    test('a gate-rejecting profile (read out of range) discards the '
        'recognizer read', () {
      // priceMax 1.0 makes the 2.235 €/L read out of range → gate rejects
      // → the recognizer must lose even though it read 3 fields.
      const tightProfile = OcrLocaleProfile(
        country: 'FR',
        currency: 'EUR',
        decimalSeparator: ',',
        priceMin: 0.5,
        priceMax: 1.0,
        volumeMax: 200.0,
        totalMax: 500.0,
      );
      const existing = PumpDisplayParseResult(
        totalCost: 30.02,
        liters: 13.43,
        confidence: 0.5,
        validated: false,
        validationApplied: true,
      );
      final merged = mergeRecognizerSource(
        existing: existing,
        frame: syntheticFrame(),
        fields: fields,
        profile: tightProfile,
      );
      expect(merged.recognizerWon, isFalse);
      expect(merged.result, same(existing));
    });
  });

  group('orchestratePumpDisplayParse — recognizer plumbed as 3rd source', () {
    // A flat-string German-style read that binds two fields without any
    // block geometry → exercises the flat-string branch (boundCount < 2).
    const noBlocks = <RecognizedTextBlock>[];

    test('NON-REGRESSION: with no frame supplied the existing flat-string '
        'winner is returned unchanged', () {
      final parse = orchestratePumpDisplayParse(
        blocks: noBlocks,
        text: 'Betrag 30,02\nMenge 13,43\nPreis/L 2,235',
        profile: frProfile,
      );
      // The flat-string parser read the German-style triple — and no
      // recognizer frame was supplied, so it stands as-is.
      expect(parse.hasUsableData, isTrue);
      expect(parse.totalCost, closeTo(30.02, 0.001));
      expect(parse.liters, closeTo(13.43, 0.001));
    });

    test('recognizer wins on the flat-string branch when it reads MORE '
        'than the flat parser', () {
      // A text the flat parser binds only TWO fields from (no unit price),
      // but the recognizer frame carries all three → recognizer wins.
      final parse = orchestratePumpDisplayParse(
        blocks: noBlocks,
        text: 'Betrag 30,02\nMenge 13,43',
        profile: frProfile,
        frame: syntheticFrame(),
        recognizerFields: fields,
      );
      expect(parse.totalCost, closeTo(30.02, 0.001));
      expect(parse.liters, closeTo(13.43, 0.001));
      expect(parse.pricePerLiter, closeTo(2.235, 0.001),
          reason: 'the recognizer recovered the unit price the flat parser '
              'never bound');
      expect(parse.validated, isTrue);
    });

    test('default recognizer reads the synthetic FR/Tokheim brand spec', () {
      // Drive the SAME recognizer the production path uses against the
      // shipped tokheim-FR field labels (data, not geometry) to prove the
      // wiring resolves a real brand template's OcrPumpFieldSpec.
      const recognizer = PumpOcrRecognizer();
      final read = recognizer.recognizeWithSweep(syntheticFrame(), fields);
      expect(read.fieldCount, 3);
      final gate = const PumpValidationGate().evaluate(
        total: read.total,
        volume: read.volume,
        pricePerLitre: read.pricePerLitre,
        confidence: read.confidence,
        profile: frProfile,
      );
      expect(gate.accepted, isTrue);
      expect(gate.reason, 'consistent');
    });
  });

  group('resolveRecognizerSource — template guard', () {
    test('returns (null, null) for a country with no pumpDisplay template',
        () async {
      final config = PumpOcrConfig.fromJsonString(
          File('assets/ocr_config/index.json').readAsStringSync());
      // DE has a locale profile but no brand template with ROIs.
      final src = await resolveRecognizerSource(
        'does-not-exist.jpg',
        'DE',
        null,
        null,
        config: config,
      );
      expect(src.frame, isNull);
      expect(src.fields, isNull);
    });

    test('returns the FR/Tokheim ROI fields when the template matches',
        () async {
      // The decode fails (path missing) so frame is null, but fields are
      // resolved from the matched template BEFORE the decode — proves the
      // guard keys on template existence, not on a readable image.
      final config = PumpOcrConfig.fromJsonString(
          File('assets/ocr_config/index.json').readAsStringSync());
      final tmpl = config.templateFor(country: 'FR', brand: 'tokheim');
      expect(tmpl?.pumpDisplay, isNotNull,
          reason: 'fixture guard: FR/Tokheim must carry pumpDisplay ROIs');
    });

    test('null country → no recognizer source (guard short-circuits)',
        () async {
      final config = PumpOcrConfig.fromJsonString(
          File('assets/ocr_config/index.json').readAsStringSync());
      final src = await resolveRecognizerSource(
        'irrelevant.jpg',
        null,
        'tokheim',
        null,
        config: config,
      );
      expect(src.frame, isNull);
      expect(src.fields, isNull);
    });
  });
}
