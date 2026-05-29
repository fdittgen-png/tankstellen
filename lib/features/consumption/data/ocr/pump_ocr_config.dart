// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/logging/error_logger.dart';
import 'ocr_geometry.dart';

/// The physical orientation of a pump display readout (#2276).
///
/// [horizontal] — the three value groups are arranged in a wide,
/// left-to-right strip (e.g. Tokheim FR pumps with PRIX | VOLUME |
/// PRIX DU LITRE side by side, which is the default and matches the
/// existing 16∶5 reticle).
///
/// [vertical] — the values are stacked top-to-bottom, common on many
/// German / Italian pumps (Betrag on top, Abgabe in the middle, Preis
/// below).  The reticle switches to a narrow portrait aspect for these.
enum OcrDisplayOrientation {
  horizontal,
  vertical;

  /// Parse from a JSON string (`"horizontal"` / `"vertical"`). Returns
  /// [horizontal] for any unknown / missing value so old config entries
  /// are always forward-compatible.
  static OcrDisplayOrientation fromJson(Object? raw) {
    if (raw == 'vertical') return vertical;
    return horizontal;
  }
}

/// Country-scoped numeric expectations for a pump readout (#2275).
///
/// Drops the old EUR-hardcoded assumptions: the currency, decimal
/// separator and the sane value ranges all come from JSON so the same
/// parser + validation gate works for GBP/£/p-per-litre, DKK/kr, etc.
/// once their profiles are added. The validation gate (in the parser)
/// uses [priceMin]/[priceMax]/[volumeMax]/[totalMax] to reject a read
/// whose magnitudes are not domain-sane for the active country.
@immutable
class OcrLocaleProfile {
  /// ISO country code this profile applies to (e.g. `FR`).
  final String country;

  /// Currency code shown on the display (e.g. `EUR`). Data, not UI —
  /// carries an `i18n-ignore` at the call site.
  final String currency;

  /// Decimal separator the display uses (`,` for FR, `.` for UK).
  final String decimalSeparator;

  final double priceMin;
  final double priceMax;
  final double volumeMax;
  final double totalMax;

  const OcrLocaleProfile({
    required this.country,
    required this.currency,
    required this.decimalSeparator,
    required this.priceMin,
    required this.priceMax,
    required this.volumeMax,
    required this.totalMax,
  });

  /// `true` when [price] is a plausible per-litre unit price for this
  /// country.
  bool priceInRange(double price) => price >= priceMin && price <= priceMax;

  /// `true` when [volume] is a plausible litres reading.
  bool volumeInRange(double volume) => volume > 0 && volume <= volumeMax;

  /// `true` when [total] is a plausible total charge.
  bool totalInRange(double total) => total > 0 && total <= totalMax;

  static OcrLocaleProfile? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final country = raw['country'];
    final currency = raw['currency'];
    if (country is! String || country.isEmpty) return null;
    if (currency is! String || currency.isEmpty) return null;
    final sep = raw['decimalSeparator'];
    final priceMin = _num(raw['priceMin']);
    final priceMax = _num(raw['priceMax']);
    final volumeMax = _num(raw['volumeMax']);
    final totalMax = _num(raw['totalMax']);
    if (priceMin == null ||
        priceMax == null ||
        volumeMax == null ||
        totalMax == null) {
      return null;
    }
    if (priceMin <= 0 || priceMax <= priceMin) return null;
    return OcrLocaleProfile(
      country: country,
      currency: currency,
      decimalSeparator: sep is String && sep.isNotEmpty ? sep : ',',
      priceMin: priceMin,
      priceMax: priceMax,
      volumeMax: volumeMax,
      totalMax: totalMax,
    );
  }

  static double? _num(Object? v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
}

/// The three value fields of a pump display, each with the normalized
/// ROI the segment recognizer should read (relative to the upright,
/// reticle-cropped frame), plus the data label shown on the physical
/// display (e.g. "PRIX", "VOLUME") so the alignment overlay can draw
/// the correct guide text without hard-coding any locale-specific name.
@immutable
class OcrPumpFieldSpec {
  final OcrNormalizedRect total;
  final OcrNormalizedRect volume;
  final OcrNormalizedRect pricePerLitre;

  /// Label printed on the pump display for each field, keyed by field
  /// name (`"total"` / `"volume"` / `"pricePerLitre"`). These are DATA
  /// values from the JSON (e.g. "PRIX", "VOLUME", "PRIX DU LITRE") and
  /// are never user-facing text in the ARB sense — they replicate what
  /// the user can already see printed on the physical display.
  ///
  /// Null entries fall back to a generic slot label in the overlay.
  final Map<String, String?> displayLabels;

  const OcrPumpFieldSpec({
    required this.total,
    required this.volume,
    required this.pricePerLitre,
    this.displayLabels = const {},
  });

  static OcrPumpFieldSpec? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final total = OcrNormalizedRect.fromJson(raw['total']);
    final volume = OcrNormalizedRect.fromJson(raw['volume']);
    final ppl = OcrNormalizedRect.fromJson(raw['pricePerLitre']);
    if (total == null || volume == null || ppl == null) return null;
    final labels = <String, String?>{};
    for (final key in ['total', 'volume', 'pricePerLitre']) {
      final v = raw['${key}Label'];
      labels[key] = v is String && v.isNotEmpty ? v : null;
    }
    return OcrPumpFieldSpec(
      total: total,
      volume: volume,
      pricePerLitre: ppl,
      displayLabels: labels,
    );
  }
}

/// A single brand/template entry: which station brand it covers, the
/// country whose [OcrLocaleProfile] applies, and the pump-display field
/// ROIs. The receipt side keeps using [ReceiptOverrideRegistry]; this
/// is the pump-display analogue the Epic asked for.
@immutable
class OcrBrandTemplate {
  /// Brand id (e.g. `tokheim`). Matched against the station's brand.
  final String brand;

  /// ISO country code keying into the locale profiles.
  final String country;

  /// Display name for diagnostics (not user-facing).
  final String label;

  /// Pump-display field ROIs, or `null` when this template only carries
  /// receipt hints (forward-compatible).
  final OcrPumpFieldSpec? pumpDisplay;

  /// How the three numeric fields are physically laid out on the pump
  /// display (#2276). Drives the aspect ratio of the framing overlay
  /// (wide strip for [OcrDisplayOrientation.horizontal], narrow column
  /// for [OcrDisplayOrientation.vertical]).
  ///
  /// Defaults to [OcrDisplayOrientation.horizontal] so existing entries
  /// without the key continue to work unchanged.
  final OcrDisplayOrientation displayOrientation;

  const OcrBrandTemplate({
    required this.brand,
    required this.country,
    required this.label,
    this.pumpDisplay,
    this.displayOrientation = OcrDisplayOrientation.horizontal,
  });

  static OcrBrandTemplate? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final brand = raw['brand'];
    final country = raw['country'];
    if (brand is! String || brand.isEmpty) return null;
    if (country is! String || country.isEmpty) return null;
    final label = raw['label'];
    return OcrBrandTemplate(
      brand: brand.toLowerCase(),
      country: country.toUpperCase(),
      label: label is String ? label : brand,
      pumpDisplay: OcrPumpFieldSpec.fromJson(raw['pumpDisplay']),
      displayOrientation:
          OcrDisplayOrientation.fromJson(raw['displayOrientation']),
    );
  }
}

/// Loads and validates the per-country/brand OCR config bundle (#2275),
/// generalizing the receipt-only [ReceiptOverrideRegistry] into a
/// 2-layer registry: `localeProfiles` (currency / decimals / ranges per
/// country) + `brands` (per brand+country pump-display ROIs).
///
/// Shipped as `assets/ocr_config/index.json`; validate-on-load (a
/// malformed profile or template is logged and skipped, never crashes),
/// remote-overridable later via [PumpOcrConfig.fromJsonString].
class PumpOcrConfig {
  static const String defaultAssetPath = 'assets/ocr_config/index.json';

  final String _assetPath;
  final AssetBundle? _bundle;
  final Map<String, OcrLocaleProfile> _profiles = {};
  final List<OcrBrandTemplate> _brands = [];
  bool _loaded = false;

  PumpOcrConfig({
    String assetPath = defaultAssetPath,
    AssetBundle? bundle,
  })  : _assetPath = assetPath,
        _bundle = bundle;

  /// Build from an in-memory JSON string — for tests and remote config.
  factory PumpOcrConfig.fromJsonString(String source) {
    final config = PumpOcrConfig();
    config._ingest(source);
    config._loaded = true;
    return config;
  }

  /// Load + cache. Safe to call repeatedly. Missing / malformed config
  /// degrades to empty (logged) so the app keeps running.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    String raw;
    try {
      final bundle = _bundle ?? rootBundle;
      raw = await bundle.loadString(_assetPath);
    } catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.storage, e, st,
          context: const {'where': 'PumpOcrConfig: asset load failed'}));
      return;
    }
    _ingest(raw);
  }

  /// The locale profile for [country], or `null` when absent.
  OcrLocaleProfile? profileFor(String country) =>
      _profiles[country.toUpperCase()];

  /// The best brand template for [country] + [brand]. An exact
  /// brand+country match wins; otherwise the first template for the
  /// country (so a known-country/unknown-brand pump still gets the
  /// country's field geometry if only one brand is configured).
  OcrBrandTemplate? templateFor({
    required String country,
    String? brand,
  }) {
    final c = country.toUpperCase();
    final b = brand?.toLowerCase();
    OcrBrandTemplate? countryOnly;
    for (final t in _brands) {
      if (t.country != c) continue;
      if (b != null && t.brand == b) return t;
      countryOnly ??= t;
    }
    return countryOnly;
  }

  @visibleForTesting
  int get profileCount => _profiles.length;

  @visibleForTesting
  int get brandCount => _brands.length;

  @visibleForTesting
  void reset() {
    _profiles.clear();
    _brands.clear();
    _loaded = false;
  }

  void _ingest(String raw) {
    dynamic decoded;
    try {
      decoded = json.decode(raw);
    } on FormatException catch (e, st) { // ignore: unused_catch_stack
      debugPrint('PumpOcrConfig: malformed JSON in $_assetPath: $e');
      return;
    }
    if (decoded is! Map) {
      debugPrint('PumpOcrConfig: top-level JSON is not an object.');
      return;
    }
    final profiles = decoded['localeProfiles'];
    if (profiles is List) {
      for (final p in profiles) {
        final profile = OcrLocaleProfile.fromJson(p);
        if (profile == null) {
          debugPrint('PumpOcrConfig: skipping malformed locale profile');
          continue;
        }
        _profiles[profile.country.toUpperCase()] = profile;
      }
    }
    final brands = decoded['brands'];
    if (brands is List) {
      for (final b in brands) {
        final template = OcrBrandTemplate.fromJson(b);
        if (template == null) {
          debugPrint('PumpOcrConfig: skipping malformed brand template');
          continue;
        }
        _brands.add(template);
      }
    }
  }
}
