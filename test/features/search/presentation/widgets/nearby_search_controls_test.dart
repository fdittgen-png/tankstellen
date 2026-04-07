import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/search/presentation/widgets/fuel_type_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/location_input.dart';
import 'package:tankstellen/features/search/presentation/widgets/nearby_search_controls.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('NearbySearchControls', () {
    testWidgets('always renders LocationInput when filters are expanded',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        NearbySearchControls(
          onGpsSearch: () {},
          onZipSearch: (_) {},
          onCitySearch: (_) {},
          filtersExpanded: true,
          onToggleFilters: (_) {},
          isLandscape: false,
        ),
        overrides: test.overrides,
      );

      expect(find.byType(LocationInput), findsOneWidget);
      expect(find.byType(FuelTypeSelector), findsOneWidget);
    });

    testWidgets('always renders LocationInput when filters are collapsed',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        NearbySearchControls(
          onGpsSearch: () {},
          onZipSearch: (_) {},
          onCitySearch: (_) {},
          filtersExpanded: false,
          onToggleFilters: (_) {},
          isLandscape: false,
        ),
        overrides: test.overrides,
      );

      // Search bar stays visible regardless of filter state
      expect(find.byType(LocationInput), findsOneWidget);
    });

    testWidgets('shows collapsed filter summary when filters not expanded',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        NearbySearchControls(
          onGpsSearch: () {},
          onZipSearch: (_) {},
          onCitySearch: (_) {},
          filtersExpanded: false,
          onToggleFilters: (_) {},
          isLandscape: false,
        ),
        overrides: test.overrides,
      );

      // Collapsed filter summary shows tune icon
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('shows search button in portrait when filters expanded',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        NearbySearchControls(
          onGpsSearch: () {},
          onZipSearch: (_) {},
          onCitySearch: (_) {},
          filtersExpanded: true,
          onToggleFilters: (_) {},
          isLandscape: false,
        ),
        overrides: test.overrides,
      );

      expect(find.text('Nearby stations'), findsOneWidget);
    });

    testWidgets('renders radius slider when filters expanded', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        NearbySearchControls(
          onGpsSearch: () {},
          onZipSearch: (_) {},
          onCitySearch: (_) {},
          filtersExpanded: true,
          onToggleFilters: (_) {},
          isLandscape: false,
        ),
        overrides: test.overrides,
      );

      expect(find.byType(Slider), findsOneWidget);
    });
  });
}
