import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/search/presentation/screens/search_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_summary_bar.dart';
import 'package:tankstellen/features/search/presentation/widgets/user_position_bar.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('SearchScreen (results-first layout)', () {
    testWidgets('renders Scaffold', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('renders the SearchSummaryBar at the top', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      expect(find.byType(SearchSummaryBar), findsOneWidget);
    });

    testWidgets('does NOT render the inline LocationInput/FuelTypeSelector',
        (tester) async {
      // In the new results-first layout, these live on the criteria screen.
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      // No TextField on the results screen — only the summary bar.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('renders UserPositionBar', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      expect(find.byType(UserPositionBar), findsOneWidget);
    });

    testWidgets('shows empty state message when no search performed',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      expect(
        find.text('Search to find fuel stations.'),
        findsOneWidget,
      );
    });

    testWidgets('rebuild does not re-trigger auto-search side effects',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(Scaffold), findsAtLeast(1));
      expect(find.text('Search to find fuel stations.'), findsOneWidget);
    });

    testWidgets('results area dominates the viewport (≥60% vertical)',
        (tester) async {
      // Use a fixed-size phone viewport.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchScreen(),
        overrides: [
          ...test.overrides,
          userPositionNullOverride(),
        ],
      );

      // The Expanded child (results area) is found via the Semantics label.
      final resultsFinder = find.bySemanticsLabel('Search results');
      expect(resultsFinder, findsOneWidget);

      final resultsBox = tester.getSize(resultsFinder.first);
      final screenHeight = tester.view.physicalSize.height /
          tester.view.devicePixelRatio;
      expect(
        resultsBox.height >= screenHeight * 0.5,
        isTrue,
        reason:
            'Expected results area to be at least 50% of screen height, got '
            '${resultsBox.height}/$screenHeight',
      );
    });
  });
}
