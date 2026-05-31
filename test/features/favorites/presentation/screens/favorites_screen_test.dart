// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:tankstellen/features/favorites/providers/favorites_provider.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../mocks/mocks.dart' show MockStorageRepository;

void main() {
  // #2155 — the AlertsTab now mounts immediately in the wide-layout
  // branch (default 800×600 test surface lands there); the previous
  // tab layout already pre-built it via TabBarView, but the wide-row
  // path surfaces an unmocked getAlerts() faster. Stub it suite-wide.
  void stubAlerts(MockStorageRepository m) {
    when(() => m.getAlerts()).thenReturn(const <Map<String, dynamic>>[]);
  }

  group('FavoritesScreen', () {
    testWidgets('renders Scaffold', (tester) async {
      final test = standardTestOverrides(favoriteIds: []);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      stubAlerts(test.mockStorage);

      await pumpApp(
        tester,
        const FavoritesScreen(),
        overrides: test.overrides,
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('renders app bar with Favorites title', (tester) async {
      final test = standardTestOverrides(favoriteIds: []);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      stubAlerts(test.mockStorage);

      await pumpApp(
        tester,
        const FavoritesScreen(),
        overrides: test.overrides,
      );

      // Title comes from l10n?.favorites ?? 'Favorites'
      expect(find.text('Favorites'), findsAtLeast(1));
    });

    testWidgets('shows empty state message when no favorites', (tester) async {
      final test = standardTestOverrides(favoriteIds: []);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      stubAlerts(test.mockStorage);

      await pumpApp(
        tester,
        const FavoritesScreen(),
        overrides: test.overrides,
      );

      // Empty state shows star_outline icon and "No favorites yet" text.
      // #2155 — the default 800×600 test surface now lands in the wide
      // layout (no tab switcher), so the only star_outline is the
      // empty-state body icon. The portrait-tab test below pins the
      // tab-row star case explicitly.
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
      expect(find.text('No favorites yet'), findsOneWidget);
    });

    testWidgets('shows hint text in empty state', (tester) async {
      final test = standardTestOverrides(favoriteIds: []);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      stubAlerts(test.mockStorage);

      await pumpApp(
        tester,
        const FavoritesScreen(),
        overrides: test.overrides,
      );

      expect(
        find.text('Tap the star on a station to save it as a favorite.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'shows tabs for Favorites and Price Alerts (portrait phone)',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: []);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      stubAlerts(test.mockStorage);

      await pumpApp(
        tester,
        // #2155 — wrap in a portrait-phone-shaped MediaQuery so the
        // tab layout fires (>=600dp OR landscape → side-by-side).
        const MediaQuery(
          data: MediaQueryData(size: Size(360, 800)),
          child: FavoritesScreen(),
        ),
        overrides: test.overrides,
      );

      // TabSwitcher should have both tabs
      expect(find.text('Favorites'), findsAtLeast(2)); // Tab + AppBar
      expect(find.text('Price Alerts'), findsOneWidget);
    });

    testWidgets(
        '#2155 landscape phone renders FavoritesTab + AlertsTab '
        'side-by-side (no TabSwitcher)', (tester) async {
      final test = standardTestOverrides(favoriteIds: []);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      stubAlerts(test.mockStorage);

      await pumpApp(
        tester,
        const MediaQuery(
          // Landscape phone: 800 x 360 (wide, short).
          data: MediaQueryData(size: Size(800, 360)),
          child: FavoritesScreen(),
        ),
        overrides: test.overrides,
      );

      // No tab switcher chip-row in landscape — "Price Alerts" appears
      // only as the pane title row in AlertsTab, not as a tab label.
      // The empty-state bodies of both panes should be visible at once.
      expect(find.byType(VerticalDivider), findsOneWidget);
      expect(find.text('No favorites yet'), findsOneWidget);
    });

    testWidgets(
        '#2155 wide portrait (tablet) also gets the side-by-side layout',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: []);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      stubAlerts(test.mockStorage);

      await pumpApp(
        tester,
        const MediaQuery(
          // Portrait tablet: 800 x 1200 (wide and tall).
          data: MediaQueryData(size: Size(800, 1200)),
          child: FavoritesScreen(),
        ),
        overrides: test.overrides,
      );

      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets(
        '#2530 expanded width picks up the shared 2:3 master/detail ratio',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: []);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      stubAlerts(test.mockStorage);

      await pumpApp(
        tester,
        const MediaQuery(
          // Expanded width (≥840dp): tablet landscape / desktop.
          data: MediaQueryData(size: Size(1024, 768)),
          child: FavoritesScreen(),
        ),
        overrides: test.overrides,
      );

      expect(find.byType(VerticalDivider), findsOneWidget);
      // FavoritesTab (master) flex 2, AlertsTab (detail) flex 3.
      final flexes = tester
          .widgetList<Expanded>(find.byType(Expanded))
          .map((e) => e.flex)
          .toList();
      expect(flexes, containsAllInOrder(<int>[2, 3]));
    });

    testWidgets('renders station cards when favorites have data',
        (tester) async {
      final test = standardTestOverrides(
          favoriteIds: [testStation.id]);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      stubAlerts(test.mockStorage);

      final result = ServiceResult(
        data: [testStation],
        source: ServiceSource.cache,
        fetchedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...test.overrides,
            favoriteStationsProvider.overrideWith(
              () => _FixedFavoriteStations(result),
            ),
          ].cast(),
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: Scaffold(body: FavoritesScreen()),
          ),
        ),
      );
      // Use pump with duration instead of pumpAndSettle to avoid animation timeout
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(StationCard), findsOneWidget);
    });
  });
}

class _FixedFavoriteStations extends FavoriteStations {
  final ServiceResult<List<Station>> _result;
  _FixedFavoriteStations(this._result);

  @override
  AsyncValue<ServiceResult<List<Station>>> build() =>
      AsyncValue.data(_result);

  @override
  Future<void> loadAndRefresh() async {
    // No-op: keep the fixed result
  }
}
