-- Bind trip-share grants to the trip's real owner (#4049).
--
-- Reported privately by Andrew Pozdnakov (@andrewpozdnakov7) during
-- F-Droid MR !42093 review; confirmed by execution against this project
-- on 2026-09-11 with synthetic, rolled-back fixtures.
--
-- ── THE DEFECT ────────────────────────────────────────────────────
-- A `trip_shares` row proved who CREATED a grant and never that the
-- grant's `trip_id` belonged to that creator. The additive read
-- policies then matched a grant on (trip_id, recipient) alone. So an
-- authenticated user could name ANOTHER account's trip id, make
-- themselves both owner and recipient, and read that trip.
--
-- Measured before the fix (synthetic actors, transaction rolled back):
--   control, no grant .............. 0 rows   (RLS was enforcing)
--   INSERT self-grant on A's trip .. ACCEPTED -> summary 1, details 1
--   UPDATE repoint onto A's trip ... ACCEPTED -> summary 1
--   share_trip_with_email on A's trip  returned true -> summary 1
--
-- Three surfaces, all of which had to be closed. Fixing only the RLS
-- policies would have left the SECURITY DEFINER RPC working, because
-- SECURITY DEFINER bypasses RLS on the insert entirely.
--
-- ── WHY A HELPER FUNCTION ─────────────────────────────────────────
-- The obvious fix — have the trip_shares INSERT policy check
-- trip_summaries directly — recurses: trip_summaries' own read policy
-- queries trip_shares, whose policy would query trip_summaries again.
-- `owns_trip` is SECURITY DEFINER, so it runs as owner with RLS
-- bypassed and the cycle never forms. The READ policies need no helper:
-- `s.owner_id = trip_summaries.user_id` compares two columns already in
-- scope and adds no lookup.

-- ───────────────────────────────────────────────────────────────────
-- 1. Ownership oracle — SECURITY DEFINER purely to break the RLS cycle
-- ───────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.owns_trip(p_trip_id TEXT, p_user UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.trip_summaries
     WHERE id = p_trip_id AND user_id = p_user
  );
$$;

REVOKE ALL ON FUNCTION public.owns_trip(TEXT, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.owns_trip(TEXT, UUID) TO authenticated;
-- The explicit anon revoke is NOT redundant with REVOKE FROM PUBLIC:
-- Supabase grants EXECUTE to anon separately, and the Supabase security
-- advisor flagged exactly this the first time it was omitted. Without
-- it, owns_trip() is an unauthenticated existence oracle — and because
-- trip ids are wall-clock timestamps rather than random, that is a
-- discovery primitive, not a curiosity. Mirrors the sibling share RPCs.
REVOKE EXECUTE ON FUNCTION public.owns_trip(TEXT, UUID) FROM anon;

-- ───────────────────────────────────────────────────────────────────
-- 2. Write side — a grant may only name a trip the grantor owns
-- ───────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS trip_shares_owner_insert ON public.trip_shares;
CREATE POLICY trip_shares_owner_insert ON public.trip_shares
  FOR INSERT WITH CHECK (
    owner_id = auth.uid() AND public.owns_trip(trip_id, auth.uid())
  );

-- UPDATE needs the check on BOTH sides: USING stops a grant that
-- already points elsewhere from being touched, WITH CHECK stops a
-- legitimate grant being repointed at someone else's trip. Checking
-- only INSERT does not suffice — the repoint was a working attack.
DROP POLICY IF EXISTS trip_shares_owner_update ON public.trip_shares;
CREATE POLICY trip_shares_owner_update ON public.trip_shares
  FOR UPDATE
  USING (owner_id = auth.uid() AND public.owns_trip(trip_id, auth.uid()))
  WITH CHECK (owner_id = auth.uid() AND public.owns_trip(trip_id, auth.uid()));

-- ───────────────────────────────────────────────────────────────────
-- 3. Read side — the grant's owner must be the trip's owner
-- ───────────────────────────────────────────────────────────────────
-- Defence in depth: even if an invalid grant exists (one written before
-- this migration), it grants nothing, because the read now demands the
-- grantor actually own the row being read.
DROP POLICY IF EXISTS trip_summaries_shared_read ON public.trip_summaries;
CREATE POLICY trip_summaries_shared_read ON public.trip_summaries
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.trip_shares s
      WHERE s.trip_id = trip_summaries.id
        AND s.shared_with_id = auth.uid()
        AND s.owner_id = trip_summaries.user_id
    )
  );

DROP POLICY IF EXISTS trip_details_shared_read ON public.trip_details;
CREATE POLICY trip_details_shared_read ON public.trip_details
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.trip_shares s
      WHERE s.trip_id = trip_details.id
        AND s.shared_with_id = auth.uid()
        AND s.owner_id = trip_details.user_id
    )
  );

-- ───────────────────────────────────────────────────────────────────
-- 4. The SECURITY DEFINER RPC — the surface that bypasses RLS
-- ───────────────────────────────────────────────────────────────────
-- Same body as before plus one guard. Without it the function inserts
-- `p_trip_id` unchecked AS THE DEFINER, so no RLS policy above is ever
-- consulted. Verified exploitable before this change.
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
  -- #4049 — the caller must own the trip they are sharing. Returns the
  -- same FALSE as an unresolvable recipient so the function never
  -- becomes an oracle for "does this trip id exist".
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
$$;

-- ───────────────────────────────────────────────────────────────────
-- 5. Clean up grants that could never have been legitimate
-- ───────────────────────────────────────────────────────────────────
-- The read policy already neutralises these, but a stale row that
-- claims a trip its owner never owned has no reason to exist.
DELETE FROM public.trip_shares s
 WHERE NOT EXISTS (
   SELECT 1 FROM public.trip_summaries t
    WHERE t.id = s.trip_id AND t.user_id = s.owner_id
 );
