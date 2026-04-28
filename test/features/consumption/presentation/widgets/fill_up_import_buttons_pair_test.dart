import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_import_buttons_pair.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  Widget buildPair({
    bool scanningReceipt = false,
    bool scanningPump = false,
    VoidCallback? onScanReceipt,
    VoidCallback? onScanPumpDisplay,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: FillUpImportButtonsPair(
          scanningReceipt: scanningReceipt,
          scanningPump: scanningPump,
          onScanReceipt: onScanReceipt ?? () {},
          onScanPumpDisplay: onScanPumpDisplay ?? () {},
        ),
      ),
    );
  }

  group('FillUpImportButtonsPair', () {
    testWidgets('renders both keyed buttons', (tester) async {
      await tester.pumpWidget(buildPair());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('import_receipt_button')), findsOneWidget);
      expect(find.byKey(const Key('import_pump_button')), findsOneWidget);
    });

    testWidgets(
        'default state renders both default icons (receipt + gas station)',
        (tester) async {
      await tester.pumpWidget(buildPair());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.document_scanner_outlined), findsOneWidget);
      expect(find.byIcon(Icons.local_gas_station_outlined), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('default state shows localized "Receipt" and "Pump display"',
        (tester) async {
      await tester.pumpWidget(buildPair());
      await tester.pumpAndSettle();

      expect(find.text('Receipt'), findsOneWidget);
      expect(find.text('Pump display'), findsOneWidget);
    });

    testWidgets('scanningReceipt: true disables the receipt button',
        (tester) async {
      await tester.pumpWidget(buildPair(scanningReceipt: true));
      // CircularProgressIndicator animates forever; use pump() not
      // pumpAndSettle().
      await tester.pump();

      final receipt = tester.widget<OutlinedButton>(
        find.byKey(const Key('import_receipt_button')),
      );
      expect(receipt.onPressed, isNull);
    });

    testWidgets(
        'scanningReceipt: true replaces the receipt icon with a progress indicator',
        (tester) async {
      await tester.pumpWidget(buildPair(scanningReceipt: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.document_scanner_outlined), findsNothing);
    });

    testWidgets(
        'scanningReceipt: true does NOT affect the pump button — pump remains '
        'enabled with its icon', (tester) async {
      await tester.pumpWidget(buildPair(scanningReceipt: true));
      await tester.pump();

      final pump = tester.widget<OutlinedButton>(
        find.byKey(const Key('import_pump_button')),
      );
      expect(pump.onPressed, isNotNull);
      expect(find.byIcon(Icons.local_gas_station_outlined), findsOneWidget);
    });

    testWidgets('scanningPump: true disables the pump button', (tester) async {
      await tester.pumpWidget(buildPair(scanningPump: true));
      await tester.pump();

      final pump = tester.widget<OutlinedButton>(
        find.byKey(const Key('import_pump_button')),
      );
      expect(pump.onPressed, isNull);
    });

    testWidgets(
        'scanningPump: true replaces the pump icon with the only progress '
        'indicator', (tester) async {
      await tester.pumpWidget(buildPair(scanningPump: true));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.local_gas_station_outlined), findsNothing);
      // The receipt side should still show its icon.
      expect(find.byIcon(Icons.document_scanner_outlined), findsOneWidget);
    });

    testWidgets('tapping the enabled receipt button calls onScanReceipt',
        (tester) async {
      var receiptTaps = 0;
      var pumpTaps = 0;
      await tester.pumpWidget(
        buildPair(
          onScanReceipt: () => receiptTaps++,
          onScanPumpDisplay: () => pumpTaps++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('import_receipt_button')));
      await tester.pump();

      expect(receiptTaps, 1);
      expect(pumpTaps, 0);
    });

    testWidgets('tapping the enabled pump button calls onScanPumpDisplay',
        (tester) async {
      var receiptTaps = 0;
      var pumpTaps = 0;
      await tester.pumpWidget(
        buildPair(
          onScanReceipt: () => receiptTaps++,
          onScanPumpDisplay: () => pumpTaps++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('import_pump_button')));
      await tester.pump();

      expect(pumpTaps, 1);
      expect(receiptTaps, 0);
    });

    testWidgets(
        'tapping the disabled receipt button (scanningReceipt: true) does NOT '
        'call onScanReceipt', (tester) async {
      var receiptTaps = 0;
      await tester.pumpWidget(
        buildPair(
          scanningReceipt: true,
          onScanReceipt: () => receiptTaps++,
        ),
      );
      await tester.pump();

      // Sanity-check disabled state.
      final receipt = tester.widget<OutlinedButton>(
        find.byKey(const Key('import_receipt_button')),
      );
      expect(receipt.onPressed, isNull);

      await tester.tap(
        find.byKey(const Key('import_receipt_button')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(receiptTaps, 0);
    });

    testWidgets(
        'both scanning flags true → both buttons disabled and two progress '
        'indicators visible', (tester) async {
      await tester.pumpWidget(
        buildPair(scanningReceipt: true, scanningPump: true),
      );
      await tester.pump();

      final receipt = tester.widget<OutlinedButton>(
        find.byKey(const Key('import_receipt_button')),
      );
      final pump = tester.widget<OutlinedButton>(
        find.byKey(const Key('import_pump_button')),
      );
      expect(receipt.onPressed, isNull);
      expect(pump.onPressed, isNull);

      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
      expect(find.byIcon(Icons.document_scanner_outlined), findsNothing);
      expect(find.byIcon(Icons.local_gas_station_outlined), findsNothing);
    });
  });
}
