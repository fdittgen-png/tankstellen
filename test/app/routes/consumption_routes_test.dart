// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/consumption_routes.dart';

void main() {
  group('consumptionRoutes', () {
    test('returns exactly 7 routes', () {
      // Guards against accidental insert/delete — `/consumption-tab`
      // lives in shellBranches, but every other consumption route is
      // owned here. `/trip-history` was removed in #1313 — the Trajets
      // sub-tab covers the same content inline. `/consumption-stats`
      // was added in #2698 (monthly fuel-cost statistics page).
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

    test('route 2 path is "/consumption-stats" (#2698)', () {
      // #2698 — monthly fuel-cost statistics page, opened from the
      // ConsumptionStatsCard chevron on the consumption tab.
      final route = consumptionRoutes[2] as GoRoute;
      expect(route.path, '/consumption-stats');
    });

    test('route 3 path is "/consumption/pick-station"', () {
      final route = consumptionRoutes[3] as GoRoute;
      expect(route.path, '/consumption/pick-station');
    });

    test('route 4 path is "/trip-recording" (#726)', () {
      // #726 — global trip recording view, opened from AddFillUpScreen
      // after OBD2 connect, re-entered via the active-trip banner.
      final route = consumptionRoutes[4] as GoRoute;
      expect(route.path, '/trip-recording');
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

    test('"/trip-history" route is removed (#1313)', () {
      // Trajets sub-tab inside ConsumptionScreen renders inline trip
      // history; the standalone screen + route are gone.
      final paths = consumptionRoutes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();
      expect(paths, isNot(contains('/trip-history')));
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
