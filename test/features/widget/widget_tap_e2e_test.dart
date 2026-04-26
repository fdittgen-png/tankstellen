import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/core/services/service_providers.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/data/models/search_params.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/features/station_detail/providers/station_detail_provider.dart';
import 'package:tankstellen/features/widget/presentation/widget_click_listener.dart';

/// Two stations whose ids are deliberately different countries with
/// different brands. The bug in #753 was that tapping row A on the
/// home-screen widget rendered station B's detail (or vice-versa);
/// this test pumps the same plumbing the cold/warm widget-click path
/// uses (URI → router push → `stationDetailProvider`) and asserts the
/// rendered detail's brand matches the row that was tapped.
const _stationFR = Station(
  id: 'fr-12345',
  name: 'TotalEnergies Toulouse',
  brand: 'TotalEnergies',
  street: 'Avenue de la République',
  postCode: '31000',
  place: 'Toulouse',
  lat: 43.6,
  lng: 1.44,
  isOpen: true,
);

const _stationDE = Station(
  id: 'de-uuid-abc',
  name: 'Shell Berlin',
  brand: 'Shell',
  street: 'Hauptstraße',
  postCode: '10115',
  place: 'Berlin',
  lat: 52.5,
  lng: 13.4,
  isOpen: true,
);

/// A single fake [StationService] that resolves both stations by id.
/// This is the **detail-fetch** layer; we don't go through the search
/// pipeline. Returning either station depending on the id is what a
/// real per-country service does for its OWN station — but the bug
/// scenario crosses countries, which is what the routing fix prevents.
class _FakeAllCountriesStationService implements StationService {
  final List<Station> stations;
  final List<String> getStationDetailCalls = [];

  _FakeAllCountriesStationService(this.stations);

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(
    String stationId,
  ) async {
    getStationDetailCalls.add(stationId);
    final match = stations.where((s) => s.id == stationId).firstOrNull;
    if (match == null) {
      throw StateError(
        '_FakeAllCountriesStationService: no fixture for $stationId',
      );
    }
    return ServiceResult(
      data: StationDetail(station: match),
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  Future<ServiceResult<List<Station>>> searchStations(
    SearchParams params, {
    dynamic cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
    List<String> ids,
  ) =>
      throw UnimplementedError();
}

/// Empty search state — forces every detail lookup to go through the
/// stationServiceProvider fallback, which is the path widget taps take
/// when the user hasn't run a fresh search recently.
class _EmptySearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() {
    return AsyncValue.data(
      ServiceResult(
        data: const [],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      ),
    );
  }
}

({
  ProviderContainer container,
  GoRouter router,
  _FakeAllCountriesStationService service,
}) _buildHarness() {
  final service = _FakeAllCountriesStationService([_stationFR, _stationDE]);
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('home')),
      GoRoute(
        path: '/station/:id',
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          // We render brand from the provider, not from a fixed string,
          // so a wrong-station bug surfaces in the find.text() assertion
          // rather than just a path mismatch.
          return Consumer(builder: (context, ref, _) {
            final detail = ref.watch(stationDetailProvider(id));
            return detail.when(
              data: (sd) => Scaffold(
                body: Column(
                  children: [
                    Text('detail-id:${sd.data.station.id}'),
                    Text('detail-brand:${sd.data.station.brand}'),
                  ],
                ),
              ),
              error: (e, _) => Text('error:$e'),
              loading: () => const Text('loading'),
            );
          });
        },
      ),
    ],
  );

  final container = ProviderContainer(overrides: [
    routerProvider.overrideWith((_) => router),
    // Pin the active country so `stationDetailProvider` exercises the
    // cross-country tap path for at least one of the two ids the test
    // pumps. With FR active, the DE id routes through
    // `perCountryStationServiceProvider('DE')`; with the same fake
    // wired to both, the symmetric tests pass regardless of which
    // direction the user is tapping.
    activeCountryProvider.overrideWith(() => _FixedActiveCountry(Countries.france)),
    // Cover both routing seams in `stationDetailProvider`:
    //  - `stationServiceProvider` is used when id-prefix country == active.
    //  - `perCountryStationServiceProvider(<code>)` is used when they differ
    //    (#753 cross-country tap path).
    // Override both with the same fake so symmetric tests pass regardless
    // of which path the provider chooses.
    stationServiceProvider.overrideWithValue(service),
    perCountryStationServiceProvider('FR').overrideWithValue(service),
    perCountryStationServiceProvider('DE').overrideWithValue(service),
    searchStateProvider.overrideWith(_EmptySearchState.new),
  ]);

  return (container: container, router: router, service: service);
}

void main() {
  group('widget tap → station detail (#753 e2e)', () {
    testWidgets(
        'tap on row A (fr-12345) opens FR station detail with TotalEnergies brand — '
        'NOT the DE Shell station',
        (tester) async {
      final harness = _buildHarness();
      addTearDown(harness.container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: harness.container,
          child: MaterialApp.router(
            routerConfig: harness.router,
            builder: (context, child) => WidgetClickListener(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      );
      expect(find.text('home'), findsOneWidget);

      // Simulate the warm-click path: a URI lands via the
      // home_widget channel and the listener pushes the route.
      harness.container
          .read(widgetLaunchHandlerProvider)
          .handle(Uri.parse('tankstellenwidget://station?id=fr-12345'));
      await tester.pumpAndSettle();

      expect(harness.router.state.matchedLocation, '/station/fr-12345');
      expect(find.text('detail-id:fr-12345'), findsOneWidget);
      expect(find.text('detail-brand:TotalEnergies'), findsOneWidget,
          reason: 'Tapped FR row → FR station detail must render. If '
              'this ever shows the DE Shell brand, #753 has regressed: '
              'the widget tap is opening the wrong station.');
      expect(find.text('detail-brand:Shell'), findsNothing);

      // The fake service must have been asked for the FR id, not the DE one.
      expect(harness.service.getStationDetailCalls, ['fr-12345']);
    });

    testWidgets(
        'tap on row B (de-uuid-abc) opens DE Shell detail — '
        'symmetric with the FR test so an id-swap regression trips both',
        (tester) async {
      final harness = _buildHarness();
      addTearDown(harness.container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: harness.container,
          child: MaterialApp.router(
            routerConfig: harness.router,
            builder: (context, child) => WidgetClickListener(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      );

      harness.container
          .read(widgetLaunchHandlerProvider)
          .handle(Uri.parse('tankstellenwidget://station?id=de-uuid-abc'));
      await tester.pumpAndSettle();

      expect(harness.router.state.matchedLocation, '/station/de-uuid-abc');
      expect(find.text('detail-id:de-uuid-abc'), findsOneWidget);
      expect(find.text('detail-brand:Shell'), findsOneWidget);
      expect(find.text('detail-brand:TotalEnergies'), findsNothing,
          reason: 'Symmetric to the FR-row test — locks down both '
              'directions of the id-swap regression.');

      expect(harness.service.getStationDetailCalls, ['de-uuid-abc']);
    });

    testWidgets(
        '#753 collision scenario — search-state cached the FR station under '
        'numeric id `12345`; tapping the DE widget row with country-prefixed '
        'id `de-uuid-abc` MUST open the DE station, not fall into the stale '
        'FR cache hit',
        (tester) async {
      // The classic collision: pre-#753 the FR service emitted bare
      // numeric ids ("12345") and the DE service emitted bare UUIDs.
      // With both prefixed, `searchStateProvider`'s short-circuit on
      // `station.id == stationId` now requires an EXACT id match,
      // so a stale country-A cache cannot shadow a country-B widget tap.
      const cachedFr = Station(
        id: 'fr-12345',
        name: 'TotalEnergies Lyon',
        brand: 'TotalEnergies',
        street: 'Rue stale',
        postCode: '69000',
        place: 'Lyon',
        lat: 45.7,
        lng: 4.8,
        isOpen: true,
      );

      final service =
          _FakeAllCountriesStationService([_stationFR, _stationDE]);
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('home')),
          GoRoute(
            path: '/station/:id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return Consumer(builder: (context, ref, _) {
                final detail = ref.watch(stationDetailProvider(id));
                return detail.when(
                  data: (sd) => Scaffold(
                    body: Text('detail-brand:${sd.data.station.brand}'),
                  ),
                  error: (e, _) => Text('error:$e'),
                  loading: () => const Text('loading'),
                );
              });
            },
          ),
        ],
      );

      final container = ProviderContainer(overrides: [
        routerProvider.overrideWith((_) => router),
        // Active country = DE so the DE id resolves via the active
        // `stationServiceProvider` and the FR id (if it ever arrived)
        // would have routed via `perCountryStationServiceProvider('FR')`.
        activeCountryProvider.overrideWith(() => _FixedActiveCountry(Countries.germany)),
        stationServiceProvider.overrideWithValue(service),
        perCountryStationServiceProvider('FR').overrideWithValue(service),
        perCountryStationServiceProvider('DE').overrideWithValue(service),
        searchStateProvider.overrideWith(
          () => _SeededSearchState(const [FuelStationResult(cachedFr)]),
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => WidgetClickListener(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      );

      // User taps the DE widget row whose id is `de-uuid-abc`. The
      // search-state has a stale FR entry with id `fr-12345` — a
      // different prefix. A correct match will drop through to the
      // service fallback and resolve to Shell.
      container
          .read(widgetLaunchHandlerProvider)
          .handle(Uri.parse('tankstellenwidget://station?id=de-uuid-abc'));
      await tester.pumpAndSettle();

      expect(find.text('detail-brand:Shell'), findsOneWidget,
          reason: '#753 collision regression — must not return the '
              'stale FR cache entry just because its raw numeric id '
              'happens to overlap with the DE UUID. The country '
              'prefix is what makes these globally unique.');
    });
  });
}

class _SeededSearchState extends SearchState {
  final List<SearchResultItem> seeded;
  _SeededSearchState(this.seeded);

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() {
    return AsyncValue.data(
      ServiceResult(
        data: seeded,
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      ),
    );
  }
}

class _FixedActiveCountry extends ActiveCountry {
  final CountryConfig _country;
  _FixedActiveCountry(this._country);

  @override
  CountryConfig build() => _country;
}
