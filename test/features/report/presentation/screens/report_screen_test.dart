import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/report/presentation/screens/report_screen.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('ReportScreen', () {
    testWidgets('renders Scaffold with the retitled "Signaler un problème"',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      await pumpApp(
        tester,
        const ReportScreen(stationId: 'test-station-1'),
        overrides: test.overrides,
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      // #484 — was "Report price" (misleading because status reports
      // are not about prices). Retitled to the generic "Signaler un
      // problème" that covers the whole scope.
      expect(find.text('Signaler un problème'), findsOneWidget);
    });

    testWidgets('renders all report type radio options', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

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
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      await pumpApp(
        tester,
        const ReportScreen(stationId: 'test-station-1'),
        overrides: test.overrides,
      );

      // FilledButton should exist but be disabled (no type selected
      // AND no backend configured — either reason is sufficient)
      expect(find.text('Send report'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });

  group('ReportScreen country gating (regression #484)', () {
    testWidgets(
        'DE without Tankerkoenig key and without TankSync → no-backend '
        'banner shown, submit button disabled, radios disabled',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      await pumpApp(
        tester,
        const ReportScreen(stationId: 'test-station-1'),
        overrides: test.overrides,
      );

      // Banner is present.
      expect(
        find.byKey(const ValueKey('report-no-backend-banner')),
        findsOneWidget,
      );

      // Submit button is disabled.
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      // Every radio option has a null onChanged (disabled).
      for (final radio in tester
          .widgetList<RadioListTile<ReportType>>(
              find.byType(RadioListTile<ReportType>))) {
        expect(radio.onChanged, isNull,
            reason:
                'radios must be disabled when no backend is available');
      }
    });

    testWidgets(
        'FR without TankSync → no-backend banner shown (Tankerkoenig '
        'path is DE-only, so non-DE users MUST have TankSync)',
        (tester) async {
      final test = standardTestOverrides(country: Countries.france);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      await pumpApp(
        tester,
        const ReportScreen(stationId: 'test-station-1'),
        overrides: test.overrides,
      );

      expect(
        find.byKey(const ValueKey('report-no-backend-banner')),
        findsOneWidget,
      );
    });

    testWidgets(
        'FR with TankSync key but no Tankerkoenig key still falls into the '
        'no-backend case when the sync provider reports as disconnected '
        '(standardTestOverrides uses _DisabledSyncState by default)',
        (tester) async {
      final test = standardTestOverrides(country: Countries.france);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      await pumpApp(
        tester,
        const ReportScreen(stationId: 'test-station-1'),
        overrides: test.overrides,
      );

      // The default sync state in the test helper is _DisabledSyncState
      // (userId is null), so TankSync is effectively not connected.
      // This mirrors the real-world scenario where French users without
      // TankSync configured previously got a silent failure.
      expect(
        find.byKey(const ValueKey('report-no-backend-banner')),
        findsOneWidget,
      );
    });

    testWidgets(
        'DE WITH Tankerkoenig API key → banner hidden, radios enabled',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(true);
      when(() => test.mockStorage.getApiKey())
          .thenReturn('11111111-2222-3333-4444-555555555555');

      await pumpApp(
        tester,
        const ReportScreen(stationId: 'test-station-1'),
        overrides: test.overrides,
      );

      expect(
        find.byKey(const ValueKey('report-no-backend-banner')),
        findsNothing,
        reason: 'DE+key must NOT show the no-backend banner',
      );

      for (final radio in tester
          .widgetList<RadioListTile<ReportType>>(
              find.byType(RadioListTile<ReportType>))) {
        expect(radio.onChanged, isNotNull,
            reason: 'radios must be enabled when at least one backend is '
                'available');
      }
    });
  });
}
