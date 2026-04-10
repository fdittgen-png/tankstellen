# ADR 0008: Storage backend evaluation for v5.x (Hive vs Isar vs Drift)

**Status:** Accepted
**Date:** 2026-04-08
**Supersedes (partially):** [ADR 0004](0004-hive-for-storage.md) — re-validates the Hive choice for v5.x
**Related issue:** [#23](https://github.com/fdittgen/tankstellen/issues/23)
**Related risk:** R-02 (Hive in maintenance-only mode)

## Context

Hive 2.2.3 is in maintenance-only mode. The original author (Simon Leier)
moved focus to **Isar**, and the official `hive` pub package has not
received a feature release since June 2022 (`2.2.3`). Risk R-02 in the
risk analysis flags this as a medium-term threat: a future Flutter SDK
bump could expose a latent bug in Hive that will not be fixed upstream.

This ADR evaluates whether to migrate off Hive for v5.x (beta launch
targeted July 2026) and, if so, to what.

### What we currently store

Six encrypted Hive boxes (see `lib/core/storage/hive_boxes.dart`):

| Box             | Typical size           | Access pattern            |
|-----------------|------------------------|---------------------------|
| `settings`      | < 50 entries           | key/value lookups         |
| `favorites`     | 10-200 entries         | list + per-station lookup |
| `profiles`      | 1-10 entries           | key/value by profile ID   |
| `cache`         | 100-2000 entries, ~2KB | key/value with TTL meta   |
| `price_history` | ~30 entries/station    | list append + range scan  |
| `alerts`        | 1-50 entries           | full scan                 |

All boxes are AES-encrypted with a key stored in `FlutterSecureStorage`
(Android Keystore / Windows DPAPI). All six domain stores live in
`lib/core/storage/stores/` behind the `StorageRepository` interface, so
the blast radius of any backend swap is bounded by that facade.

**Data shape:** everything is stored as `Map<String, dynamic>` from JSON
serialisation of freezed models. We do not register Hive TypeAdapters.
This is important — it means we pay the JSON encode/decode cost on every
read and write today, and it means a new backend does not need to
re-derive type adapters.

**Touched files (as of this ADR):**
16 files import `Hive.` or `hive_flutter` — 10 under `lib/core/storage/`,
2 in sync/profile data layers, 3 in profile/consent presentation, and
the error-tracing store. Tests touch Hive through `HiveStorage.initForTest()`.

## Why consider migration now

1. **Maintenance risk (R-02):** 2+ years without a feature release. A
   Flutter SDK update could ship an incompatible dependency constraint.
2. **Hive 4 (a.k.a. "Isar-backed Hive") is not coming:** the v2→v4 roadmap
   was abandoned; v3 was briefly tagged and retracted.
3. **Query power:** price history "best time to fill" analytics currently
   loads every record for a station into memory and filters in Dart.
   Even at 30 days this is cheap, but the feature set is growing.
4. **Web / desktop parity:** Hive works on web but has known flakiness
   with encryption + IndexedDB. v5 is Android-first but iOS is planned.

## Option A — Migrate to Isar

**Package:** `isar` 3.1.0+1 (stable; last release Nov 2023).
**Note:** `isar_community` (a fork under active volunteer maintenance) is
being published; Isar v4 is under development but not production-ready.

**Pros**
- Same author as Hive, so mental model is similar.
- Actual query language (indexes, `where` clauses, sorting) for price
  history analytics without loading everything into memory.
- Much larger data capacity (multi-GB) — future-proof for crowdsourced
  price uploads.
- Lazy loading of objects: big win for cache boxes.
- Built-in encryption via `encryptionKey` parameter (AES-256).

**Cons**
- **Native dependency** (NDK, CocoaPods, Windows DLL). Adds build
  complexity, increases APK size by ~4MB per ABI, breaks pure-Dart tests
  (needs `Isar.initializeIsarCore(download: true)` in test setup).
- **Upstream uncertainty:** Isar 3.x is also maintenance-only; v4 is a
  rewrite without a ship date. Swapping one maintenance-mode package for
  another does not retire R-02.
- Requires `@Collection()` annotations and codegen — every model that
  currently round-trips through JSON needs an Isar schema.
- Isolate model is different (instance-per-isolate) — our WorkManager
  init path in `HiveBoxes.initInIsolate()` would need a full rewrite.
- Web support is experimental and does not support encryption.

## Option B — Migrate to Drift (formerly Moor)

**Package:** `drift` 2.x (active; monthly releases throughout 2025).

**Pros**
- **Actively maintained**, well-funded, Flutter-team-adjacent. Retires R-02.
- Type-safe SQL with compile-time checked queries.
- First-class **schema migrations** via `MigrationStrategy` (Hive has none).
- Real relational model for price history, ratings, and favorites.
- Excellent web support (sql.js + IndexedDB) and desktop via sqlite3.
- `drift_flutter` ships isolate helpers out of the box.
- Transactions across multiple tables (we would retire the ad-hoc
  "write-then-rollback-on-fail" gymnastics in the sync layer).

**Cons**
- **Paradigm shift:** key/value semantics → relational tables. Six boxes
  become ~10-12 tables with a well-defined schema. This is real work.
- Every domain store (`*_hive_store.dart`) must be rewritten and every
  test fixture regenerated. Estimated 40-60 touched files including tests.
- SQLCipher (encrypted SQLite) adds ~1.5MB per ABI and requires a
  platform-specific setup; alternatively we keep file-level encryption
  at the OS layer and treat the DB as unencrypted at rest.
- `sqflite` / `sqlite3_flutter_libs` is a native dep — same build
  complexity concerns as Isar, but more battle-tested on Flutter.
- Cold-start reads are slower than Hive's memory-mapped boxes (low tens
  of ms for typical queries vs single-digit ms for Hive).

## Option C — Stay on Hive (do nothing for v5.x)

**Pros**
- **Zero migration cost.** 1079 tests keep passing. No user data migration.
- Fastest cold reads in the benchmark (memory-mapped, zero-copy).
- Pure Dart — no NDK, no CocoaPods, no DLL, no codegen for schema.
- Isolate story is simple and works today.
- If Hive ever truly breaks, `hive_ce` (community edition, active fork)
  is a drop-in replacement with identical APIs and file format. This is
  a meaningful escape hatch that costs ~1 day of work to adopt.

**Cons**
- R-02 remains open. If a Flutter SDK bump breaks `hive 2.2.3`, we have
  to switch to `hive_ce` under time pressure instead of on our own
  schedule.
- No SQL — analytics features stay in-memory.
- No built-in schema migrations — we keep hand-rolling migration code
  like `_migrateToEncrypted()` in `hive_boxes.dart`.

## Migration cost estimate

| Target      | Files touched | Test rewrites | Data migration | Build delta |
|-------------|---------------|---------------|----------------|-------------|
| Hive → Isar | ~25           | ~30           | Custom copier  | +4MB/ABI + native dep |
| Hive → Drift| ~40-60        | ~50-80        | Custom copier  | +1.5MB/ABI + native dep |
| Hive → hive_ce (escape hatch) | ~3 | 0 | None (format compatible) | 0 |

**Effort estimates:** Isar: 8-12 developer days. Drift: 15-25 developer
days (includes schema design). hive_ce drop-in: 1 day.

**Shared migration work for A or B:** A one-shot `StorageMigrator`
service that reads every Hive box on first launch of the new version,
writes into the new backend, verifies counts, then deletes the old
boxes. Backwards compatibility means shipping both `hive` and the new
dependency in one release, doing the migration, then removing Hive in
the following release.

## Decision

**Stay on Hive for v5.x, with `hive_ce` pre-vetted as our escape hatch.**

Rationale:

1. The facade pattern (`StorageRepository` + domain stores) already gives
   us the main benefit a migration would bring — backend portability.
   The evaluation itself is most of the value; we do not need to spend
   2-4 weeks of the v5 budget on a migration that users will never see.
2. Neither Isar 3.x nor a hypothetical Isar 4 is more actively
   maintained than `hive_ce` today, so "migrate to Isar" does not
   actually retire R-02. It swaps one maintenance-mode dependency for
   another and adds a native dep on top.
3. Drift is the only option that genuinely retires R-02, but its cost
   (15-25 days + schema design + test rewrite) dominates our v5 budget
   and delivers no user-visible value at beta launch. It should be
   revisited for v6 if and when we need SQL analytics (e.g.,
   crowdsourced price aggregation across users).
4. `hive_ce` is a tested, file-format-compatible fork. Keeping it on
   the shelf reduces R-02 from "medium" to "low" at roughly zero cost.
5. All user data is encrypted at rest today. Neither Isar nor Drift
   improves that story materially.

## Migration plan (escape hatch only)

Trigger conditions — any one of:
- `hive 2.2.3` fails to resolve against a required Flutter SDK bump.
- A CVE is filed against Hive and is not patched within 14 days.
- A showstopper bug appears in production crash reports.

Phased execution:

1. **Phase 0 (now, as part of this ADR):** add `hive_ce` to the internal
   tracking list; verify the latest version reads a Hive 2.2.3 file on a
   throwaway branch. Document the swap in this ADR's "Consequences".
2. **Phase 1 (trigger fires):** branch `chore/hive-ce-swap`. Replace the
   `hive` + `hive_flutter` imports with `hive_ce` + `hive_ce_flutter`.
   Run the full test suite. Expected effort: 1 day.
3. **Phase 2 (v6 re-evaluation, ~12 months out):** revisit this ADR. If
   analytics features are now on the roadmap, re-score Drift against
   real requirements and — if chosen — execute the full migration with a
   one-shot `StorageMigrator` and a two-release rollout (ship both
   backends, migrate, then remove Hive).

## Consequences

- We accept R-02 as an explicit, tracked risk with a defined mitigation
  (`hive_ce` swap). The risk drops from medium to low.
- v5 scope does not include a storage migration, freeing 2-4 developer
  weeks for user-facing features.
- ADR 0004 remains the canonical reason we chose Hive; this ADR is its
  re-validation for v5.x.
- Any v6 work that needs SQL (cross-station queries, long-range
  analytics, crowdsourced aggregation) will trigger a fresh evaluation
  with Drift as the presumptive target.

## Alternatives Considered

The three options above (Isar, Drift, stay-on-Hive) are the alternatives
that were evaluated in depth. Briefly, also considered and rejected:

- **ObjectBox** — fast and actively maintained, but GPL/commercial
  dual-licensed. Violates our MIT/BSD/Apache-only dependency policy
  (see ADR 0007).
- **sqflite directly (no Drift)** — gives us SQL but loses Drift's
  compile-time query checking and migration tooling. All of Drift's
  cons without its main pros.
- **sembast** — pure Dart NoSQL, actively maintained, no native deps.
  Attractive escape hatch, but benchmarks show 3-5x slower reads than
  Hive for our access pattern. Worse than `hive_ce` on both axes.
- **Partial migration** (e.g., Drift for `price_history` only, Hive for
  everything else) — doubles the storage surface area and the test
  matrix with no clear win. Rejected.

## References

- Hive pub page: https://pub.dev/packages/hive — last publish 2022-06-12
- Hive Community Edition: https://pub.dev/packages/hive_ce
- Isar: https://pub.dev/packages/isar — last stable 2023-11
- Drift: https://pub.dev/packages/drift — active monthly releases
- `lib/core/storage/hive_boxes.dart` — current init and encryption logic
- `lib/core/storage/hive_storage.dart` — facade used by all callers
- [ADR 0004](0004-hive-for-storage.md) — original Hive decision
