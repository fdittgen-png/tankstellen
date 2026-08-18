// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/favorite_dismissible.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Stand-in for a keepAlive notifier handle — the generic [T] keeps
/// feature types out of the core widget.
class _FakeFavorites {
  final removed = <String>[];
  final readded = <String>[];
}

void main() {
  group('FavoriteDismissible', () {
    Future<_FakeFavorites> pumpDismissible(WidgetTester tester) async {
      final handle = _FakeFavorites();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FavoriteDismissible<_FakeFavorites>(
              dismissKey: 'fav-x1',
              label: 'Station X',
              latitude: 48.1,
              longitude: 11.5,
              captureHandle: () => handle,
              removeFavorite: (h) async => h.removed.add('x1'),
              undoRemove: (h) => h.readded.add('x1'),
              child: const ListTile(title: Text('Station X card')),
            ),
          ),
        ),
      );
      return handle;
    }

    testWidgets('renders the wrapped child inside a Dismissible',
        (tester) async {
      await pumpDismissible(tester);
      expect(find.byType(Dismissible), findsOneWidget);
      expect(find.text('Station X card'), findsOneWidget);
    });

    testWidgets(
        'swipe left asks for confirmation, removes on confirm, and offers undo',
        (tester) async {
      final handle = await pumpDismissible(tester);
      await tester.drag(find.text('Station X card'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // #3682 — the app-wide destructive-action confirmation dialog.
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(handle.removed, ['x1']);
      // Undo snackbar re-adds via the pre-await captured handle (#3159).
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.tap(find.byType(SnackBarAction));
      await tester.pumpAndSettle();
      expect(handle.readded, ['x1']);
    });

    testWidgets('cancelling the confirmation keeps the favorite',
        (tester) async {
      final handle = await pumpDismissible(tester);
      await tester.drag(find.text('Station X card'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(handle.removed, isEmpty);
      expect(find.text('Station X card'), findsOneWidget);
    });
  });
}
