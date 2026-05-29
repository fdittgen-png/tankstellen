// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/profile_routes.dart';

void main() {
  group('profileRoutes', () {
    test('returns exactly 9 routes', () {
      // Guards against accidental insert/delete — the Profile shell
      // branch pushes onto these sub-screens. #2248 added the three
      // Developer-tools routes (/developer-tools[/error-log|/flags]).
      expect(profileRoutes.length, 9);
    });

    test('route 0 path is "/vehicles"', () {
      final route = profileRoutes[0] as GoRoute;
      expect(route.path, '/vehicles');
    });

    test('route 1 path is "/vehicles/edit"', () {
      final route = profileRoutes[1] as GoRoute;
      expect(route.path, '/vehicles/edit');
    });

    test('route 2 path is "/itineraries"', () {
      final route = profileRoutes[2] as GoRoute;
      expect(route.path, '/itineraries');
    });

    test('route 3 path is "/privacy-dashboard"', () {
      final route = profileRoutes[3] as GoRoute;
      expect(route.path, '/privacy-dashboard');
    });

    test('route 4 path is "/theme-settings" (#897)', () {
      // #897 — dedicated Theme settings screen pushed from the Theme
      // card on the profile/settings screen.
      final route = profileRoutes[4] as GoRoute;
      expect(route.path, '/theme-settings');
    });

    test('route 5 path is "/loyalty-settings" (#1120)', () {
      // #1120 — fuel-club / loyalty discount settings.
      final route = profileRoutes[5] as GoRoute;
      expect(route.path, '/loyalty-settings');
    });

    test('route 6 path is "/developer-tools" (#2248)', () {
      final route = profileRoutes[6] as GoRoute;
      expect(route.path, '/developer-tools');
    });

    test('route 7 path is "/developer-tools/error-log" (#2248)', () {
      final route = profileRoutes[7] as GoRoute;
      expect(route.path, '/developer-tools/error-log');
    });

    test('route 8 path is "/developer-tools/flags" (#2248)', () {
      final route = profileRoutes[8] as GoRoute;
      expect(route.path, '/developer-tools/flags');
    });

    test('every entry is a GoRoute', () {
      for (var i = 0; i < profileRoutes.length; i++) {
        expect(
          profileRoutes[i],
          isA<GoRoute>(),
          reason: 'route $i should be a GoRoute',
        );
      }
    });

    test('every GoRoute has a non-null builder', () {
      for (var i = 0; i < profileRoutes.length; i++) {
        final route = profileRoutes[i] as GoRoute;
        expect(
          route.builder,
          isNotNull,
          reason: 'route $i (${route.path}) should have a non-null builder',
        );
      }
    });
  });
}
