// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/confirm_delete_dialog.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// #3682 — the ONE destructive-action confirmation. Pins the contract
/// every delete surface in the app relies on: true only on the explicit
/// destructive tap; cancel/barrier/back are false; defaults localize;
/// overrides + the per-surface test key ride through.
void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    String? title,
    String? message,
    String? confirmLabel,
    Key? confirmKey,
    required void Function(Future<bool>) onShow,
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
                key: const Key('open'),
                onPressed: () => onShow(confirmDestructiveAction(
                  context,
                  title: title,
                  message: message,
                  confirmLabel: confirmLabel,
                  confirmKey: confirmKey,
                )),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  testWidgets('defaults: localized title/body, warning icon, Delete label',
      (tester) async {
    late Future<bool> result;
    await pumpHost(tester, onShow: (f) => result = f);

    expect(find.text('Delete?'), findsOneWidget);
    expect(find.text('Do you really want to delete this?'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });

  testWidgets('cancel and barrier both return FALSE — a destructive action '
      'never happens by accident', (tester) async {
    final results = <Future<bool>>[];
    await pumpHost(tester, onShow: results.add);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await results.single, isFalse);

    // Re-open, dismiss via the barrier: the null result maps to false.
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(await results.last, isFalse);
  });

  testWidgets('overrides + per-surface confirmKey ride through',
      (tester) async {
    late Future<bool> result;
    await pumpHost(
      tester,
      title: 'Delete this vehicle?',
      message: 'Golf and its history will be gone.',
      confirmLabel: 'Delete vehicle',
      confirmKey: const Key('surface_confirm'),
      onShow: (f) => result = f,
    );
    expect(find.text('Delete this vehicle?'), findsOneWidget);
    expect(find.text('Golf and its history will be gone.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('surface_confirm')));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });
}
