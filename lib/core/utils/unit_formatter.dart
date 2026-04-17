import 'package:intl/intl.dart';

import '../country/country_config.dart';
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
  static String formatPricePerUnit(double? price, {String? countryCode}) {
    if (price == null || price <= 0) return '--';
    final cfg = _resolve(countryCode);
    final suffix = cfg.pricePerUnitSuffix;
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
  static String pricePerUnitSuffix({String? countryCode}) =>
      _resolve(countryCode).pricePerUnitSuffix;

  /// Format a double with one decimal in the *active locale* so
  /// metric countries render "2,3 km" (comma) and English-locale
  /// countries render "2.3 km" (dot). Using `toStringAsFixed` would
  /// hard-code the dot and drop the comma that French/German users
  /// expect.
  static String _oneDecimal(double v) =>
      NumberFormat('0.0', _activeLocale).format(v);

  static String _threeDecimals(double v) =>
      NumberFormat('0.000', _activeLocale).format(v);

  static String get _activeLocale {
    switch (PriceFormatter.activeCountry) {
      case 'DE':
        return 'de_DE';
      case 'FR':
        return 'fr_FR';
      case 'AT':
        return 'de_AT';
      case 'ES':
        return 'es_ES';
      case 'IT':
        return 'it_IT';
      case 'PT':
        return 'pt_PT';
      case 'BE':
        return 'fr_BE';
      case 'LU':
        return 'fr_LU';
      case 'DK':
        return 'da_DK';
      case 'GB':
        return 'en_GB';
      case 'AU':
        return 'en_AU';
      case 'MX':
        return 'es_MX';
      case 'AR':
        return 'es_AR';
      default:
        return 'en_US';
    }
  }
}
