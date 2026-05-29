// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/seven_segment_recognizer.dart';

/// Correctness trust-anchor for the deterministic ssocr-style decoder
/// (#2275). Renders 7-segment numbers with full control over geometry
/// and feeds them through the *real* [SevenSegmentRecognizer] — so a
/// regression in the segment table, the row/column segmentation, the
/// "1" / decimal-point handling, or the a–g sampling windows fails here
/// immediately. The real-photo harness
/// (`fr_tokheim_real_ocr_fixture_test.dart`) then exercises the same
/// decoder on the actual pump captures.
img.Image _render(
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
  img.fill(im, color: img.ColorRgb8(255, 255, 255));
  var x = pad;
  for (final ch in s.split('')) {
    if (ch == '.') {
      // Decimal point: a small dot in the gap after the previous digit.
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
    void rect(int a, int b, int c, int d) =>
        img.fillRect(im, x1: a, y1: b, x2: c, y2: d, color: img.ColorRgb8(0, 0, 0));
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

void main() {
  const dec = SevenSegmentRecognizer();

  group('SevenSegmentRecognizer — synthetic glyphs (#2275)', () {
    // Every fixture ground-truth value plus boundary cases.
    const cases = <String>[
      '8.03', '8.93', '0.899', // 9548
      '10.00', '11.12', // 9550
      '79.91', '36.06', '2.216', // 9519 / 9498
      '10.47', '5.24', '1.999', // 9499
      '24.94', '29.37', '0.849', // 9690
      '30.02', '13.43', '2.235', // 9498
      '1234567890', // every digit
    ];

    for (final value in cases) {
      test('decodes "$value" exactly', () {
        final reading = dec.decode(_render(value));
        expect(reading.text, value, reason: 'decoded text must match');
        expect(reading.value, double.parse(value));
        expect(reading.confidence, 1.0,
            reason: 'every glyph should match a known pattern');
      });
    }

    test('reports an empty reading for a blank image', () {
      final blank = img.Image(width: 100, height: 60);
      img.fill(blank, color: img.ColorRgb8(255, 255, 255));
      final reading = dec.decode(blank);
      expect(reading.isEmpty, isTrue);
      expect(reading.value, isNull);
      expect(reading.confidence, 0);
    });

    test('a tiny image yields an empty reading, never throws', () {
      final tiny = img.Image(width: 2, height: 2);
      expect(dec.decode(tiny).isEmpty, isTrue);
    });

    test('value is null when a glyph could not be matched', () {
      const reading = SevenSegmentReading(
          text: '8?3', confidence: 0.66, digitCount: 3);
      expect(reading.value, isNull);
    });
  });
}
