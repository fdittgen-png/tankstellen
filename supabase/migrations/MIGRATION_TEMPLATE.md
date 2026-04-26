# Migration Template Checklist

Every new migration in `supabase/migrations/` must satisfy this checklist before
the corresponding PR is merged. The bullets below are intentionally short so they
can be copy-pasted into the PR description.

## Pre-merge checklist

- [ ] Filename uses the `YYYYMMDDhhmmss_short_name.sql` convention and sorts
  AFTER the latest existing migration (so `supabase db push` applies it last).
- [ ] All `CREATE TABLE` statements use `IF NOT EXISTS`. The migration is
  idempotent: running it twice on the same database is a no-op.
- [ ] **RLS confirmed: this migration does NOT disable RLS on any table, and
  any new tables explicitly call `ALTER TABLE … ENABLE ROW LEVEL SECURITY;`.**
- [ ] Every new table has at least one policy. No bare RLS-enabled table is
  shipped (default-deny would lock the app out of its own data).
- [ ] User-owned tables fence rows with `user_id = auth.uid()` (or equivalent
  on the primary key). Public-read tables (`USING (true)`) are only used for
  aggregate / community data and are documented in
  `docs/security/SUPABASE_RLS_MATRIX.md`.
- [ ] If the migration adds a new table, the matrix doc
  (`docs/security/SUPABASE_RLS_MATRIX.md`) is updated in the same PR with the
  new table's policy rows.
- [ ] If the migration adds a new policy on an existing table, the matrix doc
  row for that table is updated.
- [ ] No GRANT / REVOKE on `anon` or `authenticated` that would bypass RLS.
- [ ] No `BYPASSRLS` role attribute set on any role in the migration.
- [ ] Foreign keys to `public.users(id)` use `ON DELETE CASCADE` (so deleting a
  user nukes their data) unless there is a documented reason to use
  `ON DELETE SET NULL` (e.g. anonymising community reports).
- [ ] Indexes on user-scoped tables include a `user_id` prefix where the table
  is queried by user; verified against the read patterns in
  `lib/core/sync/`.

## Post-merge

- [ ] After the PR merges, run `supabase db push` against staging to apply.
- [ ] On the next tag release, the network-tagged
  `test/security/supabase_rls_test.dart` will assert the live policy set
  matches the matrix doc.

## Why each item matters

The single largest risk in TankSync is leaking another user's favorites,
alerts, or fill-ups via a missing or weakened RLS policy. The default
Supabase posture for a freshly-created table is: RLS off, world-readable. One
forgotten `ENABLE ROW LEVEL SECURITY` and the entire fleet is exposed to any
client with the anon key — which is shipped in every install. The verification
test catches drift, but it is run on tag releases only; this checklist catches
the same issue at PR review time, before the migration ever reaches staging.
