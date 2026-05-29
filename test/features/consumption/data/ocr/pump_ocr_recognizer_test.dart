// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_geometry.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_recognizer.dart';

/// Coverage for the recognizer orchestrator (#2275): the glare
/// auto-reject and the orientation sweep. The end-to-end read against
/// the real photos lives in `fr_tokheim_real_ocr_fixture_test.dart`.
void main() {
  const fields = OcrPumpFieldSpec(
    total: OcrNormalizedRect(left: 0, top: 0, width: 1, height: 0.33),
    volume: OcrNormalizedRect(left: 0, top: 0.33, width: 1, height: 0.33),
    pricePerLitre: OcrNormalizedRect(left: 0, top: 0.66, width: 1, height: 0.33),
  );

  test('auto-rejects an over-glared (near-white) frame', () {
    const rec = PumpOcrRecognizer(glarePolicy: GlarePolicy(rejectAbove: 0.35));
    final white = img.Image(width: 120, height: 120);
    img.fill(white, color: img.ColorRgb8(255, 255, 255));
    final result = rec.recognize(white, fields);
    expect(result.glareRejected, isTrue);
    expect(result.fieldCount, 0);
  });

  test('a dark blank frame is not glare-rejected but recovers nothing', () {
    const rec = PumpOcrRecognizer();
    final dark = img.Image(width: 120, height: 120);
    img.fill(dark, color: img.ColorRgb8(20, 20, 20));
    final result = rec.recognize(dark, fields);
    expect(result.glareRejected, isFalse);
    expect(result.fieldCount, 0);
  });

  test('the orientation sweep never throws and returns a result', () {
    const rec = PumpOcrRecognizer();
    final frame = img.Image(width: 200, height: 120);
    img.fill(frame, color: img.ColorRgb8(30, 30, 30));
    final result = rec.recognizeWithSweep(frame, fields);
    // No digits in a blank frame, but the sweep must complete cleanly.
    expect(result.fieldCount, 0);
    expect(result.orientationQuarterTurns, inInclusiveRange(0, 3));
  });
}
