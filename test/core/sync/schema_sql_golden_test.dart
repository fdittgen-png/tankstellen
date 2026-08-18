// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_sql.dart';

/// Byte-identity golden for the TankSync wizard SQL (2026-08-17 review,
/// extensibility finding 8 — the SyncedTableSpec refactor's safety net).
///
/// The goldens under `test/core/sync/goldens/` were captured from the
/// PRE-refactor `buildMigrationSql` (the exact text self-hosters paste
/// into their Supabase SQL editor, #2929). The per-table SyncedTableSpec
/// derivation must reproduce them **byte for byte** — assembly-order or
/// whitespace drift in the wizard SQL is a real change to what every
/// self-hoster runs, and must never ride along silently with a refactor.
///
/// When the schema changes ON PURPOSE (new table / policy / RPC — which
/// also bumps [kSupabaseSchemaVersion]), regenerate the goldens from the
/// new intended output and commit them with the schema change, exactly
/// like any golden update.
void main() {
  const goldenDir = 'test/core/sync/goldens';

  String golden(String name) {
    final file = File('$goldenDir/$name');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'missing golden $goldenDir/$name — regenerate it from the '
          'intended buildMigrationSql output and commit it',
    );
    return file.readAsStringSync();
  }

  test('fresh-install wizard SQL (empty schema) is byte-identical to the '
      'golden', () {
    expect(
      buildMigrationSql(const {}),
      golden('migration_sql_empty_schema.golden.sql'),
    );
  });

  test('fully-provisioned wizard SQL (every table present) is '
      'byte-identical to the golden', () {
    expect(
      buildMigrationSql({for (final t in tableSql.keys) t: true}),
      golden('migration_sql_fully_provisioned.golden.sql'),
    );
  });
}
