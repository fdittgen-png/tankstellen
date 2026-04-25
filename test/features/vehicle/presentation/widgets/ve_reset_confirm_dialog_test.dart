import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/ve_reset_confirm_dialog.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [VeResetConfirmDialog] (#815).
///
/// Covers the four return paths of the destructive-action confirmation
/// dialog: render the title/body, return `false` on Cancel, return
/// `true` on Reset, and return `null` on barrier dismiss. The widget
/// is otherwise a thin wrapper around `showDialog` so the tests focus
/// on the surface the caller sees: the rendered text and the Future
/// payload.
void main() {
  group('VeResetConfirmDialog', () {
    testWidgets('show() opens an AlertDialog with the title rendered',
        (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Reset calibration?'), findsOneWidget);
    });

    testWidgets('renders the explanatory body copy', (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('default value (0.85)'),
        findsOneWidget,
        reason:
            'Body must explain that confirming restores the default '
            'volumetric efficiency so the user understands what is lost.',
      );
    });

    testWidgets('renders both action buttons with the expected labels',
        (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();

      // Both actions are TextButtons inside the AlertDialog.
      final actions = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      );
      expect(actions, findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancel'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Reset calibration'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping Cancel resolves the future with `false`',
        (tester) async {
      late Future<bool?> result;
      await _pumpHost(tester, onShow: (future) => result = future);

      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancel'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(await result, false);
    });

    testWidgets('tapping Reset calibration resolves the future with `true`',
        (tester) async {
      late Future<bool?> result;
      await _pumpHost(tester, onShow: (future) => result = future);

      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Reset calibration'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(await result, true);
    });

    testWidgets('barrier dismiss resolves the future with `null`',
        (tester) async {
      late Future<bool?> result;
      await _pumpHost(tester, onShow: (future) => result = future);

      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap the modal barrier (top-left corner is well outside the
      // centered AlertDialog) to dismiss without picking either action.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(await result, isNull);
    });
  });
}

/// Pumps a small host scaffold with a button that opens the dialog.
///
/// The optional [onShow] callback receives the Future returned by
/// [VeResetConfirmDialog.show] so individual tests can await it and
/// assert the resolved value.
Future<void> _pumpHost(
  WidgetTester tester, {
  void Function(Future<bool?> future)? onShow,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              key: const Key('open-dialog'),
              onPressed: () {
                final future = VeResetConfirmDialog.show(context);
                onShow?.call(future);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
