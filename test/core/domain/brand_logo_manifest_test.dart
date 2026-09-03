// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/brand_logo_manifest.dart';
import 'package:tankstellen/core/domain/brand_registry.dart';

/// Drift + licence guard for the bundled brand logos (#3940).
///
/// The manifest and `assets/brand_logos/` are produced together by
/// `dart run tool/fetch_brand_logos.dart`, but nothing stops a later hand
/// edit from deleting one side. A file with no manifest entry ships
/// artwork whose licence and attribution are nowhere in the app — which
/// is exactly the CC-BY condition the credits screen exists to satisfy;
/// a manifest entry with no file renders Flutter's broken-image glyph.
/// Both directions are pinned here.
void main() {
  /// Licences a bundled file may carry. Anything else — a "non-free
  /// logo" / fair-use tag above all, but equally a NonCommercial or
  /// NoDerivatives CC variant — must never reach `assets/`: the assets
  /// ship in the F-Droid build, which would then need a `NonFreeAssets`
  /// anti-feature.
  bool isAcceptedLicence(String raw) {
    final key = raw.toLowerCase().trim();
    if (key.isEmpty) return false;
    if (RegExp(r'(^|[-_ ])(nc|nd)([-_ ]|$)').hasMatch(key)) return false;
    if (key.contains('fair') || key.contains('non-free')) return false;
    return key == 'pd' ||
        key == 'public domain' ||
        key.startsWith('pd-') ||
        key == 'cc0' ||
        key == 'cc-zero' ||
        key.startsWith('cc0-') ||
        key.startsWith('cc-by') ||
        key.startsWith('cc by');
  }

  List<File> assetFiles() {
    final dir = Directory(brandLogoAssetDir);
    expect(dir.existsSync(), isTrue,
        reason: '$brandLogoAssetDir must exist — run '
            '`dart run tool/fetch_brand_logos.dart`.');
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.png'))
        .toList();
  }

  group('bundled brand logos', () {
    test('the manifest is not empty', () {
      expect(BrandLogoManifest.all, isNotEmpty);
    });

    test('every manifest entry has a file on disk', () {
      final missing = [
        for (final logo in BrandLogoManifest.all)
          if (!File(logo.assetPath).existsSync()) logo.assetPath,
      ];
      expect(missing, isEmpty,
          reason: 'manifest entries without an asset render a broken image');
    });

    test('every asset on disk has a manifest entry', () {
      final declared = {
        for (final logo in BrandLogoManifest.all) logo.assetFile,
      };
      final orphans = [
        for (final file in assetFiles())
          if (!declared.contains(file.uri.pathSegments.last))
            file.uri.pathSegments.last,
      ];
      expect(orphans, isEmpty,
          reason: 'an asset with no manifest entry ships artwork whose '
              'licence and author appear nowhere in the credits screen');
    });

    test('every entry carries a non-empty licence, author and source', () {
      for (final logo in BrandLogoManifest.all) {
        expect(logo.licence.trim(), isNotEmpty, reason: logo.brand);
        expect(logo.author.trim(), isNotEmpty, reason: logo.brand);
        expect(logo.sourceUrl.trim(), isNotEmpty, reason: logo.brand);
        expect(logo.commonsFile.trim(), isNotEmpty, reason: logo.brand);
        expect(logo.wikidataId, matches(RegExp(r'^Q\d+$')),
            reason: logo.brand);
        expect(logo.sourceUrl,
            startsWith('https://commons.wikimedia.org/wiki/File:'),
            reason: '${logo.brand} — the source must be verifiable');
      }
    });

    test('no entry carries a licence outside the accepted set', () {
      final rejected = [
        for (final logo in BrandLogoManifest.all)
          if (!isAcceptedLicence(logo.licence)) '${logo.brand}: ${logo.licence}',
      ];
      expect(rejected, isEmpty,
          reason: 'only public-domain and CC-BY / CC-BY-SA / CC0 files may '
              'be bundled — see tool/fetch_brand_logos.dart');
    });

    test('brands and asset file names are unique', () {
      final brands = BrandLogoManifest.all.map((l) => l.brand).toList();
      final files = BrandLogoManifest.all.map((l) => l.assetFile).toList();
      expect(brands.toSet().length, brands.length);
      expect(files.toSet().length, files.length);
    });

    test('every manifest brand is a canonical registry brand', () {
      final canonical = BrandRegistry.allBrands.toSet();
      final unknown = [
        for (final logo in BrandLogoManifest.all)
          if (!canonical.contains(logo.brand)) logo.brand,
      ];
      expect(unknown, isEmpty,
          reason: 'a manifest key that is not a canonical brand can never '
              'be resolved by BrandLogoManifest.of');
    });

    test('the asset directory is declared in pubspec.yaml', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- $brandLogoAssetDir/'),
          reason: 'the assets: block is not wildcarded — an undeclared '
              'directory ships zero logos at runtime while every test '
              'that reads the filesystem still passes');
    });
  });

  group('BrandLogoManifest.of', () {
    test('resolves an upstream alias through the registry', () {
      // `Statoil` is a Circle K alias; `SHELL` is a raw upstream spelling.
      expect(BrandLogoManifest.of('SHELL')?.brand, 'Shell');
      expect(BrandLogoManifest.of('Statoil')?.brand, 'Circle K');
      expect(BrandLogoManifest.of('INTERMARCHE')?.brand, 'Intermarché');
    });

    test('returns null for a brand with no free-licensed logo', () {
      // Coopérative U carries no P154 and its stylised U is copyrighted —
      // the honest outcome is the monogram, not an approximation.
      expect(BrandLogoManifest.of('Super U'), isNull);
      expect(BrandLogoManifest.of('Carrefour'), isNull);
    });

    test('returns null for an unknown or empty brand', () {
      expect(BrandLogoManifest.of(''), isNull);
      expect(BrandLogoManifest.of('   '), isNull);
      expect(BrandLogoManifest.of('Definitely Not A Brand'), isNull);
    });
  });
}
