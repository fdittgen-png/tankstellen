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

/// Bottom-nav Conso-tab gating, profile-driven (post-#conso-coherence-2).
///
/// History:
/// - #893 hid Conso when no vehicle was configured.
/// - #conso-coherence-1 removed the gate entirely.
/// - #conso-coherence-2 (these tests) re-gates Conso on the
///   `isConsumptionTabReachable` helper — the same one the Settings
///   section uses. True when `manualConsumption` OR `obd2TripRecording`
///   is effectively enabled. Maps cleanly to wizard profiles:
///     Basic    → neither flag → no Conso tab
///     Medium   → manualConsumption on → Conso tab visible
///     Full     → obd2TripRecording on → Conso tab visible

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

class _TestFeatureFlags extends FeatureFlags {
  _TestFeatureFlags(this._initial);
  final Set<Feature> _initial;

  @override
  Set<Feature> build() => {..._initial};
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required Set<Feature> enabledFeatures,
  String initialLocation = '/',
}) async {
  // Force phone-size canvas so the compact bottom nav renders (not
  // NavigationRail — the rail swap triggers at >=600dp).
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShellScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, _) => const Text('SearchBody')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/map', builder: (_, _) => const Text('MapBody')),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/favorites',
              builder: (_, _) => const Text('FavoritesBody'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/consumption-tab',
              builder: (_, _) => const Text('ConsumptionBody'),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const Text('SettingsBody'),
            ),
          ]),
          // #1901 — Trajets is now its own branch (index 5), appended
          // after Profile. ShellScreen registers 6 branches.
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/trajets-tab',
              builder: (_, _) => const Text('TrajetsBody'),
            ),
          ]),
        ],
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Seed a vehicle so other vehicle-aware providers don't hit
        // their own empty-state paths during the pump — we're only
        // testing the bottom-nav Conso gate here, not vehicle gating.
        vehicleProfileListProvider.overrideWith(() => _OneVehicleList()),
        featureFlagsProvider
            .overrideWith(() => _TestFeatureFlags(enabledFeatures)),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShellScreen — Conso gated on isConsumptionTabReachable', () {
    testWidgets(
      'Basic profile (no manualConsumption, no obd2) → Conso tab '
      'HIDDEN (3 destinations total)',
      (tester) async {
        // Basic bundle: visibility / search flags only.
        await _pumpShell(
          tester,
          enabledFeatures: {
            Feature.showFuel,
            Feature.showElectric,
            Feature.priceAlerts,
            Feature.priceHistory,
            Feature.routePlanning,
            Feature.evCharging,
          },
        );

        // Search is the icon-only centre button; Map/Favorites carry
        // text labels. Settings is no longer a tab (#1874).
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.text('Map'), findsOneWidget);
        expect(find.text('Favorites'), findsOneWidget);
        // #1901 — the Carburant destination label is now 'Fuel'.
        expect(find.text('Fuel'), findsNothing,
            reason: 'Basic profile must not surface the Carburant tab — '
                'no consumption features are reachable.');
        expect(find.text('Trips'), findsNothing,
            reason: 'Basic profile must not surface the Trajets tab.');
        expect(find.byIcon(Icons.local_gas_station_outlined),
            findsNothing);
      },
    );

    testWidgets(
      'Medium profile (manualConsumption + showConsumptionTab on) → '
      'Conso tab VISIBLE (4 destinations total)',
      (tester) async {
        // `isConsumptionTabReachable` is
        // `showConsumptionTab && (manualConsumption || obd2TripRecording)`
        // — both halves of the AND must be on. Seeding
        // showConsumptionTab explicitly because `_TestFeatureFlags.build()`
        // returns ONLY the seeded set (overrides any manifest default).
        await _pumpShell(
          tester,
          enabledFeatures: {
            Feature.showFuel,
            Feature.showElectric,
            Feature.priceAlerts,
            Feature.priceHistory,
            Feature.routePlanning,
            Feature.evCharging,
            Feature.tankSync,
            Feature.baselineSync,
            Feature.manualConsumption,
            Feature.showConsumptionTab,
          },
        );

        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.text('Map'), findsOneWidget);
        expect(find.text('Favorites'), findsOneWidget);
        // #1901 — Medium profile (manualConsumption, no obd2) is
        // fuel-only ConsoMode: the Carburant tab shows, Trajets does not.
        expect(find.text('Fuel'), findsOneWidget);
        expect(find.text('Trips'), findsNothing,
            reason: 'Medium profile has no OBD2 trips — Trajets hidden.');
        expect(find.byIcon(Icons.local_gas_station_outlined),
            findsOneWidget);
      },
    );

    testWidgets(
      'Full profile (OBD2 stack on) → Conso tab VISIBLE',
      (tester) async {
        await _pumpShell(
          tester,
          enabledFeatures: {
            Feature.showFuel,
            Feature.showElectric,
            Feature.priceAlerts,
            Feature.priceHistory,
            Feature.routePlanning,
            Feature.evCharging,
            Feature.tankSync,
            Feature.baselineSync,
            Feature.manualConsumption,
            Feature.obd2TripRecording,
            Feature.showConsumptionTab,
            Feature.autoRecord,
            Feature.gamification,
            Feature.consumptionAnalytics,
            Feature.loyaltyCards,
            Feature.hapticEcoCoach,
            Feature.glideCoach,
            Feature.gpsTripPath,
          },
        );

        // #1901 — Full profile (obd2TripRecording on) is fuel-and-trips
        // ConsoMode: both Carburant and Trajets destinations show.
        expect(find.text('Fuel'), findsOneWidget);
        expect(find.text('Trips'), findsOneWidget);
        expect(find.byIcon(Icons.local_gas_station_outlined),
            findsOneWidget);
        expect(find.byIcon(Icons.route_outlined), findsOneWidget);
      },
    );
  });
}
