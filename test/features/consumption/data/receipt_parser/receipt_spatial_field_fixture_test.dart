// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/ocr/ocr_trace_package.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_config.dart';
import 'package:tankstellen/features/consumption/data/ocr/recognized_text_block.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';

/// #3458 — the Pézenas E85 field fixture (REAL ML Kit blocks + boxes from
/// the 2026-07-03 debug export; image stripped).
///
/// Ground truth printed on the paper:
///   Volume  41.39 ℓ   ·   Prix € 0,899/ℓ   ·   TOT TTC € 37,21
///   ETHANOL 85, 02-07-2026.
///
/// On master the flat/anchored parser produced the scrambled triple
/// `liters 37.21 / pricePerLiter 41.39 / totalCost 1540.12 (derived)` and
/// the circular gate stamped it consistent at confidence 1.0 — this test
/// is RED on master by construction.
void main() {
  const fixturePath = 'test/fixtures/ocr_receipt_pezenas_e85_rotated.json';

  // FR profile mirroring the shipped config (priceMin 0.5 / priceMax 4.0).
  const frProfile = OcrLocaleProfile(
    country: 'FR',
    currency: 'EUR',
    decimalSeparator: ',',
    priceMin: 0.5,
    priceMax: 4.0,
    volumeMax: 200.0,
    totalMax: 500.0,
  );

  late final List<RecognizedTextBlock> blocks;
  late final String flatText;

  setUpAll(() {
    final raw =
        jsonDecode(File(fixturePath).readAsStringSync()) as Map<String, dynamic>;
    final mlkit = raw['mlkit'] as Map<String, dynamic>;
    flatText = mlkit['flatText'] as String;
    blocks = [
      for (final b in (mlkit['blocks'] as List).cast<Map<String, dynamic>>())
        RecognizedTextBlock(
          text: b['text'] as String,
          box: OcrBox(
            left: ((b['box'] as List)[0] as num).toDouble(),
            top: ((b['box'] as List)[1] as num).toDouble(),
            right: ((b['box'] as List)[2] as num).toDouble(),
            bottom: ((b['box'] as List)[3] as num).toDouble(),
          ),
        ),
    ];
  });

  const parser = ReceiptParser();

  void expectGroundTruth(ReceiptParseResult r) {
    expect(r.liters, closeTo(41.39, 0.001),
        reason: 'Volume row → 41.39 L (master read 37.21)');
    expect(r.pricePerLiter, closeTo(0.899, 0.0001),
        reason: 'Prix row "€ 0,899/?" → 0.899 €/L despite the mangled '
            '/ℓ suffix (master read 41.39)');
    expect(r.totalCost, closeTo(37.21, 0.001),
        reason: 'TOT TIC (TTC↔TIC OCR confusion) row → 37.21 € '
            '(master DERIVED 1540.12)');
    expect(r.derived, isEmpty,
        reason: 'all three fields were independently READ — the derived '
            'total tautology is dead');
    expect(r.validated, isTrue,
        reason: '41.39 × 0.899 = 37.209 ≈ 37.21 over READ fields');
    expect(r.brandLayout, 'fuel_station');
  }

  group('#3458 — Pézenas E85 field fixture (RED on master)', () {
    test('parses the correct triple + fuel + date', () {
      final r = parser.parseBlocks(blocks, flatText, profile: frProfile);
      expectGroundTruth(r);
      expect(r.fuelType, FuelType.e85, reason: 'ETHANOL 85 product line');
      expect(r.date, DateTime(2026, 7, 2));
      // The master failure mode, spelled out:
      expect(r.totalCost, isNot(closeTo(1540.12, 0.01)));
      expect(r.liters, isNot(closeTo(37.21, 0.001)));
      expect(r.pricePerLiter, isNot(closeTo(41.39, 0.001)));
    });

    test('parses identically with NO locale profile (currency-aware: the '
        'printed € selects EUR ranges)', () {
      final r = parser.parseBlocks(blocks, flatText);
      expectGroundTruth(r);
    });

    test('debug export carries the per-field pairing decisions', () {
      final trace = OcrTraceRecorder(kind: OcrTraceKind.receipt);
      parser.parseBlocks(blocks, flatText, profile: frProfile, trace: trace);
      final package = trace.build();
      final byField = {for (final p in package.pairings) p.field: p};

      expect(byField['unitPrice']?.labelText, 'Prix');
      expect(byField['unitPrice']?.valueText, '€ 0,899/?');
      expect(byField['unitPrice']?.rule, 'row-overlap');
      expect(byField['total']?.labelText, 'TOT TIC');
      expect(byField['total']?.value, closeTo(37.21, 0.001));
      expect(byField['volume']?.value, closeTo(41.39, 0.001));
      expect(byField['vat']?.rule, 'vat-row-excluded');
      expect(byField['vat']?.value, closeTo(6.20, 0.001));
      expect(byField['net']?.rule, 'net-row-excluded');
      expect(byField['net']?.value, closeTo(31.01, 0.001));

      // The export schema keeps its sections and adds `pairings`.
      final json = package.toJson(includeImage: false);
      expect(json['pairings'], isNotEmpty);
      expect(json['gate'], isNotNull);
      expect(json['result'], isNotNull);
    });
  });

  group('#3458 — rotation invariance (90°/180°/270°)', () {
    // The fixture frame is ~1000 × 1900 px.
    const w0 = 1000.0;
    const h0 = 1900.0;

    List<RecognizedTextBlock> rotate(
      List<RecognizedTextBlock> src,
      int quarterTurns,
    ) {
      var out = src;
      var height = h0;
      var width = w0;
      for (var i = 0; i < quarterTurns; i++) {
        out = [for (final b in out) b.rotate90(height)];
        final nextHeight = width;
        width = height;
        height = nextHeight;
      }
      return out;
    }

    for (final turns in const [1, 2, 3]) {
      test('${turns * 90}°-rotated block set parses identically', () {
        final r = parser.parseBlocks(
          rotate(blocks, turns),
          flatText,
          profile: frProfile,
        );
        expectGroundTruth(r);
      });
    }
  });
}
