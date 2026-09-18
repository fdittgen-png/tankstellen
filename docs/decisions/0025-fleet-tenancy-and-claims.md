<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0025: Fleet tenancy and claims — org-scoped tables behind oracles, RPC-only writes, and every fleet number declares what it is (#4212, #4219)

**Status:** Accepted
**Date:** 2026-09-18
**Issue:** #4212 (tenancy + privacy-first data model), #4219 (claim / provenance framework) — both children of Epic #4211
**Related:** ADR 0002 (local-first), ADR 0022 (one consumption contract), #4049 (trip-share ownership binding), #4160 (`DataValue`), Epic #3865 (GDPR), #2929 (HARD RULE #5 schema parity)

## Context

Epic #4211 extends Sparkilo from a personal fuel assistant into a
fleet-aware layer: an employee identifies a company car, refuels where it
is worth it, files a receipt; a manager sees aggregate cost, consumption
and CO2e — and never a live employee map. Two children have to be decided
before any of the others can be built:

- **#4212** — where fleet data lives, who may read it, and how the
  existing `user_id = auth.uid()` world acquires a *second* tenancy
  boundary without a single client-side `INSERT` policy on an
  organisation's rows.
- **#4219** — what a fleet-facing number *is*: a fact somebody measured,
  a calculation, an estimate, an accounting candidate awaiting company
  approval, an environmental estimate under a named factor, or an
  inference about a person. The UI must never blur these, and a report
  without a factor says "not calculated" rather than substituting one.

### What exists and shapes the decision

- **Every synced entity is user-scoped by construction.** `EntitySync<T>`
  encodes `(record, userId)` and the transport hard-filters
  `.eq('user_id', userId)` (`lib/core/sync/entity_sync.dart`,
  `sync_transport.dart`). An organisation's vehicle is not the uploading
  employee's row. Org-owned rows therefore cannot ride on `EntitySync`;
  they need a separate, *read-only* client path, and every org write goes
  through a server function that re-checks role and org.
- **Membership-scoped RLS recurses unless an oracle breaks the cycle.**
  A `fleet_vehicles` policy that queries `fleet_members` whose policy
  queries `fleet_vehicles` never terminates. #4049 solved the same shape
  with `public.owns_trip` — a `SECURITY DEFINER` function pinned to
  `SET search_path = public`, `REVOKE … FROM PUBLIC`, `GRANT … TO
  authenticated`, and an explicit `REVOKE … FROM anon` (Supabase grants
  `anon` separately; the security advisor flagged the omission once
  already). The wizard emits such functions **before** `rlsSql`, because
  `CREATE POLICY` resolves functions at creation time.
- **The schema-parity gate is bidirectional** (HARD RULE #5,
  `test/core/sync/schema_verifier_completeness_test.dart`): a table the
  wizard creates must be one the client reads, and vice versa. Fleet
  schema and its first client reader land in **one** change.
- **The trust vocabulary already exists.** `DataValue<T>` (#4160) is the
  app-wide "measured / estimated / stale / unknown-with-reason" shape;
  `ConsumptionSourceClass` (ADR 0022) names *which branch* produced a
  fuel figure. #4219's claim classes sit *above* both: a claim says what
  a number may be used for, not how trusted it is.
- **`Co2Calculator`** (`lib/core/services/co2_calculator.dart`) carries
  eight constants with a prose source ("EU JEC WTW v5 (2020)") and no
  version, scope or geography metadata, and returns `0` for an
  unsupported fuel — the exact "undocumented substitute" #4219 forbids.
  Its personal-dashboard callers must keep their behaviour.
- **Identity is anonymous-per-device until upgraded to e-mail**
  (`supabase_client.dart`, `upgradeAnonymousToEmail`). A membership on an
  anonymous UUID would be lost on reinstall and is unauditable.
- **Three sync modes** (`SyncMode.community | joinExisting | private`).
  On the shared community project, one processor would hold personal
  and employer data side by side.
- **GDPR wiring** (Epic #3865): `docs/privacy/data_inventory.json` is
  the source of truth; a policy-version bump re-translates 23 policy
  pages; erasure is registry-driven (`erase_my_data()`, `HiveBoxes.
  allBoxes`); the export set is a superset of the deletion set.
- **No paid services.** Fuel-card provider APIs, e-invoicing platforms
  and cloud OCR are out. Everything below runs on Supabase (self-host or
  community) and on-device.

## Decision

The ten decisions below were taken by the maintainer on 2026-09-18 and
are binding for every slice of Epic #4211. They are numbered D1–D10 so
later ADRs and issues can cite them.

### D1 — Tenant model: `org_id` tables, explicit membership, explicit roles

Every org-owned table carries `org_id`. Membership is one row per
`(org_id, user_id)` in `fleet_members`, with an **explicit** `role`
(`employee | manager | admin`) — never inferred from `database_owner`,
never from a generic admin flag. **One organisation per user in v1**
(`fleet_members` is unique on `user_id`); multi-org is a later schema
change, not a v1 ambiguity.

Tables (all in `supabase/migrations/20260918000001_fleet_tenancy.sql`,
mirrored in the wizard SQL):

| Table | Owner | Key | Purpose |
|---|---|---|---|
| `fleet_organizations` | org | `id` | The tenant. `name`, `created_by` (nullable, `ON DELETE SET NULL`). |
| `fleet_members` | user-linked | `(org_id, user_id)`, unique `user_id` | Role + status per member. |
| `fleet_vehicles` | org | `id`, unique `(org_id, fleet_code)` | The stable company asset: `fleet_code`, `display_name`, `plate_masked`, JSONB `data`. |
| `vehicle_assignments` | user-linked | `id` | **Effective-dated** link vehicle → employee: `effective_from`, `effective_to` (null = open). |
| `fleet_policies` | org | `org_id` | JSONB `data`: thresholds, retention, allowed networks (D9). |

`fleet_vehicles` never references a personal `VehicleProfile`; the
employee's local profile may reference the fleet vehicle id (F4). No
migration infers an employer relationship from an existing personal
vehicle — fleet mode is additive.

### D2 — Identity: fleet membership requires the e-mail-upgraded identity

Joining or creating a fleet requires the e-mail-upgraded TankSync
identity. An anonymous identity sees the join control **disabled with a
reason** (the wording lives in ARB, F8). Server-side the RPCs refuse a
JWT whose `is_anonymous` claim is true, so the rule holds even for a
client that skipped the UI.

### D3 — Backend: fleet mode only on `private` / `joinExisting`

Fleet mode is offered only when `SyncMode` is `private` or
`joinExisting`. The community backend never hosts an organisation: the
`fleet_create_organization` RPC checks a `tanksync_meta` row
`fleet_enabled = 'true'` that only the self-host operator sets (via the
SQL editor / service role — `tanksync_meta` has no client write policy).
On the community project that row does not exist, so creation fails
closed. This also keeps community users out of the fleet privacy-policy
bump (D6).

### D4 — Offline: explicit stale state, no silent fallback

The client caches the org directory (organisation, vehicles, the
caller's assignments, policies) under a key of
`SyncContextKey | orgId` — backend host **and** account **and** org, so
a directory can never be shown to another account, on another backend,
or for another org. Freshness is explicit and three-valued:

| Age of cache | State | Vehicle selection |
|---|---|---|
| < 24 h | `fresh` | enabled |
| 24 h – 7 d | `stale` (badge) | enabled, labelled stale |
| ≥ 7 d | `expired` | **disabled** until a pull succeeds |

No auto-switch of the current vehicle, no fallback to another vehicle
or org, ever. A pull that fails leaves the previous cache in place with
its own age; it never fabricates a fresher one.

### D5 — Privacy-first hard rules (v1)

1. **No manager read policy** on `trip_summaries`, `trip_details` or
   `obd2_baselines`. Those tables keep their `user_id = auth.uid()`
   policies untouched; fleet adds nothing to them.
2. **No location column** in any fleet table — not lat/lon, not a
   geohash, not a station id that resolves to one. Fleet rows describe
   assets, memberships, assignments and policies.
3. **Per-vehicle rows are suppressed** in every aggregate below the
   org's `aggregationMinSamples` (D9); a one-employee fleet sees totals,
   never a per-vehicle line that is one person.
4. **Every manager read or export is audited** — a `fleet_audit_events`
   row per privileged call (table lands with the first manager surface,
   F7/F9; F2 ships no manager read path, so it ships no audit table).
5. Raw-journey purpose grants (the "explicit purpose only" column of the
   visibility matrix) are **out of scope** for this epic. There is no
   schema, policy or UI for them; "not default" means "does not exist".

#### Visibility matrix (from #4212, now binding)

| Data | Employee | Fleet manager | Admin / auditor |
|---|---|---|---|
| Assigned vehicle | own, current + history | org scope | org scope |
| Fill-up / expense | own submissions | org aggregate + permitted detail (non-draft expenses, F7) | policy-dependent, audited |
| Cost / km | own | org aggregate (≥ min samples) | same as manager |
| Raw GPS journey | own, where enabled | **none** (D5.1) | **none in v1** (D5.5) |
| Driving behaviour | own coaching | aggregate / exception only, never a ranking | **none in v1** |
| OBD raw telemetry | own diagnostics | **none** (D5.1) | **none in v1** |
| Receipt image | own submission | only inside the expense workflow, audited | policy-dependent, audited |
| Org directory (vehicles, policies) | read | read + write via RPC | read + write via RPC |
| Membership rows | own row | org scope | org scope |

### D6 — Privacy-policy bump: once, with the manager dashboard (F9)

`docs/privacy/data_inventory.json` stays at `policyVersion: 3` through
F0–F8. Fleet slices before F9 ship behind beta-only channel availability
and touch no policy page. F9 bumps to v4 in one coordinated change
(inventory, `AppConstants.privacyPolicyVersion`, 23 policy pages,
`DATA_SAFETY.md`, xcprivacy).

### D7 — Org writes are RPC-only

There is **no** client `INSERT`, `UPDATE` or `DELETE` policy on
`fleet_organizations`, `fleet_members`, `fleet_vehicles`,
`vehicle_assignments` or `fleet_policies`. Every write is a
`SECURITY DEFINER` RPC that re-checks `auth.uid()`, the org and the
caller's role inside its body, because a definer function bypasses RLS
and the policies are never consulted (#4049's third surface):

| RPC | Role required | Effect |
|---|---|---|
| `fleet_create_organization(p_name)` | any e-mail identity; `fleet_enabled` (D3); not already a member (D1) | inserts org, the caller as `admin`, an empty policy row; returns the org id |
| `fleet_upsert_vehicle(p_org, p_id, p_fleet_code, p_display_name, p_plate_masked, p_data)` | `manager` / `admin` of `p_org` | inserts or updates one vehicle; returns its id |
| `fleet_assign_vehicle(p_org, p_fleet_vehicle_id, p_user, p_effective_from)` | `manager` / `admin`; target is a member; vehicle belongs to the org | opens an assignment (idempotent on an already-open one); returns its id |
| `fleet_end_assignment(p_assignment_id, p_effective_to)` | `manager` / `admin` of the row's org | sets `effective_to`; **never deletes** |

The read side is RLS through two oracles — `is_fleet_member(org, user)`
and `fleet_role(org, user)` — emitted with `ownershipFnSql` so they
exist before the policies that call them. Employees read the org
directory and their **own** assignments; managers read org-wide. A
`vehicle_assignments` row is history: ending one stamps `effective_to`,
so a fill-up recorded during the assignment stays attributed to it.

### D8 — CO2: the registry carries TtW and WtW, labelled; reports default to WtW

`EmissionFactorRegistry` (F1) is versioned: every factor names its
source, version, publication date, unit, scope (`tankToWheel` /
`wellToWheel`), fuel key and geography. A lookup that finds no published
factor for `(fuel, scope, geography)` returns
`DataValue.unknown(notPublishedForThisItem)` — never `0`, never a
neighbour's factor. Fleet reports label the scope and default to
**well-to-wheel** so they agree with the personal carbon dashboard,
which `Co2Calculator` computes unchanged.

The v1 seed publishes exactly the eight WtW values `Co2Calculator`
already ships, tagged "EU JEC WTW v5 (2020)", and **no TtW values**:
the app can cite none today, and inventing them is what this ADR
forbids. TtW lookups therefore say "not calculated" until a cited table
is added. See Consequences for the review this inherits.

### D9 — Thresholds and retention are deployment configuration

Numbers live in `fleet_policies.data` per organisation, seeded with
placeholder defaults that are **documented as deployment configuration,
not legal conclusions** (#4211: "legal basis and employment / works-
council requirements remain deployment-specific"):

| Key | Placeholder default | Meaning |
|---|---|---|
| `aggregationMinSamples` | `5` | below this, a per-vehicle / per-person row is suppressed (D5.3) |
| `retention.expensesYears` | `10` | accounting documents |
| `retention.attributionEventsMonths` | `12` | vehicle-attribution evidence (F4) |
| `retention.auditYears` | `3` | privileged-access audit events |

#### Data-class matrix: purpose · retention · roles · export · erasure

| Data class | Purpose (why it exists) | Retention (D9 key) | Who reads | In the user's export | On erasure (`erase_my_data`) |
|---|---|---|---|---|---|
| Organisation, vehicles, policies | run the fleet | life of the org | members (R), managers (RW via RPC) | no — not the user's data | untouched; `created_by` → NULL |
| Membership row | tenancy + role | until left / erased | own row; managers org-wide | yes (`server/fleet_members.json`) | **deleted** (`fleet_members.user_id`) |
| Vehicle assignment | attribute fill-ups / trips to the right car over time | `attributionEventsMonths` after `effective_to` | own rows; managers org-wide | yes (`server/vehicle_assignments.json`) | **deleted** (`vehicle_assignments.user_id`) — the org keeps the vehicle, loses "who drove it" |
| Local directory cache | offline vehicle selection (D4) | overwritten per pull; hard-expired at 7 d | this device | yes (`local/fleet_directory.json`) | wiped (`HiveBoxes.allBoxes`) |
| Fill-up / expense / document (F5/F7) | reimbursement, accounting | `expensesYears` | own; managers non-draft only | yes | user-owned rows deleted; accounting copies the org exported before erasure are the org's controller responsibility |
| Attribution evidence (F4) | explain why a vehicle was chosen | `attributionEventsMonths` | own | yes | deleted |
| Audit events (F7/F9) | GDPR Art. 30-style accountability for privileged access | `auditYears` | admin / auditor | the subject's own access rows | retained (legal-obligation basis — deployment config) |
| Raw GPS / OBD telemetry | personal coaching, diagnostics | unchanged | **own only** (D5.1) | yes (already) | unchanged (already) |

Controller/processor responsibility, lawful-basis references and
employee transparency text are **customer-supplied metadata** carried in
`fleet_policies.data` (keys reserved: `controller`, `lawfulBasisRef`,
`transparencyTextRef`) and rendered, never authored, by the app.

### D10 — Information architecture: no new shell

The six-branch shell and its intent labels (#4143) stay. Fleet manager
screens are a route family reached from **Settings → Fleet** (F8/F9).
The employee's "Current vehicle" is a compact context control on the
surfaces that need it (F4/F10), not a tab.

### Claim taxonomy (#4219 part 1) — binding for every fleet-facing number

Every fleet KPI is a `ClaimedValue<T>` (F1): a `DataValue<T>` (trust),
a `ClaimClass` (what the number may be used for), a sample count, and
the list of `FleetMetricSource`s it was built from.

| # | `ClaimClass` | Definition | Example | Rendering rule |
|---|---|---|---|---|
| 1 | `measuredFact` | Observed by the app or confirmed by the employee | litres and price from a confirmed fill-up / receipt | plain number; may carry "when" |
| 2 | `calculatedOperational` | Arithmetic over measured facts only | €/km from measured cost and measured distance | plain number; formula available on request |
| 3 | `estimate` | Any input was modelled or stale | GPS / MAF consumption; €/km built on an estimate | **always** `≈`; basis named |
| 4 | `accountingCandidate` | Could enter a reimbursement / VAT workflow **after** human and company confirmation | an expense assembled from a receipt | status badge (draft → … → exported); never a total labelled "reimbursable" |
| 5 | `environmentalEstimate` | CO2 / CO2e under a **named** factor, version and scope | 42 kg CO2e (WtW, JEC v5 2020) | factor version + scope beside the number; "not calculated" when no factor |
| 6 | `personalDataInference` | Derived from an identifiable person's activity | driving-behaviour residual, journey pattern | own-only; aggregate / exception at manager level; every privileged read audited |

Rules the type enforces (tested in `test/core/domain/fleet/`):

- `ClaimedValue.measuredFact` refuses a modelled value or an estimating
  source; `map` keeps the class; `derive` refuses `measuredFact` as a
  target and degrades `calculatedOperational` to `estimate` when any
  input is qualified. **An estimate can never be promoted to measured.**
- An `Unknown` input stays `Unknown` with its reason through every
  derivation — a CO2 figure without a factor has no number to show.
- `FleetMetricSource` is the #4212 vocabulary (`measured_fill_up`,
  `obd_measured`, `gps_estimated`, `imported`, `derived`) plus
  `obd_estimated`: ADR 0022's `ConsumptionSourceClass.estimated` is a
  MAF / speed-density litre with the pump gain applied — an engine-data
  *estimate*. Folding it into `obd_measured` would be the promotion this
  taxonomy forbids; folding it into `gps_estimated` would misstate its
  inputs. The mapping from `ConsumptionSourceClass` is exhaustive.
- `imported` is asserted by a third party, not observed by the app: it
  becomes a `measuredFact` only after employee confirmation, and keeps
  `imported` in its provenance list when it does.

### Reimbursement / accounting state boundary

A receipt being authentic says nothing about reimbursement. Five states
are kept **separately** on an expense (F5) and none implies the next:

```
source document → extracted value → employee confirmation → company approval → accounting / export status
```

`ExpenseStatus` (F5): `draft → needsReview → submitted → approved |
rejected → exported → archived`. `draft → approved` is not a legal
transition; receipt presence never sets anything past `draft`. Totals,
VAT and reimbursement amount are three fields, never one.

### UI wording rules (binding for every fleet ARB key)

1. A class-3 or class-5 number is never shown without `≈` and its
   basis / factor label; the label is part of the value widget, not a
   footnote.
2. The words *deductible*, *tax-compliant*, *official*, *certified*,
   *reimbursable* and *disclosure* do not appear unless the deployment
   has configured the applicable rule (`fleet_policies.data`), and then
   only with the configured source named in the same sentence.
3. "Not calculated" (with the reason from `DataUnknownReason`) is the
   only rendering of an `Unknown`; never `0`, never `—` without a
   reason, never a neighbour's value.
4. Manager surfaces name the aggregation threshold when a row is
   suppressed ("fewer than 5 samples"), so absence is explained.
5. No sound, voice or spoken output anywhere in fleet mode (#4211).

### What never leaves the device

- Raw GPS samples and OBD frames beyond what the user already syncs
  under their own `user_id` (trip sync consent) — fleet adds no upload.
- Receipt image bytes never enter a log, trace or crash report; the OCR
  trace package excludes them (F5 test).
- The attribution evidence (adapter MAC, VIN, iOS peripheral UUID) used
  to pick a vehicle (F4): only the resulting `fleetVehicleId` plus a
  confidence label rides inside `fill_ups.data`.
- The e-mail address behind the identity: server RPCs return ids and
  outcomes, never addresses (the #3747 pattern).

## Consequences

- **Two sync paths.** Org-owned rows are pull-only through a dedicated
  `FleetTransport` that can address exactly the five fleet tables; user-
  owned fleet rows (expenses, documents, F7) use `EntitySync` unchanged.
  `sync_transport.dart` / `entity_sync.dart` are not touched.
- **Schema version 12 → 13.** Five tables, two oracles, four RPCs and
  the `erase_my_data()` amendment reach the wizard SQL and both goldens
  in one change; a self-host that has not re-run the SQL is flagged.
- **Erasure semantics are asymmetric on purpose.** Erasing an employee
  deletes their membership and assignment rows (and, via `ON DELETE
  CASCADE` from `public.users`, anything else keyed on them) but leaves
  the organisation's vehicles and policies. The org's controller
  obligations for accounting copies are its own (D9 matrix).
- **The inherited CO2 values are owed a source review.** `Co2Calculator`
  labels its constants WTW, yet 2.31 kg/L (petrol) and 2.65 kg/L
  (diesel) coincide with the widely published *tank-to-wheel* combustion
  factors, and E85 at 1.40 reads like a biogenic-credited pathway. The
  registry records the label the app currently asserts; it does not
  correct it. Verifying each value against the cited JEC tables — and
  adding cited TtW entries — is a follow-up issue, not something a
  provenance slice may do by fiat.
- **RPC-only writes mean no offline org edits.** A manager without
  connectivity cannot assign a vehicle; that is accepted for v1 (D4 has
  no write cache).
- **`fleet_enabled` is an operator switch in `tanksync_meta`**, which
  the wizard does not set. Self-host operators who want fleet mode run
  one `INSERT` documented with the migration.
- **The live RLS matrix is owed.** CI holds the SQL text to the contract
  (`fleet_rls_contract_test.dart`); the behavioural proof (two orgs
  cannot see each other; ended assignments keep history; anon cannot
  call an oracle; an employee cannot call a manager RPC) runs against
  the maintainer project with the live-RPC skill and is pasted into the
  F2 PR.
- **Later slices consume, never re-decide.** F3 registers the
  capability; F4 the vehicle identity; F5/F7 expenses; F6 the policy
  pre-filter; F8 onboarding + Settings → Fleet; F9 the manager
  dashboard, the audit table and the v4 policy bump; F10 the IA pass.

## Alternatives Considered

- **Org-scoped `EntitySync` variant** — rejected: the engine's contract
  is "the caller owns every row it writes"; teaching it org rows would
  put a second ownership model into the one file every synced entity
  depends on, during the #4387 lifecycle rewrite.
- **Client `INSERT`/`UPDATE` policies with `fleet_role(...)` checks** —
  rejected: #4049 showed the class of bug (a row proving who wrote it,
  never that they were allowed to). RPCs re-checking role *inside* the
  definer body close the whole class.
- **Fleet on the community backend** — rejected (D3): one processor
  for personal and employer data, a policy bump for every community
  user, and no operator to answer for the org's controller obligations.
- **Anonymous identities may join** — rejected (D2): unauditable and
  lost on reinstall.
- **Inferring roles from `database_owner`** — rejected: the owner of a
  self-host is an operator, not a fleet manager of every org on it.
- **Auto-switching the current vehicle when the assignment changes** —
  rejected (D4): a silent switch re-attributes fill-ups; the employee
  selects, the app never guesses.
- **Correcting the CO2 constants inside F1** — rejected: a provenance
  slice records what is claimed; changing the number changes the
  personal dashboard for every user and needs its own cited change.
- **Five `FleetMetricSource` values exactly as #4212 lists** — rejected
  for the one added `obd_estimated`: the alternative was to misfile a
  pump-gained MAF litre as measured or as GPS.
- **A materialised `fleet_metrics` table in F2** — deferred to F9 as an
  RPC / view; nothing reads it yet and a table without a reader fails
  the parity gate by design.
- **Bumping the privacy policy now** — rejected (D6): 23 translated
  pages for surfaces that do not exist yet.
