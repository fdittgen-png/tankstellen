import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/search/domain/entities/charging_station.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/favorites_fuel_tab.dart';
import 'package:tankstellen/features/favorites/providers/ev_favorites_provider.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/ev_favorite_card.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/favorite_station_dismissible.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/favorites_section_header.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

ChargingStation _evStation({String id = 'ev-1', String name = 'Test Charger'}) {
  return ChargingStation(
    id: id,
    name: name,
    operator: 'Test Operator',
    lat: 48.8,
    lng: 2.3,
    address: '1 Rue de Test',
    connectors: const [],
  );
}

void main() {
  group('FavoritesFuelTab', () {
    testWidgets('renders empty state when no favorites of any kind',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: []);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const Material(child: FavoritesFuelTab()),
        overrides: test.overrides,
      );

      expect(find.text('No favorites yet'), findsOneWidget);
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    });

    testWidgets(
        'renders EV-only list when there are no fuel favorites '
        'but EV favorites exist', (tester) async {
      // Pass EV ID in favoriteIds so the unified provider sees it.
      final test = standardTestOverrides(favoriteIds: ['ev-1']);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const Material(child: FavoritesFuelTab()),
        overrides: [
          ...test.overrides,
          evFavoriteStationsProvider
              .overrideWith(() => _FixedEvFavorites([_evStation()])),
        ].cast(),
      );

      // EV-only branch flips us into the EV-only path; the fuel empty-state
      // copy must NOT appear.
      expect(find.text('No favorites yet'), findsNothing);
    });

    testWidgets(
        'renders BOTH the EV section header + EvFavoriteCard AND the Fuel '
        'section header + FavoriteStationDismissible when the user has '
        'starred at least one of each (regression guard for #475)',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: [testStation.id]);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
      when(() => test.mockStorage.getRatings())
          .thenReturn(const <String, int>{});

      await pumpApp(
        tester,
        const Material(child: FavoritesFuelTab()),
        overrides: [
          ...test.overrides,
          favoriteStationsProvider.overrideWith(
            () => _LoadedFavoriteStations([testStation]),
          ),
          evFavoriteStationsProvider.overrideWith(
            () => _FixedEvFavorites([_evStation()]),
          ),
        ].cast(),
      );

      // Both section headers must be rendered: EV first, then Fuel.
      expect(find.byType(FavoritesSectionHeader), findsNWidgets(2));
      // EV card should appear above the fuel card.
      final evHeader = tester
          .getCenter(find.byType(FavoritesSectionHeader).first)
          .dy;
      final fuelHeader =
          tester.getCenter(find.byType(FavoritesSectionHeader).last).dy;
      expect(evHeader, lessThan(fuelHeader),
          reason: 'EV section header must appear above the Fuel section header');

      expect(find.byType(EvFavoriteCard), findsOneWidget);
      expect(find.byType(FavoriteStationDismissible), findsOneWidget);
    });

    testWidgets('renders error UI with retry button when stream errors',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: ['stub-id']);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const Material(child: FavoritesFuelTab()),
        overrides: [
          ...test.overrides,
          favoriteStationsProvider
              .overrideWith(() => _ErroringFavoriteStations()),
        ].cast(),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}

class _FixedEvFavorites extends EvFavoriteStations {
  _FixedEvFavorites(this._stations);
  final List<ChargingStation> _stations;

  @override
  List<ChargingStation> build() => _stations;
}

class _ErroringFavoriteStations extends FavoriteStations {
  @override
  AsyncValue<ServiceResult<List<Station>>> build() => AsyncValue.error(
        Exception('boom'),
        StackTrace.current,
      );

  @override
  Future<void> loadAndRefresh() async {}
}

class _LoadedFavoriteStations extends FavoriteStations {
  _LoadedFavoriteStations(this._stations);
  final List<Station> _stations;

  @override
  AsyncValue<ServiceResult<List<Station>>> build() => AsyncValue.data(
        ServiceResult(
          data: _stations,
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
        ),
      );

  @override
  Future<void> loadAndRefresh() async {}
}
