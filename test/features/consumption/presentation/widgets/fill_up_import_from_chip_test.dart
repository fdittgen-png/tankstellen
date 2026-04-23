import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_import_from_chip.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for the restyled "Import from…" chip on the
/// Add-Fill-up form (#751 phase 2).
void main() {
  group('FillUpImportFromChip (#751 phase 2)', () {
    testWidgets('renders the single chip with the localized label',
        (tester) async {
      await pumpApp(
        tester,
        FillUpImportFromChip(
          onScanReceipt: () {},
          onScanPump: () {},
          onReadObd: () {},
        ),
      );

      expect(find.text('Import from…'), findsOneWidget);
      expect(find.byType(ActionChip), findsOneWidget);
    });

    testWidgets(
        'tapping the chip opens the bottom sheet with all three options',
        (tester) async {
      await pumpApp(
        tester,
        FillUpImportFromChip(
          onScanReceipt: () {},
          onScanPump: () {},
          onReadObd: () {},
        ),
      );

      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();

      // Sheet title + all three option titles.
      expect(find.text('Import fill-up data'), findsOneWidget);
      expect(find.text('Receipt'), findsOneWidget);
      expect(find.text('Pump display'), findsOneWidget);
      expect(find.text('OBD-II adapter'), findsOneWidget);
    });

    testWidgets('selecting the receipt option dismisses the sheet '
        'and fires the receipt callback', (tester) async {
      var receiptCalls = 0;
      var pumpCalls = 0;
      var obdCalls = 0;
      await pumpApp(
        tester,
        FillUpImportFromChip(
          onScanReceipt: () => receiptCalls++,
          onScanPump: () => pumpCalls++,
          onReadObd: () => obdCalls++,
        ),
      );

      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('import_receipt_tile')));
      await tester.pumpAndSettle();

      expect(receiptCalls, 1);
      expect(pumpCalls, 0);
      expect(obdCalls, 0);
      expect(find.text('Import fill-up data'), findsNothing,
          reason: 'Sheet should close after picking an option.');
    });

    testWidgets('selecting pump / OBD options fires the correct callbacks',
        (tester) async {
      var receiptCalls = 0;
      var pumpCalls = 0;
      var obdCalls = 0;
      await pumpApp(
        tester,
        FillUpImportFromChip(
          onScanReceipt: () => receiptCalls++,
          onScanPump: () => pumpCalls++,
          onReadObd: () => obdCalls++,
        ),
      );

      // pump
      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import_pump_tile')));
      await tester.pumpAndSettle();

      // obd
      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('import_obd_tile')));
      await tester.pumpAndSettle();

      expect(pumpCalls, 1);
      expect(obdCalls, 1);
      expect(receiptCalls, 0);
    });

    testWidgets('busy=true disables the chip tap', (tester) async {
      var receiptCalls = 0;
      // Don't use pumpApp here — the busy CircularProgressIndicator
      // animates forever and `pumpAndSettle` in the helper would
      // time out. A bare `pumpWidget` + `pump` is enough to render
      // one frame.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [],
          home: Scaffold(
            body: FillUpImportFromChip(
              busy: true,
              onScanReceipt: () => receiptCalls++,
              onScanPump: () {},
              onReadObd: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Tapping a disabled chip should not open the sheet.
      await tester.tap(find.byType(ActionChip), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Import fill-up data'), findsNothing);
      expect(receiptCalls, 0);
    });

    testWidgets('sheet options and chip meet the Android tap-target '
        'guideline (#566 — 48dp minimum)', (tester) async {
      await pumpApp(
        tester,
        FillUpImportFromChip(
          onScanReceipt: () {},
          onScanPump: () {},
          onReadObd: () {},
        ),
      );

      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

      await tester.tap(find.byType(ActionChip));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });
}
