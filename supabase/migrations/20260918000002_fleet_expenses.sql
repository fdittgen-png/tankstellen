-- Copyright (c) 2026 Florian DITTGEN
-- SPDX-License-Identifier: AGPL-3.0-or-later
--
-- #4215 (Epic #4211, ADR 0025) — the server half of the expense /
-- document workflow: two USER-owned tables, one org-owned audit log, a
-- private Storage bucket and the two RPCs a manager surface goes
-- through. Schema version 13 → 14.
--
-- ── Why these tables are user-owned, unlike every #4212 table ────────
-- The five fleet-tenancy tables describe the ORGANISATION, so they are
-- read through the membership oracles and written only by RPC. An
-- expense is the opposite: the employee creates it, corrects it, and
-- owns it until they hand it over. It therefore gets the schema's
-- ordinary `user_id = auth.uid()` shape — which is also why
-- `EntitySync` (whose contract is "the caller owns every row it
-- writes") fits it unchanged, and why no new transport is needed.
--
-- ── The one rule that is NOT ordinary: a draft never leaves ──────────
-- On top of the own-row policy each table carries a MANAGER SELECT,
-- and that policy is restricted to `status <> 'draft'`. A draft is the
-- employee's working copy of a photograph of their own payment card;
-- ADR 0025's visibility matrix gives the manager "non-draft expenses"
-- and nothing else, so the boundary is a policy predicate rather than
-- a client-side filter that a REST call could simply omit.
--
-- `fleet_documents`' manager policy joins `fleet_expenses` for the same
-- sentence: a manager may read a receipt only while a non-draft expense
-- of their org cites it.
--
-- The Storage policy repeats BOTH checks rather than delegating to the
-- metadata row, and that is the correction a review caught. `object_key`
-- is client-supplied text: an EXISTS that asked only "is some visible
-- fleet_documents row pointing at this object" let a user insert their
-- OWN row naming a VICTIM's object path and read the bytes — #4049's
-- ownership gap, one table over. So the object policy pins the metadata
-- row to the real uploader (`d.user_id = storage.objects.owner`),
-- checks the caller's role on the DOCUMENT's org, and joins the owning
-- expense for the draft rule itself. The forged row fails the first of
-- the three, because its `user_id` is the forger's and the object's
-- owner is the victim's.
--
-- The insert side is closed too: `fleet_documents_own`'s WITH CHECK
-- forces `object_key` to `<org>/<auth.uid()>/<id>`, so a client cannot
-- choose an arbitrary key in the first place, and the object policy's
-- WITH CHECK forces the same second segment on the upload.
--
-- ── Review is an RPC, for the same reason #4212's writes are ─────────
-- `fleet_review_expense` moves `submitted → approved | rejected`. The
-- manager has no UPDATE policy on the table at all, so approval cannot
-- be spoofed by an UPDATE with a chosen status, and cannot skip the
-- employee: the RPC refuses anything that is not already `submitted`,
-- mirroring `ExpenseStateMachine` on the device. Every call writes
-- `fleet_audit_events` (ADR 0025 D5.4), which lands here because this
-- is the first manager surface; F9 reuses the table.
--
-- ── Private storage, signed URLs, never a public URL ─────────────────
-- Bucket `fleet-documents` is created with `public = false` and
-- re-asserted false on every re-run. Reads are short-lived signed URLs
-- the client never persists, and every issue is audited through
-- `fleet_log_document_access`, whose access test mirrors the object
-- policy so a logged access is one that really happened. Object keys
-- are `<org>/<user>/<doc id>`,
-- and while the READ policies never trust the prefix (they join the
-- metadata row and re-check the role), the WRITE side pins it: a client
-- cannot create a row or an object outside its own `<org>/<uid>/`.
--
-- RLS impact:
--   [x] Two new user-owned tables (own-row FOR ALL + manager SELECT).
--   [x] One new org-owned audit table (SELECT only; no write policy).
--   [x] storage.objects gains two `fleet-documents`-scoped policies.
--   [x] erase_my_data() covers both new user tables and - best-effort,
--       behind the storage delete guard - the objects behind them.
--   [x] No change to any existing table's policies.
--
-- RLS confirmed: [x]
--   Live matrix re-run 2026-09-20 against project klelxnkzrxlpzuddhpfg
--   inside one aborting transaction. 32/32 cases passed; zero
--   persistence verified after (schema_version still 8, 0 fleet
--   tables, users 49, bucket objects 13468).
--
--   Security: a draft is invisible to a manager in metadata AND in
--   bytes while a submitted one is not; a manager of another org sees
--   neither; an employee cannot call fleet_review_expense; the RPC
--   refuses a non-submitted expense and an unknown decision; the audit
--   log has no write policy; anon reaches none of it. The IDOR is shut
--   at both surfaces: a forged object_key is refused at INSERT and at
--   UPDATE, and a row PLANTED with RLS bypassed - satisfying key match,
--   deleted_at, the non-draft citing expense and the manager role -
--   still yields 0 bytes, refused solely by
--   d.user_id = storage.objects.owner. That binding, not the key
--   prefix, is what carries the security here (the #4049 lesson).
--
--   Erasure: erase_my_data() completes for a fleet member (3 expenses,
--   2 documents; audit rows survive with actor nulled; org rows
--   untouched) AND for a user with no fleet rows at all, reporting all
--   23 tables. A control run with the guard disabled reproduces the
--   42501 that the STATEMENT-level protect_objects_delete trigger
--   raises even on a zero-row delete, so the guard is demonstrably what
--   closes it. The SQL sweep removed both object rows; the S3 bytes go
--   through the client's Storage API call, which SQL cannot drive.
--
--   Audit fidelity: fleet_log_document_access refuses a manager asking
--   for a draft and writes NO row, while the document's owner is still
--   allowed and audited.
--
--   See `test/core/sync/fleet/fleet_expense_rls_contract_test.dart` and
--   `erase_my_data_storage_guard_test.dart` for the halves CI enforces.

-- ───────────────────────────────────────────────────────────────────
-- 1. Tables
-- ───────────────────────────────────────────────────────────────────
-- `id` is TEXT and the primary key is (user_id, id) — the `fill_ups`
-- shape, because an expense is created offline on the device and keyed
-- by the same client-generated id the local Hive box uses.
CREATE TABLE IF NOT EXISTS public.fleet_expenses (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  org_id UUID NOT NULL REFERENCES public.fleet_organizations(id) ON DELETE CASCADE,
  fleet_vehicle_id UUID REFERENCES public.fleet_vehicles(id) ON DELETE SET NULL,
  fill_up_id TEXT,
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
    'draft', 'needs_review', 'submitted', 'approved', 'rejected',
    'exported', 'archived')),
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);
-- The manager query is (org_id, status <> 'draft'); the employee query
-- is covered by the primary key.
CREATE INDEX IF NOT EXISTS fleet_expenses_org_status_idx
  ON public.fleet_expenses(org_id, status);
CREATE INDEX IF NOT EXISTS fleet_expenses_vehicle_idx
  ON public.fleet_expenses(fleet_vehicle_id);
-- The document a manager may reach lives inside the blob; the
-- fleet_documents policy joins on it, so it is indexed.
CREATE INDEX IF NOT EXISTS fleet_expenses_document_idx
  ON public.fleet_expenses((data ->> 'documentId'));

CREATE TABLE IF NOT EXISTS public.fleet_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  org_id UUID NOT NULL REFERENCES public.fleet_organizations(id) ON DELETE CASCADE,
  object_key TEXT NOT NULL,
  sha256 TEXT NOT NULL,
  retention_class TEXT NOT NULL DEFAULT 'user_managed' CHECK (
    retention_class IN (
      'accounting_document', 'attribution_evidence', 'user_managed')),
  deleted_at TIMESTAMPTZ,
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, object_key)
);
CREATE INDEX IF NOT EXISTS fleet_documents_org_idx
  ON public.fleet_documents(org_id);
CREATE INDEX IF NOT EXISTS fleet_documents_user_idx
  ON public.fleet_documents(user_id);
-- The Storage policy joins objects to this row by key.
CREATE INDEX IF NOT EXISTS fleet_documents_object_key_idx
  ON public.fleet_documents(object_key);

-- ADR 0025 D5.4: one row per privileged call. Org-owned, append-only
-- from the RPCs — there is deliberately no INSERT / UPDATE / DELETE
-- policy, so an audit trail cannot be written or rewritten by a client.
CREATE TABLE IF NOT EXISTS public.fleet_audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES public.fleet_organizations(id) ON DELETE CASCADE,
  actor UUID REFERENCES public.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target TEXT,
  at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS fleet_audit_events_org_at_idx
  ON public.fleet_audit_events(org_id, at DESC);
CREATE INDEX IF NOT EXISTS fleet_audit_events_actor_idx
  ON public.fleet_audit_events(actor);

ALTER TABLE public.fleet_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fleet_audit_events ENABLE ROW LEVEL SECURITY;

-- Hygiene, not redundancy: Supabase grants table privileges to `anon`
-- by default, and a privilege still applies where a policy is missing.
REVOKE ALL ON TABLE public.fleet_expenses FROM anon;
REVOKE ALL ON TABLE public.fleet_documents FROM anon;
REVOKE ALL ON TABLE public.fleet_audit_events FROM anon;

-- ───────────────────────────────────────────────────────────────────
-- 2. Policies
-- ───────────────────────────────────────────────────────────────────
-- The employee owns the row outright; `(SELECT auth.uid())` so the
-- lookup is evaluated once per statement, not once per row.
DROP POLICY IF EXISTS fleet_expenses_own ON public.fleet_expenses;
CREATE POLICY fleet_expenses_own ON public.fleet_expenses
  FOR ALL TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

-- ADR 0025 visibility matrix: the manager sees SUBMITTED work, never a
-- draft. `fleet_role` returns NULL for a non-member and `NULL IN (…)`
-- is NULL, so a stranger's read is refused without a coalesce.
DROP POLICY IF EXISTS fleet_expenses_manager_select ON public.fleet_expenses;
CREATE POLICY fleet_expenses_manager_select ON public.fleet_expenses
  FOR SELECT TO authenticated
  USING (
    status <> 'draft'
    AND public.fleet_role(org_id) IN ('manager', 'admin')
  );

DROP POLICY IF EXISTS fleet_documents_own ON public.fleet_documents;
CREATE POLICY fleet_documents_own ON public.fleet_documents
  FOR ALL TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (
    user_id = (SELECT auth.uid())
    AND object_key = org_id::text || '/' || (SELECT auth.uid())::text
                     || '/' || id::text
  );

-- "Only inside the expense workflow, audited" (D9 matrix). The EXISTS
-- runs under the manager's own RLS on fleet_expenses, so the draft rule
-- above is inherited rather than restated — and the explicit status
-- test keeps the sentence readable at this call site too.
DROP POLICY IF EXISTS fleet_documents_manager_select ON public.fleet_documents;
CREATE POLICY fleet_documents_manager_select ON public.fleet_documents
  FOR SELECT TO authenticated
  USING (
    public.fleet_role(org_id) IN ('manager', 'admin')
    AND EXISTS (
      SELECT 1 FROM public.fleet_expenses e
       WHERE e.org_id = fleet_documents.org_id
         AND e.status <> 'draft'
         AND e.data ->> 'documentId' = fleet_documents.id::text
    )
  );

-- The subject reads their own access rows (ADR 0025 D9: they are in the
-- user's export); an admin reads the org's. Nobody writes.
DROP POLICY IF EXISTS fleet_audit_events_select ON public.fleet_audit_events;
CREATE POLICY fleet_audit_events_select ON public.fleet_audit_events
  FOR SELECT TO authenticated
  USING (
    actor = (SELECT auth.uid())
    OR public.fleet_role(org_id) = 'admin'
  );

-- ───────────────────────────────────────────────────────────────────
-- 3. RPCs
-- ───────────────────────────────────────────────────────────────────
-- Manager review. The manager has NO update policy on fleet_expenses:
-- this function is the only door, and it re-checks auth.uid(), the org
-- and the role inside the definer body because SECURITY DEFINER
-- bypasses RLS and the policies are never consulted (#4049's third
-- surface). Raised messages are stable snake_case tokens the client
-- maps to its own translated wording.
CREATE OR REPLACE FUNCTION public.fleet_review_expense(
  p_id TEXT,
  p_user UUID,
  p_decision TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  org UUID;
  current_status TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;
  IF p_decision IS NULL OR p_decision NOT IN ('approved', 'rejected') THEN
    RAISE EXCEPTION 'unknown_decision' USING ERRCODE = '22023';
  END IF;
  SELECT org_id, status INTO org, current_status
    FROM public.fleet_expenses
   WHERE user_id = p_user AND id = p_id;
  -- Same error for "no such expense" and "not yours to see", so the
  -- function is not an existence oracle for other people's expense ids.
  IF org IS NULL THEN
    RAISE EXCEPTION 'expense_not_found' USING ERRCODE = 'P0002';
  END IF;
  IF coalesce(public.fleet_role(org), '') NOT IN ('manager', 'admin') THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;
  -- The device's ExpenseStateMachine allows submitted → approved |
  -- rejected and nothing else; the server agrees, so a draft cannot be
  -- approved even by a manager who guessed its id.
  IF current_status IS DISTINCT FROM 'submitted' THEN
    RAISE EXCEPTION 'not_submitted' USING ERRCODE = '22023';
  END IF;
  UPDATE public.fleet_expenses
     SET status = p_decision, updated_at = now()
   WHERE user_id = p_user AND id = p_id;
  INSERT INTO public.fleet_audit_events (org_id, actor, action, target)
    VALUES (org, auth.uid(), 'expense_' || p_decision, p_id);
  RETURN p_decision;
END;
$$;
REVOKE ALL ON FUNCTION public.fleet_review_expense(TEXT, UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_review_expense(TEXT, UUID, TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_review_expense(TEXT, UUID, TEXT) FROM anon;

-- One audit row per signed URL the client asks Storage for (D5.4). Its
-- access test MIRRORS the object policy rather than merely checking
-- membership, so a row in the log means a URL was really issued: the
-- looser first version recorded an access for a manager asking after a
-- DRAFT receipt, which the bytes policy then refused, leaving an
-- auditor unable to tell a real access from a refused one.
-- It returns a boolean and never the URL: issuing the URL is the
-- Storage API's job, governed by the object policies, so a caller
-- cannot use this to obtain access it does not already have.
CREATE OR REPLACE FUNCTION public.fleet_log_document_access(p_document UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  org UUID;
  doc_owner UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;
  SELECT org_id, user_id INTO org, doc_owner
    FROM public.fleet_documents
   WHERE id = p_document AND deleted_at IS NULL;
  IF org IS NULL THEN
    RETURN FALSE;
  END IF;
  -- Mirror the READ rule exactly. "Any member of the org" was not
  -- enough: a manager asking for a DRAFT receipt they may never read
  -- got a 'document_signed_url' row and a TRUE while the object policy
  -- correctly refused the bytes, so the log claimed an access that
  -- never happened and an auditor could not tell the two apart. The
  -- owner always passes; anybody else needs the role on the
  -- document's org AND a non-draft expense of that org citing it.
  IF doc_owner IS DISTINCT FROM auth.uid() THEN
    IF coalesce(public.fleet_role(org), '') NOT IN ('manager', 'admin') THEN
      RETURN FALSE;
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM public.fleet_expenses e
       WHERE e.org_id = org
         AND e.status <> 'draft'
         AND e.data ->> 'documentId' = p_document::text
    ) THEN
      RETURN FALSE;
    END IF;
  END IF;
  INSERT INTO public.fleet_audit_events (org_id, actor, action, target)
    VALUES (org, auth.uid(), 'document_signed_url', p_document::text);
  RETURN TRUE;
END;
$$;
REVOKE ALL ON FUNCTION public.fleet_log_document_access(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_log_document_access(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_log_document_access(UUID) FROM anon;

-- ───────────────────────────────────────────────────────────────────
-- 4. Private Storage bucket + per-object policies
-- ───────────────────────────────────────────────────────────────────
-- Wrapped in a guarded DO block so a Postgres without the Supabase
-- storage schema (a bare self-host, a local unit-test database) skips
-- the block with a NOTICE instead of aborting the whole paste.
DO $fleet_storage$
BEGIN
  IF to_regclass('storage.objects') IS NULL THEN
    RAISE NOTICE 'storage schema absent - fleet-documents bucket skipped';
    RETURN;
  END IF;

  -- `public = false` is re-asserted on every run: a bucket flipped
  -- public by hand is the one mistake that would put a receipt on the
  -- open internet.
  INSERT INTO storage.buckets (id, name, public)
       VALUES ('fleet-documents', 'fleet-documents', false)
  ON CONFLICT (id) DO UPDATE SET public = false;

  EXECUTE $p$DROP POLICY IF EXISTS fleet_documents_object_own ON storage.objects$p$;
  EXECUTE $p$
    CREATE POLICY fleet_documents_object_own ON storage.objects
      FOR ALL TO authenticated
      USING (bucket_id = 'fleet-documents' AND owner = (SELECT auth.uid()))
      WITH CHECK (
        bucket_id = 'fleet-documents'
        AND owner = (SELECT auth.uid())
        AND split_part(name, '/', 2) = (SELECT auth.uid())::text
      )
  $p$;

  -- The manager's read of the BYTES delegates to fleet_documents' RLS,
  -- which delegates to fleet_expenses' draft rule. One sentence, three
  -- layers, no prefix parsing: the object key is untrusted text.
  EXECUTE $p$DROP POLICY IF EXISTS fleet_documents_object_manager_read ON storage.objects$p$;
  EXECUTE $p$
    CREATE POLICY fleet_documents_object_manager_read ON storage.objects
      FOR SELECT TO authenticated
      USING (
        bucket_id = 'fleet-documents'
        AND EXISTS (
          SELECT 1
            FROM public.fleet_documents d
            JOIN public.fleet_expenses e
              ON e.org_id = d.org_id
             AND e.data ->> 'documentId' = d.id::text
           WHERE d.object_key = storage.objects.name
             AND d.user_id = storage.objects.owner
             AND d.deleted_at IS NULL
             AND e.status <> 'draft'
             AND public.fleet_role(d.org_id) IN ('manager', 'admin')
        )
      )
  $p$;
END
$fleet_storage$;

-- ───────────────────────────────────────────────────────────────────
-- 5. Erasure — the expense, the document row AND the stored bytes
-- ───────────────────────────────────────────────────────────────────
-- Same body as 20260918000001 plus the two new user-owned tables, and
-- — new here — the objects behind them: deleting a fleet_documents row
-- without its bytes would leave the receipt in the bucket, which is
-- exactly the failure GDPR Art. 17 is about. The object sweep runs
-- BEFORE the loop, while the metadata rows that name the keys still
-- exist.
CREATE OR REPLACE FUNCTION public.erase_my_data()
RETURNS TABLE(table_name TEXT, rows_deleted BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
    EXECUTE format('DELETE FROM public.%I WHERE %I = $1', spec[1], spec[2])
      USING uid;
    GET DIAGNOSTICS n = ROW_COUNT;
    table_name := spec[1] || CASE WHEN spec[2] = 'shared_with_id'
                                  THEN ' (received)' ELSE '' END;
    rows_deleted := n;
    RETURN NEXT;
  END LOOP;
END;
$$;
REVOKE ALL ON FUNCTION public.erase_my_data() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.erase_my_data() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.erase_my_data() FROM anon;

-- ───────────────────────────────────────────────────────────────────
-- 6. Schema version
-- ───────────────────────────────────────────────────────────────────
INSERT INTO public.tanksync_meta (key, value, updated_at)
  VALUES ('schema_version', '14', now())
  ON CONFLICT (key)
  DO UPDATE SET value = EXCLUDED.value, updated_at = now();
