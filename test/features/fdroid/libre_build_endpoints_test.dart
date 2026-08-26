// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3788 — the F-Droid variant must reach NO developer-hosted service by
// default. fdroiddata's static review of MR !42093 blocked the app on
// exactly this (a fixed Supabase tile proxy + a bundled
// tanksync_config.json pointing at the developer's instance), so these
// tests pin both the switch's behaviour and the build wiring that sets
// it — a silently-dropped `--dart-define` would restore the endpoints
// without any code change to notice.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/constants/libre_build.dart';

void main() {
  group('#3788 libre-build endpoint policy', () {
    test('the tile proxy resolves empty on a libre build and the map '
        'falls back to OSM-direct', () {
      if (kLibreBuild) {
        expect(AppConstants.tileProxyUrl, isEmpty);
        expect(AppConstants.effectiveTileUrl, AppConstants.osmTileUrl,
            reason: 'an empty proxy must fall back, never render grey');
      } else {
        // The default build keeps the proxy; the fallback still has to
        // work, because that is the mechanism the libre build relies on.
        expect(AppConstants.tileProxyUrl, isNotEmpty);
        expect(AppConstants.effectiveTileUrl, AppConstants.tileProxyUrl);
      }
    });

    test('effectiveTileUrl never returns an empty template', () {
      expect(AppConstants.effectiveTileUrl, isNotEmpty);
      expect(AppConstants.effectiveTileUrl, contains('{z}'));
    });
  });

  group('#3788 build wiring — the define actually reaches the binary', () {
    // The switch is worthless if a build forgets to pass it, and that
    // failure is invisible at runtime (the app just quietly uses the
    // developer's endpoints again). Pin every F-Droid build path.
    test('the fdroiddata recipe passes FDROID_LIBRE on every build entry',
        () {
      final yaml =
          File('metadata/de.tankstellen.fuelprices.yml').readAsStringSync();
      final entries = RegExp(r'^  - versionName:', multiLine: true)
          .allMatches(yaml)
          .length;
      final defines = '--dart-define=FDROID_LIBRE=true'.allMatches(yaml).length;
      expect(entries, greaterThan(0), reason: 'the recipe must build something');
      expect(defines, entries,
          reason: 'every per-ABI build entry must carry the libre define — '
              'one missing entry ships a binary that phones the '
              "developer's Supabase");
    });

    test('the self-hosted publish script passes FDROID_LIBRE too', () {
      final sh = File('scripts/fdroid_publish.sh').readAsStringSync();
      expect(sh, contains('--dart-define=FDROID_LIBRE=true'),
          reason: 'the self-hosted repo ships a prebuilt APK from this '
              'script — it must be libre by the same rule');
    });

    test('the recipe declares no AntiFeature, since its cause is gone', () {
      final yaml =
          File('metadata/de.tankstellen.fuelprices.yml').readAsStringSync();
      expect(yaml, isNot(contains('AntiFeatures:')),
          reason: 'NonFreeNet was declared only for the developer-hosted '
              'defaults #3788 removes; leaving it would misreport the app');
    });
  });
}
