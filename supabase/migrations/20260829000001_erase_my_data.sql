-- Copyright (c) 2026 Florian DITTGEN
-- SPDX-License-Identifier: MIT
--
-- #3868 (Epic #3865, GDPR Art. 17) — erase EVERY row the caller owns, in one
-- transaction, and report per table what was deleted.
--
-- Why an RPC and not the per-table client deletes of UserDataSync.deleteAll:
--   * the #3869-era `limit_bulk_delete` trigger (owner_protection) raises on
--     the 101st row of favorites / alerts / price_reports / itineraries — a
--     user with >100 favorites got a "deleted" snackbar and kept their data;
--   * public.users, sync_settings, wait_time_pings and trip_shares (as
--     owner OR recipient) had no client deletion path at all;
--   * one statement per table over the network is not atomic — a dropped
--     connection half-way left an account that was neither kept nor gone.
--
-- SECURITY DEFINER (runs as the function owner, table owner → RLS does not
-- apply) but pinned to auth.uid(): a caller can only ever erase THEMSELVES.
-- The bulk-delete trigger is bypassed by marking the transaction as
-- service_role for its duration (the trigger's own escape hatch).
-- Tables that a self-hosted schema may lack are skipped, not errored.

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

  FOREACH spec SLICE 1 IN ARRAY ARRAY[
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
