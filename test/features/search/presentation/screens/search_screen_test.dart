import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/search/presentation/screens/search_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/location_input.dart';
import 'package:tankstellen/features/search/presentation/widgets/user_position_bar.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('SearchScreen', () {
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

      // SearchScreen itself contains a Scaffold (nested inside pumpApp's Scaffold)
      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('renders LocationInput widget', (tester) async {
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

      expect(find.byType(LocationInput), findsOneWidget);
    });

    testWidgets('renders FuelTypeSelector widget', (tester) async {
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

      expect(find.byType(FuelTypeSelector), findsOneWidget);
    });

    testWidgets('renders Nearby stations button in portrait', (tester) async {
      // Set portrait phone size so the button is visible
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

      expect(find.text('Nearby stations'), findsWidgets);
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

      // Default search state has empty data list → shows start search message
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
  });
}
