# Blocker — Apply 20260418 Supabase migration (#713)

The `vehicles` and `fill_ups` tables added in the 5.0.0+5032 build are
defined but not yet applied to the hosted Supabase project. Until they
exist, `SyncService.syncVehicles` and `syncFillUps` silently no-op —
linked devices share favorites + alerts but NOT vehicles and fuel logs
(a regression against what the sync wizard advertises).

This is a one-time operation. Running it requires credentials that the
coding agent does not have, so the user must apply it themselves.

## Migration file

```
supabase/migrations/20260418000001_vehicles_and_fillups.sql
```

Contents (already committed to this repo):
- `public.vehicles` — `(user_id, id)` primary key, JSONB `data` blob,
  RLS policy allowing the owner full access.
- `public.fill_ups` — `(user_id, id)` primary key with `vehicle_id` +
  `recorded_at` columns, JSONB `data` blob, RLS policy allowing the
  owner full access.
- Indexes on `user_id` for both tables.

## Option A — Supabase CLI (recommended)

```bash
# One-time setup
npm install -g supabase        # or use the MSI from supabase.com/docs/guides/cli
supabase login                  # opens a browser, authenticate as the project owner

# From repo root
cd supabase
supabase link --project-ref <PROJECT_REF>   # the ref is in the Supabase dashboard URL
supabase db push                             # applies all pending migrations

# Verify
supabase db remote query "SELECT COUNT(*) FROM public.vehicles;"
# returns 0 — good, the table exists and is empty
```

## Option B — Dashboard paste (no CLI needed)

1. Open https://supabase.com/dashboard/project/<PROJECT_REF>/sql/new
2. Paste the contents of
   `supabase/migrations/20260418000001_vehicles_and_fillups.sql`.
3. Hit **Run**. Expect "Success. No rows returned."
4. Inspect the Table Editor to confirm both `vehicles` and `fill_ups`
   appear under the `public` schema with RLS enabled.

## Verification from the app

1. Trigger a sync: open the app → Settings → Cloud Sync → tap "Sync
   now".
2. Watch the Supabase dashboard → Logs → API for `POST /rest/v1/vehicles`
   and `POST /rest/v1/fill_ups` calls. A 201/200 status confirms the
   write path works. If you see `42P01 relation does not exist`, the
   migration did not apply.
3. On a second linked device, run "Import from linked device" — the
   vehicles and fill-ups should now appear.

## Autonomous agent limitation

The agent cannot apply the migration because:
- The Supabase CLI requires an interactive browser-based `supabase
  login` flow.
- Hosted project access uses a service-role key that is (correctly) not
  checked into the repo.

After the migration is applied manually, the `#713` issue can be
closed. No code changes accompany the migration — the Dart sync layer
already handles the table's presence gracefully.
