// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/app/shell_screen.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../helpers/mock_providers.dart';

/// Fixed ActiveLanguage notifier for testing.
class _FixedActiveLanguage extends ActiveLanguage {
  final AppLanguage _language;
  _FixedActiveLanguage(this._language);

  @override
  AppLanguage build() => _language;
}

/// Fixed SearchState returning empty data.
class _EmptySearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() {
    return AsyncValue.data(ServiceResult(
      data: const [],
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    ));
  }
}

/// Stubs one configured vehicle so the shell renders all 5 tabs —
/// some downstream widgets still gate behaviour on vehicle presence.
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

/// Seeds OBD2 + showConsumptionTab so `isConsumptionTabReachable`
/// returns true — the bottom-nav Conso gate (#conso-coherence-2)
/// drops the slot when neither manualConsumption nor
/// obd2TripRecording is on. Layout tests below assume the 5-tab
/// shell.
class _FullProfileFlags extends FeatureFlags {
  @override
  Set<Feature> build() => const {
        Feature.obd2TripRecording,
        Feature.showConsumptionTab,
      };
}

/// Fixed FavoriteStations returning empty data.
class _EmptyFavoriteStations extends FavoriteStations {
  @override
  AsyncValue<ServiceResult<List<Station>>> build() {
    return AsyncValue.data(ServiceResult(
      data: const [],
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> loadAndRefresh() async {}
}

void main() {
  group('ShellScreen responsive navigation', () {
    late List<Object> overrides;

    setUp(() {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.isSetupComplete).thenReturn(true);
      when(() => test.mockStorage.getActiveProfileId()).thenReturn(null);
      when(() => test.mockStorage.getAllProfiles()).thenReturn([]);
      overrides = [
        ...test.overrides,
        activeLanguageProvider
            .overrideWith(() => _FixedActiveLanguage(AppLanguages.all.first)),
        userPositionNullOverride(),
        searchStateProvider.overrideWith(() => _EmptySearchState()),
        favoriteStationsProvider.overrideWith(() => _EmptyFavoriteStations()),
        // Seed a vehicle so the Conso tab is visible for the
        // existing 5-tab assertions below.
        vehicleProfileListProvider.overrideWith(() => _OneVehicleList()),
        featureFlagsProvider.overrideWith(() => _FullProfileFlags()),
      ];
    });

    GoRouter buildRouter() {
      return GoRouter(
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              return ShellScreen(navigationShell: navigationShell);
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) =>
                        const Center(child: Text('SearchScreen')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/map',
                    builder: (context, state) =>
                        const Center(child: Text('MapScreen')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/favorites',
                    builder: (context, state) =>
                        const Center(child: Text('FavoritesScreen')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/consumption-tab',
                    builder: (context, state) =>
                        const Center(child: Text('ConsumptionScreen')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (context, state) =>
                        const Center(child: Text('ProfileScreen')),
                  ),
                ],
              ),
              // #1901 — Trajets is its own branch (index 5).
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/trajets-tab',
                    builder: (context, state) =>
                        const Center(child: Text('TrajetsScreen')),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    Future<void> pumpShell(
      WidgetTester tester, {
      Size size = const Size(360, 640),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = buildRouter();
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides.cast(),
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

    testWidgets('phone (360x640): shows bottom navigation bar',
        (tester) async {
      await pumpShell(tester, size: const Size(360, 640));

      // Bottom nav bar items should be present. Search is the
      // icon-only centre button; Settings moved to the app bar (#1874).
      // #1901 — Consumption split into Carburant ('Fuel') + Trajets
      // ('Trips'); the Full profile flags surface both.
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('Trips'), findsOneWidget);

      // NavigationRail should NOT be present
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('tablet portrait (768x1024): shows NavigationRail',
        (tester) async {
      await pumpShell(tester, size: const Size(768, 1024));

      // NavigationRail should be present
      expect(find.byType(NavigationRail), findsOneWidget);

      // Content should still be visible
      expect(find.text('SearchScreen'), findsOneWidget);
    });

    testWidgets('tablet landscape (1024x768): shows extended NavigationRail',
        (tester) async {
      await pumpShell(tester, size: const Size(1024, 768));

      // NavigationRail should be present
      expect(find.byType(NavigationRail), findsOneWidget);

      // Content should still be visible
      expect(find.text('SearchScreen'), findsOneWidget);
    });

    testWidgets('foldable (884x1104): shows NavigationRail', (tester) async {
      await pumpShell(tester, size: const Size(884, 1104));

      // NavigationRail should be present (884dp > 840dp threshold)
      expect(find.byType(NavigationRail), findsOneWidget);

      // Content should still be visible
      expect(find.text('SearchScreen'), findsOneWidget);
    });

    testWidgets('NavigationRail tab navigation works on tablet',
        (tester) async {
      await pumpShell(tester, size: const Size(768, 1024));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('SearchScreen'), findsOneWidget);

      // The rail starts with a destination selected (Search — its slot
      // index depends on the #1874 visual order, so just assert a
      // selection exists rather than a hard-coded 0).
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, isNotNull);

      // Find and tap the map icon in the rail
      final mapIcon = find.byIcon(Icons.map_outlined);
      expect(mapIcon, findsOneWidget);
      await tester.tap(mapIcon);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('MapScreen'), findsOneWidget);
    });

    testWidgets('VerticalDivider separates rail from content on tablet',
        (tester) async {
      await pumpShell(tester, size: const Size(768, 1024));

      // There should be a VerticalDivider between rail and content
      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('phone screen does NOT show VerticalDivider for nav',
        (tester) async {
      await pumpShell(tester, size: const Size(360, 640));

      // No VerticalDivider between rail and content (no rail)
      expect(find.byType(VerticalDivider), findsNothing);
    });
  });
}
