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
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';
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
/// #893 hides the Conso tab when the vehicle list is empty.
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
  group('ShellScreen', () {
    late List<Object> overrides;

    setUp(() {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.isSetupComplete).thenReturn(true);
      when(() => test.mockStorage.getActiveProfileId()).thenReturn(null);
      when(() => test.mockStorage.getAllProfiles()).thenReturn([]);
      overrides = [
        ...test.overrides,
        activeLanguageProvider.overrideWith(
            () => _FixedActiveLanguage(AppLanguages.all.first)),
        userPositionNullOverride(),
        searchStateProvider.overrideWith(() => _EmptySearchState()),
        favoriteStationsProvider.overrideWith(() => _EmptyFavoriteStations()),
        // #893 — seed a vehicle so the Conso tab shows up and the
        // existing 5-tab / 5-label assertions below still hold.
        vehicleProfileListProvider.overrideWith(() => _OneVehicleList()),
      ];
    });

    /// Build a GoRouter that includes the shell with 4 branches, similar
    /// to the real app router but without the redirect logic.
    GoRouter buildRouter() {
      return GoRouter(
        initialLocation: '/',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) {
              // Use the real ShellScreen via the import of shell_screen.dart
              return _ShellScaffold(navigationShell: navigationShell);
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
            ],
          ),
        ],
      );
    }

    Future<void> pumpShell(WidgetTester tester) async {
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

    testWidgets('renders all 5 bottom navigation tabs (#778)',
        (tester) async {
      await pumpShell(tester);

      // All five labels should be present in the bottom nav —
      // Consumption sits between Favorites and Settings as of #778.
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Consumption'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('tab labels match expected text', (tester) async {
      await pumpShell(tester);

      final labels = <String>[];
      for (final label in [
        'Search',
        'Map',
        'Favorites',
        'Consumption',
        'Settings'
      ]) {
        expect(find.text(label), findsOneWidget,
            reason: 'Expected tab label "$label" to be present');
        labels.add(label);
      }
      expect(labels.length, 5);
    });

    testWidgets('initial tab shows search content', (tester) async {
      await pumpShell(tester);

      expect(find.text('SearchScreen'), findsOneWidget);
    });

    testWidgets('tapping Map tab switches content', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Map'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('MapScreen'), findsOneWidget);
    });

    testWidgets('tapping Favorites tab switches content', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text('Favorites'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('FavoritesScreen'), findsOneWidget);
    });

    testWidgets('tapping Settings tab switches content', (tester) async {
      await pumpShell(tester);
      // Dump present icons so diagnostics are easy if this regresses.
      final settingsFinder = find.byWidgetPredicate(
        (w) =>
            w is Icon &&
            (w.icon == Icons.settings_outlined ||
                w.icon == Icons.settings),
      );
      expect(settingsFinder, findsAtLeast(1));
      await tester.tap(settingsFinder.first);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('ProfileScreen'), findsOneWidget);
    });

    testWidgets('real ShellScreen navigation bar icons have semantic labels',
        (tester) async {
      // Force phone-size screen so bottom nav bar is rendered (not NavigationRail)
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final handle = tester.ensureSemantics();

      // Build a router that uses the real ShellScreen (not the test mock)
      final router = GoRouter(
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
            ],
          ),
        ],
      );

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

      // Each nav item should have a Semantics node with the correct label
      expect(find.bySemanticsLabel('Search'), findsOneWidget);
      expect(find.bySemanticsLabel('Map'), findsOneWidget);
      expect(find.bySemanticsLabel('Favorites'), findsOneWidget);
      expect(find.bySemanticsLabel('Consumption'), findsOneWidget);
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);

      handle.dispose();
    });
  });
}

/// Minimal shell that renders a bottom navigation bar with 4 tabs.
/// Mirrors ShellScreen structure without animations to keep tests simple.
class _ShellScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const _ShellScaffold({required this.navigationShell});

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.navigationShell.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Sync with router
    final routerIndex = widget.navigationShell.currentIndex;
    if (routerIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = routerIndex);
      });
    }

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          widget.navigationShell.goBranch(index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favorites'),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station_outlined),
            label: 'Consumption',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
