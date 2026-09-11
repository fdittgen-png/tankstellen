-- #4060 — see the doc block in lib/core/sync/schema_sql_policies.dart.
-- Additive: v1 stays so clients already in the field keep working.
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
AS $$
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
$$;
REVOKE ALL ON FUNCTION public.share_trip_with_email_v2(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.share_trip_with_email_v2(TEXT, TEXT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.share_trip_with_email_v2(TEXT, TEXT) FROM anon;
