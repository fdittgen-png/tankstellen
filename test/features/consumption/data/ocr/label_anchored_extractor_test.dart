// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/label_anchored_extractor.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/consumption/data/ocr/recognized_text_block.dart';

/// Label-anchored pump-display extractor coverage — issue #2478, the
/// "test it first on those photos" requirement.
///
/// ## Ground-truth source
///
/// The maintainer's two real FR Tokheim photos are committed at
/// `test/fixtures/pump_displays/fr_tokheim/fr_tokheim_sample1.jpg` and
/// `…_sample2.jpg`. Both display the SAME transaction:
///
///   * PRIX (total)         = 18,59 €
///   * VOLUME               = 23,30 L
///   * PRIX DU LITRE (unit) = 0,798 €/L     (0.798 × 23.30 = 18.59 ✓)
///
/// On master only PRIX + VOLUME read; PRIX DU LITRE — the lower-left
/// unit price, washed out by glare and swallowed by the bare-`PRIX`
/// regex prefix collision — dropped. ML Kit needs a platform channel and
/// cannot run in `flutter test`, so (as with the #948 fixtures) we hand-
/// build the block list a real photo of each produces: the three labels,
/// their three values, plus the pollution blocks (metrology header, card
/// reader, TOKHEIM branding, station sticker, "Vmin = 5L") that must be
/// ignored. The geometry mirrors the upright, EXIF-baked readout: each
/// label sits directly ABOVE its value (FR Tokheim vertical layout).
void main() {
  // FR profile from the shipped config (priceMin 0.5 / priceMax 4.0).
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
      RecognizedTextBlock(text: text, box: OcrBox(left: l, top: t, right: r, bottom: b));

  /// Upright FR Tokheim readout for the two sample photos. PRIX 18,59 on
  /// top-left, VOLUME 23,30 mid, PRIX DU LITRE 0,798 lower-left, each
  /// label directly ABOVE its value, plus the pollution blocks.
  List<RecognizedTextBlock> samplePhotoBlocks() => <RecognizedTextBlock>[
        // --- transaction labels + values (vertical: value below label) --
        block('PRIX', l: 40, t: 100, r: 130, b: 130),
        block('18,59', l: 40, t: 140, r: 200, b: 185),
        block('VOLUME', l: 40, t: 220, r: 170, b: 250),
        block('23,30', l: 40, t: 260, r: 200, b: 305),
        block('PRIX DU LITRE', l: 40, t: 340, r: 230, b: 370),
        block('0,798', l: 40, t: 380, r: 180, b: 420),
        // --- pollution that MUST be ignored -----------------------------
        block('Note du service de la Métrologie', l: 400, t: 20, r: 720, b: 50),
        block('Seules les indications de prix', l: 400, t: 55, r: 760, b: 80),
        block('TOKHEIM', l: 300, t: 600, r: 460, b: 660),
        block('Vmin = 5L', l: 700, t: 20, r: 820, b: 55),
        block('3', l: 720, t: 600, r: 760, b: 660),
      ];

  group('#2478 — both sample photos read the SAME triple', () {
    for (final photo in const ['sample1', 'sample2']) {
      test('fr_tokheim_$photo: 18.59 € / 23.30 L / 0.798 €/L, consistent', () {
        final r = extractByLabelAnchor(samplePhotoBlocks(), profile: frProfile);
        expect(r.totalCost, closeTo(18.59, 0.001));
        expect(r.liters, closeTo(23.30, 0.001));
        expect(r.pricePerLiter, closeTo(0.798, 0.001));
        expect(r.isConsistent, isTrue);
        // All three read directly — nothing derived.
        expect(r.derived, isEmpty);
      });
    }
  });

  group('#2478 — PRIX vs PRIX DU LITRE disambiguation', () {
    test('bare PRIX → total amount; PRIX DU LITRE → unit price', () {
      // The root bug: a bare-PRIX regex prefix-matched PRIX DU LITRE and
      // swallowed the unit price. Longest-match must split them.
      final r = extractByLabelAnchor(samplePhotoBlocks(), profile: frProfile);
      expect(r.totalCost, closeTo(18.59, 0.001),
          reason: 'PRIX anchors the 18,59 total, not the 0,798 unit price');
      expect(r.pricePerLiter, closeTo(0.798, 0.001),
          reason: 'PRIX DU LITRE anchors the 0,798 unit price');
    });

    test('assembles a label split across two blocks: "PRIX DU" + "LITRE"', () {
      final blocks = <RecognizedTextBlock>[
        block('PRIX', l: 40, t: 100, r: 130, b: 130),
        block('18,59', l: 40, t: 140, r: 200, b: 185),
        block('VOLUME', l: 40, t: 220, r: 170, b: 250),
        block('23,30', l: 40, t: 260, r: 200, b: 305),
        // ML Kit split the wrapped unit-price label across two blocks.
        block('PRIX DU', l: 40, t: 340, r: 150, b: 370),
        block('LITRE', l: 40, t: 372, r: 130, b: 400),
        block('0,798', l: 40, t: 410, r: 180, b: 450),
      ];
      final r = extractByLabelAnchor(blocks, profile: frProfile);
      expect(r.totalCost, closeTo(18.59, 0.001));
      expect(r.liters, closeTo(23.30, 0.001));
      expect(r.pricePerLiter, closeTo(0.798, 0.001));
      expect(r.isConsistent, isTrue);
    });
  });

  group('#2478 — cross-check derives a dropped field', () {
    test('drop the 0,798 unit price → price DERIVED = 18.59/23.30 = 0.798', () {
      final blocks = samplePhotoBlocks()
          .where((b) => b.text != '0,798' && b.text != 'PRIX DU LITRE')
          .toList();
      final r = extractByLabelAnchor(blocks, profile: frProfile);
      expect(r.totalCost, closeTo(18.59, 0.001));
      expect(r.liters, closeTo(23.30, 0.001));
      expect(r.pricePerLiter, closeTo(0.798, 0.001),
          reason: '18.59 / 23.30 = 0.7979… rounds to 0.798');
      expect(r.derived, contains(PumpField.pricePerLitre));
      expect(r.isConsistent, isTrue);
    });

    test('drop the 18,59 total → total DERIVED = 23.30 × 0.798 = 18.59', () {
      final blocks = samplePhotoBlocks()
          .where((b) => b.text != '18,59' && b.text != 'PRIX')
          .toList();
      final r = extractByLabelAnchor(blocks, profile: frProfile);
      expect(r.liters, closeTo(23.30, 0.001));
      expect(r.pricePerLiter, closeTo(0.798, 0.001));
      expect(r.totalCost, closeTo(18.59, 0.001),
          reason: '23.30 × 0.798 = 18.5934 rounds to 18.59');
      expect(r.derived, contains(PumpField.total));
      expect(r.isConsistent, isTrue);
    });
  });

  group('#2478 — 90° rotation invariance', () {
    test('rotating every box (x,y)→(H−y,x) yields the identical triple', () {
      const imageHeight = 700.0;
      final upright = samplePhotoBlocks();
      final rotated =
          upright.map((b) => b.rotate90(imageHeight)).toList();

      final a = extractByLabelAnchor(upright, profile: frProfile);
      final b = extractByLabelAnchor(rotated, profile: frProfile);

      expect(b.totalCost, closeTo(a.totalCost!, 0.0001));
      expect(b.liters, closeTo(a.liters!, 0.0001));
      expect(b.pricePerLiter, closeTo(a.pricePerLiter!, 0.0001));
      expect(b.totalCost, closeTo(18.59, 0.001));
      expect(b.liters, closeTo(23.30, 0.001));
      expect(b.pricePerLiter, closeTo(0.798, 0.001));
      expect(b.isConsistent, isTrue);
    });
  });

  group('#2478 — magnitude fallback with no labels', () {
    test('three bare numbers bucket by range + decimal signature', () {
      final blocks = <RecognizedTextBlock>[
        block('18,59', l: 40, t: 140, r: 200, b: 185),
        block('23,30', l: 40, t: 260, r: 200, b: 305),
        block('0,798', l: 40, t: 380, r: 180, b: 420),
      ];
      final r = extractByLabelAnchor(blocks, profile: frProfile);
      expect(r.pricePerLiter, closeTo(0.798, 0.001),
          reason: '3-decimal in 0.5..4.0 range → unit price');
      expect(r.liters, closeTo(23.30, 0.001), reason: 'larger 2-dec → volume');
      expect(r.totalCost, closeTo(18.59, 0.001),
          reason: 'smaller 2-dec is total, but cross-check keeps them paired');
      expect(r.isConsistent, isTrue);
    });
  });

  group('#2478 — out-of-range reject is left for the gate', () {
    test('a 7.98 €/L misread anchors but fails the FR price range', () {
      // A mis-decoded unit price (decimal point shifted) reads 7,98 — the
      // extractor still anchors it, but it is outside FR priceMax 4.0 so
      // the validation gate (run by the orchestrator) rejects the read.
      final blocks = <RecognizedTextBlock>[
        block('PRIX', l: 40, t: 100, r: 130, b: 130),
        block('18,59', l: 40, t: 140, r: 200, b: 185),
        block('VOLUME', l: 40, t: 220, r: 170, b: 250),
        block('23,30', l: 40, t: 260, r: 200, b: 305),
        block('PRIX DU LITRE', l: 40, t: 340, r: 230, b: 370),
        block('7,98', l: 40, t: 380, r: 180, b: 420),
      ];
      final r = extractByLabelAnchor(blocks, profile: frProfile);
      expect(r.pricePerLiter, closeTo(7.98, 0.001));
      expect(frProfile.priceInRange(r.pricePerLiter!), isFalse,
          reason: '7.98 €/L is above the FR priceMax of 4.0');
      // It also fails the identity (23.30 × 7.98 ≫ 18.59) so the gate
      // rejects on either ground.
      expect(r.isConsistent, isFalse);
    });
  });

  group('#2478 — empty input', () {
    test('no blocks → empty result', () {
      final r = extractByLabelAnchor(const [], profile: frProfile);
      expect(r.boundCount, 0);
      expect(r.totalCost, isNull);
    });
  });

  group('#2478 — the two source sample photos are committed', () {
    // The hand-built block fixtures above were transcribed from these
    // two real maintainer photos. They are committed so the read can be
    // re-verified by eye and the fixtures regenerated if a future OCR
    // pass produces materially different blocks.
    const dir = 'test/fixtures/pump_displays/fr_tokheim';
    for (final name in const ['fr_tokheim_sample1', 'fr_tokheim_sample2']) {
      test('$name.jpg is present and decodes as a JPEG', () {
        final file = File('$dir/$name.jpg');
        expect(file.existsSync(), isTrue,
            reason: '$name.jpg must be committed as the fixture source');
        expect(img.decodeJpg(file.readAsBytesSync()), isNotNull,
            reason: '$name.jpg must be a valid JPEG');
      });
    }
  });
}
