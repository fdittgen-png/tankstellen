// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/pump_gain_reset_confirm_dialog.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [PumpGainResetConfirmDialog] (#3901).
///
/// Covers the return paths of the destructive-action confirmation
/// dialog: render the title/body, `false` on Cancel, `true` on Reset,
/// `false` on barrier dismiss (#3682 shared dialog). The widget is a
/// thin wrapper around the shared dialog so the tests focus on the
/// surface the caller sees: the rendered text and the Future payload.
void main() {
  group('PumpGainResetConfirmDialog', () {
    testWidgets('show() opens an AlertDialog with the title rendered',
        (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Reset pump calibration?'), findsOneWidget);
    });

    testWidgets('renders the explanatory body copy', (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('full-to-full'),
        findsOneWidget,
        reason: 'Body must explain that the next full-to-full tank window '
            're-learns the gain so the user understands what is lost.',
      );
    });

    testWidgets('renders both action buttons with the expected labels',
        (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();

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
          matching: find.text('Reset pump calibration'),
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

    testWidgets('tapping Reset pump calibration resolves with `true`',
        (tester) async {
      late Future<bool?> result;
      await _pumpHost(tester, onShow: (future) => result = future);

      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Reset pump calibration'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(await result, true);
    });

    testWidgets('barrier dismiss resolves the future with `false`',
        (tester) async {
      late Future<bool?> result;
      await _pumpHost(tester, onShow: (future) => result = future);

      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(await result, isFalse);
    });
  });
}

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
                final future = PumpGainResetConfirmDialog.show(context);
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
