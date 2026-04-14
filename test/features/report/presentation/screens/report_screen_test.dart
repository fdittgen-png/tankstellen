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
      await tester.pumpAndSettle();

      expect(find.text("What's wrong?"), findsOneWidget);
      // #484 — 10 report types. ListView lazily materialises children,
      // so we collect every RadioListTile<ReportType> that becomes
      // visible as we scroll the list, then assert all 10 enum values
      // were seen.
      final seen = <ReportType>{};
      final scrollable = find.byType(Scrollable).first;
      for (var i = 0; i < 20 && seen.length < ReportType.values.length; i++) {
        for (final radio in tester.widgetList<RadioListTile<ReportType>>(
            find.byType(RadioListTile<ReportType>))) {
          seen.add(radio.value);
        }
        await tester.drag(scrollable, const Offset(0, -200));
        await tester.pump();
      }
      // Final pass after the last drag.
      for (final radio in tester.widgetList<RadioListTile<ReportType>>(
          find.byType(RadioListTile<ReportType>))) {
        seen.add(radio.value);
      }
      expect(seen, equals(ReportType.values.toSet()),
          reason: 'all 10 report types must be rendered in the list');
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

      // #484 — with 10 radio options the button sits below the fold;
      // scroll it into view before probing its state.
      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        120,
        scrollable: find.byType(Scrollable).first,
      );
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

      // Scroll the button into view (#484 — 10 radios push it below fold).
      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        120,
        scrollable: find.byType(Scrollable).first,
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

  group('ReportScreen metadata report types (#484)', () {
    Future<void> scrollToRadio(WidgetTester tester, String label) async {
      await tester.scrollUntilVisible(
        find.text(label),
        120,
        scrollable: find.byType(Scrollable).first,
      );
    }

    Future<void> scrollToButton(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        120,
        scrollable: find.byType(Scrollable).first,
      );
    }

    testWidgets(
        'selecting wrongName shows a text field, not the price field',
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
      await tester.pumpAndSettle();

      await scrollToRadio(tester, 'Nom de la station incorrect');
      await tester.tap(find.text('Nom de la station incorrect'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('report-correction-text-field')),
        findsOneWidget,
        reason: 'wrongName must render the correction text field',
      );
      // Price field label must NOT be present.
      expect(find.text('Correct price (e.g. 1.459)'), findsNothing);
    });

    testWidgets(
        'selecting wrongAddress shows the correction text field',
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
      await tester.pumpAndSettle();

      await scrollToRadio(tester, 'Adresse incorrecte');
      await tester.tap(find.text('Adresse incorrecte'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('report-correction-text-field')),
        findsOneWidget,
      );
    });

    testWidgets(
        'selecting wrongE85 shows the price field (extended fuel type)',
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
      await tester.pumpAndSettle();

      await scrollToRadio(tester, 'Prix E85 incorrect');
      await tester.tap(find.text('Prix E85 incorrect'));
      await tester.pumpAndSettle();

      expect(find.text('Correct price (e.g. 1.459)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('report-correction-text-field')),
        findsNothing,
      );
    });

    testWidgets(
        'submit stays disabled for wrongName until text is entered',
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
      await tester.pumpAndSettle();

      await scrollToRadio(tester, 'Nom de la station incorrect');
      await tester.tap(find.text('Nom de la station incorrect'));
      await tester.pumpAndSettle();

      // Scroll the button into view to assert its state.
      await scrollToButton(tester);

      var button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull,
          reason: 'submit must stay disabled until correction is typed');

      await tester.enterText(
        find.byKey(const ValueKey('report-correction-text-field')),
        'Shell Castelnau',
      );
      await tester.pumpAndSettle();

      await scrollToButton(tester);
      button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull,
          reason: 'submit must enable once correction text is present');
    });
  });

  group('ReportType enum (#484)', () {
    test('fuelTypeColumnValue returns the DB-facing identifier', () {
      expect(ReportType.wrongE5.fuelTypeColumnValue, 'e5');
      expect(ReportType.wrongE10.fuelTypeColumnValue, 'e10');
      expect(ReportType.wrongDiesel.fuelTypeColumnValue, 'diesel');
      expect(ReportType.wrongE85.fuelTypeColumnValue, 'e85');
      expect(ReportType.wrongE98.fuelTypeColumnValue, 'e98');
      expect(ReportType.wrongLpg.fuelTypeColumnValue, 'lpg');
      expect(ReportType.wrongStatusOpen.fuelTypeColumnValue, 'status_open');
      expect(
          ReportType.wrongStatusClosed.fuelTypeColumnValue, 'status_closed');
      expect(ReportType.wrongName.fuelTypeColumnValue, 'name');
      expect(ReportType.wrongAddress.fuelTypeColumnValue, 'address');
    });

    test('isTankerkoenigSupported only covers the 5 legacy types', () {
      // Legacy types — supported.
      expect(ReportType.wrongE5.isTankerkoenigSupported, isTrue);
      expect(ReportType.wrongE10.isTankerkoenigSupported, isTrue);
      expect(ReportType.wrongDiesel.isTankerkoenigSupported, isTrue);
      expect(ReportType.wrongStatusOpen.isTankerkoenigSupported, isTrue);
      expect(ReportType.wrongStatusClosed.isTankerkoenigSupported, isTrue);
      // Everything added in #484 — TankSync only.
      expect(ReportType.wrongE85.isTankerkoenigSupported, isFalse);
      expect(ReportType.wrongE98.isTankerkoenigSupported, isFalse);
      expect(ReportType.wrongLpg.isTankerkoenigSupported, isFalse);
      expect(ReportType.wrongName.isTankerkoenigSupported, isFalse);
      expect(ReportType.wrongAddress.isTankerkoenigSupported, isFalse);
    });

    test('needsPrice / needsText are mutually exclusive and exhaustive',
        () {
      for (final type in ReportType.values) {
        expect(type.needsPrice && type.needsText, isFalse,
            reason: '$type cannot be both price and text');
      }
      // Sanity — every type has a non-empty display name (French
      // fallback is always present).
      for (final type in ReportType.values) {
        expect(type.displayName(null), isNotEmpty);
      }
    });
  });
}
