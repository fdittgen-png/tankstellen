// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../country/country_config.dart';
import 'unit_formatter.dart';

class PriceFormatter {
  PriceFormatter._();

  /// Active country config — the single source of truth for the
  /// formatting locale and currency symbol. Resolved from
  /// [CountryConfig] (`locale`, `currencySymbol`) so the formatter can
  /// never drift from the registry the way the old hand-maintained
  /// `_localeMap`/`_currencyMap` tables did (#2168). Those tables
  /// silently omitted SI/KR/CL/RO and fell back to `en_US`/`€`, so a
  /// Korean profile rendered € instead of ₩.
  static CountryConfig _activeConfig =
      Countries.byCode('FR') ?? Countries.germany;

  /// ISO code of the country currently set as active. Read-only
  /// from outside; mutate via [setCountry] to keep derived caches
  /// (format objects) in sync.
  static String get activeCountry => _activeConfig.code;

  /// The resolved config for the active country. Exposed so
  /// [UnitFormatter] reads the same locale source instead of keeping
  /// its own parallel switch.
  static CountryConfig get activeConfig => _activeConfig;

  /// Set the active country for price formatting.
  static void setCountry(String countryCode) {
    _activeConfig =
        Countries.byCode(countryCode.toUpperCase()) ?? Countries.germany;
    _cachedFullFormat = null;
  }

  static String get _locale => _activeConfig.locale;

  static String get currency => _activeConfig.currencySymbol;

  // Lazy-initialized formatter that resets when country changes.
  static NumberFormat? _cachedFullFormat;

  static NumberFormat get _fullFormat =>
      _cachedFullFormat ??= NumberFormat('0.000', _locale);

  /// Format price as plain string (e.g., "1,459 €" or "1.459 £").
  ///
  /// Pass [currencyOverride] to force a specific symbol — used by the
  /// Favorites list (see #514) to render each row in the origin
  /// country's currency rather than the globally-set profile currency.
  static String formatPrice(double? price, {String? currencyOverride}) {
    if (price == null || price <= 0) return '--';
    final cur = currencyOverride ?? currency;
    return '${_fullFormat.format(price)} $cur';
  }

  /// Format price without currency symbol for compact display.
  static String formatPriceCompact(double? price) {
    if (price == null || price <= 0) return '--';
    return _fullFormat.format(price);
  }

  /// Build a TextSpan with the 9/10ths digit in superscript.
  /// Example: 1,45⁹ € — the standard fuel price display.
  static TextSpan priceTextSpan(
    double? price, {
    required TextStyle baseStyle,
    String? currencyOverride,
  }) {
    if (price == null || price <= 0) {
      return TextSpan(text: '--', style: baseStyle);
    }

    final cur = currencyOverride ?? currency;
    final full = _fullFormat.format(price);
    final base = full.substring(0, full.length - 1);
    final tenths = full.substring(full.length - 1);

    final superStyle = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * 0.65,
      fontFeatures: const [FontFeature.superscripts()],
    );

    return TextSpan(
      children: [
        TextSpan(text: base, style: baseStyle),
        WidgetSpan(
          alignment: PlaceholderAlignment.top,
          child: Transform.translate(
            offset: Offset(0, -(baseStyle.fontSize ?? 14) * 0.2),
            child: Text(tenths, style: superStyle),
          ),
        ),
        TextSpan(text: ' $cur', style: baseStyle),
      ],
    );
  }

  /// Format distance per the active country's convention. Delegates
  /// to [UnitFormatter.formatDistance] so the km→mi branch for
  /// imperial-distance countries (GB, …) lives in one place.
  ///
  /// Pass [countryCode] to render a cross-country row (e.g. a DE
  /// station in the FR favorites list) in the origin country's
  /// units.
  static String formatDistance(double? distanceKm, {String? countryCode}) {
    // Imported lazily via a top-level symbol to avoid a circular
    // import between price_formatter.dart and unit_formatter.dart.
    return UnitFormatter.formatDistance(distanceKm, countryCode: countryCode);
  }

  /// Get fuel type display name.
  static String fuelTypeName(String fuelType) {
    switch (fuelType.toLowerCase()) {
      case 'e5':
        return 'Super E5';
      case 'e10':
        return 'Super E10';
      case 'diesel':
        return 'Diesel';
      case 'all':
        return 'Alle';
      default:
        return fuelType;
    }
  }
}
