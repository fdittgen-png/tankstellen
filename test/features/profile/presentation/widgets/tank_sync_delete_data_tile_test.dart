// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/synced_data_deletion.dart';
import 'package:tankstellen/features/profile/presentation/widgets/tank_sync_delete_data_tile.dart';

import '../../../../helpers/pump_app.dart';

/// #3453 — the "delete my synced data" flow: tile → category picker →
/// destructive confirmation whose copy documents the server-side-only
/// decision (local data on this device is kept).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the tile with title + subtitle', (tester) async {
    await pumpApp(tester, const TankSyncDeleteDataTile());

    expect(find.byKey(const Key('tankSyncDeleteDataTile')), findsOneWidget);
    expect(find.text('Delete synced data'), findsOneWidget);
    expect(
      find.textContaining('trips, vehicles or fill-ups'),
      findsOneWidget,
    );
  });

  testWidgets('tap opens the category picker with all four categories',
      (tester) async {
    await pumpApp(tester, const TankSyncDeleteDataTile());

    await tester.tap(find.byKey(const Key('tankSyncDeleteDataTile')));
    await tester.pumpAndSettle();

    for (final category in SyncedDataCategory.values) {
      expect(
        find.byKey(Key('syncDeleteDataOption_${category.name}')),
        findsOneWidget,
        reason: 'category "${category.name}" must be offered',
      );
    }
  });

  testWidgets('picking a category shows the confirmation with the '
      'server-side-only copy; cancel closes without action', (tester) async {
    await pumpApp(tester, const TankSyncDeleteDataTile());

    await tester.tap(find.byKey(const Key('tankSyncDeleteDataTile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('syncDeleteDataOption_trips')));
    await tester.pumpAndSettle();

    // The documented decision: server-side only, local data stays.
    expect(
      find.textContaining('Data stored locally on this device is kept'),
      findsOneWidget,
    );
    expect(find.text('Delete from server'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete from server'), findsNothing);
  });

  testWidgets('confirming while disconnected surfaces the failure snackbar '
      '(no live session in tests → delete returns false)', (tester) async {
    await pumpApp(tester, const TankSyncDeleteDataTile());

    await tester.tap(find.byKey(const Key('tankSyncDeleteDataTile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('syncDeleteDataOption_trips')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete from server'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Deleting synced data failed'), findsOneWidget);
  });
}
