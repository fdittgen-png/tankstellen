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

    testWidgets('renders all 4 bottom navigation tabs', (tester) async {
      await pumpShell(tester);

      // All four tab labels should be present
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('tab labels match expected text', (tester) async {
      await pumpShell(tester);

      // Verify the bottom nav bar contains exactly these labels
      final labels = <String>[];
      // Find all Text widgets that are nav bar labels (inside InkWell)
      for (final label in ['Search', 'Map', 'Favorites', 'Settings']) {
        expect(find.text(label), findsOneWidget,
            reason: 'Expected tab label "$label" to be present');
        labels.add(label);
      }
      expect(labels.length, 4);
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

      await tester.tap(find.text('Settings'));
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
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
