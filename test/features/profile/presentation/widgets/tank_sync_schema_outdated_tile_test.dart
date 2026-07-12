// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_drift_notice.dart';
import 'package:tankstellen/features/profile/presentation/widgets/tank_sync_schema_outdated_tile.dart';

import '../../../../helpers/pump_app.dart';

/// #3560 — the ambient schema-outdated warning tile: zero-height until a
/// sync run hits schema drift (or the verifier flags the recorded
/// version), then an amber row pointing at the sync wizard.
void main() {
  setUp(SchemaDriftNotice.instance.reset);
  tearDown(SchemaDriftNotice.instance.reset);

  testWidgets('renders nothing while no drift signal fired', (tester) async {
    await pumpApp(tester, const TankSyncSchemaOutdatedTile());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tankSyncSchemaOutdatedTile')), findsNothing);
  });

  testWidgets('a drift noticed THIS session surfaces the warning live',
      (tester) async {
    await pumpApp(tester, const TankSyncSchemaOutdatedTile());
    await tester.pumpAndSettle();

    SchemaDriftNotice.instance.note('favorites');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tankSyncSchemaOutdatedTile')), findsOneWidget);
    expect(find.text('Cloud database needs an update'), findsOneWidget);
  });
}
