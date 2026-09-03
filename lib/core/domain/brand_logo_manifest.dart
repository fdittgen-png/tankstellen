// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'brand_logo_manifest_data.dart';
import 'brand_registry.dart';

/// Directory every bundled brand logo lives in. Listed explicitly in
/// `pubspec.yaml` — the `assets:` block is deliberately not wildcarded.
const String brandLogoAssetDir = 'assets/brand_logos';

/// One bundled brand logo, with the provenance that lets the credits
/// screen satisfy the file's licence (#3940).
///
/// Every field is DATA, not user-facing copy: brand names, Commons file
/// names, licence template names and author strings are reproduced
/// verbatim from Wikimedia Commons and must never be translated. Only the
/// surrounding labels on the credits screen come from ARB.
@immutable
class BrandLogoAsset {
  /// Canonical [BrandRegistry] brand name this logo depicts.
  final String brand;

  /// File name under [brandLogoAssetDir] (always a `.png` rendering —
  /// see the tool header for why the app bundles rasters, not SVG).
  final String assetFile;

  /// The Wikidata item the logo was resolved from, via `P154`.
  final String wikidataId;

  /// The Wikimedia Commons file name the raster was rendered from.
  final String commonsFile;

  /// The Commons licence template the file carries — `PD-textlogo`,
  /// `PD-shape`, `cc-by-sa-4.0` … Only public-domain and CC-BY / CC-BY-SA
  /// / CC0 files are ever bundled.
  final String licence;

  /// The file's author / attribution string, as Commons records it.
  final String author;

  /// The Commons file page, so a reader can verify the licence.
  final String sourceUrl;

  const BrandLogoAsset(
    this.brand,
    this.assetFile,
    this.wikidataId,
    this.commonsFile,
    this.licence,
    this.author,
    this.sourceUrl,
  );

  /// The `rootBundle` path `Image.asset` loads.
  String get assetPath => '$brandLogoAssetDir/$assetFile';
}

/// Lookup over [bundledBrandLogos].
///
/// The bundled logo is `BrandLogo`'s FIRST tier: it needs no network call
/// and is independent of the internet-logos privacy switch (#3870),
/// because the file ships inside the app. Brands with no free-licensed
/// logo — most of the registry — fall through to the #3930 monogram.
class BrandLogoManifest {
  BrandLogoManifest._();

  static Map<String, BrandLogoAsset>? _byBrand;

  static Map<String, BrandLogoAsset> get _index {
    return _byBrand ??= {
      for (final logo in bundledBrandLogos) logo.brand.toLowerCase(): logo,
    };
  }

  /// Every bundled logo, sorted by brand — the credits screen's source.
  static List<BrandLogoAsset> get all => bundledBrandLogos;

  /// The bundled logo for [rawBrand], or `null` when the brand has none.
  ///
  /// The raw string is canonicalised through [BrandRegistry] first, so
  /// every upstream spelling (`TOTAL ACCESS`, `Statoil`, `Star`) lands on
  /// the same file — the same resolution order `BrandAppearance.of` uses,
  /// so the bundled tier and the monogram tier can never disagree about
  /// which brand a station is.
  static BrandLogoAsset? of(String rawBrand) {
    final trimmed = rawBrand.trim();
    if (trimmed.isEmpty) return null;
    final canonical = BrandRegistry.canonicalize(trimmed) ?? trimmed;
    return _index[canonical.toLowerCase()];
  }
}
