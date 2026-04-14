import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/favorites_fuel_tab.dart';
import 'package:tankstellen/features/favorites/providers/ev_favorites_provider.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

ChargingStation _evStation({String id = 'ev-1', String name = 'Test Charger'}) {
  return ChargingStation(
    id: id,
    name: name,
    latitude: 48.8,
    longitude: 2.3,
    address: '1 Rue de Test',
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
      final test = standardTestOverrides(favoriteIds: []);
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
