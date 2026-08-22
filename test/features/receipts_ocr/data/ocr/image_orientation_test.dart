// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tankstellen/features/receipts_ocr/data/ocr/image_orientation.dart';
import '../../../../helpers/silence_error_logger.dart';

/// Coverage for the #3766 OCR downscale helper: the recognizer must be
/// fed a bounded bitmap (a shared full-res photo decodes to tens of MB
/// inside ML Kit), while EXIF orientation keeps being baked upright
/// (#1711) and small images pass through unscaled.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  Uint8List jpeg(int w, int h, {int? exifOrientation}) {
    final src = img.Image(width: w, height: h);
    img.fill(src, color: img.ColorRgb8(80, 90, 100));
    if (exifOrientation != null) {
      src.exif.imageIfd['Orientation'] = exifOrientation;
    }
    return Uint8List.fromList(img.encodeJpg(src));
  }

  group('prepareReceiptImageForOcr (#3766)', () {
    test('downscales an oversized landscape to the max longest side', () {
      final out = prepareReceiptImageForOcr(jpeg(4000, 3000));
      expect(out, isNotNull);
      final decoded = img.decodeJpg(out!)!;
      expect(decoded.width, kReceiptOcrMaxDimension);
      // Aspect preserved: 4000×3000 → 1600×1200.
      expect(decoded.height, 1200);
    });

    test('downscales an oversized portrait on its HEIGHT', () {
      final out = prepareReceiptImageForOcr(jpeg(1920, 2560));
      expect(out, isNotNull);
      final decoded = img.decodeJpg(out!)!;
      expect(decoded.height, kReceiptOcrMaxDimension);
      expect(decoded.width, 1200);
    });

    test('never upscales an image already under the cap', () {
      final out = prepareReceiptImageForOcr(jpeg(1200, 900));
      expect(out, isNotNull);
      final decoded = img.decodeJpg(out!)!;
      expect(decoded.width, 1200);
      expect(decoded.height, 900);
    });

    test('an image exactly at the cap passes through unscaled', () {
      final out = prepareReceiptImageForOcr(jpeg(kReceiptOcrMaxDimension, 800));
      final decoded = img.decodeJpg(out!)!;
      expect(decoded.width, kReceiptOcrMaxDimension);
      expect(decoded.height, 800);
    });

    test('bakes EXIF orientation 6 upright BEFORE bounding — the rotated '
        'longest side is what gets capped', () {
      // A 3200×2000 sensor frame tagged "rotate 90° CW" displays as
      // 2000×3200: after the bake the HEIGHT is the longest side, so the
      // output is 1000×1600 — proving rotation happens before the resize.
      final out = prepareReceiptImageForOcr(
        jpeg(3200, 2000, exifOrientation: 6),
      );
      expect(out, isNotNull);
      final decoded = img.decodeJpg(out!)!;
      expect(decoded.width, 1000);
      expect(decoded.height, kReceiptOcrMaxDimension);
    });

    test('honours a custom maxDimension', () {
      final out = prepareReceiptImageForOcr(jpeg(2000, 1000), maxDimension: 500);
      final decoded = img.decodeJpg(out!)!;
      expect(decoded.width, 500);
      expect(decoded.height, 250);
    });

    test('returns null for non-JPEG / garbage bytes', () {
      final garbage = Uint8List.fromList(List.generate(64, (i) => i % 256));
      expect(prepareReceiptImageForOcr(garbage), isNull);
    });
  });
}
