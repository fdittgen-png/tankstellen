// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:intl/intl.dart';

import '../country/country_config.dart';
import '../domain/consumption_unit.dart';
import '../domain/fuel_type.dart';
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
  /// [fractionDigits] overrides the default single decimal on the
  /// km/mi figure (#3743) — pass `0` for whole-unit surfaces like an
  /// odometer reading, `2` for the fine-grained live trip distance.
  /// The sub-unit branches (m / yd) always render whole numbers.
  static String formatDistance(
    double? km, {
    String? countryCode,
    int? fractionDigits,
  }) {
    if (km == null) return '--';
    final cfg = _resolve(countryCode);
    final digits = fractionDigits ?? 1;
    if (cfg.distanceUnit == 'mi') {
      final miles = km * _milesPerKm;
      if (miles < 1) {
        return '${(miles * 1760).round()} yd';
      }
      return '${formatDecimal(miles, fractionDigits: digits)} mi';
    }
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${formatDecimal(km, fractionDigits: digits)} km';
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
  ///
  /// #3883 — [unit] renders a combustion value (always COMPUTED in
  /// L/100 km) in the user's display unit (km/L, mpg). Null keeps the
  /// L/100 km mask; EV values ignore it (kWh/100 km has no mpg twin).
  static String formatConsumption(
    double value, {
    required bool isEv,
    ConsumptionUnit? unit,
  }) {
    if (isEv) {
      // i18n-ignore: language-neutral consumption unit format mask (#2185)
      return '${value.toStringAsFixed(1)} kWh/100 km';
    }
    final u = unit ?? ConsumptionUnit.lPer100Km;
    final converted = u.fromLPer100Km(value);
    if (converted == null) return '--';
    return '${converted.toStringAsFixed(u.fractionDigits)} ${u.mask}';
  }

  /// Locale-aware twin of [formatConsumption] (#3889): the figure uses the
  /// active locale's decimal separator (`6,4 L/100 km` in de/fr) — for the
  /// cards that rendered `formatDecimal` + a hard mask before.
  static String formatConsumptionLocalized(double value, ConsumptionUnit unit) {
    final converted = unit.fromLPer100Km(value);
    if (converted == null) return '--';
    return '${formatDecimal(converted, fractionDigits: unit.fractionDigits)} ${unit.mask}';
  }

  /// Format a bare decimal number in the *active locale* so metric
  /// countries render "2,3" (comma) and English-locale countries
  /// render "2.3" (dot). Using `toStringAsFixed` would hard-code the
  /// dot and drop the comma that French/German users expect (#3743).
  ///
  /// This is the general-purpose value formatter for UI figures whose
  /// unit/suffix is supplied by the surrounding string or label
  /// (percentages, L/100 values, kWh, file sizes, …). Prefer the
  /// dedicated helpers ([formatDistance], [formatVolume],
  /// [formatPricePerUnit]) when a unit-aware one exists.
  static String formatDecimal(double? value, {int fractionDigits = 1}) {
    if (value == null) return '--';
    final pattern = fractionDigits <= 0 ? '0' : '0.${'0' * fractionDigits}';
    return NumberFormat(pattern, _activeLocale).format(value);
  }

  /// Odometer reading as a grouped whole number with the country's
  /// distance unit (#3903): `122 700 km` (fr), `122,700 km` (en),
  /// `76,246 mi` (GB). Dashboards show whole units; the grouping
  /// separator follows the active locale like [formatDecimal] does.
  static String formatOdometer(double? km, {String? countryCode}) {
    if (km == null) return '--';
    final cfg = _resolve(countryCode);
    final imperial = cfg.distanceUnit == 'mi';
    final value = imperial ? km * _milesPerKm : km;
    final figure = NumberFormat('#,##0', _activeLocale).format(value);
    return imperial ? '$figure mi' : '$figure km';
  }

  /// Medium date (`Aug 21, 2026` / `21 août 2026` / `21.08.2026`) in the
  /// given UI [locale] — the one surface-level date format for list rows
  /// and captions (#3903). Pass `Localizations.localeOf(context)
  /// .toString()`; the caller owns the widget context, this class does
  /// not.
  static String formatMediumDate(DateTime date, {required String locale}) =>
      DateFormat.yMMMd(locale).format(date);

  static String _oneDecimal(double v) => formatDecimal(v);

  static String _threeDecimals(double v) =>
      formatDecimal(v, fractionDigits: 3);

  /// The active country's CLDR locale, sourced from the same
  /// [CountryConfig] SSoT as [PriceFormatter] (#2168). Previously a
  /// third copy of the country→locale switch that omitted SI/KR/CL/RO
  /// and fell back to `en_US` (wrong decimal separator for those).
  static String get _activeLocale => PriceFormatter.activeConfig.locale;
}
