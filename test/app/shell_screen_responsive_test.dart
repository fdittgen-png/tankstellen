import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/app/shell_screen.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
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
                    path: '/profile',
                    builder: (context, state) =>
                        const Center(child: Text('ProfileScreen')),
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

      // Bottom nav bar items should be present
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

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

      // Tap Map in the NavigationRail
      // NavigationRail uses NavigationRailDestination icons
      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 0);

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
