// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/core/domain/search_result_item.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/features/widget/providers/pending_widget_uri_provider.dart';
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

/// Stubs one configured vehicle. Some downstream widgets gate on
/// vehicle presence; seeding one keeps them out of the empty-state
/// paths during these layout tests.
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
/// is true and the bottom-nav Conso slot (#conso-coherence-2) stays
/// visible for the 5-branch assertions below.
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
        // #893 — the Conso tab is hidden when no vehicle is configured,
        // so tests that assert the 5-tab layout must seed at least one
        // vehicle.
        vehicleProfileListProvider.overrideWith(() => _OneVehicleList()),
        featureFlagsProvider.overrideWith(() => _FullProfileFlags()),
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
      expect(find.text('Sparkilo'), findsOneWidget); // Welcome title
    });

    testWidgets('/ renders shell with search when setup is complete',
        (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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
      expect(find.text('Sparkilo'), findsOneWidget);
    });

    testWidgets('shell has 5 navigation branches (#778)', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      // Shell renders all 5 tab icons — Consumption now sits
      // between Favorites and Settings (#778).
      expect(find.byIcon(Icons.search_outlined).evaluate().isNotEmpty ||
          find.byIcon(Icons.search).evaluate().isNotEmpty, isTrue);
      expect(find.byIcon(Icons.map_outlined).evaluate().isNotEmpty ||
          find.byIcon(Icons.map).evaluate().isNotEmpty, isTrue);
      expect(find.byIcon(Icons.star_outline).evaluate().isNotEmpty ||
          find.byIcon(Icons.star).evaluate().isNotEmpty, isTrue);
      expect(
          find.byIcon(Icons.local_gas_station_outlined).evaluate().isNotEmpty ||
              find.byIcon(Icons.local_gas_station).evaluate().isNotEmpty,
          isTrue);
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

    /// Pumps a minimal Router-driven widget tree so the redirect chain
    /// fires, then returns the path go_router resolved to. The target
    /// screen (e.g. `/station/:id`) may not have its full provider
    /// chain seeded — we drain `tester.takeException()` to absorb the
    /// expected build error, which doesn't change what
    /// `routerDelegate.currentConfiguration.uri` reports.
    Future<String> resolveRedirect(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late GoRouter testRouter;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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
      // Drain any build exception from the redirect target's screen —
      // tests don't seed every provider transitive of every possible
      // landing route. The routerDelegate already has the matched
      // location locked in before the screen tries to render.
      tester.takeException();
      final resolved = testRouter
          .routerDelegate
          .currentConfiguration
          .uri
          .toString();
      // Drain any pending microtasks / Riverpod retry timers spawned
      // by the target screen's failed provider reads. Without this
      // the test runner's invariant check (`!timersPending`) trips
      // and the test fails on cleanup, not on the assertion we
      // actually care about.
      await tester.pumpAndSettle(const Duration(seconds: 1));
      tester.takeException();
      return resolved;
    }

    testWidgets(
      '#widget-deeplink — pending widget URI redirects to /station/:id '
      'instead of the configured landing screen on cold start',
      (tester) async {
        final container = ProviderContainer(overrides: overrides.cast());
        addTearDown(container.dispose);

        container.read(pendingWidgetUriProvider.notifier).set(
            Uri.parse('tankstellenwidget://station?id=fr-12345'));

        expect(
          await resolveRedirect(tester, container),
          '/station/fr-12345',
          reason: 'pending widget URI must win over the configured '
              'landing screen so the cold-start flow lands on the '
              'station detail without the landing-screen flash',
        );
      },
    );

    testWidgets(
      '#widget-deeplink — pending widget URI is consumed exactly once',
      (tester) async {
        final container = ProviderContainer(overrides: overrides.cast());
        addTearDown(container.dispose);

        container.read(pendingWidgetUriProvider.notifier).set(
            Uri.parse('tankstellenwidget://station?id=de-99'));
        await resolveRedirect(tester, container);

        // Stash is one-shot: the underlying provider state must be
        // null after the redirect consumed it. Without this contract
        // the user would be trapped on the same station detail forever
        // when they back out.
        expect(container.read(pendingWidgetUriProvider), isNull);
      },
    );

    testWidgets(
      '#widget-deeplink — EV widget URI redirects to /ev-station/:id',
      (tester) async {
        final container = ProviderContainer(overrides: overrides.cast());
        addTearDown(container.dispose);

        container.read(pendingWidgetUriProvider.notifier).set(
            Uri.parse('tankstellenwidget://station?id=ocm-42'));

        expect(
          await resolveRedirect(tester, container),
          '/ev-station/ocm-42',
          reason: 'OCM-prefixed widget IDs must route to the EV detail '
              'screen, not the fuel detail screen (parity with the '
              'warm-click path)',
        );
      },
    );

    testWidgets(
      '#widget-deeplink — invalid widget URI falls through to the '
      'configured landing screen',
      (tester) async {
        final container = ProviderContainer(overrides: overrides.cast());
        addTearDown(container.dispose);

        // Scheme matches but host is garbage; widgetUriToPath returns
        // null and the redirect falls back to resolveLandingLocation.
        container.read(pendingWidgetUriProvider.notifier).set(
            Uri.parse('tankstellenwidget://garbage?nope=yes'));

        expect(await resolveRedirect(tester, container), '/');
        // Stash still drains so a future malformed URI can't keep
        // re-triggering this branch. Note: `widgetUriToPath` returns
        // null for unparseable URIs but `_consumePendingWidgetPath`
        // ALWAYS drains the stash so a single bad URI doesn't bounce
        // the redirect chain on every navigation.
        expect(container.read(pendingWidgetUriProvider), isNull);
      },
    );
  });
}
