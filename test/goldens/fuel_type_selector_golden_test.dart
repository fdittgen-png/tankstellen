import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';

import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

void main() {
  group('FuelTypeSelector golden tests', () {
    testWidgets('Germany fuel types', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const RepaintBoundary(
          child: FuelTypeSelector(),
        ),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.all),
        ],
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('fuel_type_selector_germany.png'),
      );
    });

    testWidgets('France fuel types', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const RepaintBoundary(
          child: FuelTypeSelector(),
        ),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.france),
          selectedFuelTypeOverride(FuelType.all),
        ],
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('fuel_type_selector_france.png'),
      );
    });

    testWidgets('Germany with diesel selected', (tester) async {
      final storage = mockHiveStorageOverride();
      when(() => storage.mock.getActiveProfileId()).thenReturn(null);
      when(() => storage.mock.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const RepaintBoundary(
          child: FuelTypeSelector(),
        ),
        overrides: [
          storage.override,
          activeCountryOverride(Countries.germany),
          selectedFuelTypeOverride(FuelType.diesel),
        ],
      );

      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('fuel_type_selector_diesel_selected.png'),
      );
    });
  });
}
