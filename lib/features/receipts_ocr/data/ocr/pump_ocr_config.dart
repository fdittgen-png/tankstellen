// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/guarded.dart';
import '../../../../core/logging/error_logger.dart';

/// Country-scoped numeric expectations for an OCR'd fuel purchase (#2275).
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

  /// Serialises this profile for the OCR trace package's `input` section
  /// (#2517) — trace-only, never on the production read path.
  Map<String, dynamic> toTraceJson() => {
    'country': country,
    'currency': currency,
    'decimalSeparator': decimalSeparator,
    'priceMin': priceMin,
    'priceMax': priceMax,
    'volumeMax': volumeMax,
    'totalMax': totalMax,
  };

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

/// Loads and validates the per-country OCR config bundle (#2275):
/// `localeProfiles` (currency / decimals / sane value ranges per
/// country), consumed by the receipt parser's currency-aware
/// extractors and validation gate. (#3765 removed the second layer —
/// per-brand pump-display ROI templates — along with the pump-display
/// scanner.)
///
/// Shipped as `assets/ocr_config/index.json`; validate-on-load (a
/// malformed profile is logged and skipped, never crashes),
/// remote-overridable later via [PumpOcrConfig.fromJsonString].
class PumpOcrConfig {
  static const String defaultAssetPath = 'assets/ocr_config/index.json';

  final String _assetPath;
  final AssetBundle? _bundle;
  final Map<String, OcrLocaleProfile> _profiles = {};
  bool _loaded = false;

  PumpOcrConfig({this._assetPath = defaultAssetPath, this._bundle});

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
      logFailure(e, st,
          where: 'PumpOcrConfig: asset load failed',
          layer: ErrorLayer.storage);
      return;
    }
    _ingest(raw);
  }

  /// The locale profile for [country], or `null` when absent.
  OcrLocaleProfile? profileFor(String country) =>
      _profiles[country.toUpperCase()];

  @visibleForTesting
  int get profileCount => _profiles.length;

  @visibleForTesting
  void reset() {
    _profiles.clear();
    _loaded = false;
  }

  void _ingest(String raw) {
    dynamic decoded;
    try {
      decoded = json.decode(raw);
    } on FormatException catch (e, st) {
      logFailure(e, st,
          where: 'PumpOcrConfig._ingest: malformed JSON in $_assetPath',
          layer: ErrorLayer.storage);
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
  }
}
