import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/presentation/widgets/profile_landing_screen_dropdown.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../fixtures/stations.dart';
import '../helpers/mock_providers.dart';

class _FixedActiveLanguage extends ActiveLanguage {
  @override
  AppLanguage build() => AppLanguages.all.first;
}

/// Returns a single station so the search results list is non-empty —
/// otherwise `SearchResultsContent` renders the empty-state shortcut card
/// instead of the SortSelector and the cold-launch sort assertion has
/// nothing to look at.
class _EmptySearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<Station>>> build() => AsyncValue.data(
        ServiceResult(
          data: [testStation],
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
        ),
      );
}

class _EmptyFavoriteStations extends FavoriteStations {
  @override
  AsyncValue<ServiceResult<List<Station>>> build() => AsyncValue.data(
        ServiceResult(
          data: const [],
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
        ),
      );

  @override
  Future<void> loadAndRefresh() async {}
}

/// Builds a [ProviderScope] override list that mimics a fully set-up app:
/// GDPR consent given, onboarding complete, an active profile that has the
/// supplied [landing] preference. Used by every cold-launch test below.
List<Object> _readyAppOverrides({
  required LandingScreen landing,
}) {
  final test = standardTestOverrides();
  when(() => test.mockStorage.hasApiKey()).thenReturn(false);
  when(() => test.mockStorage.isSetupComplete).thenReturn(true);
  when(() => test.mockStorage.getSetting(StorageKeys.gdprConsentGiven))
      .thenReturn(true);
  when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
  when(() => test.mockStorage.getRatings()).thenReturn(const <String, int>{});
  when(() => test.mockStorage.getActiveProfileId()).thenReturn('p1');
  when(() => test.mockStorage.getProfile('p1')).thenReturn({
    'id': 'p1',
    'name': 'Test',
    'preferredFuelType': 'e10',
    'defaultSearchRadius': 10.0,
    'landingScreen': landing.name,
    'favoriteStationIds': <String>[],
    'autoUpdatePosition': false,
    'routeSegmentKm': 50.0,
    'avoidHighways': false,
    'showFuel': true,
    'showElectric': true,
    'ratingMode': 'local',
    'preferredAmenities': <String>[],
  });
  when(() => test.mockStorage.getAllProfiles()).thenReturn([
    {
      'id': 'p1',
      'name': 'Test',
      'landingScreen': landing.name,
    },
  ]);

  return [
    ...test.overrides,
    activeLanguageProvider.overrideWith(_FixedActiveLanguage.new),
    userPositionNullOverride(),
    searchStateProvider.overrideWith(_EmptySearchState.new),
    favoriteStationsProvider.overrideWith(_EmptyFavoriteStations.new),
  ];
}

Future<void> _pumpAppWithRouter(
    WidgetTester tester, List<Object> overrides) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
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
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('Cold launch lands on the right screen for each LandingScreen value', () {
    testWidgets('landingScreen=favorites -> FavoritesScreen is mounted', (
      tester,
    ) async {
      await _pumpAppWithRouter(
        tester,
        _readyAppOverrides(landing: LandingScreen.favorites),
      );

      // The shell must mount FavoritesScreen, not SearchScreen, on cold
      // launch when the active profile prefers favorites. This is the
      // half of #472 that the previous resolveLandingLocation tests
      // never proved at the widget level.
      expect(
        find.byType(FavoritesScreen),
        findsOneWidget,
        reason: 'favorites landing should mount FavoritesScreen on cold launch',
      );
    });

    testWidgets('landingScreen=cheapest -> SortSelector starts on Price', (
      tester,
    ) async {
      await _pumpAppWithRouter(
        tester,
        _readyAppOverrides(landing: LandingScreen.cheapest),
      );

      // The SortSelector exists somewhere in the search screen tree.
      // The "Price" chip must be selected because the cheapest landing
      // preference must derive into SortMode.price during initial build.
      // This is the regression guard for #470.
      expect(find.byType(SortSelector), findsOneWidget);
      final selector = tester.widget<SortSelector>(find.byType(SortSelector));
      expect(
        selector.selected,
        SortMode.price,
        reason: 'cheapest landing should derive SortMode.price on cold launch',
      );
    });

    testWidgets('landingScreen=nearest -> SortSelector starts on Distance', (
      tester,
    ) async {
      await _pumpAppWithRouter(
        tester,
        _readyAppOverrides(landing: LandingScreen.nearest),
      );

      expect(find.byType(SortSelector), findsOneWidget);
      final selector = tester.widget<SortSelector>(find.byType(SortSelector));
      expect(selector.selected, SortMode.distance);
    });
  });

  group('ProfileLandingScreenDropdown shows exactly 3 options (no Recherche)', () {
    testWidgets('open menu lists Favoris / Cheapest / Nearest only', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProfileLandingScreenDropdown(
              value: LandingScreen.nearest,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Open the dropdown.
      await tester.tap(find.byType(DropdownButtonFormField<LandingScreen>));
      await tester.pumpAndSettle();

      // The 4-enum minus map = 3 visible options. "Search" / "Recherche"
      // must not appear under any spelling. This is the regression guard
      // for #471.
      expect(find.text('Map'), findsNothing);
      expect(find.text('Carte'), findsNothing);
      expect(find.text('Search'), findsNothing);
      expect(find.text('Recherche'), findsNothing);
      // The three valid options are present.
      expect(find.text('Favorites'), findsAtLeast(1));
      expect(find.text('Cheapest nearby'), findsAtLeast(1));
      expect(find.text('Nearest stations'), findsAtLeast(1));
    });
  });

}
