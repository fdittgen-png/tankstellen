/// Per-country price validation to flag suspicious fuel prices.
///
/// Checks prices against absolute thresholds and relative deviation
/// from search average. Returns a [PriceSanityResult] indicating
/// whether a price looks plausible or should show a warning badge.
class PriceSanity {
  const PriceSanity._();

  /// Absolute price thresholds per currency/region.
  ///
  /// Prices outside these ranges are flagged as suspicious.
  /// Thresholds are intentionally generous to avoid false positives.
  static const _thresholds = <String, ({double low, double high})>{
    // EUR countries
    'DE': (low: 0.80, high: 2.50),
    'FR': (low: 0.80, high: 2.50),
    'AT': (low: 0.80, high: 2.50),
    'ES': (low: 0.80, high: 2.50),
    'IT': (low: 0.80, high: 2.50),
    'PT': (low: 0.80, high: 2.50),
    'BE': (low: 0.80, high: 2.50),
    'LU': (low: 0.80, high: 2.50),
    // Non-EUR
    'GB': (low: 0.80, high: 2.00), // GBP
    'DK': (low: 8.00, high: 18.00), // DKK
    'AR': (low: 200.0, high: 2000.0), // ARS
    'AU': (low: 1.00, high: 3.00), // AUD
    'MX': (low: 15.0, high: 30.0), // MXN
  };

  /// Default EUR thresholds for unknown countries.
  static const _defaultThreshold = (low: 0.50, high: 3.00);

  /// Check if a single price is within plausible range for the country.
  static PriceSanityResult check(
    double? price, {
    required String countryCode,
    double? searchAverage,
  }) {
    if (price == null || price <= 0) return PriceSanityResult.ok;

    final threshold = _thresholds[countryCode.toUpperCase()] ?? _defaultThreshold;

    if (price < threshold.low) {
      return PriceSanityResult.suspiciousLow;
    }
    if (price > threshold.high) {
      return PriceSanityResult.suspiciousHigh;
    }

    // Check relative deviation from search average
    if (searchAverage != null && searchAverage > 0) {
      final deviation = (price - searchAverage) / searchAverage;
      if (deviation > 0.30) {
        return PriceSanityResult.aboveAverage;
      }
    }

    return PriceSanityResult.ok;
  }

  /// Calculate the average price from a list of non-null prices.
  static double? average(List<double?> prices) {
    final valid = prices.whereType<double>().where((p) => p > 0).toList();
    if (valid.isEmpty) return null;
    return valid.reduce((a, b) => a + b) / valid.length;
  }

  /// Get the threshold range for a country (for display/testing).
  static ({double low, double high}) thresholdFor(String countryCode) {
    return _thresholds[countryCode.toUpperCase()] ?? _defaultThreshold;
  }
}

/// Result of a price sanity check.
enum PriceSanityResult {
  /// Price is within normal range.
  ok,

  /// Price is suspiciously low (possible data error or unit mismatch).
  suspiciousLow,

  /// Price is suspiciously high (possible data error or closed station).
  suspiciousHigh,

  /// Price is > 30% above the search average (might be correct but expensive).
  aboveAverage,
}
