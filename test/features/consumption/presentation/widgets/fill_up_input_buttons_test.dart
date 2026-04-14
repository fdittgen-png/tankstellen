import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_input_buttons.dart';

void main() {
  group('FillUpInputButtons', () {
    Future<void> pumpButtons(
      WidgetTester tester, {
      required bool scanning,
      required bool obdReading,
      VoidCallback? onScanReceipt,
      VoidCallback? onReadObd,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FillUpInputButtons(
              scanning: scanning,
              obdReading: obdReading,
              onScanReceipt: onScanReceipt ?? () {},
              onReadObd: onReadObd ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('renders both buttons in their idle state', (tester) async {
      await pumpButtons(tester, scanning: false, obdReading: false);
      expect(find.text('Scan receipt'), findsOneWidget);
      expect(find.text('OBD-II'), findsOneWidget);
      expect(find.byIcon(Icons.document_scanner), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows a spinner on the scan button while scanning',
        (tester) async {
      await pumpButtons(tester, scanning: true, obdReading: false);
      expect(find.byIcon(Icons.document_scanner), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows a spinner on the OBD button while reading',
        (tester) async {
      await pumpButtons(tester, scanning: false, obdReading: true);
      expect(find.byIcon(Icons.bluetooth), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables the scan button while scanning', (tester) async {
      var pressed = false;
      await pumpButtons(
        tester,
        scanning: true,
        obdReading: false,
        onScanReceipt: () => pressed = true,
      );
      // Disabled buttons don't fire onPressed.
      await tester.tap(find.text('Scan receipt'));
      await tester.pump();
      expect(pressed, isFalse);
    });

    testWidgets('disables the OBD button while reading', (tester) async {
      var pressed = false;
      await pumpButtons(
        tester,
        scanning: false,
        obdReading: true,
        onReadObd: () => pressed = true,
      );
      await tester.tap(find.text('OBD-II'));
      await tester.pump();
      expect(pressed, isFalse);
    });

    testWidgets('forwards onScanReceipt when idle', (tester) async {
      var pressed = false;
      await pumpButtons(
        tester,
        scanning: false,
        obdReading: false,
        onScanReceipt: () => pressed = true,
      );
      await tester.tap(find.text('Scan receipt'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('forwards onReadObd when idle', (tester) async {
      var pressed = false;
      await pumpButtons(
        tester,
        scanning: false,
        obdReading: false,
        onReadObd: () => pressed = true,
      );
      await tester.tap(find.text('OBD-II'));
      await tester.pump();
      expect(pressed, isTrue);
    });
  });
}
