import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class PriceFormatter {
  PriceFormatter._();

  static final _fullFormat = NumberFormat('0.000', 'de_DE');
  static final _distanceFormat = NumberFormat('0.0', 'de_DE');

  /// Format price as plain string (e.g., "1,459 EUR").
  /// For UI with superscript, use [priceTextSpan] instead.
  static String formatPrice(double? price) {
    if (price == null || price <= 0) return '--';
    return '${_fullFormat.format(price)} \u20ac';
  }

  /// Format price without currency symbol for compact display.
  static String formatPriceCompact(double? price) {
    if (price == null || price <= 0) return '--';
    return _fullFormat.format(price);
  }

  /// Build a TextSpan with the 9/10ths digit in superscript.
  /// Example: 1,45⁹ € — the standard European fuel price display.
  ///
  /// Returns [baseStyle] for "1,45" and a smaller raised style for "9".
  static TextSpan priceTextSpan(
    double? price, {
    required TextStyle baseStyle,
    String currency = '\u20ac',
  }) {
    if (price == null || price <= 0) {
      return TextSpan(text: '--', style: baseStyle);
    }

    // Split: 1.459 → base "1,45", superscript "9"
    final full = _fullFormat.format(price); // "1,459"
    final base = full.substring(0, full.length - 1); // "1,45"
    final tenths = full.substring(full.length - 1); // "9"

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
        TextSpan(text: ' $currency', style: baseStyle),
      ],
    );
  }

  /// Format distance in km (e.g., "2,3 km").
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
