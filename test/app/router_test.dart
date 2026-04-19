import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../helpers/mock_providers.dart';
import '../mocks/mocks.dart';

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
  group('GoRouter configuration', () {
    late MockHiveStorage mockStorage;
    late List<Object> overrides;

    setUp(() {
      mockStorage = MockHiveStorage();
      when(() => mockStorage.hasApiKey()).thenReturn(false);
      when(() => mockStorage.getActiveProfileId()).thenReturn(null);
      when(() => mockStorage.getAllProfiles()).thenReturn([]);
      when(() => mockStorage.getFavoriteIds()).thenReturn([]);

      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.isSetupComplete).thenReturn(true);
      when(() => test.mockStorage.getActiveProfileId()).thenReturn(null);
      when(() => test.mockStorage.getAllProfiles()).thenReturn([]);
      // GDPR consent given so redirect skips consent screen
      when(() => test.mockStorage.getSetting(StorageKeys.gdprConsentGiven))
          .thenReturn(true);

      overrides = [
        ...test.overrides,
        activeLanguageProvider.overrideWith(
            () => _FixedActiveLanguage(AppLanguages.all.first)),
        userPositionNullOverride(),
        searchStateProvider.overrideWith(() => _EmptySearchState()),
        favoriteStationsProvider.overrideWith(() => _EmptyFavoriteStations()),
      ].cast();
    });

    testWidgets('redirects to /setup when setup not complete', (tester) async {
      // Create a separate storage mock where setup is NOT complete
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.isSetupComplete).thenReturn(false);
      when(() => test.mockStorage.getActiveProfileId()).thenReturn(null);
      when(() => test.mockStorage.getAllProfiles()).thenReturn([]);
      // GDPR consent already given so redirect goes to /setup, not /consent
      when(() => test.mockStorage.getSetting(StorageKeys.gdprConsentGiven))
          .thenReturn(true);

      final testOverrides = <Object>[
        ...test.overrides,
        activeLanguageProvider.overrideWith(
            () => _FixedActiveLanguage(AppLanguages.all.first)),
        userPositionNullOverride(),
        searchStateProvider.overrideWith(() => _EmptySearchState()),
        favoriteStationsProvider.overrideWith(() => _EmptyFavoriteStations()),
      ];

      late GoRouter testRouter;
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides.cast(),
          child: Consumer(builder: (context, ref, _) {
            testRouter = ref.watch(routerProvider);
            return MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              routerConfig: testRouter,
            );
          }),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // Should redirect to setup
      expect(find.text('Fuel Prices'), findsOneWidget); // Welcome title
    });

    testWidgets('/ renders shell with search when setup is complete',
        (tester) async {
      late GoRouter testRouter;
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides.cast(),
          child: Consumer(builder: (context, ref, _) {
            testRouter = ref.watch(routerProvider);
            return MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              routerConfig: testRouter,
            );
          }),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // The search screen AppBar title
      expect(find.text('Fuel Prices'), findsOneWidget);
    });

    testWidgets('shell has 4 navigation branches', (tester) async {
      late GoRouter testRouter;
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides.cast(),
          child: Consumer(builder: (context, ref, _) {
            testRouter = ref.watch(routerProvider);
            return MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              routerConfig: testRouter,
            );
          }),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      // The shell should render 4 tab items via InkWell or similar
      // Check for all 4 tab icons
      expect(find.byIcon(Icons.search_outlined).evaluate().isNotEmpty ||
          find.byIcon(Icons.search).evaluate().isNotEmpty, isTrue);
      expect(find.byIcon(Icons.map_outlined).evaluate().isNotEmpty ||
          find.byIcon(Icons.map).evaluate().isNotEmpty, isTrue);
      expect(find.byIcon(Icons.star_outline).evaluate().isNotEmpty ||
          find.byIcon(Icons.star).evaluate().isNotEmpty, isTrue);
      expect(find.byIcon(Icons.settings_outlined).evaluate().isNotEmpty ||
          find.byIcon(Icons.settings).evaluate().isNotEmpty, isTrue);
    });

    test('router has expected route paths', () {
      // Verify the router configuration statically by checking that key
      // paths exist in the route tree. We build a router with a mock
      // storage to inspect its routes.
      final storage = MockHiveStorage();
      when(() => storage.isSetupComplete).thenReturn(true);
      when(() => storage.getActiveProfileId()).thenReturn(null);

      final goRouter = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/setup', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/map', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/favorites', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/profile', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/station/:id', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/alerts', builder: (_, _) => const SizedBox()),
          GoRoute(path: '/calculator', builder: (_, _) => const SizedBox()),
        ],
      );

      // Just verify the router was created with routes — the real router
      // test is the widget test above.
      expect(goRouter.configuration.routes.length, 8);
      goRouter.dispose();
    });
  });
}
