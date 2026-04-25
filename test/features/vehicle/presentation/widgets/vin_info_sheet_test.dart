import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vin_info_sheet.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for [VinInfoSheet] (#895 / #561 zero-coverage backlog).
///
/// The sheet is a stateless informational modal — no providers are
/// involved. Tests focus on:
///   * the four labeled section headers all render,
///   * the layout chrome (`SafeArea`, scroll view, height cap),
///   * the static `show()` launcher actually routes the sheet onto
///     the navigator stack with the expected modal flags.
void main() {
  group('VinInfoSheet', () {
    testWidgets('renders the title row with the info icon', (tester) async {
      await pumpApp(tester, const VinInfoSheet());

      // Title row uses the `vinInfoTooltip` localization key.
      expect(find.text('What is a VIN?'), findsWidgets);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('renders all four section headers', (tester) async {
      await pumpApp(tester, const VinInfoSheet());

      // The "What is a VIN?" string is shared with the title row, so
      // we expect at least two occurrences (title + section header).
      expect(find.text('What is a VIN?'), findsNWidgets(2));
      expect(find.text('Why we ask'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Where to find it'), findsOneWidget);
    });

    testWidgets('renders the dismiss button labeled "Got it"',
        (tester) async {
      await pumpApp(tester, const VinInfoSheet());

      expect(find.widgetWithText(FilledButton, 'Got it'), findsOneWidget);
    });

    testWidgets('wraps content in a SafeArea (top: false)', (tester) async {
      await pumpApp(tester, const VinInfoSheet());

      final safeArea = tester.widget<SafeArea>(find.byType(SafeArea).first);
      expect(safeArea.top, isFalse,
          reason: 'top:false avoids double-padding when the sheet '
              'opens above a transparent system status bar.');
    });

    testWidgets('caps maxHeight at 85% of the screen height',
        (tester) async {
      // Force a known viewport so the cap is deterministic.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpApp(tester, const VinInfoSheet());

      // The sheet's own ConstrainedBox is the only one with a finite,
      // non-zero maxHeight near 85% of the viewport. Other
      // ConstrainedBox widgets in the Material/Scaffold ancestor chain
      // are unbounded.
      final boxes = tester
          .widgetList<ConstrainedBox>(find.byType(ConstrainedBox))
          .where((b) => b.constraints.maxHeight.isFinite)
          .toList();
      expect(boxes, isNotEmpty,
          reason: 'VinInfoSheet must wrap its body in a finite-height '
              'ConstrainedBox so long copy scrolls instead of '
              'spilling past the top of the screen.');
      expect(boxes.first.constraints.maxHeight, closeTo(800 * 0.85, 0.01),
          reason: 'The sheet caps height at 85% of the viewport.');
    });

    testWidgets('long body uses a SingleChildScrollView', (tester) async {
      await pumpApp(tester, const VinInfoSheet());

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets(
      'VinInfoSheet.show(context) opens the modal with a drag handle',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => VinInfoSheet.show(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Sheet not visible before tap.
        expect(find.byType(VinInfoSheet), findsNothing);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Sheet visible after tap.
        expect(find.byType(VinInfoSheet), findsOneWidget);

        // showDragHandle:true draws a drag handle inside the modal
        // bottom sheet container.
        final sheetFinder = find.byType(BottomSheet);
        expect(sheetFinder, findsOneWidget);
        final sheet = tester.widget<BottomSheet>(sheetFinder);
        expect(sheet.showDragHandle, isTrue,
            reason: 'show() must request a drag handle so users can '
                'pull the sheet down.');
        expect(sheet.enableDrag, isTrue);
      },
    );
  });
}
