import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/station_routes.dart';

/// `stationRoutes` is parameterised with a riverpod [Ref] so its
/// `/ev-station/:id` builder can hydrate a [ChargingStation] from the
/// storage repository at navigation time. The test grabs a real Ref
/// out of a throw-away [ProviderContainer] via a captor [Provider]; we
/// never invoke the route builders themselves (that would require the
/// full storage stack), only inspect the static config.
List<RouteBase> _routesUnderTest() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final captor = Provider<List<RouteBase>>((ref) => stationRoutes(ref));
  return container.read(captor);
}

void main() {
  group('stationRoutes', () {
    test('returns exactly 5 routes', () {
      // Guards against accidental insert/delete — fuel detail, EV
      // detail, EV deep-link, price history, and report.
      expect(_routesUnderTest().length, 5);
    });

    test('route 0 path is "/station/:id/history" with id path parameter', () {
      // Order matters: the more-specific `/station/:id/history` route
      // must come BEFORE `/station/:id` so go_router matches the
      // history sub-screen first.
      final route = _routesUnderTest()[0] as GoRoute;
      expect(route.path, '/station/:id/history');
      expect(route.path, contains(':id'));
    });

    test('route 1 path is "/station/:id" with id path parameter', () {
      final route = _routesUnderTest()[1] as GoRoute;
      expect(route.path, '/station/:id');
      expect(route.path, contains(':id'));
    });

    test('route 2 path is "/ev-station" (extra-payload variant)', () {
      // No path parameter — this variant takes the ChargingStation
      // payload via `state.extra` (set by the in-memory search-results
      // tap path).
      final route = _routesUnderTest()[2] as GoRoute;
      expect(route.path, '/ev-station');
      expect(route.path, isNot(contains(':')));
    });

    test('route 3 path is "/ev-station/:id" with id path parameter (#713)', () {
      // #713 — deep-link friendly EV detail. Takes the station id in
      // the path and hydrates the ChargingStation from the cached
      // widget JSON via the storage repository.
      final route = _routesUnderTest()[3] as GoRoute;
      expect(route.path, '/ev-station/:id');
      expect(route.path, contains(':id'));
    });

    test('route 4 path is "/report/:id" with id path parameter', () {
      final route = _routesUnderTest()[4] as GoRoute;
      expect(route.path, '/report/:id');
      expect(route.path, contains(':id'));
    });

    test('every entry is a GoRoute', () {
      final routes = _routesUnderTest();
      for (var i = 0; i < routes.length; i++) {
        expect(
          routes[i],
          isA<GoRoute>(),
          reason: 'route $i should be a GoRoute',
        );
      }
    });

    test('every GoRoute has a non-null builder', () {
      final routes = _routesUnderTest();
      for (var i = 0; i < routes.length; i++) {
        final route = routes[i] as GoRoute;
        expect(
          route.builder,
          isNotNull,
          reason: 'route $i (${route.path}) should have a non-null builder',
        );
      }
    });

    test('no GoRoute declares nested sub-routes', () {
      // All five station screens push on top of the shell — none
      // nests further routes. If a future change introduces a sub-tree
      // (e.g. `/station/:id/edit`), this assertion forces an update.
      final routes = _routesUnderTest();
      for (var i = 0; i < routes.length; i++) {
        final route = routes[i] as GoRoute;
        expect(
          route.routes,
          isEmpty,
          reason: 'route $i (${route.path}) should not declare sub-routes',
        );
      }
    });

    test('all routes that take an id use the same `:id` parameter name', () {
      // Three of the five routes accept a station id in the path.
      // Pinning the parameter name guards against a typo (`:stationId`
      // vs `:id`) silently breaking the `state.pathParameters['id']`
      // reads in every builder.
      final routes = _routesUnderTest();
      final paramRoutes = routes
          .whereType<GoRoute>()
          .where((r) => r.path.contains(':'))
          .toList();
      expect(paramRoutes.length, 4);
      for (final r in paramRoutes) {
        expect(
          r.path,
          contains(':id'),
          reason: '${r.path} should use the canonical `:id` parameter name',
        );
      }
    });
  });
}
