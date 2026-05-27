// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Reactivity regression tests for #2114 — the search-results list must
// repaint when underlying providers change (favorites toggle, ignored
// station Undo) without requiring a fresh search.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_list.dart';
import 'package:tankstellen/features/search/providers/ignored_stations_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

const _s1 = Station(
  id: 's1',
  name: 'Total Pézenas',
  brand: 'TOTAL',
  street: '1 rue A',
  postCode: '34120',
  place: 'Pézenas',
  lat: 43.45,
  lng: 3.42,
  isOpen: true,
);
const _s2 = Station(
  id: 's2',
  name: 'Esso Pézenas',
  brand: 'ESSO',
  street: '2 rue B',
  postCode: '34120',
  place: 'Pézenas',
  lat: 43.46,
  lng: 3.43,
  isOpen: true,
);
const _independent = Station(
  id: 'sIndep',
  name: 'Independent',
  brand: '',
  street: '3 rue C',
  postCode: '34120',
  place: 'Pézenas',
  lat: 43.47,
  lng: 3.44,
  isOpen: true,
);

Finder _cardById(String id) => find.byKey(ValueKey('station-$id'));

Future<void> _pumpList(WidgetTester tester) async {
  final test = standardTestOverrides();
  when(() => test.mockStorage.hasApiKey()).thenReturn(false);
  when(() => test.mockStorage.getApiKey()).thenReturn(null);
  when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
  when(() => test.mockStorage.getRatings()).thenReturn(<String, int>{});
  // The Favorites.add mutation reads the storage repo and calls
  // getFavoriteIds() to compute the new state. Stubs need to be
  // dynamic so the second read sees the first add.
  final fav = <String>[];
  when(() => test.mockStorage.getFavoriteIds()).thenAnswer((_) => List.of(fav));
  when(() => test.mockStorage.addFavorite(any())).thenAnswer((inv) async {
    fav.add(inv.positionalArguments.first as String);
  });
  when(() => test.mockStorage.saveFavoriteStationData(any(), any()))
      .thenAnswer((_) async {});
  when(() => test.mockStorage.removeFavorite(any())).thenAnswer((inv) async {
    fav.remove(inv.positionalArguments.first as String);
  });
  when(() => test.mockStorage.removeFavoriteStationData(any()))
      .thenAnswer((_) async {});
  when(() => test.mockStorage.isFavorite(any())).thenAnswer(
      (inv) => fav.contains(inv.positionalArguments.first as String));
  // Ignored mutations.
  final ignored = <String>[];
  when(() => test.mockStorage.getIgnoredIds()).thenAnswer((_) => List.of(ignored));
  when(() => test.mockStorage.addIgnored(any())).thenAnswer((inv) async {
    ignored.add(inv.positionalArguments.first as String);
  });
  when(() => test.mockStorage.removeIgnored(any())).thenAnswer((inv) async {
    ignored.remove(inv.positionalArguments.first as String);
  });

  await pumpApp(
    tester,
    SearchResultsList(
      result: ServiceResult<List<SearchResultItem>>(
        data: const [
          FuelStationResult(_s1),
          FuelStationResult(_s2),
          FuelStationResult(_independent),
        ],
        source: ServiceSource.cache,
        fetchedAt: DateTime(2026, 5, 27),
      ),
      onRefresh: () {},
    ),
    overrides: test.overrides,
  );
}

ProviderContainer _containerOf(WidgetTester tester) {
  // Use any element BELOW the ProviderScope — MaterialApp is the
  // direct child in pumpApp.
  final element = tester.element(find.byType(MaterialApp));
  return ProviderScope.containerOf(element, listen: false);
}

void main() {
  group('#2114 — search-results list reactivity', () {
    testWidgets(
        'Undo on ignored-station restores the row WITHOUT a fresh search',
        (tester) async {
      await _pumpList(tester);
      final container = _containerOf(tester);
      // Baseline: all three cards visible.
      expect(_cardById('s1'), findsOneWidget);
      expect(_cardById('s2'), findsOneWidget);
      expect(_cardById('sIndep'), findsOneWidget);

      // Simulate the "hide Independent" action (what the SnackBar's
      // primary action does).
      await container
          .read(ignoredStationsProvider.notifier)
          .add('sIndep');
      await tester.pumpAndSettle();
      expect(_cardById('sIndep'), findsNothing,
          reason: 'Hide is supposed to filter the row out.');

      // Simulate tapping Undo on the SnackBar.
      await container
          .read(ignoredStationsProvider.notifier)
          .remove('sIndep');
      await tester.pumpAndSettle();
      expect(_cardById('sIndep'), findsOneWidget,
          reason: 'Undo must restore the row without a fresh search.');
    });

    testWidgets(
        'Toggling favorite via the provider repaints the card star WITHOUT '
        'a fresh search', (tester) async {
      await _pumpList(tester);
      final container = _containerOf(tester);
      final initialFilled = find.byIcon(Icons.star).evaluate().length;

      // Simulate tapping the favorite star on s1 (what the card's
      // `onFavoriteTap` does).
      await container
          .read(favoritesProvider.notifier)
          .add('s1', stationData: _s1);
      await tester.pumpAndSettle();
      final afterFilled = find.byIcon(Icons.star).evaluate().length;
      expect(afterFilled, greaterThan(initialFilled),
          reason: 'Favorite toggle must add a filled star to the rendered '
              'tree immediately. Pre=$initialFilled, post=$afterFilled.');
    });
  });
}
