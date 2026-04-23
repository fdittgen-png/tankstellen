import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/core/location/user_position_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/features/favorites/providers/ev_favorites_provider.dart';
import 'package:tankstellen/features/favorites/providers/favorite_stations_provider.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Integration test for issue #565 — fresh-install end-to-end.
///
/// Boots the app against a completely empty Hive (no consent flag, no
/// setup flag, no profile) and walks the redirect chain that the
/// router enforces:
///
///   1. App starts -> router redirects to /consent (GDPR prompt)
///   2. GDPR consent stored -> router would advance to /setup (wizard)
///   3. Wizard completes (skipSetup + default profile) -> router
///      would advance to / (search shell — and the user is in a state
///      where they can initiate a search).
///
/// The test uses REAL Hive boxes (no MockStorageRepository) backed by
/// a temp directory. Phase 1 is exercised as a full widget test
/// (`MaterialApp.router` + `ProviderScope`) because the consent screen
/// has no heavy dependencies. Phases 2 and 3 assert the same storage
/// predicates the router's redirect callback reads live (see
/// lib/app/router.dart: the callback consults
/// `StorageKeys.gdprConsentGiven`, `isSetupComplete`, and
/// `resolveLandingLocation`) — rendering the wizard + shell in a
/// single `testWidgets` call is blocked by animations/timers inside
/// the shell branches that never settle under the test harness.
///
/// NOTE: `test/helpers/pump_app.dart` does not yet support an
/// in-memory Hive bootstrap for router-based tests. Captured as a
/// follow-up opportunity in the PR body. This test therefore inlines
/// the setup against the documented `Hive.init` + `ProviderScope`
/// pattern (same approach used by `cross_country_favorites_test.dart`).
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('fresh_install_integration_');
    Hive.init(tempDir.path);
    await HiveStorage.initForTest();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// Heavy external providers that must be stubbed even though storage
  /// is real. None of these touch Hive — they just prevent the test
  /// from reaching GPS / network / sync code.
  List<Object> freshInstallOverrides() {
    return <Object>[
      userPositionProvider.overrideWith(_NullUserPosition.new),
      searchStateProvider.overrideWith(_EmptySearchState.new),
      favoriteStationsProvider.overrideWith(_EmptyFavoriteStations.new),
      evFavoritesProvider.overrideWith(_EmptyEvFavorites.new),
      syncStateProvider.overrideWith(_DisabledSync.new),
    ];
  }

  testWidgets(
      '#565 phase 1: empty Hive -> router redirects to /consent (GDPR prompt)',
      (tester) async {
    // Initial-location for the router is /consent (see router.dart),
    // so on an empty Hive the user must land on the consent screen
    // and the search shell must NOT be reachable.
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: freshInstallOverrides().cast(),
        child: Consumer(builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            routerConfig: router,
          );
        }),
      ),
    );
    // Give the router one settle cycle to resolve the initial redirect.
    await tester.pump(const Duration(milliseconds: 300));

    // The GDPR consent screen header is always present when the user
    // lands on /consent. The English string is the documented
    // fallback in `GdprConsentScreen`, so it is stable across l10n
    // regeneration.
    expect(
      find.text('Your Privacy'),
      findsOneWidget,
      reason:
          'Fresh install with no GDPR flag must land on /consent — #565.',
    );

    // Sanity: the search shell MUST NOT be reachable before consent.
    expect(find.text('Fuel Prices'), findsNothing);
  });

  test(
      '#565 phase 2: consent given, setup incomplete -> router would redirect '
      'to /setup (onboarding wizard)',
      () async {
    // Build a throw-away ProviderContainer that exposes the real
    // HiveStorage through `hiveStorageProvider`. We drive the
    // storage state by calling its getters/setters directly — exactly
    // the calls the UI makes in consent → setup flow.
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final storage = container.read(storageRepositoryProvider);

    // Step 1: user accepts GDPR consent — mirrors what
    // `GdprConsentProvider.save(...)` writes (see
    // lib/core/providers/app_state_provider.dart).
    await storage.putSetting(StorageKeys.gdprConsentGiven, true);
    await storage.putSetting(StorageKeys.consentLocation, false);
    await storage.putSetting(StorageKeys.consentErrorReporting, false);
    await storage.putSetting(StorageKeys.consentCloudSync, false);

    // Invariants the router reads at redirect time:
    expect(
      storage.getSetting(StorageKeys.gdprConsentGiven),
      isTrue,
      reason: 'Consent screen must persist the consent flag — #559.',
    );
    expect(
      storage.isSetupComplete,
      isFalse,
      reason:
          'Consent alone is not setup completion — the wizard must still show. '
          'This is the exact gate that #555 previously bypassed.',
    );
    expect(
      storage.getActiveProfileId(),
      isNull,
      reason:
          'No profile exists before the wizard finishes — activeProfileProvider '
          'resolves to null and ActiveCountry falls back to locale detection.',
    );

    // The router redirect: hasConsent=true && !isReady && !isConsent
    // → '/setup'. With the state we just wrote, that predicate is
    // satisfied, which is the invariant under test.
  });

  test(
      '#565 phase 3: wizard completes -> router resolves landing to / '
      '(search shell)',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final storage = container.read(storageRepositoryProvider);

    // Replay phase 2 state first.
    await storage.putSetting(StorageKeys.gdprConsentGiven, true);
    await storage.putSetting(StorageKeys.consentLocation, false);
    await storage.putSetting(StorageKeys.consentErrorReporting, false);
    await storage.putSetting(StorageKeys.consentCloudSync, false);

    // Wizard finish step — mirrors
    // `OnboardingWizardScreen._completeSetup` in
    // lib/features/setup/presentation/screens/onboarding_wizard_screen.dart.
    await storage.skipSetup();
    final repo = container.read(profileRepositoryProvider);
    final profile = await repo.ensureDefaultProfile();

    // Post-wizard invariants the router reads at redirect time:
    expect(storage.isSetupComplete, isTrue,
        reason: 'Wizard must flip the setup-complete flag.');
    expect(storage.getActiveProfileId(), equals(profile.id),
        reason:
            'Default profile must be active so ActiveCountry/ActiveLanguage '
            'can resolve from it.');

    // `resolveLandingLocation` is the exact function the router
    // invokes when `isReady && isConsent` (or when consent is given
    // the first time). The default profile is created with
    // `LandingScreen.nearest`, which resolves to '/'.
    final landing = resolveLandingLocation(storage);
    expect(
      landing,
      '/',
      reason:
          'Fresh-install wizard creates a profile with landing=nearest, so '
          'the router must land the user on / — the search shell. This '
          'is the full fresh-install path asserted by #565.',
    );

    // The user is now in a state where they can perform a search:
    // the landing route is the search shell and an active profile
    // with a preferred fuel type and a default radius is present.
    expect(profile.preferredFuelType, isNotNull);
    expect(profile.defaultSearchRadius, greaterThan(0));
  });

  testWidgets(
      '#565 router redirect is driven by GDPR flag — no flag means no shell',
      (tester) async {
    // Cross-check: confirm the router redirect does NOT leak any
    // "always allow" shortcut that would let the user bypass consent.
    // With an empty Hive we must never see the shell, no matter how
    // many pumps we do, as long as the consent flag is absent.
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: freshInstallOverrides().cast(),
        child: Consumer(builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            routerConfig: router,
          );
        }),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Attempt a manual navigation to '/' — the redirect must still
    // bounce the user back to /consent. The consent header stays
    // visible; the shell never appears.
    final BuildContext ctx = tester.element(find.text('Your Privacy'));
    GoRouter.of(ctx).go('/');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Your Privacy'), findsOneWidget,
        reason:
            'Even on an explicit go("/") the router must redirect back to '
            '/consent when no GDPR flag is persisted. This is the guard that '
            'protects the pre-consent invariant #565 locks in.');
    expect(find.text('Fuel Prices'), findsNothing);
  });
}

// ---------------------------------------------------------------------------
// Static fakes for heavy external data providers.
//
// These keep the widget-level phase hermetic: no network, no GPS, no sync.
// They DO NOT override storage — the router reads through to the real Hive
// boxes backed by the temp directory.
// ---------------------------------------------------------------------------

class _NullUserPosition extends UserPosition {
  @override
  UserPositionData? build() => null;
}

class _EmptySearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() =>
      AsyncValue.data(ServiceResult(
        data: const <SearchResultItem>[],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      ));
}

class _EmptyFavoriteStations extends FavoriteStations {
  @override
  AsyncValue<ServiceResult<List<Station>>> build() =>
      AsyncValue.data(ServiceResult(
        data: const <Station>[],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      ));

  @override
  Future<void> loadAndRefresh() async {}
}

class _EmptyEvFavorites extends EvFavorites {
  @override
  List<String> build() => const <String>[];
}

class _DisabledSync extends SyncState {
  @override
  SyncConfig build() => const SyncConfig();
}
