import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/screens/search_criteria_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_summary_bar.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('SearchSummaryBar', () {
    testWidgets('renders fuel type, quantity, radius badge and button',
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
      expect(find.text('Search'), findsOneWidget);
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

      // Tap the inkwell via the bar surface.
      await tester.tap(find.byType(SearchSummaryBar));
      await tester.pumpAndSettle();

      expect(find.byType(SearchCriteriaScreen), findsOneWidget);
    });

    testWidgets('tapping the Search button also opens the criteria screen',
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
          userPositionNullOverride(),
        ],
      );

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(find.byType(SearchCriteriaScreen), findsOneWidget);
    });
  });
}
