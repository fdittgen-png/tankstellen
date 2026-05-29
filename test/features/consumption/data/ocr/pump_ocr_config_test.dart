// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/ocr/pump_ocr_config.dart';

/// Coverage for the per-country/brand OCR config registry (#2275): JSON
/// parse, validate-on-load (malformed entries skipped, not fatal),
/// profile + template lookup, and that the SHIPPED asset is well-formed.
void main() {
  group('PumpOcrConfig — parsing + lookup', () {
    const valid = '''
{
  "localeProfiles": [
    {"country":"FR","currency":"EUR","decimalSeparator":",",
     "priceMin":0.5,"priceMax":4.0,"volumeMax":200.0,"totalMax":500.0},
    {"country":"GB","currency":"GBP","decimalSeparator":".",
     "priceMin":0.8,"priceMax":3.0,"volumeMax":200.0,"totalMax":500.0}
  ],
  "brands": [
    {"brand":"Tokheim","country":"FR","label":"Tokheim (FR)",
     "pumpDisplay":{
       "total":{"left":0.30,"top":0.30,"width":0.20,"height":0.07},
       "volume":{"left":0.30,"top":0.37,"width":0.20,"height":0.07},
       "pricePerLitre":{"left":0.44,"top":0.31,"width":0.10,"height":0.10}
     }}
  ]
}
''';

    test('loads profiles + brands from a valid bundle', () {
      final cfg = PumpOcrConfig.fromJsonString(valid);
      expect(cfg.profileCount, 2);
      expect(cfg.brandCount, 1);
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

    test('templateFor matches brand+country, falls back to country-only', () {
      final cfg = PumpOcrConfig.fromJsonString(valid);
      final exact = cfg.templateFor(country: 'FR', brand: 'tokheim');
      expect(exact, isNotNull);
      expect(exact!.pumpDisplay, isNotNull);
      // Unknown brand in a configured country → country-only fallback.
      final fallback = cfg.templateFor(country: 'FR', brand: 'unknown');
      expect(fallback, isNotNull);
      // Unconfigured country → nothing.
      expect(cfg.templateFor(country: 'ZZ'), isNull);
    });

    test('malformed profile / brand entries are skipped, not fatal', () {
      const partlyBad = '''
{
  "localeProfiles": [
    {"country":"FR","currency":"EUR","priceMin":0.5,"priceMax":4.0,
     "volumeMax":200.0,"totalMax":500.0},
    {"country":"","currency":"EUR","priceMin":0.5,"priceMax":4.0,
     "volumeMax":200.0,"totalMax":500.0},
    {"currency":"EUR"}
  ],
  "brands": [
    {"country":"FR"},
    {"brand":"x","country":"FR"}
  ]
}
''';
      final cfg = PumpOcrConfig.fromJsonString(partlyBad);
      expect(cfg.profileCount, 1, reason: 'only the valid FR profile survives');
      expect(cfg.brandCount, 1, reason: 'only the brand with a brand id survives');
    });

    test('totally malformed JSON degrades to empty', () {
      final cfg = PumpOcrConfig.fromJsonString('not json {');
      expect(cfg.profileCount, 0);
      expect(cfg.brandCount, 0);
    });
  });

  group('PumpOcrConfig — shipped asset', () {
    test('assets/ocr_config/index.json is valid and has FR + Tokheim', () {
      final raw = File('assets/ocr_config/index.json').readAsStringSync();
      final cfg = PumpOcrConfig.fromJsonString(raw);
      expect(cfg.profileFor('FR'), isNotNull,
          reason: 'the shipped config must define the FR locale profile');
      final tokheim = cfg.templateFor(country: 'FR', brand: 'tokheim');
      expect(tokheim, isNotNull);
      expect(tokheim!.pumpDisplay, isNotNull,
          reason: 'FR/Tokheim must carry pump-display field ROIs');
    });
  });
}
