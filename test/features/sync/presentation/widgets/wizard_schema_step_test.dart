// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_verifier.dart';
import 'package:tankstellen/features/sync/presentation/widgets/wizard_schema_step.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  // Drive the widget straight off SchemaVerifier's lists so the maps can't
  // drift as the synced-table set grows (#2929).
  final allTablesReady = {
    for (final t in SchemaVerifier.allTables) t: true,
  };

  final allTablesMissing = {
    for (final t in SchemaVerifier.allTables) t: false,
  };

  group('WizardSchemaStep', () {
    testWidgets('shows "Database ready!" when all required tables present', (tester) async {
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: WizardSchemaStep(
            schemaStatus: allTablesReady,
            migrationSql: null,
            onRecheck: () {},
            onDone: () {},
          ),
        ),
      );

      expect(find.text('Database ready!'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('shows "Database needs setup" when tables missing', (tester) async {
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: WizardSchemaStep(
            schemaStatus: allTablesMissing,
            migrationSql: 'CREATE TABLE users...',
            onRecheck: () {},
            onDone: () {},
          ),
        ),
      );

      expect(find.text('Database needs setup'), findsOneWidget);
      expect(find.text('Copy SQL to clipboard'), findsOneWidget);
      expect(find.text('Re-check schema'), findsOneWidget);
    });

    testWidgets('outdated schema gates Done + shows the re-run SQL block', (tester) async {
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: WizardSchemaStep(
            schemaStatus: allTablesReady,
            migrationSql: 'CREATE TABLE users...',
            schemaOutdated: true,
            onRecheck: () {},
            onDone: () {},
          ),
        ),
      );

      // Tables all present, but the schema version is stale → the wizard
      // must not let the user finish; it surfaces the re-run SQL controls.
      expect(find.text('Done'), findsNothing);
      expect(find.text('Copy SQL to clipboard'), findsOneWidget);
      expect(find.text('Re-check schema'), findsOneWidget);
    });

    testWidgets('calls onDone when Done tapped', (tester) async {
      var done = false;
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: WizardSchemaStep(
            schemaStatus: allTablesReady,
            migrationSql: null,
            onRecheck: () {},
            onDone: () => done = true,
          ),
        ),
      );

      await tester.scrollUntilVisible(find.text('Done'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      expect(done, isTrue);
    });
  });
}
