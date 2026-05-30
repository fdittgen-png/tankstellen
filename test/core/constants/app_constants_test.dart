// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';

void main() {
  group('AppConstants.appVersion', () {
    test('returns build-time fallback before runtime initialization', () {
      // Before setRuntimeVersion is called, should return _buildVersion
      expect(AppConstants.appVersion, isNotEmpty);
      expect(AppConstants.appVersion, isNot('4.0.0'),
          reason: 'Stale 4.0.0 must never appear (#570)');
    });

    test('returns runtime version after setRuntimeVersion', () {
      AppConstants.setRuntimeVersion('5.0.0+5012');
      expect(AppConstants.appVersion, '5.0.0+5012');
    });

    test('runtime version overrides build-time constant', () {
      AppConstants.setRuntimeVersion('99.0.0+9999');
      expect(AppConstants.appVersion, '99.0.0+9999');
    });
  });

  group('OSM tile identity (#2396)', () {
    // A digit-dot-digit version pattern (e.g. "5.0.0").
    final versionPattern = RegExp(r'\d+\.\d+');

    test('osmUserAgent is stable + version-free', () {
      // OSM wants a STABLE identity, not one that changes per release.
      // Even after the runtime version is bumped, the OSM UA must not
      // carry a version number — otherwise every release looks like a
      // fresh client to OSM's abuse heuristics.
      AppConstants.setRuntimeVersion('7.3.1+7310');
      expect(
        versionPattern.hasMatch(AppConstants.osmUserAgent),
        isFalse,
        reason:
            'osmUserAgent must be version-free (#2396) — it is the bare '
            'package id, not "$AppConstants.userAgent".',
      );
      expect(AppConstants.osmUserAgent, AppConstants.appPackage);
    });

    test('the versioned userAgent stays versioned for data-API clients', () {
      AppConstants.setRuntimeVersion('7.3.1+7310');
      expect(
        versionPattern.hasMatch(AppConstants.userAgent),
        isTrue,
        reason:
            'Only the OSM/tile UA goes version-free; the data-API HTTP '
            'clients keep the versioned identity.',
      );
    });

    test('tileProxyUrl is a {z}/{x}/{y} Supabase functions template', () {
      // LAYER 2 (#2397) constant — defined now, wired later. The shape is
      // locked so the proxy contract test (LAYER 2) and the eventual
      // SparkiloTileLayer default flip have a stable target.
      expect(AppConstants.tileProxyUrl, contains('.supabase.co'));
      expect(AppConstants.tileProxyUrl, contains('/functions/v1/tiles'));
      expect(AppConstants.tileProxyUrl, contains('{z}/{x}/{y}'));
    });

    test('tileProxyOsmUserAgent carries a stable id + contact URL', () {
      expect(AppConstants.tileProxyOsmUserAgent, contains('tile-proxy'));
      expect(AppConstants.tileProxyOsmUserAgent, contains('https://'));
    });
  });
}
