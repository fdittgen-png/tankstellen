-- Copyright (c) 2026 Florian DITTGEN
-- SPDX-License-Identifier: MIT
--
-- #3747 (item 2) — close the email→UUID oracle.
--
-- `resolve_share_recipient(email)` returns a RAW auth.users UUID to any
-- authenticated caller: an account-enumeration + identifier-harvesting
-- oracle (probe any email, learn whether an account exists AND obtain
-- its stable user id). The share flow never needed the UUID client-side
-- — it only ever fed it straight back into a trip_shares INSERT.
--
-- `share_trip_with_email` moves that resolve+insert server-side and
-- returns ONLY success/failure. Ownership semantics mirror the client
-- insert path exactly: the share row's owner_id is forced to
-- auth.uid() (previously the client set owner_id itself and the
-- trip_shares_owner_insert RLS policy WITH CHECKed it), and the upsert
-- conflict target matches the client's
-- onConflict: 'trip_id,owner_id,shared_with_id'.

CREATE OR REPLACE FUNCTION public.share_trip_with_email(p_trip_id TEXT, p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  recipient UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;
  -- Same normalisation as resolve_share_recipient (lower + trim) so
  -- casing / whitespace differences don't cause a false miss.
  SELECT id INTO recipient FROM auth.users
    WHERE lower(email) = lower(trim(p_email))
    LIMIT 1;
  IF recipient IS NULL THEN
    -- The ONE bit the old oracle legitimately served ("no such
    -- account") survives; the UUID never crosses the wire.
    RETURN FALSE;
  END IF;
  INSERT INTO public.trip_shares (trip_id, owner_id, shared_with_id, permission)
    VALUES (p_trip_id, auth.uid(), recipient, 'read')
    ON CONFLICT (trip_id, owner_id, shared_with_id)
      WHERE shared_with_id IS NOT NULL
    DO UPDATE SET permission = 'read';
  RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.share_trip_with_email(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.share_trip_with_email(TEXT, TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.share_trip_with_email(TEXT, TEXT) FROM anon;

-- Close the oracle. The function STAYS defined (idempotent re-runs,
-- and service_role / SQL-editor use keep working) but authenticated
-- clients can no longer resolve an arbitrary email to a raw UUID.
-- Older app builds pointed at a schema with this migration applied
-- lose the legacy share path (they get a 42501) — accepted: the
-- schema-version checker flags the mismatch, and current builds use
-- share_trip_with_email with a graceful fallback for OLD schemas.
REVOKE EXECUTE ON FUNCTION public.resolve_share_recipient(TEXT) FROM authenticated;

-- ───────────────────────────────────────────────────────────────────
-- price_reports.reporter_id exposure (#3747, documented, NOT changed)
-- ───────────────────────────────────────────────────────────────────
-- `reports_read USING (true)` intentionally stays: community price
-- reports are a shared feature, every client renders other users'
-- reports. That read surface also exposes `reporter_id` (a stable
-- pseudonymous account UUID) to any authenticated reader. A
-- column-level fix is NOT safely deployable today:
--   * REVOKE SELECT(reporter_id) breaks the app's own reads —
--     UserDataSync.fetchAll does `select=*` on price_reports (PostgREST
--     expands `*` eagerly and errors on an unreadable column) and
--     filters `.eq('reporter_id', uid)`, which needs SELECT privilege
--     on the column;
--   * the account-wipe path (synced_data_deletion / delete flows) keys
--     `DELETE … WHERE reporter_id = auth.uid()`, whose WHERE clause
--     also requires SELECT privilege on the column.
-- A reader-facing view without reporter_id (with the base-table read
-- policy tightened to own rows) is the proper fix and needs a
-- coordinated client migration — out of scope here. The client-side
-- community read (CommunityReportService.getReports) no longer selects
-- the column as of this change set.
