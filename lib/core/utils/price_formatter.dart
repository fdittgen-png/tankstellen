import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class PriceFormatter {
  PriceFormatter._();

  /// Country code → locale mapping for number formatting.
  /// Comma-decimal countries (most of Europe) use 'de_DE'.
  /// Period-decimal countries use 'en_US'.
  static const _localeMap = <String, String>{
    'DE': 'de_DE',
    'FR': 'fr_FR',
    'AT': 'de_AT',
    'ES': 'es_ES',
    'IT': 'it_IT',
    'PT': 'pt_PT',
    'BE': 'fr_BE',
    'LU': 'fr_LU',
    'DK': 'da_DK',
    'GB': 'en_GB',
    'AU': 'en_AU',
    'MX': 'es_MX',
    'AR': 'es_AR',
  };

  /// Currency symbols per country.
  static const _currencyMap = <String, String>{
    'DE': '€',
    'FR': '€',
    'AT': '€',
    'ES': '€',
    'IT': '€',
    'PT': '€',
    'BE': '€',
    'LU': '€',
    'DK': 'kr',
    'GB': '£',
    'AU': '\$',
    'MX': '\$',
    'AR': '\$',
  };

  /// Active country code. Set by the app on country change.
  static String _activeCountry = 'FR';

  /// Set the active country for price formatting.
  static void setCountry(String countryCode) {
    _activeCountry = countryCode.toUpperCase();
    _cachedFullFormat = null;
    _cachedDistanceFormat = null;
  }

  static String get _locale =>
      _localeMap[_activeCountry] ?? 'en_US';

  static String get currency =>
      _currencyMap[_activeCountry] ?? '€';

  // Lazy-initialized formatters that reset when country changes.
  static NumberFormat? _cachedFullFormat;
  static NumberFormat? _cachedDistanceFormat;

  static NumberFormat get _fullFormat =>
      _cachedFullFormat ??= NumberFormat('0.000', _locale);

  static NumberFormat get _distanceFormat =>
      _cachedDistanceFormat ??= NumberFormat('0.0', _locale);

  /// Format price as plain string (e.g., "1,459 €" or "1.459 £").
  static String formatPrice(double? price) {
    if (price == null || price <= 0) return '--';
    return '${_fullFormat.format(price)} $currency';
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

  /// Format distance in km (e.g., "2,3 km" or "2.3 km").
  static String formatDistance(double? distanceKm) {
    if (distanceKm == null) return '--';
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${_distanceFormat.format(distanceKm)} km';
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
