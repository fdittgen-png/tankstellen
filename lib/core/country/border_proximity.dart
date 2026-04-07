import 'dart:math';

import '../utils/geo_utils.dart';
import 'country_config.dart';

/// Represents a nearby country border with the neighboring country info.
class NearbyBorder {
  final CountryConfig neighbor;
  final double distanceKm;

  const NearbyBorder({required this.neighbor, required this.distanceKm});
}

/// Adjacency map: which supported countries share a land border.
///
/// Only includes countries that we have API coverage for, so we can
/// actually show cross-border prices.
const _adjacency = <String, List<String>>{
  'DE': ['FR', 'AT', 'DK'],
  'FR': ['DE', 'ES', 'IT'],
  'AT': ['DE', 'IT'],
  'ES': ['FR', 'PT'],
  'IT': ['FR', 'AT'],
  'DK': ['DE'],
  'PT': ['ES'],
};

/// Approximate border crossing points between country pairs.
///
/// Each entry is a representative lat/lng on or near the shared border.
/// Multiple points per border to cover long borders (e.g., DE-FR has
/// Strasbourg area and Saarbrücken area).
/// Keys are alphabetically sorted (matching [_borderKey] output).
const _borderPoints = <String, List<({double lat, double lng})>>{
  'DE-FR': [
    (lat: 48.58, lng: 7.79),   // Strasbourg / Kehl
    (lat: 49.23, lng: 7.00),   // Saarbrücken
  ],
  'AT-DE': [
    (lat: 47.55, lng: 13.05),  // Salzburg
    (lat: 47.38, lng: 11.10),  // Innsbruck / Garmisch
    (lat: 47.58, lng: 9.74),   // Bregenz / Lindau
  ],
  'DE-DK': [
    (lat: 54.78, lng: 9.44),   // Flensburg
    (lat: 54.80, lng: 8.86),   // Tønder area
  ],
  'ES-FR': [
    (lat: 42.70, lng: 2.88),   // Perpignan area
    (lat: 43.35, lng: -1.79),  // Hendaye / Irun
  ],
  'FR-IT': [
    (lat: 43.79, lng: 7.50),   // Nice / Ventimiglia
    (lat: 45.13, lng: 6.78),   // Modane / Fréjus tunnel
  ],
  'AT-IT': [
    (lat: 47.00, lng: 11.50),  // Brenner Pass
    (lat: 46.65, lng: 13.80),  // Villach / Tarvisio
  ],
  'ES-PT': [
    (lat: 42.10, lng: -8.65),  // Tui / Valença
    (lat: 38.87, lng: -7.00),  // Badajoz / Elvas
  ],
};

/// Returns the canonical key for a country pair (alphabetically sorted).
String _borderKey(String a, String b) {
  final sorted = [a, b]..sort();
  return '${sorted[0]}-${sorted[1]}';
}

/// Detects neighboring countries within [thresholdKm] of the given position.
///
/// Only considers countries that:
/// 1. Share a land border with [currentCountryCode]
/// 2. Are supported by the app (have a CountryConfig)
/// 3. Have at least one border crossing point within [thresholdKm]
///
/// Returns an empty list if no borders are nearby.
List<NearbyBorder> detectNearbyBorders({
  required double lat,
  required double lng,
  required String currentCountryCode,
  double thresholdKm = 30.0,
}) {
  final neighbors = _adjacency[currentCountryCode];
  if (neighbors == null) return const [];

  final results = <NearbyBorder>[];

  for (final neighborCode in neighbors) {
    final config = Countries.byCode(neighborCode);
    if (config == null) continue;

    final key = _borderKey(currentCountryCode, neighborCode);
    final points = _borderPoints[key];
    if (points == null) continue;

    // Find the closest border crossing point
    double minDist = double.infinity;
    for (final point in points) {
      final d = distanceKm(lat, lng, point.lat, point.lng);
      minDist = min(minDist, d);
    }

    if (minDist <= thresholdKm) {
      results.add(NearbyBorder(neighbor: config, distanceKm: minDist));
    }
  }

  // Sort by distance (closest border first)
  results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return results;
}
