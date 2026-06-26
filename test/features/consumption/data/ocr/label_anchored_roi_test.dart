// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/_pump_label_table.dart';
import 'package:tankstellen/features/consumption/data/ocr/label_anchored_roi.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_geometry.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/consumption/data/ocr/recognized_text_block.dart';

/// #3397 / Epic #2823 — label-anchored value ROIs. The fixed template ROIs
/// can't track where the LCD lands in a hand-held photo; deriving each value
/// ROI from the label box ML Kit located is what makes the 7-segment read
/// aim at the actual digits. These are pure-geometry tests (no platform).

RecognizedTextBlock _label(String text,
        {required double l, required double t, required double r, required double b}) =>
    RecognizedTextBlock(text: text, box: OcrBox(left: l, top: t, right: r, bottom: b));

// A fixed template whose ROIs are deliberately in the WRONG place (top-left
// corner) — the failure mode this fix addresses. Anchoring must override them.
const _wrongFixed = OcrPumpFieldSpec(
  total: OcrNormalizedRect(left: 0.0, top: 0.0, width: 0.1, height: 0.05),
  volume: OcrNormalizedRect(left: 0.0, top: 0.05, width: 0.1, height: 0.05),
  pricePerLitre: OcrNormalizedRect(left: 0.0, top: 0.10, width: 0.1, height: 0.05),
);

const _anchor = OcrValueAnchor(); // above, gap .15, w×1.4, h×2.4

void main() {
  group('resolveLabelAnchoredFields (#3397)', () {
    test('a PRIX label anchors the total ROI ABOVE it, centred on it', () {
      // 1000×1000 frame; "PRIX" low in the frame (digits above it).
      final out = resolveLabelAnchoredFields(
        template: _wrongFixed,
        blocks: [_label('PRIX', l: 300, t: 600, r: 400, b: 640)],
        frameWidth: 1000,
        frameHeight: 1000,
        anchor: _anchor,
      );

      expect(out.anchored, contains(PumpField.total));
      final roi = out.fields.total;
      // Sits ABOVE the label (bottom edge above the label's top at 0.60).
      expect(roi.bottom, lessThanOrEqualTo(0.60),
          reason: 'the value is above its label on a Tokheim display');
      // Horizontally centred on the label centre (0.35).
      final roiCx = roi.left + roi.width / 2;
      expect(roiCx, closeTo(0.35, 1e-9));
      // Scaled from the label (width 0.1 × 1.4).
      expect(roi.width, closeTo(0.14, 1e-9));
      expect(roi.height, closeTo(0.096, 1e-9));
      // It is NOT the wrong fixed corner ROI.
      expect(roi.top, greaterThan(0.2));
    });

    test(
        'the SAME label framed bigger + shifted moves the ROI with it — the '
        'robustness property the fixed ROIs lacked', () {
      OcrNormalizedRect totalRoiFor(double l, double t, double r, double b) =>
          resolveLabelAnchoredFields(
            template: _wrongFixed,
            blocks: [_label('PRIX', l: l, t: t, r: r, b: b)],
            frameWidth: 1000,
            frameHeight: 1000,
            anchor: _anchor,
          ).fields.total;

      final near = totalRoiFor(300, 600, 400, 640); // small, low
      final zoomed = totalRoiFor(150, 300, 450, 460); // 2× wider/taller, higher

      // Both stay above + centred on their label; the zoomed one is bigger and
      // higher in the frame — it tracked the label instead of a fixed rect.
      expect(zoomed.width, greaterThan(near.width));
      expect((zoomed.left + zoomed.width / 2), closeTo(0.30, 1e-9));
      expect(zoomed.bottom, lessThanOrEqualTo(0.30));
    });

    test('a field whose label ML Kit did NOT find keeps its fixed ROI', () {
      final out = resolveLabelAnchoredFields(
        template: _wrongFixed,
        blocks: [_label('PRIX', l: 300, t: 600, r: 400, b: 640)], // only total
        frameWidth: 1000,
        frameHeight: 1000,
        anchor: _anchor,
      );
      expect(out.anchored, equals({PumpField.total}));
      // volume + price untouched (the fixed fallback).
      expect(out.fields.volume, same(_wrongFixed.volume));
      expect(out.fields.pricePerLitre, same(_wrongFixed.pricePerLitre));
    });

    test('"PRIX DU LITRE" anchors the price field, not the bare-PRIX total', () {
      final out = resolveLabelAnchoredFields(
        template: _wrongFixed,
        blocks: [
          _label('PRIX', l: 300, t: 600, r: 400, b: 640),
          _label('VOLUME', l: 300, t: 660, r: 460, b: 700),
          _label('PRIX DU LITRE', l: 460, t: 610, r: 640, b: 650),
        ],
        frameWidth: 1000,
        frameHeight: 1000,
        anchor: _anchor,
      );
      expect(out.anchoredCount, 3);
      // The price ROI is anchored to the PRIX-DU-LITRE block (centre ~0.55),
      // NOT to the bare PRIX block (centre 0.35) — the #2478 collision.
      final priceCx = out.fields.pricePerLitre.left + out.fields.pricePerLitre.width / 2;
      expect(priceCx, closeTo(0.55, 1e-9));
    });

    test('empty blocks or a zero frame returns the template unchanged', () {
      expect(
        resolveLabelAnchoredFields(
                template: _wrongFixed,
                blocks: const [],
                frameWidth: 1000,
                frameHeight: 1000,
                anchor: _anchor)
            .anchoredCount,
        0,
      );
      expect(
        resolveLabelAnchoredFields(
                template: _wrongFixed,
                blocks: [_label('PRIX', l: 0, t: 0, r: 10, b: 10)],
                frameWidth: 0,
                frameHeight: 0,
                anchor: _anchor)
            .fields,
        same(_wrongFixed),
      );
    });

    test('direction:below places the value UNDER the label', () {
      final out = resolveLabelAnchoredFields(
        template: _wrongFixed,
        blocks: [_label('PRIX', l: 300, t: 200, r: 400, b: 240)],
        frameWidth: 1000,
        frameHeight: 1000,
        anchor: const OcrValueAnchor(direction: ValueAnchorDirection.below),
      ).fields.total;
      expect(out.top, greaterThanOrEqualTo(0.24),
          reason: 'value sits below the label (label bottom 0.24)');
    });
  });

  group('OcrValueAnchor.fromJson (#3397)', () {
    test('parses direction + factors', () {
      final a = OcrValueAnchor.fromJson({
        'direction': 'right',
        'gap': 0.2,
        'widthFactor': 1.1,
        'heightFactor': 1.9,
      })!;
      expect(a.direction, ValueAnchorDirection.right);
      expect(a.gap, 0.2);
      expect(a.widthFactor, 1.1);
      expect(a.heightFactor, 1.9);
    });

    test('absent / non-map ⇒ null (anchoring disabled, fixed ROIs)', () {
      expect(OcrValueAnchor.fromJson(null), isNull);
      expect(OcrValueAnchor.fromJson('nope'), isNull);
    });

    test('unknown direction defaults to above; missing factors default', () {
      final a = OcrValueAnchor.fromJson(const <String, Object?>{})!;
      expect(a.direction, ValueAnchorDirection.above);
      expect(a.widthFactor, 1.4);
      expect(a.heightFactor, 2.4);
    });
  });
}
