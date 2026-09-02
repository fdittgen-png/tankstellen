// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/profile_routes.dart';
import 'package:tankstellen/core/navigation/app_routes.dart';

void main() {
  group('profileRoutes', () {
    test('returns exactly 24 routes', () {
      // Guards against accidental insert/delete — the Profile shell
      // branch pushes onto these sub-screens. #2248 added the three
      // Developer-tools routes (/developer-tools[/error-log|/flags]);
      // #2471 added the gated /developer-tools/obd2-health screen;
      // #2518 added the gated /developer-tools/ocr-tester screen;
      // #3884 added the twelve Settings topic screens + the radar
      // sub-screen (/settings/...).
      expect(profileRoutes.length, 24);
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

    test('route 3 "/privacy-dashboard" redirects to Settings → Privacy & data '
        '(#3908 — the dashboard is retired)', () {
      final route = profileRoutes[3] as GoRoute;
      expect(route.path, '/privacy-dashboard');
      expect(route.builder, isNull);
      expect(route.redirect, isNotNull);
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

    test('route 9 path is "/developer-tools/obd2-health" (#2471)', () {
      final route = profileRoutes[9] as GoRoute;
      expect(route.path, '/developer-tools/obd2-health');
    });

    test('route 10 path is "/developer-tools/ocr-tester" (#2518)', () {
      final route = profileRoutes[10] as GoRoute;
      expect(route.path, '/developer-tools/ocr-tester');
    });

    test('routes 11–23 are the #3884 Settings topic screens, in root-tile '
        'order, with the radar sub-screen after Driving & consumption', () {
      const expected = <String>[
        RoutePaths.settingsProfiles,
        RoutePaths.settingsVehicles,
        RoutePaths.settingsDriving,
        RoutePaths.settingsRadar,
        RoutePaths.settingsPrices,
        RoutePaths.settingsUnits,
        RoutePaths.settingsFeatures,
        RoutePaths.settingsDataSources,
        RoutePaths.settingsSync,
        RoutePaths.settingsPrivacy,
        RoutePaths.settingsBackup,
        RoutePaths.settingsAdvanced,
        RoutePaths.settingsAbout,
      ];
      for (var i = 0; i < expected.length; i++) {
        final route = profileRoutes[11 + i] as GoRoute;
        expect(route.path, expected[i], reason: 'route ${11 + i}');
        expect(route.path, startsWith('/settings/'));
      }
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

    test('every GoRoute has a non-null builder (or a redirect)', () {
      for (var i = 0; i < profileRoutes.length; i++) {
        final route = profileRoutes[i] as GoRoute;
        expect(
          route.builder ?? route.redirect,
          isNotNull,
          reason: 'route $i (${route.path}) should have a builder or redirect',
        );
      }
    });
  });
}
