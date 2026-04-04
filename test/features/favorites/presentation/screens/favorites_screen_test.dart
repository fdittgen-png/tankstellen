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

void main() {
  group('FavoritesScreen', () {
    testWidgets('renders Scaffold', (tester) async {
      final test = standardTestOverrides(favoriteIds: []);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

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

      await pumpApp(
        tester,
        const FavoritesScreen(),
        overrides: test.overrides,
      );

      // Empty state shows star_border icon and "No favorites yet" text
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
      expect(find.text('No favorites yet'), findsOneWidget);
    });

    testWidgets('shows hint text in empty state', (tester) async {
      final test = standardTestOverrides(favoriteIds: []);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

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

    testWidgets('shows tabs for Favorites and Price Alerts',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: []);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const FavoritesScreen(),
        overrides: test.overrides,
      );

      // TabBar should have both tabs
      expect(find.text('Favorites'), findsAtLeast(2)); // Tab + AppBar
      expect(find.text('Price Alerts'), findsOneWidget);
    });

    testWidgets('renders station cards when favorites have data',
        (tester) async {
      final test = standardTestOverrides(
          favoriteIds: [testStation.id]);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

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
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const Scaffold(body: FavoritesScreen()),
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
