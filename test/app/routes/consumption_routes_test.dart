import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/consumption_routes.dart';

void main() {
  group('consumptionRoutes', () {
    test('returns exactly 7 routes', () {
      // Guards against accidental insert/delete — `/consumption-tab`
      // lives in shellBranches, but every other consumption route is
      // owned here.
      expect(consumptionRoutes.length, 7);
    });

    test('route 0 path is "/consumption"', () {
      final route = consumptionRoutes[0] as GoRoute;
      expect(route.path, '/consumption');
    });

    test('route 1 path is "/carbon"', () {
      final route = consumptionRoutes[1] as GoRoute;
      expect(route.path, '/carbon');
    });

    test('route 2 path is "/consumption/pick-station"', () {
      final route = consumptionRoutes[2] as GoRoute;
      expect(route.path, '/consumption/pick-station');
    });

    test('route 3 path is "/trip-recording" (#726)', () {
      // #726 — global trip recording view, opened from AddFillUpScreen
      // after OBD2 connect, re-entered via the active-trip banner.
      final route = consumptionRoutes[3] as GoRoute;
      expect(route.path, '/trip-recording');
    });

    test('route 4 path is "/trip-history"', () {
      final route = consumptionRoutes[4] as GoRoute;
      expect(route.path, '/trip-history');
    });

    test('route 5 path is "/trip/:id" with id path parameter (#889)', () {
      // #889 — trip-detail route uses `:id` so it can be deep-linked
      // from the Trajets tab. The exact pattern is load-bearing — the
      // builder reads `state.pathParameters['id']`.
      final route = consumptionRoutes[5] as GoRoute;
      expect(route.path, '/trip/:id');
      expect(route.path, contains(':id'));
    });

    test('route 6 path is "/consumption/add"', () {
      final route = consumptionRoutes[6] as GoRoute;
      expect(route.path, '/consumption/add');
    });

    test('every entry is a GoRoute', () {
      for (var i = 0; i < consumptionRoutes.length; i++) {
        expect(
          consumptionRoutes[i],
          isA<GoRoute>(),
          reason: 'route $i should be a GoRoute',
        );
      }
    });

    test('every GoRoute has a non-null builder', () {
      for (var i = 0; i < consumptionRoutes.length; i++) {
        final route = consumptionRoutes[i] as GoRoute;
        expect(
          route.builder,
          isNotNull,
          reason: 'route $i (${route.path}) should have a non-null builder',
        );
      }
    });

    test('no GoRoute declares nested sub-routes', () {
      // The consumption flow is flat — every screen pushes on top of
      // the shell. If a future change introduces nested routes, this
      // assertion forces an explicit update + a per-sub-route test.
      for (var i = 0; i < consumptionRoutes.length; i++) {
        final route = consumptionRoutes[i] as GoRoute;
        expect(
          route.routes,
          isEmpty,
          reason: 'route $i (${route.path}) should not declare sub-routes',
        );
      }
    });
  });
}
