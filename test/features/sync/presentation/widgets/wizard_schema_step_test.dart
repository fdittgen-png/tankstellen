import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/sync/presentation/widgets/wizard_schema_step.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  // Provide all required + optional tables from SchemaVerifier
  final allTablesReady = <String, bool>{
    'users': true,
    'favorites': true,
    'alerts': true,
    'price_snapshots': true,
    'push_tokens': true,
    'sync_settings': true,
    'price_reports': true,
    'itineraries': true,
    'ignored_stations': true,
    'station_ratings': true,
    'database_owner': true,
  };

  final allTablesMissing = <String, bool>{
    'users': false,
    'favorites': false,
    'alerts': false,
    'price_snapshots': false,
    'push_tokens': false,
    'sync_settings': false,
    'price_reports': false,
    'itineraries': false,
    'ignored_stations': false,
    'station_ratings': false,
    'database_owner': false,
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
