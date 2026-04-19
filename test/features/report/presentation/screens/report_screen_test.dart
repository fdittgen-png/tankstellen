import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/error_reporting/error_report_payload.dart';
import 'package:tankstellen/core/error_reporting/error_reporter.dart';
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
        'banner shown; price/status radios disabled but name/address '
        '(GitHub-routed, #508) stay enabled',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      await pumpApp(
        tester,
        const ReportScreen(stationId: 'test-station-1'),
        overrides: test.overrides,
      );

      // Banner is present — price/status reports still need a backend
      // in DE, so when neither Tankerkoenig nor TankSync is configured
      // we surface the banner so the user knows to configure one.
      expect(
        find.byKey(const ValueKey('report-no-backend-banner')),
        findsOneWidget,
      );

      // Walk every radio we can find as we scroll: GitHub-routed types
      // (wrongName, wrongAddress) must be enabled even without a
      // backend; everything else must be disabled.
      //
      // `true`  → enabled (onChanged != null)
      // `false` → disabled (onChanged == null)
      //
      // Scroll through every radio, snapshotting each type's enabled
      // flag. With the #710 RadioGroup migration the radios all live
      // inside a single RadioGroup widget — ListView sees it as one
      // child and builds the whole subtree at once — but the drag
      // pattern still works because the RadioListTiles are always
      // present in the widget tree from the first frame.
      //
      // `true`  → enabled (tappable), `false` → disabled.
      final seen = <ReportType, bool>{};
      final scrollable = find.byType(Scrollable).first;
      for (var i = 0;
          i < 20 && seen.length < ReportType.values.length;
          i++) {
        for (final radio in tester.widgetList<RadioListTile<ReportType>>(
            find.byType(RadioListTile<ReportType>))) {
          seen.putIfAbsent(radio.value, () => radio.enabled ?? true);
        }
        if (seen.length == ReportType.values.length) break;
        await tester.drag(scrollable, const Offset(0, -200));
        await tester.pump();
      }

      // Scroll the submit button into view explicitly — after the
      // RadioGroup refactor the radios occupy a single ListView slot
      // and the button's position relative to the fold changed, so
      // raw drag-until-seen isn't a reliable anchor any more.
      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      for (final type in ReportType.values) {
        expect(seen.containsKey(type), isTrue,
            reason: '$type must be rendered in DE even without a backend');
        if (type.routesToGitHub) {
          expect(seen[type], isTrue,
              reason:
                  '$type is GitHub-routed and must stay enabled (#508)');
        } else {
          expect(seen[type], isFalse,
              reason:
                  '$type needs a backend and must be disabled here');
        }
      }
    });

    testWidgets(
        'FR without TankSync → no banner, only wrongName + wrongAddress '
        'visible, both enabled (#508)',
        (tester) async {
      final test = standardTestOverrides(country: Countries.france);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      await pumpApp(
        tester,
        const ReportScreen(stationId: 'test-station-1'),
        overrides: test.overrides,
      );
      await tester.pumpAndSettle();

      // Outside DE, only GitHub-routed types are visible — nothing
      // needs configuring, so the banner must NOT appear.
      expect(
        find.byKey(const ValueKey('report-no-backend-banner')),
        findsNothing,
      );

      // Exactly two radios, both GitHub-routed, both enabled.
      final radios = tester
          .widgetList<RadioListTile<ReportType>>(
              find.byType(RadioListTile<ReportType>))
          .toList();
      expect(radios, hasLength(2));
      expect(
        radios.map((r) => r.value).toList(),
        equals([ReportType.wrongName, ReportType.wrongAddress]),
      );
      for (final r in radios) {
        expect(r.enabled ?? true, isTrue,
            reason: 'GitHub-routed radios must be enabled regardless of '
                'backend availability');
      }
    });

    testWidgets(
        'FR with no sync — submit button enables when wrongAddress is '
        'selected and text is entered, even without any backend (#508)',
        (tester) async {
      final test = standardTestOverrides(country: Countries.france);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      await pumpApp(
        tester,
        const ReportScreen(stationId: 'test-station-1'),
        overrides: test.overrides,
      );
      await tester.pumpAndSettle();

      // Select wrongAddress
      await tester.tap(find.text('Adresse incorrecte'));
      await tester.pumpAndSettle();

      // Button still disabled without text.
      var button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('report-correction-text-field')),
        '42 rue de la République, 34310 Montagnac',
      );
      await tester.pumpAndSettle();

      button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull,
          reason: 'GitHub-routed reports must work without a backend');
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
        expect(radio.enabled ?? true, isTrue,
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

  group('ReportScreen country-gated visibility (#508)', () {
    testWidgets(
        'DE — all 10 report types are rendered', (tester) async {
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

      final seen = <ReportType>{};
      final scrollable = find.byType(Scrollable).first;
      for (var i = 0;
          i < 20 && seen.length < ReportType.values.length;
          i++) {
        for (final radio in tester.widgetList<RadioListTile<ReportType>>(
            find.byType(RadioListTile<ReportType>))) {
          seen.add(radio.value);
        }
        await tester.drag(scrollable, const Offset(0, -200));
        await tester.pump();
      }
      expect(seen, equals(ReportType.values.toSet()));
    });

    testWidgets('FR — only wrongName + wrongAddress are rendered',
        (tester) async {
      final test = standardTestOverrides(country: Countries.france);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      await pumpApp(
        tester,
        const ReportScreen(stationId: 'test-station-1'),
        overrides: test.overrides,
      );
      await tester.pumpAndSettle();

      final values = tester
          .widgetList<RadioListTile<ReportType>>(
              find.byType(RadioListTile<ReportType>))
          .map((r) => r.value)
          .toList();
      expect(
        values,
        equals(const [ReportType.wrongName, ReportType.wrongAddress]),
      );
    });

    test('visibleForCountry returns all types for DE, last 2 for FR/GB', () {
      expect(
        ReportType.visibleForCountry('DE'),
        equals(ReportType.values),
      );
      expect(
        ReportType.visibleForCountry('FR'),
        equals(const [ReportType.wrongName, ReportType.wrongAddress]),
      );
      expect(
        ReportType.visibleForCountry('GB'),
        equals(const [ReportType.wrongName, ReportType.wrongAddress]),
      );
    });

    test('routesToGitHub covers exactly wrongName + wrongAddress', () {
      for (final t in ReportType.values) {
        expect(t.routesToGitHub, t == ReportType.wrongName || t == ReportType.wrongAddress,
            reason: '$t routesToGitHub is wrong');
      }
    });
  });

  group('ReportScreen GitHub routing (#508)', () {
    testWidgets(
        'wrongAddress on FR hands off to ErrorReporter with populated payload',
        (tester) async {
      ErrorReportPayload? captured;
      final reporter = ErrorReporter(launcher: (uri) async => true);

      final test = standardTestOverrides(country: Countries.france);
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getApiKey()).thenReturn(null);

      // A wrapped reporter that records the payload on reportError and
      // then delegates (with consent skipped) to the real one.
      final recording = _RecordingReporter((p) => captured = p);

      await pumpApp(
        tester,
        ReportScreen(
          stationId: 'station-42',
          reporter: recording,
        ),
        overrides: test.overrides,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Adresse incorrecte'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('report-correction-text-field')),
        '42 rue de la République',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(captured, isNotNull, reason: 'reporter must be invoked');
      expect(captured!.countryCode, 'FR');
      expect(captured!.errorType, 'WrongMetadataReport');
      expect(captured!.errorMessage, contains('station-42'));
      expect(captured!.errorMessage, contains('42 rue de la République'));
      expect(captured!.sourceLabel, isNotNull);

      // Silence the unused-field lint on `reporter`.
      expect(reporter, isA<ErrorReporter>());
    });

    testWidgets(
        'wrongName on DE still routes to GitHub (not to Tankerkoenig)',
        (tester) async {
      ErrorReportPayload? captured;
      final recording = _RecordingReporter((p) => captured = p);

      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(true);
      when(() => test.mockStorage.getApiKey())
          .thenReturn('11111111-2222-3333-4444-555555555555');

      await pumpApp(
        tester,
        ReportScreen(
          stationId: 'station-99',
          reporter: recording,
        ),
        overrides: test.overrides,
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Nom de la station incorrect'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Nom de la station incorrect'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('report-correction-text-field')),
        'Shell Castelnau',
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.countryCode, 'DE');
      expect(captured!.errorType, 'WrongMetadataReport');
      expect(captured!.errorMessage, contains('station-99'));
      expect(captured!.errorMessage, contains('Shell Castelnau'));
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

/// Test double that extends [ErrorReporter] and short-circuits
/// `reportError` to record the payload — skipping both the consent
/// dialog and the real browser launcher.
class _RecordingReporter extends ErrorReporter {
  _RecordingReporter(this.onReport)
      : super(launcher: _noopLauncher);

  final void Function(ErrorReportPayload) onReport;

  static Future<bool> _noopLauncher(Uri _) async => true;

  @override
  Future<bool> reportError(
    BuildContext context,
    ErrorReportPayload payload, {
    bool requireConsent = true,
  }) async {
    onReport(payload);
    return true;
  }
}
