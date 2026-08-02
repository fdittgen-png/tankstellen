**07 · Data**

# Supabase backend

> Postgres with row-level security is the only authorisation boundary in a mobile app that survives a modified client. Everything on this page follows from taking that seriously: the client is untrusted, the database enforces, and the migration history is the specification of what the database enforces.

**Chunk prefix** sb **Updated** 2026-08-01 **Depends on** 01 Foundations · 09 Confidentiality

#### On this page

1. [The trust model](#model)
1. [Migrations are numbered and immutable](#migrations)
1. [Row-level security: default deny](#rls)
1. [Role helpers and the recursion problem](#helpers)
1. [Writes behind SECURITY DEFINER RPCs](#rpc)
1. [The permission matrix](#matrix)
1. [Invariants belong in the database](#invariants)
1. [Edge functions and scheduled work](#functions)
1. [Client/server schema parity](#parity)
1. [Self-hostability](#selfhost)
1. [Offline, sync and deletion](#offline)

<!-- chunk: sb.model | tags: security,architecture,trust -->

## The trust model

The mobile app ships with a publishable key that every user has. That key is not a secret and must not be treated as one — it is an entry ticket, and row-level security is the door.

| Component | Trusted? | Consequence |
| --- | --- | --- |
| The Flutter client | **No** | Anyone can extract the key, replay requests, and call any table or function the key can reach |
| The publishable/anon key | **No** — it is public by design | Committing it to the repository is fine and expected. Committing the *service-role* key is a breach. |
| The JWT claims | Yes — signed by the backend | `auth.uid()` is reliable inside a policy |
| RLS policies | Yes | The actual boundary |
| `SECURITY DEFINER` functions | Yes, if `search_path` is pinned and execute is revoked from `public` | Where writes with business rules live |

> **[RULE]**

> **Any check that exists only in Dart is a UX affordance, not a security control.** Hiding a button, disabling a field, filtering a list client-side — all fine for usability, all worthless against a crafted request. Every one of them must have a corresponding policy or function check. When you write a client-side guard, write the server-side one in the same pull request.

> **[WHY]**

> Because it grants exactly the permissions RLS allows to an unauthenticated or authenticated role, and no more. One project ships the same URL and publishable key in the store binary, the F-Droid binary and the web build, and states so explicitly: RLS is the boundary. If that statement makes you uncomfortable, the discomfort is a signal that the policies are not yet doing their job — not that the key needs hiding.

<!-- chunk: sb.migrations | tags: migrations,sql,process -->

## Migrations are numbered and immutable

Numbered SQL files, applied in order, never edited after they have been applied anywhere. A fix is a new migration.

```text
supabase/migrations/
  0001_initial_schema.sql
  0002_rls_policies.sql
  0003_indexes.sql
  …
  0051_personal_invitations.sql
  0052_member_join_validation.sql       ← supersedes an interim 0051 draft
  …
  0073_vat_grants_hardening.sql
```

> **[RULE]**

> **Never edit an applied migration.** Any environment that already ran it will not re-run it, so the edit reaches new deployments only — and you now have two databases with the same migration history and different schemas. That divergence is silent and it is discovered at the worst possible moment.

Write migrations so they converge from any prior state:

- `create table if not exists`, `drop policy if exists` before `create policy`, `drop function if exists` before redefining.
- When a migration supersedes an interim draft, have it **explicitly drop the draft's leftovers** in its first section, and say so in the file header.
- Put a header comment in every file: what it does, what it supersedes, and anything unusual about how it was applied.

> **[TRAP]**

> **Symptom: the applied-migrations table lists a name with no matching file, and it looks like schema drift.** It usually is not. In one project two such rows turned out to be (a) a section of a larger migration that had been applied as its own row, with the parent file's header saying exactly that, and (b) an interim draft superseded the same day, whose successor explicitly dropped its leftovers.

> **The lesson, worth writing into your own docs:** a migration-row name that does not match a file is *not* evidence of drift until you have read the file. Verify convergence — check that the successor uses `if exists` guards for everything the draft created — rather than assuming either way.

> **[CHECK]**

> Periodically rebuild a scratch database from `migrations/` alone and diff its schema against the live one. That is the only real proof the repository is complete. Do it before any release that touches the schema.

<!-- chunk: sb.rls | tags: rls,security,postgres -->

## Row-level security: default deny

Enable RLS on a table in the same migration that creates it, and grant only what is needed. Any operation not explicitly allowed is blocked.

```sql
create table reservations (
  id            uuid primary key default gen_random_uuid(),
  workspace_id  uuid not null references workspaces(id) on delete cascade,
  member_id     uuid not null references members(id)    on delete cascade,
  seat_id       uuid not null references seats(id),
  starts_at     timestamptz not null,
  ends_at       timestamptz not null,
  created_at    timestamptz not null default now()
);

-- Immediately, in the same migration. A table created without this is
-- world-readable to anyone holding the publishable key.
alter table reservations enable row level security;

create policy reservations_select on reservations
  for select using (is_member_of(workspace_id));

-- No insert/update/delete policy: writes go through an RPC (see below).
```

> **[RULE]**

> **A new table gets `enable row level security` in the same statement block that creates it.** Not in a follow-up migration, not "before we go live". A table without RLS is readable and writable by every holder of the publishable key, which is every user of your app and anyone who downloads it.

**Denormalise the scope column.** Copy `workspace_id` (or your tenant key) onto every table, even where it is reachable by a join. Every policy then becomes a single helper call instead of a correlated subquery — which matters both for readability and for query plans, since the policy is evaluated per row.

> **[RULE]**

> **Secrets tables get zero policies.** A table holding provider credentials, webhook signing keys, or anything similar should have RLS enabled and *no* policy at all, so it is unreachable from the client role entirely. It is read only by `SECURITY DEFINER` functions and edge functions using the service role.

<!-- chunk: sb.helpers | tags: rls,postgres,security-definer -->

## Role helpers and the recursion problem

Membership checks must be `SECURITY DEFINER` functions with a pinned `search_path`, or a policy on the membership table cannot consult the membership table.

```sql
create or replace function is_member_of(ws uuid)
returns boolean
language sql
stable
security definer
set search_path = public          -- pinned: callers cannot shadow objects
as $$
  select exists (
    select 1 from members m
    where m.workspace_id = ws
      and m.user_id = auth.uid()
      and m.status <> 'exited'
  );
$$;

revoke execute on function is_member_of(uuid) from public, anon;
grant   execute on function is_member_of(uuid) to authenticated;
```

> **[TRAP]**

> **Symptom: `infinite recursion detected in policy for relation "members"`.** The select policy on `members` calls a helper that queries `members`, which triggers the policy again. `SECURITY DEFINER` breaks the loop because the function body runs as the owner and bypasses RLS on the tables it reads.

> **The two obligations that come with it:** pin `search_path` so a caller cannot create a shadowing object in a schema earlier on the path, and revoke execute from `public` and `anon` so an unauthenticated caller cannot invoke it directly.

> **[RULE]**

> **Every new function gets `revoke execute … from public, anon`.** Postgres grants execute to `public` by default. A helper that leaks membership existence, or an RPC that performs a write, is reachable by an unauthenticated caller until you revoke it. Make the revoke part of the function template so it cannot be forgotten.

Keep the helper set small and composable — typically `is_member_of`, `is_admin_of`, `is_owner_of`, and one for "shares a tenant with this user". Roles compose additively, so an owner passes all three.

<!-- chunk: sb.rpc | tags: rpc,writes,transactions -->

## Writes behind SECURITY DEFINER RPCs

Reads go through policies; writes with any business rule go through a function, because a policy can only answer yes or no — it cannot check a quota, cap an end time, or create two rows atomically.

```sql
create or replace function check_in(p_seat uuid, p_until timestamptz)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ws     uuid;
  v_member uuid;
  v_end    timestamptz := p_until;
  v_next   timestamptz;
  v_id     uuid;
begin
  select workspace_id into v_ws from seats where id = p_seat;
  if v_ws is null then raise exception 'seat_not_found'; end if;

  select id into v_member from members
   where workspace_id = v_ws and user_id = auth.uid() and status <> 'exited';
  if v_member is null then raise exception 'not_a_member'; end if;

  -- Cap at the next reservation on this seat, if any.
  select min(starts_at) into v_next from reservations
   where seat_id = p_seat and starts_at > now();
  if v_next is not null and v_next < v_end then v_end := v_next; end if;

  -- Conflict check and insert in ONE transaction — never against a
  -- possibly-stale client view.
  if exists (
    select 1 from reservations
     where seat_id = p_seat and starts_at < v_end and ends_at > now()
  ) then
    raise exception 'seat_taken';
  end if;

  insert into reservations (workspace_id, member_id, seat_id, starts_at, ends_at)
  values (v_ws, v_member, p_seat, now(), v_end)
  returning id into v_id;

  return v_id;
end;
$$;

revoke execute on function check_in(uuid, timestamptz) from public, anon;
grant   execute on function check_in(uuid, timestamptz) to authenticated;
```

> **[WHY]**

> Double-booking is the characteristic failure of any reservation system, and it comes from checking availability against a view the client fetched some seconds ago. The client's list is always stale by the time the user taps. Making the conflict check and the insert one server-side statement is the only construction where the answer cannot change between the check and the write.

**Raise named errors, not sentences.** `raise exception 'seat_taken'` gives the client a stable code it can map to a localised message. A prose error message becomes a string comparison in Dart and breaks the moment someone improves the wording.

<!-- chunk: sb.matrix | tags: rls,documentation,security-review -->

## The permission matrix

Maintain a document mapping every table and operation to every role, with the mechanism that enforces it — and update it in the same pull request as the migration.

| Table | Operation | anon | user | worker | admin | owner | Mechanism |
| --- | --- | --- | --- | --- | --- | --- | --- |
| profiles | select own | — | ✅ | ✅ | ✅ | ✅ | `profiles_select` |
| profiles | insert | — | auto | auto | auto | auto | `handle_new_user` trigger only |
| workspaces | select | — | — | ✅ | ✅ | ✅ | `is_member_of()` |
| workspaces | insert | — | RPC | RPC | RPC | RPC | `create_workspace()` — creator becomes owner |
| workspaces | update / delete | — | — | — | — | ✅ | `is_owner_of()` |
| members | update roles | — | — | — | — | ✅ | `members_update_owner` |
| members | leave | — | — | RPC | RPC | RPC | `leave_workspace()` sets status |

> **[RULE]**

> **Every migration touching a table, a policy or a `SECURITY DEFINER` function updates the matrix in the same pull request, re-runs the security advisors, and pastes the advisor result into the pull-request description.** All four parts. The matrix without the advisor run is a claim; the advisor run without the matrix is a number nobody can interpret.

The matrix earns its keep in review. A reviewer cannot hold thirty policies in their head, but they can read one row and ask "should an admin really be able to do that?" — which is the question that catches over-broad grants.

> **[TRAP]**

> **Symptom: a delete is blocked for users who should be allowed it.** A defensive client-side or policy-level block added "for safety" on top of RLS that already scopes rows to the owner. The RLS was already correct; the extra guard was over-broad and only removed functionality. Before adding a belt-and-braces restriction, check what the policy already guarantees — the matrix is where you check.

<!-- chunk: sb.invariants | tags: postgres,triggers,invariants -->

## Invariants belong in the database

A rule that must always hold is a trigger or a constraint, not a code path — because there is always a second code path.

| Invariant | Mechanism |
| --- | --- |
| A tenant always has at least one owner | `before update or delete` trigger that raises if the change would leave none. The last owner can be *replaced*, never removed. |
| Exited members lose all visibility | Every role helper filters `status <> 'exited'` — one place, not per policy |
| An invite code is unique and unguessable | Server-generated from an unambiguous alphabet (no `0`/`O`, `1`/`l`), unique index |
| Rejoining does not duplicate a membership | The join RPC re-activates an exited row rather than inserting |
| A payment settles exactly once | Unique index on the idempotency key. Choose the key carefully — see the trap below. |
| Time ranges do not overlap | `exclude using gist` constraint, or the RPC-level conflict check above |

> **[TRAP]**

> **Symptom: a payment is captured twice, or a settlement webhook arrives before the capture it refers to.** Keying idempotency on the payment-provider's capture id fails when the provider reports settlement before a capture id exists. One project keys on `(provider, order_id)` instead — an identifier that exists from the first moment of the flow — so a settlement arriving early still settles exactly once. Pick the earliest stable identifier in the external system's lifecycle, not the most specific one.

<!-- chunk: sb.functions | tags: edge-functions,deno,scheduling -->

## Edge functions and scheduled work

Edge functions are for work that needs a secret, a third party, or a schedule — never for work a policy or an RPC can do.

| Legitimate use | Example |
| --- | --- |
| Holds a secret the client must never see | Calling a payment provider or an invoicing gateway with a private key |
| Talks to a third party | Fetching upstream prices, sending an e-invoice, pushing a notification |
| Runs on a schedule | Nightly aggregation, alert evaluation, cleanup — triggered by `pg_cron` |
| Proxies and caches on behalf of clients | A map-tile proxy that caches upstream tiles in storage |
| Validates something the client cannot be trusted to validate | Report moderation, quota computation over other users' rows |

```sql
-- Scheduling lives in a migration too, so it is versioned with everything else.
select cron.schedule(
  'evaluate-alerts',
  '*/15 * * * *',
  $$ select net.http_post(
       url     := current_setting('app.functions_url') || '/check-alerts',
       headers := jsonb_build_object('Authorization',
                    'Bearer ' || current_setting('app.service_key'))
     ) $$
);
```

> **[RULE]**

> **Log every outbound call to a third party with a hash of the payload, and never the payload itself.** One project records every e-invoice transmission attempt with a SHA-256 of what left the system. That gives you proof of what was sent, and the ability to detect a duplicate, without storing customer data in a log table. Store the hash, the timestamp, the target and the response status.

> **[TRAP]**

> **Symptom: an integration is "built and tested" but has never actually reached the third party.** An adapter with unit tests, a function that deploys, and logging that works still proves nothing about the external system's acceptance of your payload. One project is explicit in its own known-gaps section that its e-invoice path is blocked on a real provider account and no document has yet reached a real endpoint from that code. Mark such a path clearly as unverified end-to-end, in the documentation, until a real transmission has succeeded.

<!-- chunk: sb.parity | tags: sync,schema,parity,testing -->

## Client/server schema parity

If the app also stores data locally, the local schema and the remote schema must move together — otherwise a self-hoster gets silent per-table sync failures.

> **[RULE]**

> **Adding a new synced table, or a new explicit non-JSON column, requires updating the schema verifier in the same pull request.** That means: the required/optional table lists, the setup SQL the app hands to self-hosters, the RLS policies in that SQL, any RPC — and a bump of the schema version so an outdated deployment is flagged rather than silently broken.

> **Adding a *field* is usually transparent** when entities are stored whole in a JSONB `data` column. That is a good reason to prefer JSONB for synced payloads: the common change requires no coordination at all.

```dart
// A drift-guard test: every table the sync layer talks to must appear in
// the verifier's list and in the setup SQL.
test('every synced table is declared in the schema verifier', () {
  final used = <String>{};
  for (final f in Directory('lib/core/sync').listSync(recursive: true)
      .whereType<File>().where((f) => f.path.endsWith('.dart'))) {
    for (final m in RegExp(r"\.from\('([a-z_]+)'\)")
        .allMatches(f.readAsStringSync())) {
      used.add(m.group(1)!);
    }
  }
  final declared = {...SchemaVerifier.requiredTables,
                    ...SchemaVerifier.optionalTables};
  expect(used.difference(declared), isEmpty,
      reason: 'synced table missing from the verifier and the wizard SQL');
});
```

> **[RULE]**

> **Update the fake repository in the same pull request as the server contract.** Widget tests run against fakes. A fake that still models the old contract makes every test green while the real path is broken — the [false-green](03-tdd-and-testing.html#false-green) failure applied to the backend.

<!-- chunk: sb.selfhost | tags: self-hosting,configuration,build -->

## Self-hostability

Accept the backend URL and key as build-time defines with committed defaults, and ship the setup SQL inside the app.

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_KEY=<publishable key>
```

```dart
abstract final class BackendConfig {
  static const url = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://reference-project.supabase.co');
  static const key = String.fromEnvironment('SUPABASE_KEY',
      defaultValue: '<committed publishable key>');
  static bool get isReference => url == /* the default */ '';
}
```

For a user-facing self-host flow, an in-app wizard is better than a README:

1. The user creates their own project and pastes the URL and publishable key.
1. The app renders the setup SQL — generated from the same source as the verifier — for them to run once.
1. The app verifies the schema: which required tables exist, which are missing, what version the deployment is at.
1. On a version mismatch, the app surfaces a specific, actionable notice rather than failing per-table at runtime.

> **[CHECK]**

> Run the wizard SQL against an empty project and then run the app's own verifier against it. If the verifier reports anything missing, the SQL and the verifier have diverged — which is exactly the drift the parity rule above exists to prevent, and the only test that proves it end to end.

<!-- chunk: sb.offline | tags: sync,offline,deletion -->

## Offline, sync and deletion

Local-first means the app works with no backend at all and treats sync as an enhancement. That has three consequences that are easy to get wrong.

### Sync must be bidirectional, and usually starts out not being

> **[TRAP]**

> **Symptom: a second device shows none of the first device's data, and nobody notices for a long time because the first device looks perfect.** Upload is the easy half and gets built first; the pull path is deferred and then forgotten. One project shipped a sync layer that was upload-only for several entity types — the server received everything and the client never read any of it back. Audit each entity explicitly: does it push, does it pull, and is there a test for the pull?

### Deletion needs tombstones

Without them, a delete on device A is undone by device B's next upload, which still has the row. Record deletions in a tombstone table with a timestamp, propagate them like any other change, and keep a local pending-deletions journal so a delete performed offline is not lost.

### Identity must survive an upgrade

> **[RULE]**

> **Upgrading an anonymous account to a permanent one must preserve the user id.** Use the platform's link/update-user flow, never `signUp` — a fresh sign-up mints a new id and every row the anonymous user created becomes orphaned under RLS. See [page 08](08-authentication.html#anon).

Two smaller practices worth adopting: store all timestamps in UTC and convert only for display (recurring rules are the exception — they recur in the tenant's local time); and decode large sync payloads in a background isolate so a big pull does not drop frames.

#### Sources for this page

- One project's Supabase directory: 73 numbered migrations, 5 edge functions, `pg_cron` schedules declared in migrations, and its `SUPABASE_RLS_MATRIX.md` with the role model and the database-enforced invariants.
- The other project's sync layer: the schema verifier, the wizard SQL, the schema-version constant, and the drift-guard test asserting every `.from()` table is declared.
- Post-mortems supplying the traps: the interim-migration false drift, the upload-only sync gap, the over-broad delete block, and the idempotency-key choice in the payments integration.

The `check_in` function is a reconstruction that combines the documented behaviour (atomic walk-up check-in, capping at the next reservation) with the project's stated function conventions; it is not a verbatim copy of a migration.
