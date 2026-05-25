<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Test-suite audit — May 2026

**Issue**: #1579 (parent epic #1578, CI optimisation).

**Scope**: every `.dart` file under `test/`. 987 test files, 10620+ test cases
at audit time.

**Goal**: identify tests that can be removed **without** reducing quality —
either because they're redundant with another test, obsolete (testing a
feature that no longer exists), trivially low-value (testing language
guarantees), or superseded by newer coverage.

**Process**: no test is removed in this PR. Each removal lands as its own
PR referencing the row it deletes from this doc, so the rationale is
visible in the commit history and a reviewer can sanity-check the
citation before approving.

---

## Category 1 — Redundant route-structure tests

`test/app/routes/*_routes_test.dart` all follow the same pattern: route
count + path-per-index + `isA<GoRoute>` + `builder != null`. `shell_branches_test.dart`
already does this for the canonical branch list; the per-feature variants
add no information.

| File | Lines | Why redundant | Recommendation |
|---|---|---|---|
| `test/app/routes/onboarding_routes_test.dart` | 6-42 (all) | Same pattern as `shell_branches_test.dart` lines 7-54 | **Remove** |
| `test/app/routes/search_routes_test.dart` | 6-54 (all) | Same pattern | **Remove** |
| `test/app/routes/profile_routes_test.dart` | 6-66 (all) | Same pattern | **Remove** |
| `test/app/routes/sync_routes_test.dart` | 6-54 (all) | Same pattern | **Remove** |
| `test/app/routes/consumption_routes_test.dart` | 6-96 | Structural part redundant; child-route `DescriptionWrapper` logic at lines 97+ is unique — keep that | **Trim** to the unique lines only |

**Better path**: consolidate into one parameterised
`test/app/routes/routes_structure_test.dart` that takes
`(routes, expectedCount, expectedPaths)` and runs the same assertions
for each route list. ~150 lines saved.

---

## Category 2 — Obsolete legacy migration tests (conditional)

The `legacy_toggle_migrator` was the one-shot migration that copied
`UserProfile.{showFuel,showElectric,showConsumptionTab,autoRecord,…}`
bools into the central `featureFlagsProvider` (#1373 phase 3 series).

| File | Lines | Status | Recommendation |
|---|---|---|---|
| `test/features/feature_management/data/legacy_toggle_migrator_test.dart` | ~1295 | Tests migration math for ~7 legacy toggles | **Archive after #1373 milestone closes + a release in which the migration has converged for the entire user base.** Until then it's load-bearing — a botched migration loses user state silently. |
| `test/features/feature_management/application/legacy_toggle_migration_at_startup_wiring_test.dart` | ~109 | Wiring-only test (does startup call the migrator?) | **Remove with the migrator itself** — wiring test has no value if the migrator is gone |

**Verification**: `grep -r 'migrateLegacyToggles' lib/` shows the function
is called once in `legacy_toggle_migration_provider.dart`. Once the
migration is permanently retired in a future release, both the migrator
and these tests come out together in one PR.

---

## Category 3 — Trivially low-value tests

Tests that exercise language or framework guarantees rather than project
behaviour.

| File | Lines | Why low-value | Recommendation |
|---|---|---|---|
| `test/app/shell/shell_nav_item_test.dart` | 19-50 | Const constructor parameter pass-through — Dart's type system already enforces this | **Remove** the constructor tests; **keep** the `ShellBounceIcon` animation-math tests at lines 53-188 |
| `test/app/shell/shell_nav_item_test.dart` | 87-108 | `Icon` pass-through (Material widget pixels) — framework concern, not project | **Remove** |

---

## Category 4 — Superseded by core-logic tests

The "shim provider" tests in `test/features/profile/providers/show_*_enabled_provider_test.dart`
each cover a thin wrapper around `featureFlagsProvider`. The provider
itself does no logic — it just calls `isEffectivelyEnabled`. The core
gate is already tested elsewhere.

| File | Lines | Superseded by | Recommendation |
|---|---|---|---|
| `test/features/profile/providers/show_consumption_tab_enabled_provider_test.dart` | 1-259 | `test/features/feature_management/consumption_tab_visibility_test.dart` (the OR-gate logic) + `app_profile_test.dart` (bundle membership) | **Remove** |
| `test/features/profile/providers/show_fuel_enabled_provider_test.dart` | full | `app_profile_test.dart` + feature manifest tests | **Remove** |
| `test/features/profile/providers/show_electric_enabled_provider_test.dart` | full | `app_profile_test.dart` + feature manifest tests | **Remove** |
| `test/app/shell_consumption_tab_test.dart` | 124-146 (icon-ordering block) | `test/app/shell/shell_destinations_test.dart` lines 70-87 already asserts Settings is rightmost in both consumption-on/off states | **Trim** the icon-ordering block; keep the 5-tab count test if it's not duplicated |

---

## Estimated impact

- **Immediate-safe removals**: ~5 route tests (~200 lines), 3 shim provider
  tests (~750 lines), trivial const/Icon tests (~100 lines). **~1 050 lines**
  removed, no behaviour uncovered.
- **Conditional removals** (after #1373 milestone closes + migration
  converges): legacy migrator + wiring (~1 400 lines).
- **Test-runtime impact**: hard to measure without running both
  configurations, but the shim provider tests are widget-tester pumps
  (slow) and the route tests instantiate `GoRoute` (fast); expect a
  modest but real shard-time reduction.

---

## Out of scope (deferred / keep)

- **Flaky network tests** (italy_search_live, share_plus plugin) — see
  #1584 for the tag-and-move-to-nightly plan. Not redundant; just
  shouldn't gate PR merges.
- **The 5 shell-screen test files** — they look duplicative on the
  surface but each tests a different gating signal (responsive width,
  vehicle presence, feature flags). Keep all five.

---

## Mechanism for each removal

1. One PR per row in this doc.
2. PR body cites the row + the superseding test (file:line).
3. CI proves the suite still passes; reviewer eye-checks the citation.
4. Once removed, strike the row through here (`~~row~~`).

This audit doc is not a removal list — it's a backlog of justified
candidates. The CI optimisations in #1580-#1585 are the load-bearing
wins; this is the long-tail cleanup.
