# Supabase RLS Policy Matrix

This document is the **authoritative inventory** of every Supabase
table the TankSync backend depends on, plus the Row-Level-Security
(RLS) policies expected on each. It exists because Supabase RLS is
the only thing that prevents one user's anon-key request from reading
another user's rows — if a future migration accidentally drops a
policy or a `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`, the only
thing standing between a curious anon-key holder and the entire
`favorites` table is this matrix and its companion test
(`test/security/supabase_rls_test.dart`).

> Audit reference: B7 — "Supabase security relies entirely on RLS
> policies set in the project dashboard. There is no test, no
> migration assertion, no documented matrix."

## Threat model

The Tankstellen client ships with a Supabase **anon key**. The anon
key is public by design; all data isolation MUST happen on the
server, in Postgres, via RLS policies. There are three callers:

| Role            | How it shows up                                 | Trust level |
|-----------------|-------------------------------------------------|-------------|
| `anon`          | Unauthenticated request from the app            | Untrusted — must fail closed |
| `authenticated` | App after `signInAnonymously` / email sign-in   | Scoped to its own `auth.uid()` |
| `service_role`  | Edge Functions only (`SUPABASE_SERVICE_ROLE_KEY`) | Trusted — bypasses RLS |

Every `public.*` table MUST have RLS enabled and at least one policy.
A table with RLS enabled but zero policies is read-locked for
authenticated users — a soft-fail that breaks the app silently and
is just as bad as the open-data alternative.

## Matrix

The columns capture what the **default request** (an `anon`-key
request that has called `signInAnonymously()` and so carries an
`authenticated` JWT) is allowed to do. Operations the `service_role`
performs from Edge Functions are out of scope — that role bypasses
RLS by design.

Legend:

- **own** — limited to rows where `user_id = auth.uid()` (or `id =
  auth.uid()` for the `users` table itself).
- **all** — any authenticated user can read every row.
- **none** — denied at the policy layer (no matching policy or an
  explicit `service_role` gate).
- **(svc)** — service-role-only path; anon is denied.

| Table              | SELECT       | INSERT          | UPDATE     | DELETE             | Notes |
|--------------------|--------------|-----------------|------------|--------------------|-------|
| `users`            | own          | own             | own        | own + owner-or-svc | Splits `users_own` into per-op policies. Delete is gated by `is_database_owner()` so a single compromised account can't wipe the user table. |
| `favorites`        | own          | own             | own        | own                | Single `favorites_own` `FOR ALL`. Bulk-delete trigger caps each statement at 100 rows. |
| `alerts`           | own          | own             | own        | own                | Single `alerts_own` `FOR ALL`. Bulk-delete trigger applies. |
| `price_snapshots`  | all          | (svc)           | (svc)      | (svc)              | Aggregate prices visible to every authenticated client; only Edge Functions write. |
| `price_reports`    | all          | own (`reporter_id = auth.uid()`) | (none) | own + owner-or-svc | Reports are crowdsourced; reads are public among authenticated users. There is no UPDATE policy on purpose — corrections are new reports, not edits. |
| `push_tokens`      | own          | own             | own        | own                | Single `push_own` `FOR ALL`. ntfy.sh topics are device-scoped. |
| `sync_settings`    | own          | own             | own        | own                | Single `sync_own` `FOR ALL`. |
| `itineraries`      | own          | own             | own        | own                | Single `itineraries_own` `FOR ALL`. Bulk-delete trigger applies. |
| `ignored_stations` | own          | own             | own        | own                | Single `ignored_own` `FOR ALL`. |
| `station_ratings`  | own + shared (`is_shared = true OR user_id = auth.uid()`) | own | own | own | Two policies: `ratings_own FOR ALL` plus a SELECT-only `ratings_shared_read` that opens shared rows to other users. |
| `database_owner`   | all          | (svc)           | (svc)      | (svc)              | The singleton "first user" tracker. Anyone can read it (so a client knows whether it's the owner); only `service_role` modifies it. |
| `vehicles`         | own          | own             | own        | own                | Single `vehicles_own` `FOR ALL`. |
| `fill_ups`         | own          | own             | own        | own                | Single `fill_ups_own` `FOR ALL`. |
| `obd2_baselines`   | own          | own             | own        | own                | Single `obd2_baselines_own` `FOR ALL`. |

The migration source-of-truth lives in `supabase/migrations/`:

- `20260327000001_initial_schema.sql` — initial seven tables.
- `20260327000002_rls_policies.sql` — initial RLS + policies.
- `20260328000001_itineraries.sql` — `itineraries`.
- `20260329000001_complete_schema.sql` — additive (`ignored_stations`,
  `station_ratings`, `database_owner` placeholder), idempotent.
- `20260401000001_owner_protection.sql` — splits `users_own` into per-op
  policies, adds bulk-delete trigger, introduces `database_owner`
  policies and helper `is_database_owner()`.
- `20260414000001_report_metadata_fields.sql` — schema-only, no RLS
  change.
- `20260418000001_vehicles_and_fillups.sql` — `vehicles`, `fill_ups`.
- `20260421000001_obd2_baselines.sql` — `obd2_baselines`.
- `20260403000001_pg_cron_alert_schedules.sql` — schedules only,
  service-role-driven, no public-table RLS change.

If a migration not listed above is found in `supabase/migrations/`,
this matrix is stale. See "How to update" below.

## Verification

The matrix is enforced by `test/security/supabase_rls_test.dart`. The
test is `@Tags(['network'])`, so it only runs when explicitly invoked:

```bash
SUPABASE_TEST_URL='https://<project>.supabase.co' \
SUPABASE_TEST_SERVICE_KEY='<service_role_key>' \
flutter test --tags network test/security/supabase_rls_test.dart
```

If `SUPABASE_TEST_URL` or `SUPABASE_TEST_SERVICE_KEY` is missing, the
test prints a clear message and skips — local development without
Supabase credentials is not a hard failure. CI runs the test on
release-tag builds against a staging project (see
`.github/workflows/release.yml`).

The test asserts two invariants:

1. Every table in the matrix exists in `pg_policies` with at least
   one policy — i.e. RLS is enabled AND a non-empty policy set
   exists.
2. No `public.*` table has zero policies. A table without policies
   is either RLS-disabled (open data) or RLS-enabled-without-policies
   (read-locked) — both are bugs.

The test does NOT assert exact policy SQL — that's intentional. The
shape is matched by name + `cmd` + table; the predicate text is
allowed to evolve. If you change a policy's predicate, you do not
need to update this matrix.

## How to update

Whenever a migration touches an `ALTER TABLE ... ENABLE ROW LEVEL
SECURITY`, a `CREATE POLICY`, or a `DROP POLICY`:

1. **Add the migration** under `supabase/migrations/` with an
   `RLS confirmed` checkbox in its top-of-file comment block (see
   "Migration template" below).
2. **Update this matrix** — add or modify the row for the affected
   table.
3. **Update the expected-policy list** in
   `test/security/supabase_rls_test.dart` — the `_expectedPolicies`
   map keys are table names; the values are the policy names you
   expect on each.
4. **Re-run** `flutter test --tags network test/security/
   supabase_rls_test.dart` against your staging Supabase project to
   confirm the live policies match.

If a migration drops a table, remove it from both the matrix and
the test, and add a `git commit` message that calls out the removal
explicitly so the audit trail is searchable.

## Migration template

Every new SQL migration under `supabase/migrations/` SHOULD start
with this header. It is enforced by code review (no automated check
yet — the security test catches the runtime symptom, but the
checkbox is the human-facing reminder during PR review):

```sql
-- <NNN> — <one-line description>
--
-- Why: <link to issue / one paragraph rationale>
--
-- RLS impact:
--   [ ] No public-table RLS change (schema-only, indexes, etc.)
--   [ ] Adds new public table → MUST `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`
--                              AND `CREATE POLICY` covering anon access.
--   [ ] Modifies existing policy (DROP + CREATE).
--   [ ] Drops a public table.
--
-- RLS confirmed: [ ]
--   I have updated `docs/security/SUPABASE_RLS_MATRIX.md` and
--   `test/security/supabase_rls_test.dart` to reflect the change
--   above (or this migration has no public-table RLS impact).
```

The `RLS confirmed: [ ]` checkbox is the gate. When it is checked,
the matrix and the test must already be in the same PR.
