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
      // #3968 — count the BUILD lines only: a comment that names the define
      // (the AntiFeature block does) must not be mistaken for a build entry
      // passing it.
      final yaml = File('metadata/de.tankstellen.fuelprices.yml')
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('#'))
          .join('\n');
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

    // #3968 — the assertion that MATTERS, and the one whose absence let a
    // premature AntiFeature drop reach fdroiddata review. Passing the
    // define proves nothing on its own: Dart ignores a `--dart-define` no
    // code reads, so a recipe that pins a commit predating the reader
    // builds a binary that still talks to the developer's endpoints, with
    // a green pipeline and no warning anywhere.
    //
    // The invariant is therefore about the PINNED COMMIT, not the tree
    // this test runs in: no NonFreeNet ⇒ every pinned commit must contain
    // the reader; NonFreeNet ⇒ at least one pinned commit must lack it, so
    // the AntiFeature cannot go stale after a pin bump either.
    test('the AntiFeature state matches what the PINNED commits actually '
        'build (#3968)', () {
      final yaml =
          File('metadata/de.tankstellen.fuelprices.yml').readAsStringSync();
      final pinned = RegExp(r'^\s+commit:\s*([0-9a-f]{40})\s*$',
              multiLine: true)
          .allMatches(yaml)
          .map((m) => m.group(1)!)
          .toSet();
      expect(pinned, isNotEmpty,
          reason: 'every build entry pins a full commit sha');

      final declaresNonFreeNet =
          RegExp(r'^AntiFeatures:(?:\s*\n\s+-.*)*NonFreeNet',
                  multiLine: true)
              .hasMatch(yaml);

      final withoutReader = <String>[];
      for (final sha in pinned) {
        expect(_gitHas(sha), isTrue,
            reason: 'commit $sha is not in this clone — the check needs the '
                'object (CI checks out at fetch-depth: 0)');
        if (!_readsLibreDefine(sha)) withoutReader.add(sha);
      }

      if (declaresNonFreeNet) {
        expect(withoutReader, isNotEmpty,
            reason: 'every pinned commit now reads FDROID_LIBRE, so the '
                'NonFreeNet AntiFeature is stale — drop it in the same '
                'change that bumped the pin');
      } else {
        expect(withoutReader, isEmpty,
            reason: 'the recipe drops NonFreeNet while pinning '
                "${withoutReader.join(', ')}, which contains no reader for "
                'FDROID_LIBRE. Dart ignores an unread define, so that build '
                'still uses the developer-hosted tile proxy and the bundled '
                'TankSync defaults. Bump the pin or restore the AntiFeature');
      }
    });
  });
}

/// Whether [sha] resolves to a commit in this clone.
bool _gitHas(String sha) =>
    Process.runSync('git', ['cat-file', '-e', '$sha^{commit}']).exitCode == 0;

/// Whether the tree at [sha] contains code that READS the libre define.
/// `git grep` on a rev inspects that commit's tree, not the working copy —
/// which is the whole point: the working copy always has it.
bool _readsLibreDefine(String sha) =>
    Process.runSync('git', ['grep', '-l', 'FDROID_LIBRE', sha, '--', 'lib/'])
        .exitCode ==
    0;
