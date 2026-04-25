import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/feedback/github_issue_reporter.dart';
import 'package:tankstellen/features/consumption/data/pump_display_parse_result.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_scan_service.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/bad_scan_diff_table.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/bad_scan_form_view.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [BadScanFormView] — the pre-submission view of the
/// [BadScanReportSheet] (title + hint + diff table + Create/Cancel
/// action pair). Refs #561 (zero-coverage backlog).
void main() {
  const receiptOutcome = ReceiptScanOutcome(
    parse: ReceiptParseResult(
      liters: 32.5,
      totalCost: 55.12,
      pricePerLiter: 1.695,
      stationName: 'Shell',
      brandLayout: 'generic',
    ),
    ocrText: 'TOTAL 55,12\n32,5 L\nSP95',
    imagePath: '/tmp/fake.jpg',
  );

  const pumpOutcome = PumpDisplayScanOutcome(
    parse: PumpDisplayParseResult(
      liters: 40.0,
      totalCost: 70.0,
      pricePerLiter: 1.75,
      pumpNumber: 3,
      confidence: 0.9,
    ),
    ocrText: 'Betrag 70.00\nAbgabe 40.00\nPreis/L 1.75',
    imagePath: '/tmp/fake-pump.jpg',
  );

  Future<void> pumpView(
    WidgetTester tester, {
    ScanKind kind = ScanKind.receipt,
    bool submitting = false,
    VoidCallback? onSubmit,
    VoidCallback? onCancel,
    Locale locale = const Locale('en'),
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BadScanFormView(
            kind: kind,
            receiptScan: kind == ScanKind.receipt ? receiptOutcome : null,
            pumpScan: kind == ScanKind.pumpDisplay ? pumpOutcome : null,
            enteredLiters: 32.5,
            enteredTotalCost: 55.20,
            submitting: submitting,
            onSubmit: onSubmit ?? () {},
            onCancel: onCancel ?? () {},
          ),
        ),
      ),
    );
  }

  group('BadScanFormView (receipt kind)', () {
    testWidgets('renders the receipt title in bold', (tester) async {
      await pumpView(tester);
      await tester.pumpAndSettle();

      // English title from app_en.arb.
      final titleFinder = find.text('Report a scan error — Receipt');
      expect(titleFinder, findsOneWidget);
      final title = tester.widget<Text>(titleFinder);
      expect(title.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('renders the hint text', (tester) async {
      await pumpView(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(
          "We'll share the receipt photo and both sets of values so "
          'the next build can learn this layout.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('mounts a BadScanDiffTable', (tester) async {
      await pumpView(tester);
      await tester.pumpAndSettle();

      expect(find.byType(BadScanDiffTable), findsOneWidget);
    });

    testWidgets(
        'shows the bug_report icon and Create-issue label when not submitting',
        (tester) async {
      await pumpView(tester);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Create issue'), findsOneWidget);
    });

    testWidgets(
        'submitting=true → spinner replaces the bug_report icon',
        (tester) async {
      await pumpView(tester, submitting: true);
      // Don't pumpAndSettle — the spinner is an infinite animation.
      await tester.pump();

      expect(find.byIcon(Icons.bug_report_outlined), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Label text remains for screen readers.
      expect(find.text('Create issue'), findsOneWidget);
    });

    testWidgets('tapping Create-issue invokes onSubmit when not submitting',
        (tester) async {
      var calls = 0;
      await pumpView(tester, onSubmit: () => calls++);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Create issue'));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('submitting=true disables the Create-issue button',
        (tester) async {
      var calls = 0;
      await pumpView(tester, submitting: true, onSubmit: () => calls++);
      // Don't pumpAndSettle — the spinner is an infinite animation.
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create issue'),
      );
      expect(button.onPressed, isNull);

      // Tapping a disabled button should not fire the callback.
      await tester.tap(
        find.widgetWithText(FilledButton, 'Create issue'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('tapping Cancel invokes onCancel when not submitting',
        (tester) async {
      var calls = 0;
      await pumpView(tester, onCancel: () => calls++);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('submitting=true disables the Cancel button', (tester) async {
      var calls = 0;
      await pumpView(tester, submitting: true, onCancel: () => calls++);
      // Don't pumpAndSettle — the spinner is an infinite animation.
      await tester.pump();

      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancel'),
      );
      expect(button.onPressed, isNull);

      await tester.tap(
        find.widgetWithText(TextButton, 'Cancel'),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(calls, 0);
    });
  });

  group('BadScanFormView (pump-display kind)', () {
    testWidgets('renders the pump-display title in bold', (tester) async {
      await pumpView(tester, kind: ScanKind.pumpDisplay);
      await tester.pumpAndSettle();

      final titleFinder = find.text('Report a scan error — Pump display');
      expect(titleFinder, findsOneWidget);
      final title = tester.widget<Text>(titleFinder);
      expect(title.style?.fontWeight, FontWeight.bold);
    });
  });
}
