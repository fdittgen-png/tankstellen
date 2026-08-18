// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// RLS policies + SECURITY DEFINER RPCs for the TankSync schema, split out of
/// `schema_sql.dart` (which holds the CREATE TABLE blocks) to keep each file
/// reviewable under the line cap. Both are always (idempotently) re-asserted
/// by the wizard so re-running the setup SQL repairs drifted policies.
///
/// The per-table policy blocks live on each table's [SyncedTableSpec]
/// (`schema_table_specs*.dart`) since the extensibility-finding-8 refactor;
/// [rlsSql] here is ASSEMBLED from them, byte-identical to the previous
/// monolithic literal (pinned by
/// `test/core/sync/schema_sql_golden_test.dart`).
library;

import 'schema_table_specs.dart';

/// Row-level security: enables RLS + own-row / shared-read policies on every
/// table, assembled from [syncedTableSpecs] in list order (enable-RLS lines
/// first, then each table's policy block separated by one blank line).
/// Idempotent via DROP POLICY IF EXISTS so the wizard can re-assert policies
/// even when the tables already exist.
final String rlsSql = [
  '-- \u2500\u2500 Row Level Security \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500',
  for (final spec in syncedTableSpecs)
    'ALTER TABLE public.${spec.name} ENABLE ROW LEVEL SECURITY;',
  '',
  '${syncedTableSpecs.map((spec) => spec.rlsPolicySql).join('\n\n')}\n',
].join('\n');

/// SECURITY DEFINER RPCs the trip-sharing sync code calls
/// (`resolve_share_recipient`, `claim_trip_share`). Without these the
/// account-to-account and link-claim share flows fail on a self-host.
const String rpcSql = '''
-- ── Trip-sharing RPCs ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.resolve_share_recipient(recipient_email TEXT)
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, auth
AS \$\$
  SELECT id FROM auth.users
  WHERE lower(email) = lower(trim(recipient_email))
  LIMIT 1;
\$\$;
-- v8 (#3747): the raw-UUID resolver is an email→UUID oracle. It stays
-- defined (idempotent re-runs; service_role use) but authenticated
-- clients lost EXECUTE — they call share_trip_with_email below instead.
REVOKE ALL ON FUNCTION public.resolve_share_recipient(TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.resolve_share_recipient(TEXT) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.resolve_share_recipient(TEXT) FROM anon;

-- v8 (#3747): resolve+insert server-side; returns ONLY success/failure
-- so the recipient's UUID never crosses the wire. Ownership mirrors the
-- old client insert path: owner_id is forced to auth.uid().
CREATE OR REPLACE FUNCTION public.share_trip_with_email(p_trip_id TEXT, p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS \$\$
DECLARE
  recipient UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;
  SELECT id INTO recipient FROM auth.users
    WHERE lower(email) = lower(trim(p_email))
    LIMIT 1;
  IF recipient IS NULL THEN
    RETURN FALSE;
  END IF;
  INSERT INTO public.trip_shares (trip_id, owner_id, shared_with_id, permission)
    VALUES (p_trip_id, auth.uid(), recipient, 'read')
    ON CONFLICT (trip_id, owner_id, shared_with_id)
      WHERE shared_with_id IS NOT NULL
    DO UPDATE SET permission = 'read';
  RETURN TRUE;
END;
\$\$;
REVOKE ALL ON FUNCTION public.share_trip_with_email(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.share_trip_with_email(TEXT, TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.share_trip_with_email(TEXT, TEXT) FROM anon;

CREATE OR REPLACE FUNCTION public.claim_trip_share(token TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS \$\$
DECLARE
  claimed_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NULL;
  END IF;
  UPDATE public.trip_shares
    SET shared_with_id = auth.uid()
    WHERE share_token = token
      AND shared_with_id IS NULL
      AND owner_id <> auth.uid()
    RETURNING id INTO claimed_id;
  RETURN claimed_id;
END;
\$\$;
REVOKE ALL ON FUNCTION public.claim_trip_share(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_trip_share(TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.claim_trip_share(TEXT) FROM anon;

-- ── Account deletion RPC (#3712, schema v6) ─────────────────────────
-- Play's account-deletion requirement: "Delete account" must remove the
-- auth identity itself, not only the data rows. Pinned to auth.uid() so
-- a caller can only ever delete THEMSELVES; a null uid deletes nothing.
CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS \$\$
  DELETE FROM auth.users WHERE id = auth.uid();
\$\$;
REVOKE ALL ON FUNCTION public.delete_user() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.delete_user() FROM anon;
''';
