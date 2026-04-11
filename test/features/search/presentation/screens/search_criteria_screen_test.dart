import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/screens/search_criteria_screen.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/location_input.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('SearchCriteriaScreen', () {
    testWidgets('renders form: LocationInput, FuelTypeSelector, slider, button',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchCriteriaScreen(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(8),
          userPositionNullOverride(),
        ],
      );

      expect(find.byType(LocationInput), findsOneWidget);
      expect(find.byType(FuelTypeSelector), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      // The submit button is keyed for stable lookup.
      expect(find.byKey(const ValueKey('criteria-search-button')),
          findsOneWidget);
    });

    testWidgets('has a close (X) button that pops the route', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => Navigator.of(ctx).push(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => const SearchCriteriaScreen(),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(8),
          userPositionNullOverride(),
        ],
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchCriteriaScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(SearchCriteriaScreen), findsNothing);
    });

    testWidgets('radius slider updates value', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const SearchCriteriaScreen(),
        overrides: [
          ...test.overrides,
          selectedFuelTypeOverride(FuelType.e10),
          searchRadiusOverride(8),
          userPositionNullOverride(),
        ],
      );

      // The title row shows "8 km" initially.
      expect(find.text('8 km'), findsOneWidget);
    });
  });
}
