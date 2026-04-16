import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/country/border_proximity.dart';
import '../../../core/country/country_provider.dart';
import '../../../core/location/user_position_provider.dart';
import '../../../core/utils/station_extensions.dart';
import '../domain/entities/cross_border_comparison.dart';
import 'search_provider.dart';

part 'cross_border_provider.g.dart';

/// Computes cross-border price comparisons when the user is near a border.
///
/// Watches:
/// - [userPositionProvider] for the user's location
/// - [activeCountryProvider] for the current country
/// - [searchStateProvider] for current search results (to compute avg price)
/// - [selectedFuelTypeProvider] for the active fuel type
///
/// Returns a list of [CrossBorderComparison] for each neighboring country
/// within 30 km, or an empty list if the user is not near any border.
@riverpod
List<CrossBorderComparison> crossBorderComparisons(Ref ref) {
  final position = ref.watch(userPositionProvider);
  if (position == null) return const [];

  final country = ref.watch(activeCountryProvider);
  final fuelType = ref.watch(selectedFuelTypeProvider);

  // Only compute when we have fuel station results
  final stations = ref.watch(fuelStationsProvider);
  if (stations.isEmpty) return const [];

  // Detect nearby borders
  final nearbyBorders = detectNearbyBorders(
    lat: position.lat,
    lng: position.lng,
    currentCountryCode: country.code,
  );

  if (nearbyBorders.isEmpty) return const [];

  // Compute average price from current search results
  final prices = stations
      .map((s) => s.priceFor(fuelType))
      .where((p) => p != null && p > 0)
      .cast<double>()
      .toList();

  if (prices.isEmpty) return const [];

  final avgPrice = prices.reduce((a, b) => a + b) / prices.length;

  return nearbyBorders.map((border) {
    return CrossBorderComparison(
      neighborCode: border.neighbor.code,
      neighborName: border.neighbor.name,
      neighborFlag: border.neighbor.flag,
      neighborCurrency: border.neighbor.currencySymbol,
      currentAvgPrice: avgPrice,
      borderDistanceKm: double.parse(border.distanceKm.toStringAsFixed(1)),
      stationCount: prices.length,
    );
  }).toList();
}
