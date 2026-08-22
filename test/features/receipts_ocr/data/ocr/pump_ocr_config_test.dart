// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/receipts_ocr/data/ocr/pump_ocr_config.dart';

/// Coverage for the per-country OCR locale-profile registry (#2275):
/// JSON parse, validate-on-load (malformed entries skipped, not fatal),
/// profile lookup, and that the SHIPPED asset is well-formed. (#3765
/// removed the second layer — per-brand pump-display templates.)
void main() {
  group('PumpOcrConfig — parsing + lookup', () {
    const valid = '''
{
  "localeProfiles": [
    {"country":"FR","currency":"EUR","decimalSeparator":",",
     "priceMin":0.5,"priceMax":4.0,"volumeMax":200.0,"totalMax":500.0},
    {"country":"GB","currency":"GBP","decimalSeparator":".",
     "priceMin":0.8,"priceMax":3.0,"volumeMax":200.0,"totalMax":500.0}
  ]
}
''';

    test('loads profiles from a valid bundle', () {
      final cfg = PumpOcrConfig.fromJsonString(valid);
      expect(cfg.profileCount, 2);
    });

    test('profileFor is case-insensitive and exposes the ranges', () {
      final cfg = PumpOcrConfig.fromJsonString(valid);
      final fr = cfg.profileFor('fr');
      expect(fr, isNotNull);
      expect(fr!.currency, 'EUR');
      expect(fr.decimalSeparator, ',');
      expect(fr.priceInRange(1.999), isTrue);
      expect(fr.priceInRange(19.99), isFalse);
      expect(fr.volumeInRange(36.06), isTrue);
      expect(fr.totalInRange(79.91), isTrue);
    });

    test('malformed profile entries are skipped, not fatal', () {
      const partlyBad = '''
{
  "localeProfiles": [
    {"country":"FR","currency":"EUR","priceMin":0.5,"priceMax":4.0,
     "volumeMax":200.0,"totalMax":500.0},
    {"country":"","currency":"EUR","priceMin":0.5,"priceMax":4.0,
     "volumeMax":200.0,"totalMax":500.0},
    {"currency":"EUR"}
  ]
}
''';
      final cfg = PumpOcrConfig.fromJsonString(partlyBad);
      expect(cfg.profileCount, 1, reason: 'only the valid FR profile survives');
    });

    test('totally malformed JSON degrades to empty', () {
      final cfg = PumpOcrConfig.fromJsonString('not json {');
      expect(cfg.profileCount, 0);
    });
  });

  group('PumpOcrConfig — shipped asset', () {
    test('assets/ocr_config/index.json is valid and has FR + DE + GB', () {
      final raw = File('assets/ocr_config/index.json').readAsStringSync();
      final cfg = PumpOcrConfig.fromJsonString(raw);
      for (final country in const ['FR', 'DE', 'GB']) {
        expect(cfg.profileFor(country), isNotNull,
            reason: 'the shipped config must define the $country profile');
      }
    });
  });
}
