// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'search_results_list.dart';

/// Extracts fuel stations from the unified results list.
List<Station> _fuelStationsFrom(List<SearchResultItem> items) =>
    items.whereType<FuelStationResult>().map((r) => r.station).toList();

/// Computes which station has the cheapest price for each fuel type.
Map<String, Map<FuelType, bool>> _computeCheapestFlagsFor(
  List<Station> stations,
) {
  if (stations.isEmpty) return {};

  final cheapest = <FuelType, double>{};
  final cheapestIds = <FuelType, String>{};

  const fuelTypes = [
    FuelType.e5,
    FuelType.e10,
    FuelType.e98,
    FuelType.diesel,
    FuelType.dieselPremium,
    FuelType.e85,
    FuelType.lpg,
    FuelType.cng,
  ];

  for (final ft in fuelTypes) {
    for (final s in stations) {
      final price = s.priceFor(ft);
      if (price != null && price > 0) {
        if (!cheapest.containsKey(ft) || price < cheapest[ft]!) {
          cheapest[ft] = price;
          cheapestIds[ft] = s.id;
        }
      }
    }
  }

  final result = <String, Map<FuelType, bool>>{};
  for (final entry in cheapestIds.entries) {
    result.putIfAbsent(entry.value, () => {});
    result[entry.value]![entry.key] = true;
  }
  return result;
}

/// Get min/max price range for tier classification. Delegates to the
/// shared [priceRange] helper (#2182); the search list excludes
/// zero/sentinel prices from its tiers, hence `requirePositive: true`.
(double, double) _getPriceRangeFor(List<Station> stations, FuelType fuel) =>
    priceRange(stations, fuel, requirePositive: true);

/// The filter panel behind row B's badged filter button (#3926).
///
/// Was a "All brands ⌄" strip of its own — a sixth stacked chrome row
/// above the first station card, carrying only a label, a dot and a
/// chevron. The label + dot became the badged `Icons.filter_list` button
/// on the results row; what is left here is the panel it expands: the
/// brand / motorway chips and, for a mixed result set, the EV connector +
/// power chips (#1784 — renders nothing for a fuel-only result set).
class _ExpandableFilters extends ConsumerWidget {
  final List<Station> stations;

  const _ExpandableFilters({required this.stations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(brandFiltersExpandedProvider);
    return AnimatedCrossFade(
      firstChild: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandFilterChips(stations: stations),
          const MixedResultsFilterChips(),
        ],
      ),
      secondChild: const SizedBox(width: double.infinity),
      crossFadeState:
          expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 200),
    );
  }
}
