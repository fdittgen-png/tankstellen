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
    _cachedTotalFormat = null;
    _cachedPerKmFormat = null;
  }

  static String get _locale => _activeConfig.locale;

  static String get currency => _activeConfig.currencySymbol;

  /// ISO 4217 code of the active currency (e.g. `EUR`, `KRW`). Drives
  /// the zero-decimal decision in [formatTotal] — see [_zeroDecimal].
  static String get _currencyCode => _activeConfig.currency;

  /// Currencies that carry no minor unit, so a total is whole-numbered
  /// (₩1050, not ₩1050,00). Keyed off the ISO 4217 code so the set
  /// stays correct as countries are added. Covers the registered
  /// zero-decimal currencies (KRW, CLP) plus the common ones a future
  /// country might bring (JPY, VND, …).
  static const Set<String> _zeroDecimalCurrencies = {
    'KRW', 'CLP', 'JPY', 'VND', 'IDR', 'HUF', 'ISK', 'PYG',
    'XOF', 'XAF', 'XPF', 'RWF', 'UGX', 'DJF', 'GNF', 'KMF', 'VUV',
  };

  static bool get _zeroDecimal =>
      _zeroDecimalCurrencies.contains(_currencyCode);

  // Lazy-initialized formatter that resets when country changes.
  static NumberFormat? _cachedFullFormat;

  static NumberFormat get _fullFormat =>
      _cachedFullFormat ??= NumberFormat('0.000', _locale);

  // Lazy-initialized total-currency formatter (2 dp, or 0 dp for a
  // zero-decimal currency). Resets when the active country changes.
  static NumberFormat? _cachedTotalFormat;

  static NumberFormat get _totalFormat => _cachedTotalFormat ??=
      NumberFormat.currency(
        locale: _locale,
        symbol: '',
        decimalDigits: _zeroDecimal ? 0 : 2,
      );

  // Lazy-initialized per-km formatter (3 dp, no symbol). Resets when
  // the active country changes.
  static NumberFormat? _cachedPerKmFormat;

  static NumberFormat get _perKmFormat =>
      _cachedPerKmFormat ??= NumberFormat('0.000', _locale);

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

  /// Format a TOTAL amount (a fill-up cost, a charging session, the
  /// month's spend) in the active currency — two decimals, or zero for
  /// a zero-decimal currency like KRW / CLP / JPY.
  ///
  /// This is distinct from [formatPrice], which is the per-litre
  /// formatter at three decimals (`1,459 €`). Routing a total through
  /// the per-litre formatter is the bug behind a 1.05 € trip rendering
  /// `1,047 €` (#2491). The symbol is appended with a space to match
  /// [formatPrice]'s placement so per-litre and total figures read as
  /// the same money on one card.
  ///
  /// Pass [currencyOverride] to force a specific symbol — mirrors
  /// [formatPrice] for cross-country rows (see #514).
  static String formatTotal(double? amount, {String? currencyOverride}) {
    if (amount == null) return '--';
    final cur = currencyOverride ?? currency;
    // NumberFormat.currency with an empty symbol still reserves the
    // symbol slot — for a suffix-symbol locale (fr_FR's `#,##0.00 ¤`)
    // that leaves a trailing space, so trim before re-appending our
    // own symbol to avoid a doubled separator ("1,05  €").
    final number = _totalFormat.format(amount).trim();
    return '$number $cur';
  }

  /// Format a cost-per-distance value (e.g. €/km) at three decimals,
  /// locale-aware, without a currency symbol — the consumption stats
  /// "Avg /km" tile. Three decimals because a per-km cost is a fraction
  /// of a currency unit (0,105 €/km); the symbol is supplied by the
  /// surrounding label, not this method.
  static String formatPerKm(double? amount) {
    if (amount == null) return '--';
    return _perKmFormat.format(amount);
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
}
