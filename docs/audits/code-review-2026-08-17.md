# Six-dimension code review — 2026-08-17

Full-codebase review (231,558 hand-written lib LOC, 1,543 files; l10n/codegen
excluded) by six parallel specialist passes. Verification baseline: clean
`flutter analyze` = 0 issues; every finding was individually verified at the
cited line before being reported. Already-ratcheted dimensions (the 29
`test/lint/` gates) were treated as baseline, not re-reported.

## Report card

| Dimension | Grade | One-line verdict |
|---|---|---|
| Flutter best practices | **A** | Async/lifecycle lints at error severity; 0/97 State classes leak a disposable; custom `no_ref_after_await` ratchet closes the WidgetRef gap. |
| Dart best practices | **A** | ~1 bang per 1,000 lines; Dart 3 idiom genuinely adopted; 836 `unawaited()` vs 15 deliberate `.then`. |
| Readability | **A** | High-signal comment culture (why + issue links + units on tunables); 400-line ratchet with bump counter. |
| Maintainability | **A (low)** | Best-in-class ratchet machinery; docked for drifted honor-system parts (closed decomposition issues, unexecuted ratchet plan). |
| Performance | **A−** | Memoized hot paths, phased startup, compute() offloads; two real jank sources in trip history/WAL (fixed in #3741). |
| Security | **B+ → A- track** | RLS on all 22 tables, zero TLS bypasses, disciplined redaction; the plaintext refresh-token + backup gap is fixed in #3740; remaining M-items in epic #3743. |
| OO design / architecture | **B** | Tactically A (state machines, seams, sealed values); macro graph holds it back: 19 frozen feature cycles around the 62k-line consumption hub. |
| Extensibility | **B** | Country/synced-table/fuel-type axes genuinely extensible; registration fan-out + shared API-key slot are the debt (epic #3743). |
| Code reuse | **B** | Strong shared infrastructure; codec triplication (a live bug, fixed in #3739), widget twins, 27 hand-rolled DioException blocks. |
| Dead code | **B** | Tiny dead surface for the size; one dead file was a live bug (#3738); ~183 unused ARB keys ×24 locales. |

## Live bugs found by the review (fixed immediately)

1. **#3738** — the #3134 per-profile language bridge was never wired into the
   ProviderContainer: per-profile language silently non-functional; tests
   passed because they installed their own overrides.
2. **#3739** — TripSummary serialized by three drifted hand-rolled codecs:
   crash-snapshot rehydrate lost 13 fields, paused-trip rehydrate lost 16
   (including `kind` and `distanceSource` — the long-suspicious
   `'virtual'` default came from here).
3. **#3740 (1)** — the Supabase refresh token persisted in plaintext
   SharedPreferences and Android's default-on cloud backup shipped it
   off-device.

## Remediation waves

- **Wave 1 (merged, PR #3748):** #3738, #3739, #3740 (token-at-rest +
  backup rules + https + CSV-injection + CI env scoping + receiver/share
  hardening), #3741 (summaries-only history list, O(1)-amortized WAL flush,
  zero-copy sample buffer), #3742 (5 new lints, verified-dead deletions,
  MediaQuery hygiene).
- **Wave 2 (merged, PR #3749):** per-country API keys, one-row country
  registration, SECURITY DEFINER pinning + share-oracle closure (schema v8),
  iOS Hive relocation. The live community Supabase was found stuck at
  schema v2 and was brought to v8 the same day (months of silent
  deletion-tombstone / EV-favorite sync failures retro-fixed).
- **Wave 3 (epic #3743, remaining):** consumption split,
  TripRecordingController inversion, barrel pruning, obd2 re-layering,
  sync-config relocation, locale-aware number formatting ratchet
  (182 sites), ARB key cleanup (~183 keys), widget-twin consolidation,
  station_services error-handling dedup, ratchet-plan Phase 0/1,
  no-op Feature toggles decision.

## A-grade practices the reviews singled out (do not regress)

- The two-sided ratchet suite (shrink-only baselines, incident-linked
  docstrings, bump counters with mandatory decomposition issues).
- `never_throws_contract_test` — doc contracts turned into enforceable tests.
- `EntitySync<T>` + the schema-verifier drift guard (self-host SQL cannot
  silently diverge).
- `Obd2LinkSupervisor`'s injectable-seam constructor shape.
- Riverpod-free `CountryServiceDependencies` construction (identical fg/bg
  isolate wiring).
- Fixture-driven country-service tests with recorded real-API slices.
- Startup phasing (`_deferPostFirstFrame`) and the memoize-and-annotate idiom
  on every hot path.
- Flaky quarantine with daily resurfacing; affected-test selection on PRs.
