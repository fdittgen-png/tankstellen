// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The complete TankSync (self-hosted Supabase) schema, expressed as the
/// idempotent SQL a self-hoster pastes into their Supabase SQL Editor.
///
/// This file is the wizard's single source of truth and must stay a
/// **superset** of every table the sync code (`lib/core/sync/*.dart`)
/// `.from()`s — see `schema_verifier.dart` + the completeness drift-guard
/// test (`test/core/sync/schema_verifier_completeness_test.dart`).
///
/// It mirrors `supabase/migrations/*.sql`; when a migration adds a synced
/// table, RLS policy or RPC, the matching block here must be updated so the
/// wizard SQL keeps creating a working schema. Every statement is
/// idempotent (`CREATE TABLE IF NOT EXISTS`, `DROP POLICY IF EXISTS … CREATE
/// POLICY`, `CREATE OR REPLACE FUNCTION`) so a self-hoster can re-run it
/// safely after a schema bump.
library;

import 'schema_sql_fleet.dart';
import 'schema_sql_fleet_expenses.dart';
import 'schema_sql_fleet_metrics.dart';
import 'schema_sql_owner.dart';
import 'schema_sql_policies.dart';
import 'schema_table_specs.dart';

/// Bumped whenever the wizard SQL below changes in a way an existing
/// self-hoster must re-apply (a new table, RLS policy or RPC). The wizard
/// SQL records this into `public.tanksync_meta`; the verifier reads it back
/// and warns when a self-hoster's recorded version is older — turning what
/// used to be silent per-table breakage into a clear "re-run the setup SQL"
/// signal. See `SchemaVerifier.checkSchemaVersion`.
/// v4 (#3125): `deletions.device_id` + `deletions.app_version` forensic
/// columns (which install deleted a record, on which build).
/// v5 (#3452): `favorites.kind` (fuel | ev — EV favorites join the sync)
/// + `favorites.data` (JSONB station payload, so a favorite pulled on a
/// second device renders name/coords immediately).
/// v6 (#3712): `delete_user()` RPC — Play's account-deletion requirement
/// expects "Delete account" to remove the auth identity itself, not only
/// the data rows.
/// v7 (#3726): `content_reports` table — Play's UGC policy requires an
/// in-app REPORT mechanism before UGC can be declared in the IARC rating;
/// each report row names the reporter and the reported content
/// (`target_kind` / `target_id`) for the self-host operator to review.
/// v8 (#3747): the owner-protection block (`database_owner` +
/// first-signin bootstrap + delete restrictions, with `search_path`
/// pinned on its SECURITY DEFINER functions) ships in the wizard SQL
/// for the first time, so self-hosts get the same posture as the
/// maintainer's project. Also v8 (#3747): `share_trip_with_email()`
/// replaces the `resolve_share_recipient` email→UUID oracle — the
/// resolve+insert moves server-side, only success/failure crosses the
/// wire, and authenticated clients lose EXECUTE on the old resolver.
/// v11 (#4060): `share_trip_with_email_v2()` returns a TEXT outcome so the
/// client can tell "no such recipient" from "this trip is not on the server
/// yet" — v1 stays for clients in the field.
/// v12 (#4062): `wait_time_pings` reaches the wizard SQL — the client read
/// and deleted it through UserDataSync's table maps, invisible to the
/// literal `.from()` gate, so a self-host never got the table.
/// v13 (#4212, ADR 0025): fleet tenancy — `fleet_organizations`,
/// `fleet_members`, `fleet_vehicles`, `vehicle_assignments`,
/// `fleet_policies` (SELECT-only policies through the `is_fleet_member`
/// / `fleet_role` oracles), the four `fleet_*` write RPCs, and the two
/// user-linked fleet tables joining `erase_my_data()`.
/// v14 (#4215, ADR 0025): the expense workflow — `fleet_expenses` and
/// `fleet_documents` (USER-owned: own-row `FOR ALL` plus a manager
/// SELECT restricted to `status <> 'draft'`, so a draft never leaves
/// the employee's scope), the server-only `fleet_audit_events` log,
/// the `fleet_review_expense` / `fleet_log_document_access` RPCs, the
/// private `fleet-documents` Storage bucket with its two object
/// policies, and an `erase_my_data()` that deletes the stored receipt
/// BYTES as well as the rows that name them.
/// v15 (#4216, ADR 0025 D5.3/D5.4): the manager dashboard's read path —
/// `fleet_period_metrics(p_org, p_from, p_to)`, a SECURITY DEFINER
/// aggregate over `fleet_expenses` that re-checks the caller's role,
/// audits every call and suppresses per-vehicle rows below the org's
/// `aggregationMinSamples`, plus `fleet_log_export()` for the same
/// trail on an export. No new table: an RPC alone still bumps the
/// version, because a self-host that never re-runs the SQL has no
/// function to call and the dashboard fails with nothing to say.
const int kSupabaseSchemaVersion = 15;

/// The metadata table that records the applied schema version. Readable by
/// anyone (it carries no user data — only the schema version the verifier
/// probes); writes happen via the SQL editor / service_role, so the read-only
/// RLS policy keeps it from being an RLS-enabled-but-policy-less table.
const String _metaSql = '''
CREATE TABLE IF NOT EXISTS public.tanksync_meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.tanksync_meta ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tanksync_meta_read ON public.tanksync_meta;
CREATE POLICY tanksync_meta_read ON public.tanksync_meta
  FOR SELECT USING (true);
INSERT INTO public.tanksync_meta (key, value, updated_at)
  VALUES ('schema_version', '$kSupabaseSchemaVersion', now())
  ON CONFLICT (key)
  DO UPDATE SET value = EXCLUDED.value, updated_at = now();
''';

/// CREATE TABLE blocks keyed by table name, derived from
/// [syncedTableSpecs] (the single per-table registry — extensibility
/// finding 8). Every table the sync code `.from()`s must appear there
/// (the completeness test enforces this).
final Map<String, String> tableSql = {
  for (final spec in syncedTableSpecs) spec.name: spec.createSql,
};

/// Idempotent column adds for tables that may pre-exist with an older
/// shape. [buildMigrationSql] SKIPS the `CREATE TABLE` block of any table
/// the verifier already found, so a column added to an existing table
/// would never reach a self-hoster who re-runs the wizard — these `ALTER
/// TABLE … ADD COLUMN IF NOT EXISTS` statements are emitted
/// **unconditionally** (like the RLS/RPC blocks) to close that gap.
///
/// v4 (#3125): forensic origin stamps on tombstones.
/// v5 (#3452): EV favorites + station payloads on the favorites table.
const String upgradeSql = '''
ALTER TABLE public.deletions
  ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE public.deletions
  ADD COLUMN IF NOT EXISTS app_version TEXT;
ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'fuel';
ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS data JSONB;
''';

/// Builds the wizard SQL. [schema] maps table name → already-exists; a table
/// already present is skipped for the CREATE TABLE block (but RLS/RPCs are
/// always re-asserted, idempotently). A missing/empty map emits every table.
String buildMigrationSql(Map<String, bool> schema) {
  final buffer = StringBuffer()
    ..writeln('-- TankSync Schema Setup'
        ' (schema version $kSupabaseSchemaVersion)')
    ..writeln('-- Run this in your Supabase SQL Editor')
    ..writeln('-- Dashboard → SQL Editor → New Query → Paste → Run')
    ..writeln();

  for (final entry in tableSql.entries) {
    if (schema[entry.key] != true) {
      buffer.writeln(entry.value);
    }
  }

  buffer
    ..writeln(upgradeSql)
    // #4049 — MUST precede rlsSql: the trip_shares write policies call
    // public.owns_trip(), and CREATE POLICY resolves its expression at
    // creation time, so the function has to exist first.
    ..writeln(ownershipFnSql)
    // #4212 (v13) — same rule: the fleet policies call the membership
    // oracles, so those must exist before rlsSql creates the policies.
    ..writeln(fleetOracleSql)
    ..writeln(rlsSql)
    // v8 (#3747) — after rlsSql: the block replaces rlsSql's legacy
    // `users_own FOR ALL` policy with the owner-aware split, so it must
    // run last to be the final state.
    ..writeln(ownerProtectionSql)
    ..writeln(rpcSql)
    ..writeln(fleetRpcSql)
    // #4215 (v14) — the audit table BEFORE the RPCs that INSERT into
    // it; the bucket last, since its policies read fleet_documents.
    ..writeln(fleetAuditTableSql)
    ..writeln(fleetExpenseRpcSql)
    ..writeln(fleetDocumentStorageSql)
    // #4216 (v15) — after the audit table it INSERTs into and after
    // fleet_role(), which its body calls.
    ..writeln(fleetMetricsRpcSql)
    ..writeln(_metaSql);

  return buffer.toString();
}
