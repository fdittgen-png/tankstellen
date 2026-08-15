-- Copyright (c) 2026 Florian DITTGEN
-- SPDX-License-Identifier: MIT
--
-- #3712 — Play account-deletion requirement: "Delete account" must remove
-- the auth identity itself, not only the data rows. The client wipes every
-- owned row first (UserDataSync.deleteAll), then calls this RPC to delete
-- the caller's own auth.users record (which takes the e-mail with it).
--
-- SECURITY DEFINER because clients cannot touch auth.users; the function
-- is pinned to auth.uid() so a caller can only ever delete THEMSELVES.
-- A null uid (anon key without a session) deletes nothing.

CREATE OR REPLACE FUNCTION public.delete_user()
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
  DELETE FROM auth.users WHERE id = auth.uid();
$$;
REVOKE ALL ON FUNCTION public.delete_user() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_user() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.delete_user() FROM anon;
