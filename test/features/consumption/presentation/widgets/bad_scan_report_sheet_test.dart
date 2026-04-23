import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/receipt_parser.dart';
import 'package:tankstellen/features/consumption/data/receipt_scan_service.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/bad_scan_report_sheet.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the i18n of [BadScanReportSheet] (#751 phase 1).
///
/// The sheet used to hard-code seven English literals (title, hint,
/// row labels, table headers, share button). Phase 1 routes every
/// one through [AppLocalizations]; these tests lock that contract
/// by asserting the English ARB text renders on the `en` locale and
/// the German ARB text renders on the `de` locale.
void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) {
    const outcome = ReceiptScanOutcome(
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
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: BadScanReportSheet(
            scan: outcome,
            enteredLiters: 32.5,
            enteredTotalCost: 55.12,
            appVersion: '4.3.0+1',
          ),
        ),
      ),
    );
  }

  testWidgets('renders the English ARB strings on the en locale',
      (tester) async {
    await pumpSheet(tester);
    await tester.pumpAndSettle();

    expect(find.text('Report a scan error'), findsOneWidget);
    expect(
      find.textContaining('share the receipt photo'),
      findsOneWidget,
    );
    expect(find.text('Share report + photo'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    // Table headers
    expect(find.text('Field'), findsOneWidget);
    expect(find.text('Scanned'), findsOneWidget);
    expect(find.text('You typed'), findsOneWidget);
    // Row labels
    expect(find.text('Brand layout'), findsOneWidget);
    expect(find.text('Liters'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Price/L'), findsOneWidget);
    expect(find.text('Station'), findsOneWidget);
    expect(find.text('Fuel'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
  });

  testWidgets('renders the German ARB strings on the de locale',
      (tester) async {
    await pumpSheet(tester, locale: const Locale('de'));
    await tester.pumpAndSettle();

    expect(find.text('Scan-Fehler melden'), findsOneWidget);
    expect(find.text('Bericht + Foto teilen'), findsOneWidget);
    expect(find.text('Feld'), findsOneWidget);
    expect(find.text('Gescannt'), findsOneWidget);
    expect(find.text('Eingegeben'), findsOneWidget);
    expect(find.text('Marken-Layout'), findsOneWidget);
    expect(find.text('Gesamt'), findsOneWidget);
    expect(find.text('Tankstelle'), findsOneWidget);
    expect(find.text('Kraftstoff'), findsOneWidget);
    expect(find.text('Datum'), findsOneWidget);
  });
}
