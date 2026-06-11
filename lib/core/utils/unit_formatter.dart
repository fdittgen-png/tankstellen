// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:intl/intl.dart';

import '../country/country_config.dart';
import '../../features/search/domain/entities/fuel_type.dart';
import 'price_formatter.dart';

/// Formats per-country unit strings: distance (km/mi), volume (L/gal),
/// and the price-per-unit suffix ("€/L", "p/L", "c/L", …).
///
/// Composes on top of [PriceFormatter], which owns currency-symbol
/// selection. This class owns everything that depends on the volume
/// OR distance unit of a country — not just the currency.
///
/// Cross-country invariant: when rendering data from a non-active
/// country (e.g. a French favorite while the user is in Germany),
/// pass [countryCode] to keep the row in its origin-country units.
/// Same rule as `PriceFormatter.formatPrice(currencyOverride: …)`.
class UnitFormatter {
  UnitFormatter._();

  /// Resolve a country config by ISO code, falling back to the
  /// currently-active country (the one `PriceFormatter.setCountry`
  /// was last called with).
  static CountryConfig _resolve(String? countryCode) {
    final active = PriceFormatter.activeCountry;
    if (countryCode == null || countryCode.isEmpty) {
      return Countries.byCode(active) ?? Countries.germany;
    }
    return Countries.byCode(countryCode.toUpperCase()) ??
        Countries.byCode(active) ??
        Countries.germany;
  }

  /// Kilometres → miles conversion constant (1 km = 0.621371 mi).
  static const double _milesPerKm = 0.621371;

  /// Litres → US gallons conversion (1 L ≈ 0.264172 gal).
  static const double _gallonsPerLiter = 0.264172;

  /// Format a distance for display in the correct unit for the
  /// given country. Sub-kilometre distances render as metres for
  /// metric countries and as feet/yards for imperial (approximate
  /// short-distance guard — we only switch to the coarser unit
  /// above 1 km/mi).
  static String formatDistance(double? km, {String? countryCode}) {
    if (km == null) return '--';
    final cfg = _resolve(countryCode);
    if (cfg.distanceUnit == 'mi') {
      final miles = km * _milesPerKm;
      if (miles < 1) {
        return '${(miles * 1760).round()} yd';
      }
      return '${_oneDecimal(miles)} mi';
    }
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${_oneDecimal(km)} km';
  }

  /// Format a fuel volume in the correct unit for the given country.
  /// Currently every supported country uses litres; the imperial
  /// gallon branch is here for the first non-metric volume country
  /// we add (US being the likely first).
  static String formatVolume(double? liters, {String? countryCode}) {
    if (liters == null) return '--';
    final cfg = _resolve(countryCode);
    if (cfg.volumeUnit == 'gal') {
      return '${_oneDecimal(liters * _gallonsPerLiter)} gal';
    }
    return '${_oneDecimal(liters)} L';
  }

  /// Render a price-per-unit value with the country's convention.
  ///
  /// Examples:
  /// - FR (EUR, €/L): `1.849 €/L`
  /// - UK (GBP, p/L): `155.9 p/L` (pounds displayed as pence)
  /// - AU (AUD, c/L): `185.9 c/L` (dollars displayed as cents)
  ///
  /// The caller always passes the value in the country's **primary**
  /// currency unit (EUR/GBP/AUD, not cents). The formatter scales
  /// into pence/cents when the country's suffix requires it.
  ///
  /// [fuelType] selects a per-fuel suffix override when the country
  /// defines one (#3198 — AR GNC is priced per m³, not per litre); when
  /// omitted the country-wide suffix applies.
  static String formatPricePerUnit(
    double? price, {
    String? countryCode,
    FuelType? fuelType,
  }) {
    if (price == null || price <= 0) return '--';
    final cfg = _resolve(countryCode);
    final suffix = cfg.pricePerUnitSuffixFor(fuelType);
    // Sub-unit suffixes (pence, cents) render the price * 100 with
    // a single decimal — matches the UK forecourt "155.9 p/L" and
    // the AU "185.9 c/L" conventions.
    if (suffix == 'p/L' || suffix == 'c/L') {
      final subUnit = price * 100;
      return '${_oneDecimal(subUnit)} $suffix';
    }
    // Primary-unit suffixes keep 3 decimals for fuel price precision.
    return '${_threeDecimals(price)} $suffix';
  }

  /// Short-form price-per-unit without value — returns just the
  /// suffix for UI that labels a column or axis ("€/L", "p/L", …).
  /// [fuelType] selects a per-fuel override when one exists (#3198).
  static String pricePerUnitSuffix({String? countryCode, FuelType? fuelType}) =>
      _resolve(countryCode).pricePerUnitSuffixFor(fuelType);

  /// Format an average / instantaneous consumption value with its
  /// unit mask — `L/100 km` for combustion, `kWh/100 km` for EV.
  ///
  /// SSoT for the consumption mask that was previously copy-pasted
  /// across the consumption widgets (#2185). Intentionally keeps the
  /// **dot** decimal (`toStringAsFixed(1)`) rather than the active
  /// locale's separator: the shipped consumption widget tests assert
  /// exact strings like `6.4 L/100 km`, and the mask itself is a
  /// language-neutral format mask, so it stays as-is.
  static String formatConsumption(double value, {required bool isEv}) {
    // i18n-ignore: language-neutral consumption unit format mask (#2185)
    final mask = isEv ? 'kWh/100 km' : 'L/100 km';
    return '${value.toStringAsFixed(1)} $mask';
  }

  /// Format a double with one decimal in the *active locale* so
  /// metric countries render "2,3 km" (comma) and English-locale
  /// countries render "2.3 km" (dot). Using `toStringAsFixed` would
  /// hard-code the dot and drop the comma that French/German users
  /// expect.
  static String _oneDecimal(double v) =>
      NumberFormat('0.0', _activeLocale).format(v);

  static String _threeDecimals(double v) =>
      NumberFormat('0.000', _activeLocale).format(v);

  /// The active country's CLDR locale, sourced from the same
  /// [CountryConfig] SSoT as [PriceFormatter] (#2168). Previously a
  /// third copy of the country→locale switch that omitted SI/KR/CL/RO
  /// and fell back to `en_US` (wrong decimal separator for those).
  static String get _activeLocale => PriceFormatter.activeConfig.locale;
}
