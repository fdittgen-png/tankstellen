// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/pump_alignment_overlay.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/pump_live_feedback_bar.dart';

/// Unit tests for the guided alignment overlay geometry (#2276):
/// orientation-aware ROI rect, glare classifier, config orientation
/// parsing, and field-label loading from JSON.
void main() {
  // ---------------------------------------------------------------------------
  // PumpAlignmentOverlay.normalizedRect — ROI geometry
  // ---------------------------------------------------------------------------
  group('PumpAlignmentOverlay.normalizedRect', () {
    const previewAspect = 3 / 4; // portrait phone (width < height)
    const landscapeAspect = 16 / 9;

    test('horizontal orientation: rect is wider than tall', () {
      final r = PumpAlignmentOverlay.normalizedRect(
          landscapeAspect, OcrDisplayOrientation.horizontal);
      expect(r.width, greaterThan(r.height),
          reason: 'horizontal overlay must be landscape-shaped');
    });

    test('vertical orientation: rect is taller than wide', () {
      final r = PumpAlignmentOverlay.normalizedRect(
          previewAspect, OcrDisplayOrientation.vertical);
      // Width fraction is 55 % of widthFactor (0.86*0.55 ≈ 0.473).
      // Height should exceed width when the preview is portrait-shaped.
      expect(r.height, greaterThan(r.width),
          reason: 'vertical overlay must be portrait-shaped on a portrait preview');
    });

    test('rect is centred (left+right margins equal)', () {
      final r = PumpAlignmentOverlay.normalizedRect(
          landscapeAspect, OcrDisplayOrientation.horizontal);
      expect(r.left, closeTo(1 - r.right, 0.001));
    });

    test('rect stays within 0..1 bounds for both orientations', () {
      for (final aspect in [0.5, 1.0, 16 / 9]) {
        for (final o in OcrDisplayOrientation.values) {
          final r = PumpAlignmentOverlay.normalizedRect(aspect, o);
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.top, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(1.0001));
          expect(r.bottom, lessThanOrEqualTo(1.0001));
        }
      }
    });

    test('degenerate aspect ratio returns OcrNormalizedRect.full', () {
      final r = PumpAlignmentOverlay.normalizedRect(0, OcrDisplayOrientation.horizontal);
      expect(r.left, 0);
      expect(r.top, 0);
      expect(r.width, 1);
      expect(r.height, 1);
    });

    test('horizontal ROI matches legacy PumpDisplayReticle width', () {
      // The horizontal widthFactor is 0.86 — same as the old reticle.
      final r = PumpAlignmentOverlay.normalizedRect(
          16 / 9, OcrDisplayOrientation.horizontal);
      expect(r.width, closeTo(PumpAlignmentOverlay.widthFactor, 0.001));
    });

    test('vertical ROI is narrower than horizontal', () {
      const aspect = 16.0 / 9.0;
      final horiz = PumpAlignmentOverlay.normalizedRect(
          aspect, OcrDisplayOrientation.horizontal);
      final vert = PumpAlignmentOverlay.normalizedRect(
          aspect, OcrDisplayOrientation.vertical);
      expect(vert.width, lessThan(horiz.width));
    });
  });

  // ---------------------------------------------------------------------------
  // OcrDisplayOrientation — JSON parsing
  // ---------------------------------------------------------------------------
  group('OcrDisplayOrientation.fromJson', () {
    test('parses "vertical"', () {
      expect(OcrDisplayOrientation.fromJson('vertical'),
          OcrDisplayOrientation.vertical);
    });

    test('parses "horizontal"', () {
      expect(OcrDisplayOrientation.fromJson('horizontal'),
          OcrDisplayOrientation.horizontal);
    });

    test('defaults to horizontal for unknown string', () {
      expect(OcrDisplayOrientation.fromJson('diagonal'),
          OcrDisplayOrientation.horizontal);
    });

    test('defaults to horizontal for null', () {
      expect(OcrDisplayOrientation.fromJson(null),
          OcrDisplayOrientation.horizontal);
    });
  });

  // ---------------------------------------------------------------------------
  // OcrBrandTemplate — displayOrientation round-trip through JSON
  // ---------------------------------------------------------------------------
  group('OcrBrandTemplate.fromJson with displayOrientation', () {
    const baseJson = {
      'brand': 'tokheim',
      'country': 'FR',
      'label': 'Tokheim (FR)',
    };

    test('defaults to horizontal when key absent', () {
      final t = OcrBrandTemplate.fromJson(baseJson);
      expect(t!.displayOrientation, OcrDisplayOrientation.horizontal);
    });

    test('reads vertical from JSON', () {
      final t = OcrBrandTemplate.fromJson({
        ...baseJson,
        'displayOrientation': 'vertical',
      });
      expect(t!.displayOrientation, OcrDisplayOrientation.vertical);
    });

    test('reads horizontal from JSON', () {
      final t = OcrBrandTemplate.fromJson({
        ...baseJson,
        'displayOrientation': 'horizontal',
      });
      expect(t!.displayOrientation, OcrDisplayOrientation.horizontal);
    });
  });

  // ---------------------------------------------------------------------------
  // OcrPumpFieldSpec — displayLabels round-trip through JSON
  // ---------------------------------------------------------------------------
  group('OcrPumpFieldSpec.fromJson displayLabels', () {
    const roi = {'left': 0.1, 'top': 0.1, 'width': 0.2, 'height': 0.1};
    final baseSpec = <String, dynamic>{
      'total': roi,
      'volume': roi,
      'pricePerLitre': roi,
    };

    test('no label keys → empty map', () {
      final spec = OcrPumpFieldSpec.fromJson(baseSpec);
      expect(spec, isNotNull);
      expect(spec!.displayLabels['total'], isNull);
      expect(spec.displayLabels['volume'], isNull);
      expect(spec.displayLabels['pricePerLitre'], isNull);
    });

    test('reads all three labels', () {
      final spec = OcrPumpFieldSpec.fromJson({
        ...baseSpec,
        'totalLabel': 'PRIX',
        'volumeLabel': 'VOLUME',
        'pricePerLitreLabel': 'PRIX DU LITRE',
      });
      expect(spec!.displayLabels['total'], 'PRIX');
      expect(spec.displayLabels['volume'], 'VOLUME');
      expect(spec.displayLabels['pricePerLitre'], 'PRIX DU LITRE');
    });

    test('empty string label is treated as absent', () {
      final spec = OcrPumpFieldSpec.fromJson({
        ...baseSpec,
        'totalLabel': '',
      });
      expect(spec!.displayLabels['total'], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // isRoiOverGlaredFromBytes — luminance classifier
  // ---------------------------------------------------------------------------
  group('isRoiOverGlaredFromBytes', () {
    test('all-white (255) bytes → over-glared', () {
      final bytes = List<int>.filled(1000, 255);
      expect(isRoiOverGlaredFromBytes(bytes), isTrue);
    });

    test('all-dark (0) bytes → not over-glared', () {
      final bytes = List<int>.filled(1000, 0);
      expect(isRoiOverGlaredFromBytes(bytes), isFalse);
    });

    test('mixed: 30 % near-white → not over-glared (threshold is 35 %)', () {
      // 300 bright + 700 dark → 30 % bright.
      final bytes = [
        ...List<int>.filled(300, 250),
        ...List<int>.filled(700, 10),
      ];
      expect(isRoiOverGlaredFromBytes(bytes), isFalse);
    });

    test('mixed: 40 % near-white → over-glared (exceeds 35 % threshold)', () {
      // 400 bright + 600 dark → 40 % bright.
      final bytes = [
        ...List<int>.filled(400, 250),
        ...List<int>.filled(600, 10),
      ];
      expect(isRoiOverGlaredFromBytes(bytes), isTrue);
    });

    test('empty bytes → not over-glared (no pixels)', () {
      expect(isRoiOverGlaredFromBytes([]), isFalse);
    });

    test('exactly at boundary (35 %) → not over-glared (threshold is exclusive)', () {
      // The check is > rejectAbove (0.35), so 35/100 = 0.35 → NOT glare.
      final bytes = [
        ...List<int>.filled(35, 250),
        ...List<int>.filled(65, 10),
      ];
      expect(isRoiOverGlaredFromBytes(bytes), isFalse);
    });

    test('one pixel above boundary (36 %) → over-glared', () {
      final bytes = [
        ...List<int>.filled(36, 250),
        ...List<int>.filled(64, 10),
      ];
      expect(isRoiOverGlaredFromBytes(bytes), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Shipped JSON asset — Tokheim FR has orientation + labels
  // ---------------------------------------------------------------------------
  group('Shipped index.json — Tokheim FR #2276 fields', () {
    test('tokheim FR template has vertical orientation and field labels', () {
      final raw = File('assets/ocr_config/index.json').readAsStringSync();
      final cfg = PumpOcrConfig.fromJsonString(raw);
      final t = cfg.templateFor(country: 'FR', brand: 'tokheim');
      expect(t, isNotNull);
      expect(t!.displayOrientation, OcrDisplayOrientation.vertical,
          reason: 'Tokheim FR is a vertically stacked display');
      expect(t.pumpDisplay?.displayLabels['total'], isNotNull,
          reason: 'PRIX label should be present');
      expect(t.pumpDisplay?.displayLabels['volume'], isNotNull,
          reason: 'VOLUME label should be present');
      expect(t.pumpDisplay?.displayLabels['pricePerLitre'], isNotNull,
          reason: 'PRIX DU LITRE label should be present');
    });
  });
}
