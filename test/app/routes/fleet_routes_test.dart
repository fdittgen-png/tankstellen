// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/fleet_routes.dart';
import 'package:tankstellen/core/navigation/app_routes.dart';

/// #4215 — the count guard for the `/fleet/…` push family, mirroring
/// `profile_routes_test.dart`.
///
/// Fleet routes live in their own table precisely so that a later
/// slice appending here does not renumber the 25 pinned profile
/// routes. This test is the other half of that deal: the fleet list
/// gets the same insert/delete guard, so the split buys isolation
/// rather than losing coverage.
void main() {
  group('fleetRoutes', () {
    test('returns exactly 6 routes', () {
      // #4215 (F7) shipped the employee's two: the expense list and
      // the review screen it pushes. #4216 (F9) appended the
      // manager's four LAST, so neither index below moved.
      expect(fleetRoutes.length, 6);
    });

    test('route 0 path is "/fleet/expenses"', () {
      final route = fleetRoutes[0] as GoRoute;
      expect(route.path, RoutePaths.fleetExpenses);
      expect(route.path, '/fleet/expenses');
    });

    test('route 1 path is "/fleet/expenses/review"', () {
      final route = fleetRoutes[1] as GoRoute;
      expect(route.path, RoutePaths.fleetExpenseReview);
      expect(route.path, '/fleet/expenses/review');
    });

    test('the manager surfaces are routes 2..5, in dashboard order '
        '(#4216)', () {
      const expected = [
        RoutePaths.fleetOverview,
        RoutePaths.fleetVehicle,
        RoutePaths.fleetQueue,
        RoutePaths.fleetReports,
      ];
      for (var i = 0; i < expected.length; i++) {
        expect((fleetRoutes[2 + i] as GoRoute).path, expected[i],
            reason: 'manager route $i');
      }
    });

    test('the vehicle route carries its fleet-vehicle id as the typed '
        'extra — a company asset id is not a deep-link contract '
        '(#4216)', () {
      const route = FleetVehicleDetailRoute('veh-3');
      expect(route.location, RoutePaths.fleetVehicle);
      expect(route.extra, 'veh-3');
    });

    test('the queue and report routes carry no payload — they are '
        'whole surfaces, not records (#4216)', () {
      expect(const FleetExpenseQueueRoute().extra, isNull);
      expect(const FleetReportsRoute().extra, isNull);
    });

    test('no fleet path mentions a trip, a journey or a location — '
        'ADR 0025 D5.1 leaves the manager no route to one', () {
      for (final route in fleetRoutes) {
        final path = (route as GoRoute).path;
        for (final forbidden in const ['trip', 'journey', 'map', 'location']) {
          expect(path.contains(forbidden), isFalse,
              reason: '$path must not offer $forbidden');
        }
      }
    });

    test('every entry is a GoRoute with a builder', () {
      for (var i = 0; i < fleetRoutes.length; i++) {
        final route = fleetRoutes[i];
        expect(route, isA<GoRoute>(), reason: 'route $i');
        expect((route as GoRoute).builder ?? route.redirect, isNotNull,
            reason: 'route $i (${route.path}) needs a builder or redirect');
      }
    });

    test('every fleet path lives under the /fleet/ prefix — the family '
        'is reachable as one, and never collides with /settings/', () {
      for (final route in fleetRoutes) {
        expect((route as GoRoute).path, startsWith('/fleet/'));
      }
    });

    test('the review route carries its expense id as the typed extra, '
        'not in the path — an id is not a deep-link contract', () {
      const route = FleetExpenseReviewRoute('expense-7');
      expect(route.location, RoutePaths.fleetExpenseReview);
      expect(route.extra, 'expense-7');
    });
  });
}
