-- Cross-account trip sharing (#2240).
--
-- Distinct from the cross-DEVICE sync shipped by #1479 (same account,
-- many devices — `public.trip_summaries` / `public.trip_details` with
-- RLS `user_id = auth.uid()`). THIS migration lets a user share ONE
-- recorded trip with a DIFFERENT TankSync account (direct account-to-
-- account) OR mint an unguessable link token a recipient can claim.
--
-- Sharing only ever WIDENS read access — it never grants write, and it
-- never weakens the existing own-row policies on trip_summaries /
-- trip_details. A recipient sees a shared trip as strictly read-only.
--
-- NOT YET APPLIED TO PROD — the maintainer applies this via the
-- Supabase MCP after reviewing the security-critical RLS below. Every
-- statement is idempotent (CREATE … IF NOT EXISTS / DROP POLICY IF
-- EXISTS … CREATE POLICY) so a later `supabase db push` reconciles
-- cleanly against the already-applied schema.

-- ───────────────────────────────────────────────────────────────────
-- 1. The share-grant table
-- ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.trip_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- The shared trip's `trip_summaries.id` (TEXT, the client trip id).
  trip_id TEXT NOT NULL,
  -- The owner who created the share. CASCADE so deleting an account
  -- tears down every share they granted.
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  -- The recipient account for a DIRECT share. NULL for an unclaimed
  -- link/token share — the claim flow writes the recipient's id here.
  shared_with_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  -- The unguessable claim token for a LINK share. NULL for a direct
  -- account-to-account share. UNIQUE so a token resolves to one grant.
  share_token TEXT UNIQUE,
  -- Future-proofing: only 'read' is honoured today (sharing never
  -- grants write — see the additive SELECT policies below), but the
  -- column lets a later phase add 'comment' / 'edit' without a
  -- migration churn.
  permission TEXT NOT NULL DEFAULT 'read',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- A trip can be shared with a given recipient at most once (direct
-- shares). Token shares carry a NULL shared_with_id so they don't
-- collide here — the UNIQUE(share_token) constraint guards those.
CREATE UNIQUE INDEX IF NOT EXISTS trip_shares_unique_direct_idx
  ON public.trip_shares(trip_id, owner_id, shared_with_id)
  WHERE shared_with_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS trip_shares_owner_idx
  ON public.trip_shares(owner_id);
CREATE INDEX IF NOT EXISTS trip_shares_recipient_idx
  ON public.trip_shares(shared_with_id);
-- Speeds up the additive trip_summaries / trip_details EXISTS lookups,
-- which filter by (trip_id, shared_with_id).
CREATE INDEX IF NOT EXISTS trip_shares_trip_recipient_idx
  ON public.trip_shares(trip_id, shared_with_id);

ALTER TABLE public.trip_shares ENABLE ROW LEVEL SECURITY;

-- ───────────────────────────────────────────────────────────────────
-- 2. RLS on trip_shares — SECURITY-CRITICAL
-- ───────────────────────────────────────────────────────────────────
-- The owner has full CRUD over the share rows THEY created. Split into
-- explicit per-command policies (rather than one FOR ALL) so the
-- INSERT path can WITH CHECK that a client can't forge a row owned by
-- someone else.
DROP POLICY IF EXISTS trip_shares_owner_select ON public.trip_shares;
CREATE POLICY trip_shares_owner_select ON public.trip_shares
  FOR SELECT USING (owner_id = auth.uid());

DROP POLICY IF EXISTS trip_shares_owner_insert ON public.trip_shares;
CREATE POLICY trip_shares_owner_insert ON public.trip_shares
  FOR INSERT WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS trip_shares_owner_update ON public.trip_shares;
CREATE POLICY trip_shares_owner_update ON public.trip_shares
  FOR UPDATE USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS trip_shares_owner_delete ON public.trip_shares;
CREATE POLICY trip_shares_owner_delete ON public.trip_shares
  FOR DELETE USING (owner_id = auth.uid());

-- The recipient can READ the share rows pointing at them. This is what
-- lets the client list "trips shared with me" by selecting the grants
-- directly. Recipients CANNOT insert/update/delete a grant — only the
-- owner can revoke (DELETE) a share.
DROP POLICY IF EXISTS trip_shares_recipient_select ON public.trip_shares;
CREATE POLICY trip_shares_recipient_select ON public.trip_shares
  FOR SELECT USING (shared_with_id = auth.uid());

-- ───────────────────────────────────────────────────────────────────
-- 3. ADDITIVE read policies on trip_summaries / trip_details
-- ───────────────────────────────────────────────────────────────────
-- These WIDEN read access for recipients WITHOUT touching the existing
-- own-row policies (`trip_summaries_own` / `trip_details_own`, both
-- FOR ALL USING (user_id = auth.uid())). Postgres RLS is permissive by
-- default: a row is visible if ANY policy passes, so adding a SELECT
-- policy can only grant more reads, never revoke the owner's. Write
-- access is untouched — the own-row FOR ALL policy still gates
-- INSERT/UPDATE/DELETE to `user_id = auth.uid()`, so a recipient can
-- read but never mutate a shared trip.
DROP POLICY IF EXISTS trip_summaries_shared_read ON public.trip_summaries;
CREATE POLICY trip_summaries_shared_read ON public.trip_summaries
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.trip_shares s
      WHERE s.trip_id = trip_summaries.id
        AND s.shared_with_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS trip_details_shared_read ON public.trip_details;
CREATE POLICY trip_details_shared_read ON public.trip_details
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.trip_shares s
      WHERE s.trip_id = trip_details.id
        AND s.shared_with_id = auth.uid()
    )
  );

-- ───────────────────────────────────────────────────────────────────
-- 4. Email → user_id resolution (SECURITY DEFINER RPC)
-- ───────────────────────────────────────────────────────────────────
-- Direct account-to-account shares need to turn a recipient EMAIL into
-- a user id. `public.users` stores only the id; emails live in
-- `auth.users`, which clients cannot read. This SECURITY DEFINER
-- function exposes EXACTLY ONE bit — "does an account with this email
-- exist, and what is its id" — without leaking the users table. It
-- normalises the email (lower + trim) before matching so casing /
-- whitespace differences don't cause a false miss. Returns NULL when
-- no account matches (the caller surfaces a "no such account" message).
CREATE OR REPLACE FUNCTION public.resolve_share_recipient(recipient_email TEXT)
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public, auth
AS $$
  SELECT id FROM auth.users
  WHERE lower(email) = lower(trim(recipient_email))
  LIMIT 1;
$$;

-- Lock the function down: only authenticated callers may resolve a
-- recipient, and they get a single id back (never a row dump). Revoke
-- the default PUBLIC execute first so anonymous sessions can't probe.
REVOKE ALL ON FUNCTION public.resolve_share_recipient(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_share_recipient(TEXT) TO authenticated;

-- ───────────────────────────────────────────────────────────────────
-- 5. Token claim (SECURITY DEFINER RPC)
-- ───────────────────────────────────────────────────────────────────
-- Claiming a link/token share: the recipient calls this with the token
-- printed in the share link; the function stamps THEIR id into
-- shared_with_id (only when the row is still unclaimed) so the additive
-- read policies above start matching for them. SECURITY DEFINER so the
-- recipient — who is NOT the owner and so can't UPDATE the row under
-- RLS — can still claim it, but the WHERE clause confines the write to
-- exactly the matching, still-unclaimed token row. A self-share (owner
-- claiming their own token) is rejected so a grant can't loop back.
CREATE OR REPLACE FUNCTION public.claim_trip_share(token TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

REVOKE ALL ON FUNCTION public.claim_trip_share(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_trip_share(TEXT) TO authenticated;
