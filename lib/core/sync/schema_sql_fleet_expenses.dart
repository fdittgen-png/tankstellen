// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The audit log, review RPCs and private Storage bucket of the fleet
/// expense workflow (#4215, ADR 0025, schema v14) — the wizard twin of
/// `supabase/migrations/20260918000002_fleet_expenses.sql`, sections 1
/// (the audit table), 3 and 4.
///
/// The two USER-owned tables themselves — `fleet_expenses` and
/// `fleet_documents` — live in `schema_table_specs_fleet.dart` with
/// every other synced table, because the verifier probes them and the
/// wizard skips the `CREATE TABLE` of a table a self-hoster already
/// has. The three pieces here are different in kind:
///
///  * [fleetAuditTableSql] — `fleet_audit_events` is never `.from()`d
///    by the sync code (the RPCs below write it; `UserDataSync` reads
///    the caller's own rows through its table MAP), so it is a
///    server-only table like `tanksync_meta`: emitted unconditionally,
///    not registered as a spec, not probed;
///  * [fleetExpenseRpcSql] — the manager's only write path;
///  * [fleetDocumentStorageSql] — a `storage.*` block, which is not a
///    `public.` table at all.
///
/// Emission order is load-bearing (`schema_sql.dart`):
/// [fleetAuditTableSql] must precede [fleetExpenseRpcSql] (the RPCs
/// INSERT into it) and — like every table — the RPC block must follow
/// the policies, so the whole trio goes out after `fleetRpcSql`.
library;

/// `fleet_audit_events` (ADR 0025 D5.4): one row per privileged call.
///
/// Org-owned and append-only *from the client's point of view*: there
/// is deliberately no INSERT / UPDATE / DELETE policy, so an audit
/// trail cannot be written, edited or tidied away by anything but the
/// SECURITY DEFINER functions below. The SELECT policy gives the
/// SUBJECT their own access rows (D9 puts them in the user's export)
/// and an admin the organisation's.
const String fleetAuditTableSql = '''
-- ── Fleet audit log (#4215, v14, ADR 0025 D5.4) ────────────────────
-- Server-only: written by the fleet_* RPCs, read by the subject (own
-- rows) and by an org admin. No client write policy exists, so the
-- trail cannot be rewritten by the party it is about.
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
ALTER TABLE public.fleet_audit_events ENABLE ROW LEVEL SECURITY;
-- Hygiene, not redundancy: Supabase grants table privileges to anon
-- by default, and a privilege still applies where a policy is missing.
REVOKE ALL ON TABLE public.fleet_audit_events FROM anon;
DROP POLICY IF EXISTS fleet_audit_events_select ON public.fleet_audit_events;
CREATE POLICY fleet_audit_events_select ON public.fleet_audit_events
  FOR SELECT TO authenticated
  USING (
    actor = (SELECT auth.uid())
    OR public.fleet_role(org_id) = 'admin'
  );
''';

/// The manager's only write path onto `fleet_expenses`, plus the
/// signed-URL audit hook (#4215).
///
/// `fleet_review_expense` exists because the manager has NO update
/// policy on the table: approval cannot be spoofed by an UPDATE with a
/// chosen status, and cannot skip the employee — the function refuses
/// anything that is not already `submitted`, mirroring
/// `ExpenseStateMachine` on the device. Both functions re-check
/// `auth.uid()`, the org and the caller's role INSIDE the definer body,
/// because SECURITY DEFINER bypasses RLS and the policies are never
/// consulted (#4049's third surface).
const String fleetExpenseRpcSql = '''
-- ── Fleet expense RPCs (#4215, v14) ────────────────────────────────

-- Manager review: submitted -> approved | rejected, audited. Raised
-- messages are stable snake_case tokens the client maps to its own
-- translated wording; they are never shown verbatim.
CREATE OR REPLACE FUNCTION public.fleet_review_expense(
  p_id TEXT,
  p_user UUID,
  p_decision TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS \$\$
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
  -- Same error for "no such expense" and "not yours to see", so this is
  -- not an existence oracle for other people's expense ids.
  IF org IS NULL THEN
    RAISE EXCEPTION 'expense_not_found' USING ERRCODE = 'P0002';
  END IF;
  IF coalesce(public.fleet_role(org), '') NOT IN ('manager', 'admin') THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;
  -- The device allows submitted -> approved | rejected and nothing
  -- else; the server agrees, so a draft cannot be approved even by a
  -- manager who guessed its id.
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
\$\$;
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
AS \$\$
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
\$\$;
REVOKE ALL ON FUNCTION public.fleet_log_document_access(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.fleet_log_document_access(UUID) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.fleet_log_document_access(UUID) FROM anon;
''';

/// The private `fleet-documents` bucket and its two object policies
/// (#4215, ADR 0025 "what never leaves the device").
///
/// `public = false` is re-asserted on every run: a bucket flipped
/// public by hand is the one mistake that would put a fuel receipt —
/// a name, a place, a time and a masked card — on the open internet.
/// Reads are short-lived signed URLs the client never persists.
///
/// The manager's read of the BYTES never parses the object key — it is
/// client-supplied text — and it does NOT merely delegate to
/// `fleet_documents`' RLS either. A review caught that delegation as
/// #4049's ownership gap one table over: a user could insert their own
/// `fleet_documents` row naming a VICTIM's object path and the EXISTS
/// would match. The policy therefore pins the metadata row to the real
/// uploader (`d.user_id = storage.objects.owner`), checks the caller's
/// role on the document's own org, and joins the owning expense for the
/// draft rule.
///
/// The write side is closed at the same time: the own-object policy's
/// WITH CHECK forces the caller's uid as the key's second segment, and
/// `fleet_documents_own` (in `schema_table_specs_fleet.dart`) forces
/// `object_key` to `<org>/<auth.uid()>/<id>`.
///
/// The whole block is wrapped in a guarded `DO` so a Postgres without
/// Supabase's storage schema skips it with a NOTICE instead of aborting
/// the self-hoster's paste.
const String fleetDocumentStorageSql = '''
-- ── Private receipt bucket (#4215, v14) ────────────────────────────
DO \$fleet_storage\$
BEGIN
  IF to_regclass('storage.objects') IS NULL THEN
    RAISE NOTICE 'storage schema absent - fleet-documents bucket skipped';
    RETURN;
  END IF;

  INSERT INTO storage.buckets (id, name, public)
       VALUES ('fleet-documents', 'fleet-documents', false)
  ON CONFLICT (id) DO UPDATE SET public = false;

  EXECUTE \$p\$DROP POLICY IF EXISTS fleet_documents_object_own ON storage.objects\$p\$;
  EXECUTE \$p\$
    CREATE POLICY fleet_documents_object_own ON storage.objects
      FOR ALL TO authenticated
      USING (bucket_id = 'fleet-documents' AND owner = (SELECT auth.uid()))
      WITH CHECK (
        bucket_id = 'fleet-documents'
        AND owner = (SELECT auth.uid())
        AND split_part(name, '/', 2) = (SELECT auth.uid())::text
      )
  \$p\$;

  EXECUTE \$p\$DROP POLICY IF EXISTS fleet_documents_object_manager_read ON storage.objects\$p\$;
  EXECUTE \$p\$
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
  \$p\$;
END
\$fleet_storage\$;
''';
