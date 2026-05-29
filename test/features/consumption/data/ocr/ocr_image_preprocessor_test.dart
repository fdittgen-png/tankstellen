// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_image_preprocessor.dart';

/// Unit coverage for the on-device preprocessing primitives (#2275):
/// ROI crop, quarter-turn rotation, Sauvola adaptive binarization,
/// morphological close, border-ink clearing, and the glare metric.
void main() {
  const pp = OcrImagePreprocessor();

  int inkCount(img.Image im) {
    var n = 0;
    for (final p in im) {
      if (p.luminance < 128) n++;
    }
    return n;
  }

  group('cropToRoi', () {
    test('crops to the normalized rect', () {
      final src = img.Image(width: 100, height: 200);
      final out = pp.cropToRoi(src,
          const OcrNormalizedRect(left: 0.25, top: 0.5, width: 0.5, height: 0.25));
      expect(out.width, 50);
      expect(out.height, 50);
    });

    test('a full-frame ROI returns the same size', () {
      final src = img.Image(width: 80, height: 60);
      final out = pp.cropToRoi(src, OcrNormalizedRect.full);
      expect(out.width, 80);
      expect(out.height, 60);
    });

    test('clamps an over-hanging ROI to the image bounds', () {
      final src = img.Image(width: 100, height: 100);
      final out = pp.cropToRoi(src,
          const OcrNormalizedRect(left: 0.9, top: 0.9, width: 0.5, height: 0.5));
      expect(out.width, lessThanOrEqualTo(10));
      expect(out.height, lessThanOrEqualTo(10));
    });
  });

  group('rotateQuarterTurns', () {
    test('0 turns is a no-op size', () {
      final src = img.Image(width: 80, height: 40);
      expect(pp.rotateQuarterTurns(src, 0).width, 80);
    });

    test('1 turn swaps width and height', () {
      final src = img.Image(width: 80, height: 40);
      final out = pp.rotateQuarterTurns(src, 1);
      expect(out.width, 40);
      expect(out.height, 80);
    });

    test('2 turns keeps the dimensions', () {
      final src = img.Image(width: 80, height: 40);
      final out = pp.rotateQuarterTurns(src, 2);
      expect(out.width, 80);
      expect(out.height, 40);
    });
  });

  group('sauvolaBinarize', () {
    test('separates dark strokes from a light field as ink+background', () {
      final src = img.Image(width: 80, height: 80);
      for (final p in src) {
        final onStroke = p.y >= 30 && p.y <= 36;
        final shade = onStroke ? 40 : 210;
        p.setRgb(shade, shade, shade);
      }
      final bin = pp.sauvolaBinarize(pp.toGrayscale(src));
      final ink = inkCount(bin);
      expect(ink, greaterThan(0), reason: 'the stroke must become ink');
      expect(ink, lessThan(80 * 80),
          reason: 'the field must stay background, not all-ink');
    });

    test('output is strictly black or white (a binary mask)', () {
      final src = img.Image(width: 40, height: 40);
      for (final p in src) {
        p.setRgb(p.x < 20 ? 30 : 220, p.x < 20 ? 30 : 220, p.x < 20 ? 30 : 220);
      }
      final bin = pp.sauvolaBinarize(pp.toGrayscale(src));
      for (final p in bin) {
        final l = p.luminance.round();
        expect(l == 0 || l == 255, isTrue,
            reason: 'binarized pixels must be 0 or 255, got $l');
      }
    });
  });

  group('morphologicalClose', () {
    test('bridges a one-pixel gap between two ink strokes', () {
      // Two vertical ink bars separated by a single background column.
      final src = img.Image(width: 7, height: 20);
      img.fill(src, color: img.ColorRgb8(255, 255, 255));
      for (var y = 0; y < 20; y++) {
        src.setPixel(2, y, img.ColorRgb8(0, 0, 0));
        src.setPixel(4, y, img.ColorRgb8(0, 0, 0));
      }
      final closed = pp.morphologicalClose(src, radius: 1);
      // The gap column (x=3) should now be ink.
      expect(closed.getPixel(3, 10).luminance, lessThan(128));
    });
  });

  group('clearBorderInk', () {
    test('removes a border-connected frame but keeps a free-floating blob',
        () {
      final src = img.Image(width: 30, height: 30);
      img.fill(src, color: img.ColorRgb8(255, 255, 255));
      // A 1px ink frame touching every edge.
      for (var x = 0; x < 30; x++) {
        src.setPixel(x, 0, img.ColorRgb8(0, 0, 0));
        src.setPixel(x, 29, img.ColorRgb8(0, 0, 0));
      }
      for (var y = 0; y < 30; y++) {
        src.setPixel(0, y, img.ColorRgb8(0, 0, 0));
        src.setPixel(29, y, img.ColorRgb8(0, 0, 0));
      }
      // A free-floating blob in the middle.
      for (var y = 13; y < 17; y++) {
        for (var x = 13; x < 17; x++) {
          src.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
      final cleared = pp.clearBorderInk(src);
      // Frame gone.
      expect(cleared.getPixel(0, 0).luminance, 255);
      expect(cleared.getPixel(15, 0).luminance, 255);
      // Blob kept.
      expect(cleared.getPixel(15, 15).luminance, lessThan(128));
    });
  });

  group('glareFraction', () {
    test('is ~1 for an all-white frame and ~0 for a dark frame', () {
      final white = img.Image(width: 20, height: 20);
      img.fill(white, color: img.ColorRgb8(255, 255, 255));
      expect(pp.glareFraction(white), greaterThan(0.9));

      final dark = img.Image(width: 20, height: 20);
      img.fill(dark, color: img.ColorRgb8(20, 20, 20));
      expect(pp.glareFraction(dark), lessThan(0.05));
    });
  });

  group('OcrNormalizedRect.fromJson', () {
    test('parses a valid rect', () {
      final r = OcrNormalizedRect.fromJson(
          {'left': 0.1, 'top': 0.2, 'width': 0.3, 'height': 0.4});
      expect(r, isNotNull);
      expect(r!.right, closeTo(0.4, 1e-9));
      expect(r.bottom, closeTo(0.6, 1e-9));
    });

    test('rejects an out-of-box or malformed rect', () {
      expect(OcrNormalizedRect.fromJson({'left': 0.8, 'width': 0.5}), isNull);
      expect(OcrNormalizedRect.fromJson({'left': -0.1}), isNull);
      expect(OcrNormalizedRect.fromJson('nope'), isNull);
      expect(OcrNormalizedRect.fromJson(null), isNull);
    });
  });
}
