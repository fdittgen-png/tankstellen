// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/screens/search_criteria_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_summary_bar.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('SearchSummaryBar', () {
    testWidgets('renders fuel type and radius badge (#2131 — inline button removed)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(10),
        ],
      );

      expect(find.text('Super E10'), findsOneWidget);
      expect(find.text('Within 10 km'), findsOneWidget);
    });

    testWidgets('tapping the bar opens SearchCriteriaScreen', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchSummaryBar(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.diesel),
          searchRadiusOverride(5),
          userPositionNullOverride(),
        ],
      );

      expect(find.byType(SearchCriteriaScreen), findsNothing);

      // #2131 — the inline tonal "Search" button is gone; the bar
      // itself stays tappable as a discoverable refine affordance.
      await tester.tap(find.byType(SearchSummaryBar));
      await tester.pumpAndSettle();

      expect(find.byType(SearchCriteriaScreen), findsOneWidget);
    });
  });
}
