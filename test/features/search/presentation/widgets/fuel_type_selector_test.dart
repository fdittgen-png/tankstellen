import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('FuelTypeSelector', () {
    testWidgets('renders fuel type options for Germany', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.all),
        ],
      );

      // Germany should show: E5, E10, Diesel, Electric, All
      expect(find.text('Super E5'), findsOneWidget);
      expect(find.text('Super E10'), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);
      expect(find.text('Electric \u26a1'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('renders fuel type options for France', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.france),
          selectedFuelTypeOverride(FuelType.all),
        ],
      );

      // France has more types: E10, E5, E98, Diesel, E85, LPG, Electric, All
      expect(find.text('Super E10'), findsOneWidget);
      expect(find.text('Super E5'), findsOneWidget);
      expect(find.text('Super 98'), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);
      expect(find.text('E85 / Bio\u00e9thanol'), findsOneWidget);
      expect(find.text('GPL / LPG'), findsOneWidget);
    });

    testWidgets('current selection is highlighted via ChoiceChip', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.diesel),
        ],
      );

      // Find all ChoiceChips
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));

      // Exactly one chip should be selected
      final selectedChips = chips.where((c) => c.selected).toList();
      expect(selectedChips, hasLength(1));

      // The selected chip should be the Diesel one
      final dieselChip = selectedChips.first;
      final label = dieselChip.label as Text;
      expect(label.data, 'Diesel');
    });

    testWidgets('tapping a fuel type chip triggers selection', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.all),
        ],
      );

      // Initially 'All' is selected
      final allChipBefore = tester.widgetList<ChoiceChip>(
        find.byType(ChoiceChip),
      ).firstWhere((c) => (c.label as Text).data == 'All');
      expect(allChipBefore.selected, isTrue);

      // Tap on E10 chip
      await tester.tap(find.text('Super E10'));
      await tester.pumpAndSettle();

      // After tapping, E10 should now be selected
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final e10Chip = chips.firstWhere((c) => (c.label as Text).data == 'Super E10');
      expect(e10Chip.selected, isTrue);
    });

    testWidgets('has correct semantics labels', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const FuelTypeSelector(),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.diesel),
        ],
      );

      // The selected fuel type should have ", selected" in its semantics
      expect(
        find.bySemanticsLabel(RegExp(r'Fuel type Diesel, selected')),
        findsOneWidget,
      );
    });
  });
}
