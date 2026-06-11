// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/shell_screen.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Seeds one vehicle + a Full-profile-equivalent feature set so the
/// Conso tab is visible. The bottom-nav Conso gate is driven by
/// `isConsumptionTabReachable` — `obd2TripRecording` +
/// `showConsumptionTab` on keeps the Conso slot in the shell.
class _OneVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(
          id: 'car-1',
          name: 'Daily Driver',
          type: VehicleType.combustion,
        ),
      ];
}

class _FullProfileFlags extends FeatureFlags {
  @override
  Set<Feature> build() => const {
        Feature.obd2TripRecording,
        Feature.showConsumptionTab,
      };
}

/// #1874: the bottom bar holds four destinations — `Map · Favorites ·
/// [Search] · Consumption` — with Search the raised centre button.
/// Settings is no longer a tab (it moved to the top-right app bar), so
/// the bar never shows the settings icon.

Future<void> _pumpShell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShellScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, _) => const Text('Search')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/map', builder: (_, _) => const Text('Map')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/favorites',
              builder: (_, _) => const Text('Favorites'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/consumption-tab',
              builder: (_, _) => const Text('Consumption'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const Text('Settings'),
            ),
          ]),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleProfileListProvider.overrideWith(() => _OneVehicleList()),
        featureFlagsProvider.overrideWith(() => _FullProfileFlags()),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShellScreen bottom-bar destinations (#1874)', () {
    testWidgets('renders Map, Favorites, Search and Consumption — and '
        'no Settings tab', (tester) async {
      await _pumpShell(tester);

      // Search branch is active → its filled icon shows; the other
      // three destinations show their outlined icons.
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
      expect(find.byIcon(Icons.local_gas_station_outlined), findsOneWidget);

      // Settings is not a bottom-bar tab anymore.
      expect(find.byIcon(Icons.settings), findsNothing);
      expect(find.byIcon(Icons.settings_outlined), findsNothing);
    });

    testWidgets('tapping Consumption shows the consumption-tab branch',
        (tester) async {
      await _pumpShell(tester);
      await tester.tap(find.byIcon(Icons.local_gas_station_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Consumption'), findsWidgets);
    });
  });
}
