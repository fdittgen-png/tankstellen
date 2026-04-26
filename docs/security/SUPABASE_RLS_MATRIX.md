# Supabase RLS Policy Matrix (TankSync)

This file is the **source of truth** for what Row-Level Security (RLS) policies SHOULD exist on the TankSync Supabase backend. The accompanying test
`test/security/supabase_rls_test.dart` queries the live database (`pg_policies`) on a tag-release / staging job and asserts that reality matches this
matrix. If a future migration accidentally drops, weakens, or shadows a policy, that test fails — closing the only path that can leak user data off-device.

Audit reference: B7 (Issue #1110). Required to lift the Security grade from A− to A.

## Summary

- Every table in `public` schema has `ENABLE ROW LEVEL SECURITY` set.
- User-owned rows are fenced by `user_id = auth.uid()` (or equivalent on `users.id`).
- Public read tables (`price_snapshots`, `price_reports`) use `USING (true)` for `SELECT` only — writes are still scoped.
- `service_role` is the only role allowed to insert/delete public-aggregate rows (`price_snapshots`).
- The first user to sign in becomes the database owner (singleton row in `database_owner`); the owner gains DELETE rights across `users` and `price_reports`.

Migrations covered (in chronological order):

1. `20260327000001_initial_schema.sql`
2. `20260327000002_rls_policies.sql`
3. `20260328000001_itineraries.sql`
4. `20260329000001_complete_schema.sql` (idempotent re-run of all of the above + new tables)
5. `20260401000001_owner_protection.sql` (replaces `users_own` with split SELECT/INSERT/UPDATE/DELETE policies; adds `database_owner` table; adds delete-scoped policies on `price_snapshots` and `price_reports`)
6. `20260418000001_vehicles_and_fillups.sql`
7. `20260421000001_obd2_baselines.sql`

The matrix below reflects the **final state** after all migrations have run.

---

## `users`

RLS: enabled

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `users_own_select` | SELECT | public | `id = auth.uid()` | — |
| `users_own_insert` | INSERT | public | — | `id = auth.uid()` |
| `users_own_update` | UPDATE | public | `id = auth.uid()` | — |
| `users_delete_owner_only` | DELETE | public | `id = auth.uid() OR public.is_database_owner() OR auth.role() = 'service_role'` | — |

Notes: the original `users_own` (FOR ALL) policy is dropped in `20260401000001_owner_protection.sql` and replaced with the four explicit ones above so DELETE can be scoped to the owner.

---

## `favorites`

RLS: enabled

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `favorites_own` | ALL | public | `user_id = auth.uid()` | — |

A bulk-delete trigger (`trg_limit_delete_favorites`) caps DELETE at 100 rows per statement for non-`service_role` callers.

---

## `alerts`

RLS: enabled

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `alerts_own` | ALL | public | `user_id = auth.uid()` | — |

A bulk-delete trigger (`trg_limit_delete_alerts`) caps DELETE at 100 rows per statement.

---

## `price_snapshots`

RLS: enabled. Public-read aggregate table; only the service role may write.

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `snapshots_read` | SELECT | public | `true` | — |
| `snapshots_insert` | INSERT | public | — | `auth.role() = 'service_role'` |
| `snapshots_delete` | DELETE | public | `auth.role() = 'service_role'` | — |

UPDATE has no policy → effectively denied (RLS default-deny).

---

## `price_reports`

RLS: enabled. Community feed: anyone reads, only the reporter writes / deletes own.

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `reports_insert` | INSERT | public | — | `reporter_id = auth.uid()` |
| `reports_read` | SELECT | public | `true` | — |
| `reports_delete` | DELETE | public | `reporter_id = auth.uid() OR public.is_database_owner() OR auth.role() = 'service_role'` | — |

UPDATE has no policy → effectively denied. A bulk-delete trigger (`trg_limit_delete_reports`) caps DELETE at 100 rows per statement.

---

## `push_tokens`

RLS: enabled

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `push_own` | ALL | public | `user_id = auth.uid()` | — |

---

## `sync_settings`

RLS: enabled

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `sync_own` | ALL | public | `user_id = auth.uid()` | — |

---

## `itineraries`

RLS: enabled

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `itineraries_own` | ALL | public | `user_id = auth.uid()` | — |

A bulk-delete trigger (`trg_limit_delete_itineraries`) caps DELETE at 100 rows per statement.

---

## `ignored_stations`

RLS: enabled. Defined in `20260329000001_complete_schema.sql`.

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `ignored_own` | ALL | public | `user_id = auth.uid()` | — |

---

## `station_ratings`

RLS: enabled. Defined in `20260329000001_complete_schema.sql`. Per-user ratings, optionally shared with the community via `is_shared = true`.

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `ratings_own` | ALL | public | `user_id = auth.uid()` | — |
| `ratings_shared_read` | SELECT | public | `is_shared = true OR user_id = auth.uid()` | — |

---

## `database_owner`

RLS: enabled. Singleton row (one row per database) tracking who owns this Supabase project. Defined in `20260401000001_owner_protection.sql`.

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `owner_read` | SELECT | public | `true` | — |
| `owner_manage` | ALL | public | `auth.role() = 'service_role'` | — |

Anyone can read to check if they are the owner; only the service role can mutate the row.

---

## `vehicles`

RLS: enabled. Defined in `20260418000001_vehicles_and_fillups.sql`.

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `vehicles_own` | ALL | public | `user_id = auth.uid()` | — |

---

## `fill_ups`

RLS: enabled. Defined in `20260418000001_vehicles_and_fillups.sql`.

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `fill_ups_own` | ALL | public | `user_id = auth.uid()` | — |

---

## `obd2_baselines`

RLS: enabled. Defined in `20260421000001_obd2_baselines.sql`.

| Policy | Command | Roles | USING | WITH CHECK |
|---|---|---|---|---|
| `obd2_baselines_own` | ALL | public | `user_id = auth.uid()` | — |

---

## Verification

Run the verification test against staging:

```bash
SUPABASE_URL=https://<staging-project-ref>.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=<staging-service-role-key> \
flutter test test/security/supabase_rls_test.dart --tags network
```

Without env vars, the test cleanly skips so it never blocks offline PR checks.
