import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_save_actions.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required VoidCallback onSave,
    VoidCallback? onReportBadScan,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FillUpSaveActions(
            onSave: onSave,
            onReportBadScan: onReportBadScan,
          ),
        ),
      ),
    );
  }

  testWidgets('renders only the Save button when onReportBadScan is null',
      (tester) async {
    await pump(tester, onSave: () {});
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);
    expect(find.text('Report scan error'), findsNothing);
    expect(find.byIcon(Icons.flag_outlined), findsNothing);
  });

  testWidgets('renders both buttons when onReportBadScan is supplied',
      (tester) async {
    await pump(tester, onSave: () {}, onReportBadScan: () {});
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Report scan error'), findsOneWidget);
    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
  });

  testWidgets('Save tap fires onSave', (tester) async {
    var saved = false;
    await pump(tester, onSave: () => saved = true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    expect(saved, isTrue);
  });

  testWidgets(
      'Report-scan-error tap fires onReportBadScan (regression guard — '
      'this affordance only exists after a scan)', (tester) async {
    var reported = false;
    await pump(
      tester,
      onSave: () {},
      onReportBadScan: () => reported = true,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report scan error'));
    expect(reported, isTrue);
  });
}
