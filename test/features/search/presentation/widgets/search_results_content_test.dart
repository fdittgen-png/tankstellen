import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/widgets/shimmer_placeholder.dart';
import 'package:tankstellen/features/profile/domain/entities/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/nearest_shortcut_card.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_content.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_list.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('SearchResultsContent', () {
    Future<void> noopRetry() async {}

    testWidgets('shows shimmer while the search state is loading',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      // Bypass pumpApp here — the shimmer animation never settles.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...test.overrides,
            searchStateProvider.overrideWith(() => _LoadingSearchState()),
          ].cast(),
          child: MaterialApp(
            localizationsDelegates:
                AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SearchResultsContent(onGpsRetry: noopRetry),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(ShimmerStationList), findsOneWidget);
    });

    testWidgets(
        'shows the nearest-shortcut card and start-search hint when the '
        'data branch is empty', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        SearchResultsContent(onGpsRetry: noopRetry),
        overrides: [
          ...test.overrides,
          searchStateProvider.overrideWith(() => _EmptySearchState()),
        ].cast(),
      );

      expect(find.byType(NearestShortcutCard), findsOneWidget);
      expect(find.text('Search to find fuel stations.'), findsOneWidget);
    });

    testWidgets(
        '#494 — hides NearestShortcutCard when landing screen is NOT nearest',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        SearchResultsContent(onGpsRetry: noopRetry),
        overrides: [
          ...test.overrides,
          searchStateProvider.overrideWith(() => _EmptySearchState()),
          activeProfileProvider.overrideWith(
            () => _FakeActiveProfile(LandingScreen.cheapest),
          ),
        ].cast(),
      );

      expect(find.byType(NearestShortcutCard), findsNothing,
          reason: 'Shortcut must not push "nearest" at a user who chose '
              'cheapest as their landing screen');
      // Empty-state hint text still visible.
      expect(find.text('Search to find fuel stations.'), findsOneWidget);
    });

    testWidgets(
        '#494 — shows NearestShortcutCard when landing screen IS nearest',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        SearchResultsContent(onGpsRetry: noopRetry),
        overrides: [
          ...test.overrides,
          searchStateProvider.overrideWith(() => _EmptySearchState()),
          activeProfileProvider.overrideWith(
            () => _FakeActiveProfile(LandingScreen.nearest),
          ),
        ].cast(),
      );

      expect(find.byType(NearestShortcutCard), findsOneWidget);
    });

    testWidgets('shows the SearchResultsList when stations are loaded',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
      when(() => test.mockStorage.getRatings())
          .thenReturn(const <String, int>{});

      await pumpApp(
        tester,
        SearchResultsContent(onGpsRetry: noopRetry),
        overrides: [
          ...test.overrides,
          searchStateProvider.overrideWith(
            () => _LoadedSearchState([testStation]),
          ),
        ].cast(),
      );

      expect(find.byType(SearchResultsList), findsOneWidget);
    });
  });
}

class _LoadingSearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() => const AsyncValue.loading();
}

class _EmptySearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() => AsyncValue.data(
        ServiceResult(
          data: const [],
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
        ),
      );
}

class _LoadedSearchState extends SearchState {
  _LoadedSearchState(this._stations);
  final List<Station> _stations;

  @override
  AsyncValue<ServiceResult<List<SearchResultItem>>> build() => AsyncValue.data(
        ServiceResult(
          data: _stations.map((s) => FuelStationResult(s) as SearchResultItem).toList(),
          source: ServiceSource.cache,
          fetchedAt: DateTime.now(),
        ),
      );
}

class _FakeActiveProfile extends ActiveProfile {
  _FakeActiveProfile(this._landingScreen);
  final LandingScreen _landingScreen;

  @override
  UserProfile? build() => UserProfile(
        id: 'test',
        name: 'Test',
        landingScreen: _landingScreen,
      );
}
