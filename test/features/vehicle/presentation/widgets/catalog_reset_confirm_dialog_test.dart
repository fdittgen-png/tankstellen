// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/catalog_reset_confirm_dialog.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [CatalogResetConfirmDialog] (#3651). Mirrors the
/// [VeResetConfirmDialog] test surface: rendered copy (including the
/// matched catalog row in the body) and the Future payload per return
/// path.
void main() {
  group('CatalogResetConfirmDialog', () {
    testWidgets('renders the title and names the matched catalog row in '
        'the body so the user can verify the reset source', (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Reset from the vehicle database?'), findsOneWidget);
      expect(
        find.textContaining('Peugeot 107 I (2005-2014)'),
        findsOneWidget,
        reason: 'The body must name the matched row — confirming a reset '
            'against the wrong catalog entry would silently corrupt the '
            'profile spec.',
      );
    });

    testWidgets('Cancel resolves false, the reset action resolves true',
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
      expect(await result, false);

      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Reset from vehicle database'),
        ),
      );
      await tester.pumpAndSettle();
      expect(await result, true);
    });

    testWidgets('barrier dismiss resolves null — callers treat it as '
        '"do nothing"', (tester) async {
      late Future<bool?> result;
      await _pumpHost(tester, onShow: (future) => result = future);

      await tester.tap(find.byKey(const Key('open-dialog')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(await result, isNull);
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
                final future = CatalogResetConfirmDialog.show(
                  context,
                  'Peugeot 107 I (2005-2014)',
                );
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
