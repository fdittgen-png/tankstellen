import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/favorites/providers/ev_favorites_provider.dart';
import 'package:tankstellen/features/favorites/providers/favorite_stations_provider.dart';
import 'package:tankstellen/features/favorites/providers/merged_favorites_provider.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../fixtures/charging_stations.dart';
import '../../../fixtures/stations.dart';

/// Pins `mergedFavoritesProvider` (#1786) — fuel + EV favorites merged
/// into one distance-ordered `SearchResultItem` list.
class _Fuel extends FavoriteStations {
  _Fuel(this._stations);
  final List<Station> _stations;

  @override
  AsyncValue<ServiceResult<List<Station>>> build() => AsyncValue.data(
        ServiceResult(
          data: _stations,
          source: ServiceSource.cache,
          fetchedAt: DateTime(2024),
        ),
      );

  @override
  Future<void> loadAndRefresh() async {}
}

class _Ev extends EvFavoriteStations {
  _Ev(this._stations);
  final List<ChargingStation> _stations;

  @override
  List<ChargingStation> build() => _stations;
}

void main() {
  ProviderContainer container({
    List<Station> fuel = const [],
    List<ChargingStation> ev = const [],
  }) {
    final c = ProviderContainer(overrides: [
      favoriteStationsProvider.overrideWith(() => _Fuel(fuel)),
      evFavoriteStationsProvider.overrideWith(() => _Ev(ev)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('no favorites → empty merged list', () {
    expect(container().read(mergedFavoritesProvider), isEmpty);
  });

  test('fuel favorites become FuelStationResult rows', () {
    final merged = container(fuel: [testStation]).read(mergedFavoritesProvider);
    expect(merged, hasLength(1));
    expect(merged.single, isA<FuelStationResult>());
  });

  test('EV favorites become EVStationResult rows', () {
    final merged =
        container(ev: [testChargingStation]).read(mergedFavoritesProvider);
    expect(merged, hasLength(1));
    expect(merged.single, isA<EVStationResult>());
  });

  test('fuel + EV favorites interleave, ordered by distance', () {
    final farFuel = testStation.copyWith(id: 'f-far', dist: 9.0);
    final nearEv = testChargingStation.copyWith(id: 'ocm-near', dist: 1.0);
    final merged = container(fuel: [farFuel], ev: [nearEv])
        .read(mergedFavoritesProvider);
    // The near EV station outranks the far fuel station — the two kinds
    // interleave on the shared distance key rather than stacking.
    expect(merged.map((e) => e.id).toList(), ['ocm-near', 'f-far']);
  });
}
