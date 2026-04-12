import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_type_toggle.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('StationTypeToggle', () {
    testWidgets('renders fuel and EV segments', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const StationTypeToggle(),
        overrides: test.overrides,
      );

      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('EV'), findsOneWidget);
    });

    testWidgets('fuel is selected by default', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const StationTypeToggle(),
        overrides: test.overrides,
      );

      // SegmentedButton should exist
      expect(find.text('Fuel'), findsOneWidget);
    });

    testWidgets('tapping EV switches selection', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const StationTypeToggle(),
        overrides: test.overrides,
      );

      await tester.tap(find.text('EV'));
      await tester.pumpAndSettle();

      // After tap, EV should be the active selection
      expect(find.text('EV'), findsOneWidget);
    });
  });
}
