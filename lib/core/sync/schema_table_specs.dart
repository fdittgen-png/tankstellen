// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The single per-table registry of the TankSync (self-hosted Supabase)
/// schema (2026-08-17 review, extensibility finding 8).
///
/// Before this registry, adding a synced table meant touching FOUR
/// hand-maintained lists that only the #2929 drift-guard test kept in
/// step: `SchemaVerifier.requiredTables` / `optionalTables`, the
/// `tableSql` CREATE-TABLE map, and the matching `ALTER TABLE … ENABLE
/// ROW LEVEL SECURITY` + policy blocks inside one monolithic `rlsSql`
/// string. Each table is now ONE [SyncedTableSpec] record; the verifier
/// lists, the CREATE-TABLE map and the assembled RLS SQL are all DERIVED
/// from [syncedTableSpecs], so a new synced table is a single new record
/// (plus its `supabase/migrations/` twin — that file stays the source of
/// truth, and HARD RULE #5 / the completeness test still apply).
///
/// The derivations are byte-identical to the pre-refactor wizard SQL —
/// pinned by `test/core/sync/schema_sql_golden_test.dart`; assembly
/// order is the list order below, so REORDERING ENTRIES CHANGES THE
/// EMITTED SQL. Data lives in two under-cap part-lists:
/// `schema_table_specs_core.dart` (required) +
/// `schema_table_specs_extended.dart` (optional).
library;

import 'schema_table_specs_core.dart';
import 'schema_table_specs_extended.dart';

export 'schema_table_specs_core.dart';
export 'schema_table_specs_extended.dart';

/// One synced table of the TankSync schema.
///
///  * [name] — the Postgres table name the sync code `.from()`s.
///  * [isRequired] — required tables gate core sync (`SchemaVerifier`
///    flags a missing one as "wizard SQL not run"); optional tables
///    degrade a single feature instead.
///  * [createSql] — the idempotent `CREATE TABLE IF NOT EXISTS` block
///    (plus its indexes), exactly as the wizard emits it.
///  * [rlsPolicySql] — the table's `DROP POLICY IF EXISTS … CREATE
///    POLICY` block (no surrounding blank lines; the assembler joins
///    blocks with one blank line).
typedef SyncedTableSpec = ({
  String name,
  bool isRequired,
  String createSql,
  String rlsPolicySql,
});

/// Every synced table, in wizard-SQL emission order (required core
/// tables first, then the optional feature tables).
const List<SyncedTableSpec> syncedTableSpecs = [
  ...coreTableSpecs,
  ...extendedTableSpecs,
];
