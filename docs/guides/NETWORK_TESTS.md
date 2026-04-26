# Network-tagged tests

This project keeps a small set of tests that hit **real, third-party**
endpoints — country fuel APIs, the Play Store, public URL constants,
and (when credentials are configured) a live Supabase project. They are
isolated behind the `@Tags(['network'])` directive so the default
`flutter test` invocation never runs them.

This doc is the contract. Read it before adding, removing, or rerunning
a network-tagged test.

## Why a separate tag

- **Upstream outages must not block PRs.** Italian MIMIT, Argentina
  `datos.energia.gob.ar`, Spain MITECO and others intermittently
  time out for hours at a stretch. A failing PR check on an upstream
  outage trains contributors to ignore CI — exactly the wrong signal.
- **Contributor onboarding stays fast.** A clean clone runs
  `flutter test` and gets a green bar in under two minutes without
  network egress. New contributors aren't forced to debug
  geocoder timeouts on the first day.
- **CI cost stays predictable.** Every PR run is offline-deterministic;
  flake re-runs are cheap because they don't queue behind a 60-second
  upstream timeout.

## How to run

```bash
# Full set (every @Tags(['network']) file)
flutter test --tags=network

# A subdirectory only
flutter test --tags=network test/security/

# A single file
flutter test --tags=network test/core/services/italy_search_live_test.dart
```

Some files require environment variables to do anything meaningful
(see the per-file inventory below). Files that detect missing credentials
print a skip notice and exit cleanly — they don't fail.

## CI behavior

The default CI test step **excludes** the tag, quoted from
`.github/workflows/ci.yml`:

```yaml
# Excludes the `network` tag — those tests hit real third-party
# APIs (Argentina, Italy MIMIT, etc.) that intermittently time out
# and cannot block PRs. Run them on demand with
# `flutter test --tags=network` from a workstation.
- run: flutter test --coverage --exclude-tags=network
```

The tag is declared in `dart_test.yaml` so the runner doesn't warn
about an unknown tag:

```yaml
tags:
  network:
    description: >
      Tests that hit real third-party APIs over the network. Intermittent
      upstream timeouts mean these cannot block PRs. Run on demand with
      `flutter test --tags=network`.
```

A weekly scheduled CI run does pick them up — `ci.yml` declares:

```yaml
schedule:
  - cron: '0 6 * * 0'
```

(Every Sunday at 06:00 UTC.) The `test` job in that scheduled run still
uses `--exclude-tags=network` today; teams that want network tests
gated on the schedule should either add a separate `network-tests` job
or override the exclude flag for the `schedule` event. For now,
network tests are a manual workstation responsibility — the schedule
mainly catches **non-network** drift (stale lockfile resolutions,
analyzer rule changes, etc.).

Tag releases also do not currently trigger network tests automatically.
The Supabase RLS test (see below) is the one that **should** ride a
release: when staging credentials are wired into the release workflow,
add a step `flutter test --tags=network test/security/supabase_rls_test.dart`.

## Per-file inventory

There are four files with a file-level `@Tags(['network'])` directive
today, plus three offline files that **reference** the tag in comments
(handoff notes for future work). The inventory covers both groups so
the comment trail doesn't become orphaned context.

### Tagged: hits the network

#### `test/core/services/api_connectivity_test.dart`

Country fuel-API reachability matrix. Probes Tankerkoenig (DE),
Prix-Carburants (FR), E-Control (AT), MITECO (ES), MIMIT station +
price CSVs (IT), OK + Shell APIs (DK), Argentina Energía CSV, and
Nominatim city search for every supported country.

- **Probes**: each country's upstream root endpoint with a small
  query, asserts HTTP status + a handful of schema invariants
  (field names, list lengths, parseable lat/lng).
- **Expected runtime**: 30 – 90 s end-to-end. The Argentina CSV step
  has a 90-second timeout; everything else is 15 – 30 s.
- **Re-run trigger**: after touching any
  `lib/core/services/impl/*_station_service.dart`, after a
  Nominatim user-agent or rate-limit change, or as a sanity check
  before tagging a release.

#### `test/core/services/italy_search_live_test.dart`

End-to-end live search against the Italian MISE provider. Asserts
the full pipeline (CSV download → parse → bounding-box filter →
distance calc) returns >0 stations for Rome and Milan.

- **Probes**: `MiseStationService.searchStations()` against
  `mimit.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv`
  + the price CSV.
- **Expected runtime**: 30 – 60 s per test (60 s timeout). The CSV
  is ~5 MB and the parser is purely client-side.
- **Re-run trigger**: any change to `mise_station_service.dart`,
  `mise_csv_parser.dart`, or the Italian bounding box. Also rerun
  if a user reports "Italy returns no results" — that's the bug
  this file was created for (#695).

#### `test/security/external_urls_reachable_test.dart`

Sanity-check that every user-facing URL constant in
`AppConstants` returns a non-error status. A 404 here is a visible
broken link from the Settings or About screens.

- **Probes**: `HEAD` request against `privacyPolicyUrl`,
  `githubRepoUrl`, `githubIssuesUrl`, `tankerkoenigRegistrationUrl`,
  `paypalUrl`, and `revolutUrl` (each with a 15 s timeout).
- **Expected runtime**: 5 – 15 s.
- **Re-run trigger**: after editing
  `lib/core/constants/app_constants.dart`, or when GitHub Pages
  for the privacy policy is reconfigured (#539).

#### `test/security/supabase_rls_test.dart`

Live verification of the Supabase Row-Level-Security policy matrix.
Calls the `public.audit_rls_policies()` SQL function (added by
migration `20260426000001_rls_audit_function.sql`) and asserts
every expected policy exists with the right command, no `public.*`
table is RLS-enabled-with-zero-policies, and no live table is
absent from the matrix.

- **Probes**: `POST /rest/v1/rpc/audit_rls_policies` against the
  Supabase project resolved from `SUPABASE_TEST_URL`, authenticated
  with `SUPABASE_TEST_SERVICE_KEY`. Skips cleanly if either env
  var is unset.
- **Expected runtime**: 5 – 15 s once the audit function is
  installed; the first call after a `supabase db push` may take
  longer because Postgres rebuilds the function cache.
- **Re-run trigger**: any migration under `supabase/migrations/`
  that touches `CREATE POLICY`, `ALTER TABLE … ENABLE/DISABLE ROW
  LEVEL SECURITY`, or adds a `public.*` table. Also rerun whenever
  `docs/security/SUPABASE_RLS_MATRIX.md` is edited — the matrix
  and the test must move together (#1110).

### Offline files that reference the tag (no live probe today)

These files don't carry the directive themselves — they document
the live counterpart or reserve a follow-up slot for a future test.
Listed here so the cross-reference doesn't bit-rot.

#### `test/core/services/impl/mise_station_service_test.dart`

Pure-parser tests for `MiseStationService`. The block comment near
line 360 explicitly directs live `searchStations()` coverage to
`italy_search_live_test.dart`. **Do not** add live probes here — the
intent is to keep this file deterministic and fast.

#### `test/core/sync/price_history_sync_test.dart`

Shape-only smoke tests for `PriceHistorySync`. The dartdoc points
the reader at `test/core/data/sync_repository_test.dart` for the
network-tagged equivalent (which lives one step out at the
repository layer). If that repository test is removed or moved,
update this dartdoc in the same PR.

#### `test/core/utils/payment_app_launcher_test.dart`

Includes the helper `assertLivePlayStoreListing()` annotated
`@visibleForTesting`. The catalog is empty today (#736) so no
network-tagged test calls it. **When a payment-app brand is
re-added**, add a `@Tags(['network'])` test in this file (or a
sibling) that calls the helper for the brand — the comment near
line 180 is the contract.

## When to add a network test

Add a network-tagged test only when **correctness depends on a
real external endpoint that is impractical to fake faithfully**:

- Live geocoder or country API contract drift (a CSV column gets
  renamed, a JSON field becomes nullable, a new auth header is
  required).
- Endpoint reachability (DNS, TLS, CDN, HTTP method support).
- Server-enforced authorization (Supabase RLS — the postures we
  care about are silent-fail, not exception-throw).
- Browser-visible URL aliveness (the user taps and lands on a 404).

Do **not** use a network-tagged test for:

- Schema parsing — model that with a checked-in fixture and a
  pure-Dart parser test instead.
- Anything that can be expressed with `Dio` interceptors and a
  fake response — those belong in the offline suite.
- "Make the green bar greener" coverage. Network tests are a
  contract-drift alarm, not a coverage tool.

When you add one, also:

1. Add a top-of-file dartdoc (2 – 4 lines) describing the
   upstream and the re-run trigger. Match the style above.
2. Add an entry to the per-file inventory in this doc.
3. If the test needs credentials, gate them on env vars and
   `skip:` cleanly when absent (mirror `supabase_rls_test.dart`).
