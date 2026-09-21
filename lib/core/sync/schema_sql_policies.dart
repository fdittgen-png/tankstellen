// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

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

/// #4049 — the ownership oracle the `trip_shares` write policies call.
/// Emitted BEFORE [rlsSql] in `schema_sql.dart`, because `CREATE POLICY`
/// resolves the functions in its expression at creation time: a wizard
/// that emitted the policies first would fail the self-hoster's paste
/// with "function public.owns_trip(text, uuid) does not exist".
///
/// SECURITY DEFINER purely to break an RLS cycle — `trip_summaries`'
/// read policy queries `trip_shares`, so a `trip_shares` policy that
/// looked up `trip_summaries` directly would recurse.
const String ownershipFnSql = '''
-- #4049 — ownership oracle for the trip_shares write policies. It is
-- SECURITY DEFINER purely to break an RLS cycle: trip_summaries' read
-- policy queries trip_shares, so a trip_shares policy that looked up
-- trip_summaries directly would recurse. Must exist BEFORE the share
-- policies that call it.
CREATE OR REPLACE FUNCTION public.owns_trip(p_trip_id TEXT, p_user UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS \$\$
  SELECT EXISTS (
    SELECT 1 FROM public.trip_summaries
     WHERE id = p_trip_id AND user_id = p_user
  );
\$\$;
REVOKE ALL ON FUNCTION public.owns_trip(TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owns_trip(TEXT, UUID) TO authenticated;
-- NOT redundant with the PUBLIC revoke: Supabase grants anon separately,
-- and without this owns_trip() is an unauthenticated existence oracle.
REVOKE EXECUTE ON FUNCTION public.owns_trip(TEXT, UUID) FROM anon;
''';

/// SECURITY DEFINER RPCs the trip-sharing sync code calls
/// (`owns_trip`, `resolve_share_recipient`, `share_trip_with_email`,
/// `claim_trip_share`). Without these the account-to-account and
/// link-claim share flows fail on a self-host.
///
/// #4049 — `owns_trip` is emitted FIRST because the `trip_shares` write
/// policies in `schema_table_specs_extended.dart` call it. A self-host
/// that pasted the policies without it would get a broken share flow.
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
  -- #4049 — the caller must OWN the trip. SECURITY DEFINER bypasses RLS
  -- on the insert below, so without this guard the write policies are
  -- never consulted and any trip id could be shared. Returns the same
  -- FALSE as an unresolvable recipient, so it is not an existence
  -- oracle for trip ids.
  IF NOT public.owns_trip(p_trip_id, auth.uid()) THEN
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

-- v11 (#4060): share_trip_with_email_v2 returns a TEXT outcome. v1 gave
-- the same FALSE for "no such recipient" and "caller does not own the
-- trip / trip not on the server yet", and the client blamed the email
-- for both. Not an existence oracle: 'not_owned' covers "does not exist"
-- and "someone else's" identically. v1 stays for clients in the field.
CREATE OR REPLACE FUNCTION public.share_trip_with_email_v2(p_trip_id TEXT, p_email TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS \$\$
DECLARE
  recipient UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN 'not_authenticated';
  END IF;
  IF NOT public.owns_trip(p_trip_id, auth.uid()) THEN
    RETURN 'not_owned';
  END IF;
  SELECT id INTO recipient FROM auth.users
    WHERE lower(email) = lower(trim(p_email))
    LIMIT 1;
  IF recipient IS NULL THEN
    RETURN 'recipient_not_found';
  END IF;
  INSERT INTO public.trip_shares (trip_id, owner_id, shared_with_id, permission)
    VALUES (p_trip_id, auth.uid(), recipient, 'read')
    ON CONFLICT (trip_id, owner_id, shared_with_id)
      WHERE shared_with_id IS NOT NULL
    DO UPDATE SET permission = 'read';
  RETURN 'shared';
END;
\$\$;
REVOKE ALL ON FUNCTION public.share_trip_with_email_v2(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.share_trip_with_email_v2(TEXT, TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.share_trip_with_email_v2(TEXT, TEXT) FROM anon;

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

-- v9 (#3868, GDPR Art. 17) — erase every row the caller owns in ONE
-- transaction, bypassing limit_bulk_delete for the caller's own rows;
-- public.users, sync_settings, wait_time_pings and trip_shares included.
-- v13 (#4212) — the two user-linked fleet tables join the list; the
-- org's own rows (organisations, vehicles, policies) are not the user's.
-- v14 (#4215) — fleet_expenses + fleet_documents join it, and the
-- stored receipt BYTES go with them: deleting the metadata row without
-- its object would leave the receipt in the bucket, which is exactly
-- the failure Art. 17 is about. The sweep runs BEFORE the loop, while
-- the rows that name the object keys still exist.
CREATE OR REPLACE FUNCTION public.erase_my_data()
RETURNS TABLE(table_name TEXT, rows_deleted BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS \$\$
DECLARE
  uid UUID := auth.uid();
  spec TEXT[];
  n BIGINT;
BEGIN
  IF uid IS NULL THEN
    RETURN;
  END IF;
  -- Transaction-local: lets limit_bulk_delete() pass for this erase only.
  PERFORM set_config('request.jwt.claims',
                     json_build_object('role', 'service_role')::text, true);

  -- #4215 — the receipt objects, keyed through the rows deleted below.
  -- BEST-EFFORT, and structurally unable to abort the erasure.
  --
  -- Supabase ships protect_objects_delete on storage.objects: a BEFORE
  -- DELETE FOR EACH STATEMENT trigger that raises 42501 for a direct
  -- SQL delete. Statement-level means it fires even when the statement
  -- matches ZERO rows, so the first shape of this sweep took down
  -- erase_my_data() for EVERY caller, fleet member or not — an Art. 17
  -- regression on a shipped path (#3865). The live matrix caught it.
  --
  -- Two guards, and the second is the one that matters: the
  -- transaction-local allow_delete_query switch is what the trigger
  -- looks for, and the EXCEPTION block means no future storage-side
  -- guard can ever again take the row erasure down with it. A skipped
  -- sweep is a WARNING, never a failed erase.
  --
  -- The client removes the bytes through the Storage API BEFORE calling
  -- this function (FleetDocumentStore.eraseOwnObjects), because that is
  -- the only path that deletes the S3 object as well as its row. This
  -- statement is the fallback for a caller that did not, and on its own
  -- it can leave the stored bytes orphaned in the bucket.
  IF to_regclass('storage.objects') IS NOT NULL THEN
    BEGIN
      IF EXISTS (
        SELECT 1 FROM pg_trigger
         WHERE tgrelid = 'storage.objects'::regclass
           AND NOT tgisinternal
           AND tgname = 'protect_objects_delete'
      ) THEN
        PERFORM set_config('storage.allow_delete_query', 'true', true);
      END IF;
      DELETE FROM storage.objects o
        USING public.fleet_documents d
        WHERE o.bucket_id = 'fleet-documents'
          AND o.name = d.object_key
          AND d.user_id = uid;
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'erase_my_data: fleet-documents object sweep skipped (%)',
        SQLERRM;
    END;
  END IF;

  FOREACH spec SLICE 1 IN ARRAY ARRAY[
    ARRAY['fleet_expenses',   'user_id'],
    ARRAY['fleet_documents',  'user_id'],
    ARRAY['vehicle_assignments', 'user_id'],
    ARRAY['fleet_members',    'user_id'],
    ARRAY['trip_shares',      'owner_id'],
    ARRAY['trip_shares',      'shared_with_id'],
    ARRAY['trip_details',     'user_id'],
    ARRAY['trip_summaries',   'user_id'],
    ARRAY['content_reports',  'reporter_user_id'],
    ARRAY['price_reports',    'reporter_id'],
    ARRAY['wait_time_pings',  'user_id'],
    ARRAY['push_tokens',      'user_id'],
    ARRAY['obd2_baselines',   'user_id'],
    ARRAY['station_ratings',  'user_id'],
    ARRAY['ignored_stations', 'user_id'],
    ARRAY['itineraries',      'user_id'],
    ARRAY['fill_ups',         'user_id'],
    ARRAY['vehicles',         'user_id'],
    ARRAY['alerts',           'user_id'],
    ARRAY['favorites',        'user_id'],
    ARRAY['sync_settings',    'user_id'],
    ARRAY['deletions',        'user_id'],
    ARRAY['users',            'id']
  ]
  LOOP
    IF to_regclass('public.' || spec[1]) IS NULL THEN
      CONTINUE;
    END IF;
    EXECUTE format('DELETE FROM public.%I WHERE %I = \$1', spec[1], spec[2])
      USING uid;
    GET DIAGNOSTICS n = ROW_COUNT;
    table_name := spec[1] || CASE WHEN spec[2] = 'shared_with_id'
                                  THEN ' (received)' ELSE '' END;
    rows_deleted := n;
    RETURN NEXT;
  END LOOP;
END;
\$\$;
REVOKE ALL ON FUNCTION public.erase_my_data() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.erase_my_data() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.erase_my_data() FROM anon;
''';
