// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// #3682 — taps the shared destructive-action dialog's confirm button.
/// The ONE helper the swipe/delete tests use after triggering a delete,
/// so the tests stay as copy-free as the production dialog.
Future<void> confirmPendingDelete(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final confirm = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byIcon(Icons.delete_outline),
  );
  expect(confirm, findsOneWidget,
      reason: 'the shared delete confirmation (#3682) must be showing');
  await tester.tap(confirm);
  await tester.pumpAndSettle();
}
