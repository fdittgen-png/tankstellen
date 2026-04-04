import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/report/presentation/screens/report_screen.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('ReportScreen', () {
    testWidgets('renders Scaffold with Report price title', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const ReportScreen(stationId: 'test-station-1'),
        overrides: test.overrides,
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      expect(find.text('Report price'), findsOneWidget);
    });

    testWidgets('renders all report type radio options', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const ReportScreen(stationId: 'test-station-1'),
        overrides: test.overrides,
      );

      // All 5 report types should be available as radio buttons
      expect(find.byType(RadioListTile<ReportType>), findsNWidgets(5));
      expect(find.text("What's wrong?"), findsOneWidget);
    });

    testWidgets('renders send button in disabled state initially',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);

      await pumpApp(
        tester,
        const ReportScreen(stationId: 'test-station-1'),
        overrides: test.overrides,
      );

      // FilledButton should exist but be disabled (no type selected)
      expect(find.text('Send report'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });
}
