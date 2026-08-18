// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../ocr/pump_ocr_config.dart';

/// Currency metadata the receipt field extractors need to read amounts
/// off a paper receipt in the active country (#2273).
///
/// Replaces the EUR/€-hardcoded assumptions in `extractTotalCost` /
/// `extractPricePerLiter` with a small, config-driven descriptor derived
/// from the threaded [OcrLocaleProfile] (so the source of truth stays the
/// `assets/ocr_config/index.json` `localeProfiles`, not a parallel
/// table). Each descriptor carries:
///
///   - the major-unit symbols/codes that mark a total (`€`/`EUR`,
///     `£`/`GBP`, `kr`/`DKK`, `$`/`USD`, …);
///   - the minor-unit (subunit) marker used for per-litre prices
///     (`p` pence in the UK, `c`/`¢` cents in the US), with the divisor
///     to fold the subunit price back into the major unit;
///   - the major-unit per-litre suffix forms (`p/L`, `c/L`, `kr/L`).
///
/// All symbols are DATA, not user-facing text (they replicate what is
/// printed on the receipt), so no ARB routing is required.
class ReceiptCurrencyProfile {
  /// ISO currency code (e.g. `EUR`, `GBP`). i18n-ignore: data, not UI.
  final String currencyCode;

  /// Regex-escaped alternation of major-unit markers, symbol + code
  /// (e.g. `€|EUR`, `£|GBP`, `kr|DKK`). Used as a non-capturing group
  /// body, so callers wrap it in `(?:...)`.
  final String majorUnitPattern;

  /// Regex-escaped alternation of minor-unit (subunit) markers used when
  /// a per-litre price is quoted in the subunit (e.g. `p` for UK pence,
  /// `c|¢` for US cents). Empty when the currency has no subunit pricing
  /// convention on fuel receipts.
  final String minorUnitPattern;

  /// How many subunits make one major unit (100 for pence/cents).
  /// Per-litre prices quoted in the subunit are divided by this to get a
  /// major-unit €/L-equivalent value.
  final int minorUnitDivisor;

  /// Plausible per-litre price band in the MAJOR unit. Mirrors the
  /// pump-side [OcrLocaleProfile.priceMin]/[priceMax] so a subunit read
  /// (e.g. `142.9 p/L` → `1.429 £/L`) can be range-validated identically.
  final double priceMin;
  final double priceMax;

  const ReceiptCurrencyProfile({
    required this.currencyCode,
    required this.majorUnitPattern,
    required this.minorUnitPattern,
    required this.minorUnitDivisor,
    required this.priceMin,
    required this.priceMax,
  });

  bool get hasMinorUnit => minorUnitPattern.isNotEmpty;

  /// `true` when [price] is a plausible per-litre unit price (major unit).
  bool priceInRange(double price) => price >= priceMin && price <= priceMax;

  /// The default EUR descriptor — the historical behaviour, used whenever
  /// no [OcrLocaleProfile] is threaded so existing French/German receipts
  /// parse exactly as before.
  static const ReceiptCurrencyProfile euro = ReceiptCurrencyProfile(
    currencyCode: 'EUR',
    majorUnitPattern: '€|EUR',
    minorUnitPattern: 'c(?:ent)?',
    minorUnitDivisor: 100,
    priceMin: 0.5,
    priceMax: 4.0,
  );

  /// Build the currency descriptor for a threaded [profile], or the EUR
  /// default when [profile] is null or its currency is unknown. The price
  /// band is taken from the profile (config-driven) when present.
  static ReceiptCurrencyProfile fromLocale(OcrLocaleProfile? profile) {
    if (profile == null) return euro;
    final base = _byCode[profile.currency.toUpperCase()] ?? euro;
    // Prefer the config's own price band (per-country, JSON-sourced) so
    // adding a country only means editing the asset, not this table.
    return ReceiptCurrencyProfile(
      currencyCode: base.currencyCode,
      majorUnitPattern: base.majorUnitPattern,
      minorUnitPattern: base.minorUnitPattern,
      minorUnitDivisor: base.minorUnitDivisor,
      priceMin: profile.priceMin,
      priceMax: profile.priceMax,
    );
  }

  // The per-currency symbol table. Adding a currency here (or a country
  // to the JSON pointing at one of these codes) is all it takes to
  // support a new market — the extractors are otherwise currency-blind.
  static const Map<String, ReceiptCurrencyProfile> _byCode = {
    'EUR': euro,
    'GBP': ReceiptCurrencyProfile(
      currencyCode: 'GBP',
      // £ before the number, GBP after it; `p` (pence) is the per-litre
      // subunit UK forecourts price in (e.g. `142.9p/L`).
      majorUnitPattern: r'£|GBP',
      minorUnitPattern: 'p',
      minorUnitDivisor: 100,
      priceMin: 0.8,
      priceMax: 3.0,
    ),
    'USD': ReceiptCurrencyProfile(
      currencyCode: 'USD',
      majorUnitPattern: r'\$|USD',
      // US pumps quote `c/gal` historically but `c/L` on metric receipts.
      minorUnitPattern: r'c|¢',
      minorUnitDivisor: 100,
      priceMin: 0.5,
      priceMax: 4.0,
    ),
    // Scandinavian kroner (DKK/SEK/NOK) all print `kr` as the symbol with
    // no fuel-receipt subunit; the per-litre price is already in kroner.
    // Diesel/petrol run ~12-25 kr/L across DK/SE/NO; keep a wide band.
    'DKK': ReceiptCurrencyProfile(
      currencyCode: 'DKK',
      majorUnitPattern: 'kr|DKK',
      minorUnitPattern: '',
      minorUnitDivisor: 100,
      priceMin: 5.0,
      priceMax: 40.0,
    ),
    'SEK': ReceiptCurrencyProfile(
      currencyCode: 'SEK',
      majorUnitPattern: 'kr|SEK',
      minorUnitPattern: '',
      minorUnitDivisor: 100,
      priceMin: 5.0,
      priceMax: 40.0,
    ),
    'NOK': ReceiptCurrencyProfile(
      currencyCode: 'NOK',
      majorUnitPattern: 'kr|NOK',
      minorUnitPattern: '',
      minorUnitDivisor: 100,
      priceMin: 5.0,
      priceMax: 40.0,
    ),
  };
}
