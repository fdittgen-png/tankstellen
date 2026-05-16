import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';
import 'package:tankstellen/features/search/providers/search_filters_provider.dart';

import '../../../fixtures/charging_stations.dart';
import '../../../fixtures/stations.dart';

/// Pins `sortSearchResults` — the search results sort extracted into the
/// memoised `filteredSortedSearchResults` provider (#1762). The ordering
/// must match the pre-extraction inline widget pipeline.
void main() {
  // Three fuel stations with distinct distance / e10 price / brand.
  final fuelA = FuelStationResult(testStation.copyWith(
      id: 'a', brand: 'Cc', dist: 3.0, e10: 1.90));
  final fuelB = FuelStationResult(testStation.copyWith(
      id: 'b', brand: 'Aa', dist: 1.0, e10: 1.70));
  final fuelC = FuelStationResult(testStation.copyWith(
      id: 'c', brand: 'Bb', dist: 2.0, e10: 1.80));
  final fuels = <SearchResultItem>[fuelA, fuelB, fuelC];

  List<String> idsOf(List<SearchResultItem> items) =>
      items.map((e) => e.id).toList();

  group('sortSearchResults — fuel list', () {
    test('distance — nearest first', () {
      final sorted = sortSearchResults(
          fuels, SortMode.distance, FuelType.e10, const {});
      expect(idsOf(sorted), ['b', 'c', 'a']); // 1.0, 2.0, 3.0 km
    });

    test('price — cheapest first', () {
      final sorted = sortSearchResults(
          fuels, SortMode.price, FuelType.e10, const {});
      expect(idsOf(sorted), ['b', 'c', 'a']); // 1.70, 1.80, 1.90
    });

    test('name — alphabetical by display name', () {
      final sorted = sortSearchResults(
          fuels, SortMode.name, FuelType.e10, const {});
      expect(idsOf(sorted), ['b', 'c', 'a']); // Aa, Bb, Cc
    });

    test('rating — highest rated first', () {
      final sorted = sortSearchResults(
          fuels, SortMode.rating, FuelType.e10, const {'a': 5, 'c': 3});
      expect(idsOf(sorted), ['a', 'c', 'b']); // 5, 3, 0
    });

    test('does not mutate the input list', () {
      final input = <SearchResultItem>[fuelA, fuelB, fuelC];
      sortSearchResults(input, SortMode.distance, FuelType.e10, const {});
      expect(idsOf(input), ['a', 'b', 'c']);
    });
  });

  group('sortSearchResults — all-EV list', () {
    test('always sorts by distance regardless of sort mode', () {
      final evs = <SearchResultItem>[
        EVStationResult(testChargingStation.copyWith(id: 'ocm-far', dist: 9.0)),
        EVStationResult(
            testChargingStation.copyWith(id: 'ocm-near', dist: 2.0)),
        EVStationResult(testChargingStation.copyWith(id: 'ocm-mid', dist: 5.0)),
      ];
      // Price sort is fuel-only — an all-EV list falls back to distance.
      final sorted =
          sortSearchResults(evs, SortMode.price, FuelType.e10, const {});
      expect(idsOf(sorted), ['ocm-near', 'ocm-mid', 'ocm-far']);
    });
  });
}
