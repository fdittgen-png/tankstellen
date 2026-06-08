// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/widgets/shimmer_placeholder.dart';
import 'package:tankstellen/features/search/domain/entities/search_result_item.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_content.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_list.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';
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
        '#2743 — empty state shows the start-search hint and NO longer '
        'renders the redundant "Stations les plus proches" CTA card',
        (tester) async {
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

      // The empty-state hint remains; the central search FAB + Fuel
      // Station Radar button (owned by the shell) now carry the CTA.
      expect(find.text('Search to find fuel stations.'), findsOneWidget);
      // #2743 — the removed CTA card is gone (title + subtitle absent).
      expect(find.text('Nearest stations'), findsNothing);
      expect(
        find.text('Find the closest stations using your current location'),
        findsNothing,
      );
      expect(find.byIcon(Icons.chevron_right), findsNothing);
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

    testWidgets(
        '#3058 — an empty radar result shows a clear empty-state (not a blank '
        'SearchResultsList) so the user knows the scan finished', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        SearchResultsContent(onGpsRetry: noopRetry),
        overrides: [
          ...test.overrides,
          radarSearchProvider.overrideWith(() => _EmptyRadarSearch()),
        ].cast(),
      );

      // The radar owns the panel and found nothing → the dedicated empty-state
      // (no-results message + radar icon + Try-again), NOT a blank list.
      expect(find.text('No stations found.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byIcon(Icons.radar), findsOneWidget);
      expect(find.byType(SearchResultsList), findsNothing);
    });
  });
}

/// Radar active + zero stations — drives the #3058 empty-state branch.
class _EmptyRadarSearch extends RadarSearch {
  @override
  RadarSearchState build() => const RadarSearchState(
        active: true,
        stations: AsyncData<List<Station>>(<Station>[]),
      );

  @override
  Future<void> runRadar() async {/* no-op so a Try-again tap is inert */}
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
