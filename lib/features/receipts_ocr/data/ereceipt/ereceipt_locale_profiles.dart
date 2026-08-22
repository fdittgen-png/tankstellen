// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../ocr/pump_ocr_config.dart';

/// Pure-Dart country → [OcrLocaleProfile] lookup for the e-receipt **text**
/// parser (#2838 / Epic #2687).
///
/// The pump-display / camera OCR path threads its profile from the bundled
/// `assets/ocr_config/index.json` (loaded by [PumpOcrConfig]). The e-receipt
/// text parser is deliberately **pure-Dart with no asset I/O** — it parses a
/// string a user pasted or another app shared, so it must run synchronously
/// in a unit test (and in the share-intent handler) without a Flutter binding
/// or an `AssetBundle`. These `const` profiles mirror the JSON bands for the
/// markets the e-receipt path covers so the currency-aware extractors
/// (`extractTotalCost` / `extractPricePerLiter`) read amounts in the right
/// currency without loading anything.
///
/// The numbers intentionally match the shipped `index.json` rows (EUR markets
/// share the FR/DE band, GBP uses the GB band). Adding a market here is a
/// data-only change; the parser is otherwise currency-blind.
class EReceiptLocaleProfiles {
  EReceiptLocaleProfiles._();

  /// Returns the [OcrLocaleProfile] for an ISO 3166-1 alpha-2 [countryCode]
  /// (case-insensitive), or `null` when the market isn't mapped — the parser
  /// then falls back to its EUR default, unchanged from passing no profile.
  static OcrLocaleProfile? forCountry(String? countryCode) {
    if (countryCode == null) return null;
    return _byCountry[countryCode.toUpperCase()];
  }

  // EUR markets share one band (mirrors the FR/DE index.json rows); GBP uses
  // the GB row. `decimalSeparator` is informational here — the extractors
  // accept both `.` and `,` regardless — so it carries the country's printed
  // convention.
  static const OcrLocaleProfile _eur = OcrLocaleProfile(
    country: 'EUR',
    currency: 'EUR',
    decimalSeparator: ',',
    priceMin: 0.5,
    priceMax: 4.0,
    volumeMax: 200.0,
    totalMax: 500.0,
  );

  static const Map<String, OcrLocaleProfile> _byCountry = {
    'IT': OcrLocaleProfile(
      country: 'IT',
      currency: 'EUR',
      decimalSeparator: ',',
      priceMin: 0.5,
      priceMax: 4.0,
      volumeMax: 200.0,
      totalMax: 500.0,
    ),
    'DE': OcrLocaleProfile(
      country: 'DE',
      currency: 'EUR',
      decimalSeparator: ',',
      priceMin: 0.5,
      priceMax: 4.0,
      volumeMax: 200.0,
      totalMax: 500.0,
    ),
    'FR': OcrLocaleProfile(
      country: 'FR',
      currency: 'EUR',
      decimalSeparator: ',',
      priceMin: 0.5,
      priceMax: 4.0,
      volumeMax: 200.0,
      totalMax: 500.0,
    ),
    'AT': _eur,
    'ES': _eur,
    'PT': _eur,
    'SI': _eur,
    'LU': _eur,
    'GR': _eur,
    'GB': OcrLocaleProfile(
      country: 'GB',
      currency: 'GBP',
      decimalSeparator: '.',
      priceMin: 0.8,
      priceMax: 3.0,
      volumeMax: 200.0,
      totalMax: 500.0,
    ),
  };
}
