import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/favorites/presentation/screens/favorites_screen.dart';

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
  });
}
