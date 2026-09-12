// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:tankstellen/core/sync/schema_sql.dart';

/// Regenerates the wizard-SQL goldens `test/core/sync/schema_sql_golden_test.dart`
/// compares against — run after an INTENDED schema change (new table,
/// policy or RPC, with the matching `kSupabaseSchemaVersion` bump):
///
///     dart run tool/regen_schema_goldens.dart
///
/// Commit the two files with the schema change, like any golden update.
void main() {
  const dir = 'test/core/sync/goldens';
  File('$dir/migration_sql_empty_schema.golden.sql')
      .writeAsStringSync(buildMigrationSql(const {}));
  File('$dir/migration_sql_fully_provisioned.golden.sql').writeAsStringSync(
      buildMigrationSql({for (final t in tableSql.keys) t: true}));
  stdout.writeln('regenerated 2 goldens (schema v$kSupabaseSchemaVersion)');
}
