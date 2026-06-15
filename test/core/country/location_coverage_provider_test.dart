// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_detection_provider.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/country/location_coverage_provider.dart';

class _FakeDetected extends DetectedCountry {
  _FakeDetected(this._code);
  final String? _code;
  @override
  String? build() => _code;
}

void main() {
  ProviderContainer make({String? detected, bool configured = false}) {
    final c = ProviderContainer(overrides: [
      detectedCountryProvider.overrideWith(() => _FakeDetected(detected)),
      countryExplicitlyConfiguredProvider.overrideWithValue(configured),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('locationCoverage (#3361)', () {
    test('unknown before any country is detected', () {
      expect(make(detected: null).read(locationCoverageProvider),
          LocationCoverageStatus.unknown);
      expect(make(detected: '').read(locationCoverageProvider),
          LocationCoverageStatus.unknown);
    });

    test('unsupported for a country with no provider (US) — even configured',
        () {
      expect(make(detected: 'US', configured: true).read(locationCoverageProvider),
          LocationCoverageStatus.unsupported);
    });

    test('needsProfile: supported country (DE) but nothing configured', () {
      expect(make(detected: 'DE', configured: false).read(locationCoverageProvider),
          LocationCoverageStatus.needsProfile);
    });

    test('ok: supported country (DE) with a configured country', () {
      expect(make(detected: 'DE', configured: true).read(locationCoverageProvider),
          LocationCoverageStatus.ok);
    });
  });
}
