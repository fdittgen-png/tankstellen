import '../../search/domain/entities/fuel_type.dart';

/// Observatory `prices.{key}` parsing utilities for the Romanian
/// *Monitorul Prețurilor la Carburanți* feed.
///
/// Single source of truth for how the upstream `pretcarburant.ro`
/// fuel-key strings map onto canonical [FuelType] values, plus the
/// RON-per-litre parser that filters out junk (zero, negative,
/// non-numeric).
///
/// Mirrors the shape of `GreeceObservatoryKeys` so the two
/// scrape-driven country services parse prices the same way.
class RomaniaObservatoryKeys {
  RomaniaObservatoryKeys._();

  /// Observatory fuel-key → canonical [FuelType]. Kept lowercase so
  /// the lookup is case-insensitive against upstream drift.
  static const Map<String, FuelType> fuelForObservatoryKey = {
    'benzina_standard': FuelType.e5,
    'benzina_premium': FuelType.e98,
    'motorina_standard': FuelType.diesel,
    'motorina_premium': FuelType.dieselPremium,
    'gpl': FuelType.lpg,
  };

  /// Case-insensitive lookup for the observatory fuel-key. Returns
  /// `null` for unknown keys.
  static FuelType? lookup(String key) =>
      fuelForObservatoryKey[key.toLowerCase()];

  /// Parse the upstream `prices: { ... }` map into a [FuelType] →
  /// RON-per-litre map. Unknown keys, zero / negative prices, and
  /// non-numeric prices are silently filtered out.
  static Map<FuelType, double> parsePrices(dynamic rawPrices) {
    final out = <FuelType, double>{};
    if (rawPrices is! Map) return out;
    for (final entry in rawPrices.entries) {
      final key = entry.key.toString();
      final fuel = lookup(key);
      if (fuel == null) continue; // unknown / intentionally dropped
      final price = parseLeiPerLitre(entry.value);
      if (price == null) continue;
      out[fuel] = price;
    }
    return out;
  }

  /// Romanian pump prices are RON (lei) per litre with up to three
  /// decimals (e.g. `7.259`). Accepts `num` and numeric strings.
  /// Rejects zero and negative values.
  static double? parseLeiPerLitre(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) {
      if (raw <= 0) return null;
      return raw.toDouble();
    }
    if (raw is String) {
      final t = raw.trim();
      if (t.isEmpty) return null;
      final v = double.tryParse(t);
      if (v == null || v <= 0) return null;
      return v;
    }
    return null;
  }
}
