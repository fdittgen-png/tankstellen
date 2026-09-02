// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/navigation/app_routes.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/presentation/screens/pick_station_for_fill_up_screen.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Station picker that owns the station-first fill-up flow (#715).
///
/// #3906 — three sections: the last fill-up's station pinned on top,
/// favorites, and the nearest stations of the last search result (with
/// distances, no network call). Tests drive:
/// - favorites-empty hint + nearby-empty hint when nothing is known
/// - a favorite tile renders + tapping pushes /consumption/add with
///   stationId + name + price
/// - the last station rides on top even when it is not a favorite
/// - nearby rows come from the search cache, closest first, ≤10, with a
///   distance label
/// - the Skip button pushes /consumption/add with no context
void main() {
  group('PickStationForFillUpScreen (#715 / #3906)', () {
    testWidgets('shows the favorites-empty and nearby-empty hints when '
        'nothing is known', (tester) async {
      await _pumpPicker(tester, favorites: const []);
      expect(find.textContaining('No favorite stations'), findsOneWidget);
      expect(find.byKey(const Key('pick_station_nearby_empty')), findsOneWidget);
      expect(find.byKey(const Key('pick_station_section_last')), findsNothing);
      // Section headers come from ARB.
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Nearby'), findsOneWidget);
    });

    testWidgets('renders a tile per favorite station', (tester) async {
      await _pumpPicker(tester, favorites: [_superUJson(), _carrefourJson()]);
      expect(find.text('SUPER U'), findsOneWidget);
      expect(find.text('Carrefour'), findsOneWidget);
    });

    testWidgets(
        'tapping a station navigates to /consumption/add with station data',
        (tester) async {
      await _pumpPicker(tester, favorites: [_superUJson()]);
      await tester.tap(find.byKey(const Key('pick_station_tile_super-u-1')));
      await tester.pumpAndSettle();
      expect(_lastRoute, '/consumption/add');
      // #3135 — the pre-fill crosses as the typed AddFillUpRoute payload.
      expect(_lastExtra, isA<AddFillUpRoute>());
      final extra = _lastExtra as AddFillUpRoute;
      expect(extra.stationId, 'super-u-1');
      expect(extra.stationName, 'SUPER U');
    });

    testWidgets('#3906 — the last fill-up station is pinned on top, even '
        'when it is not a favorite, and is not repeated below',
        (tester) async {
      await _pumpPicker(
        tester,
        favorites: [_superUJson()],
        fillUps: [
          _fillUp('f-old', 'super-u-1', 'SUPER U', DateTime(2026, 7, 1)),
          _fillUp('f-new', 'leclerc-1', 'E.Leclerc', DateTime(2026, 8, 21)),
        ],
      );
      final lastHeader = find.byKey(const Key('pick_station_section_last'));
      expect(lastHeader, findsOneWidget);
      expect(find.text('Last station'), findsOneWidget);
      expect(find.text('E.Leclerc'), findsOneWidget);
      expect(find.textContaining('Last fill-up: Aug 21, 2026'), findsOneWidget);
      // The last station sits ABOVE the favorites header.
      final lastY = tester.getTopLeft(lastHeader).dy;
      final favY = tester
          .getTopLeft(find.byKey(const Key('pick_station_section_favorites')))
          .dy;
      expect(lastY, lessThan(favY));
      // Still one SUPER U row (the favorite).
      expect(find.text('SUPER U'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pick_station_tile_leclerc-1')));
      await tester.pumpAndSettle();
      final extra = _lastExtra as AddFillUpRoute;
      expect(extra.stationId, 'leclerc-1');
      expect(extra.stationName, 'E.Leclerc');
    });

    testWidgets('#3906 — nearby rows come from the search cache, closest '
        'first, capped at 10, each with a distance; favorites excluded',
        (tester) async {
      final cached = <Station>[
        for (var i = 0; i < 14; i++)
          Station(
            id: 'near-$i',
            name: 'Station $i',
            brand: 'Brand $i',
            street: 'Rue $i',
            postCode: '34000',
            place: 'MONTPELLIER',
            // Further away for higher i (position is 43.60, 3.88).
            lat: 43.60 + 0.01 * (14 - i),
            lng: 3.88,
            e10: 1.8,
          ),
        // A favorite in the cache must not be repeated under Nearby.
        Station.fromJson(_superUJson()),
      ];
      await _pumpPicker(
        tester,
        favorites: [_superUJson()],
        searchResults: cached,
        position: (lat: 43.60, lng: 3.88),
      );
      expect(find.byKey(const Key('pick_station_nearby_empty')), findsNothing);
      // near-13 is the closest (0.01° ≈ 1.1 km); near-0 the farthest.
      expect(find.byKey(const Key('pick_station_tile_near-13')), findsOneWidget);
      expect(find.text('SUPER U'), findsOneWidget);
      final distance = tester.widget<Text>(
          find.byKey(const Key('pick_station_distance_near-13')));
      expect(distance.data, contains('km'));
      // Order: near-13 above near-12.
      await tester.scrollUntilVisible(
          find.byKey(const Key('pick_station_tile_near-12')), 200);
      final y13 = tester
          .getTopLeft(find.byKey(const Key('pick_station_tile_near-13')))
          .dy;
      final y12 = tester
          .getTopLeft(find.byKey(const Key('pick_station_tile_near-12')))
          .dy;
      expect(y13, lessThan(y12));
      // Cap: the 4 farthest (near-0 … near-3) are not listed.
      await tester.scrollUntilVisible(find.byKey(const Key('pick_station_skip')), 400);
      expect(find.byKey(const Key('pick_station_tile_near-3')), findsNothing);
    });

    testWidgets('Skip button navigates to /consumption/add with no context',
        (tester) async {
      await _pumpPicker(tester, favorites: const []);
      await tester.tap(find.byKey(const Key('pick_station_skip')));
      await tester.pumpAndSettle();
      expect(_lastRoute, '/consumption/add');
      // #3135 — Skip pushes an empty typed payload (no station context).
      final extra = _lastExtra as AddFillUpRoute;
      expect(extra.stationId, isNull);
      expect(extra.stationName, isNull);
      expect(extra.fuelType, isNull);
      expect(extra.pricePerLiter, isNull);
    });
  });
}

// ---------------------------------------------------------------------------
// Test harness
// ---------------------------------------------------------------------------

String? _lastRoute;
Object? _lastExtra;

FillUp _fillUp(String id, String stationId, String name, DateTime date) =>
    FillUp(
      id: id,
      date: date,
      liters: 30,
      totalCost: 50,
      odometerKm: 100000,
      fuelType: FuelType.e10,
      stationId: stationId,
      stationName: name,
    );

class _StubFillUps extends FillUpList {
  _StubFillUps(this._items);
  final List<FillUp> _items;
  @override
  List<FillUp> build() => _items;
}

class _StubSearch extends SearchState {
  _StubSearch(this._stations);
  final List<Station> _stations;
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() =>
      AsyncValue.data(ServiceResult(
        data: [for (final s in _stations) FuelStationResult(s)],
        source: ServiceSource.cache,
        fetchedAt: DateTime(2026, 3, 11, 14, 30),
      ));
}

class _StubPosition extends UserPosition {
  _StubPosition(this._pos);
  final ({double lat, double lng})? _pos;
  @override
  UserPositionData? build() {
    final p = _pos;
    if (p == null) return null;
    return UserPositionData(
      lat: p.lat,
      lng: p.lng,
      updatedAt: DateTime(2026, 3, 11, 14, 30),
      source: 'GPS',
    );
  }
}

Future<void> _pumpPicker(
  WidgetTester tester, {
  required List<Map<String, dynamic>> favorites,
  List<FillUp> fillUps = const [],
  List<Station> searchResults = const [],
  ({double lat, double lng})? position,
}) async {
  _lastRoute = null;
  _lastExtra = null;

  final storage = _FakeStorage(favorites: favorites);
  final router = GoRouter(
    initialLocation: '/consumption/pick-station',
    routes: [
      GoRoute(
        path: '/consumption/pick-station',
        builder: (_, _) => const PickStationForFillUpScreen(),
      ),
      GoRoute(
        path: '/consumption/add',
        builder: (context, state) {
          _lastRoute = '/consumption/add';
          _lastExtra = state.extra;
          return const Scaffold(body: Text('add-fill-up-stub'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storageRepositoryProvider.overrideWithValue(storage),
        fillUpListProvider.overrideWith(() => _StubFillUps(fillUps)),
        searchStateProvider.overrideWith(() => _StubSearch(searchResults)),
        userPositionProvider.overrideWith(() => _StubPosition(position)),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _superUJson() => {
      'id': 'super-u-1',
      'name': 'Super U Pomerols',
      'brand': 'SUPER U',
      'street': 'Chemin du Portrou',
      'postCode': '34810',
      'place': 'POMEROLS',
      'lat': 43.37,
      'lng': 3.49,
      'e10': 1.999,
      'isOpen': true,
    };

Map<String, dynamic> _carrefourJson() => {
      'id': 'carrefour-1',
      'name': 'Carrefour Marseillan',
      'brand': 'Carrefour',
      'street': 'Rue des Oliviers',
      'postCode': '34340',
      'place': 'MARSEILLAN',
      'lat': 43.35,
      'lng': 3.52,
      'e5': 2.028,
      'isOpen': true,
    };

class _FakeStorage implements StorageRepository {
  final List<Map<String, dynamic>> favorites;
  _FakeStorage({required this.favorites});

  @override
  List<String> getFavoriteIds() =>
      favorites.map((f) => f['id'] as String).toList();

  @override
  Map<String, dynamic>? getFavoriteStationData(String id) {
    for (final f in favorites) {
      if (f['id'] == id) return f;
    }
    return null;
  }

  // ---- everything else returns a benign default ----
  // The picker also watches activeProfileProvider, which cascades into
  // getActiveProfileId + getProfile; return null so the test doesn't
  // require a profile fixture.
  @override
  String? getActiveProfileId() => null;
  @override
  Map<String, dynamic>? getProfile(String id) => null;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return null for any other read/bool method — the picker never
    // calls mutating methods so this is safe.
    return null;
  }
}
