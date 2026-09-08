<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0021: One logging façade, one context-map contract — every trace through `log.*`

**Status:** Accepted
**Date:** 2026-09-08
**Issue:** #3976 (Epic #3952)
**Related:** #3144 (the `AppLog` façade), #2349 / #1103 (never-throws), #3794 (session journal), #3583 (crash forensics), #2348 (ratchet parse fidelity)

## Context

The project's stated goal for error handling is that a trace lets an AI
assistant reconstruct the cause completely from the field export. The
2026-09-04 audit (Epic #3952) found the rules largely exist but that four
logging paths coexist, and the pipeline erases what it is meant to keep:

- **Four paths.** `debugPrint` (345 sites — a release no-op that never
  reaches the export), raw `unawaited(errorLogger.log(...))` (509 sites in
  241 files), `logFailure` (`lib/core/error/guarded.dart`, 105 sites), and
  the leveled façade `log.*` (`lib/core/logging/app_log.dart`, #3144 —
  imported by **5** files). A reader of any one call site cannot tell which
  contract it follows.
- **125 catch bodies whose only handling is `debugPrint`.** In the shipped
  build those are empty catches: the cause is dropped in exactly the build
  where it matters (40 in obd2, 23 in core/telemetry, 15 in
  feature_management, 9 in core/storage).
- **Context maps that cannot carry an id.** 374 of the 520 `context:` maps
  are `const`, so they name a place but never the station, trip, vehicle or
  attempt the failure was about. Searches, background scans, exports and OCR
  runs have no correlation id at all; only sync and OBD2 do.
- **A ratchet that was false-green.** `guarded_error_helper_test.dart`
  asserted 0 raw `errorLogger.log` sites because its regex needed a newline
  the formatter removes (#3977).

The façade already has the right shape: four levels, each documenting its
routing (`debug` → console only; `info` → console + breadcrumb; `warn` →
the persisted pipeline tagged `level: warn`; `error` → `errorLogger.log`
unchanged), a never-throws contract, and a process-wide singleton so it is
callable from isolates and pre-container startup. What it lacks is
exclusivity and a fixed vocabulary for `context`.

## Decision

1. **`log.*` is the only sanctioned logging call site.** `log.debug`,
   `log.info`, `log.warn`, `log.error` — nothing else. This is deliberate
   and total: `debugPrint` becomes a lint offender **everywhere**, including
   the 345 pure-trace sites, not just inside catch blocks. One path is a
   contract a reader can rely on; "error-shaped goes here, traces go there"
   is a rule every author would draw differently. `errorLogger.log` and
   `logFailure` are implementation detail behind the façade and become
   offenders at call sites too.

2. **The façade owns the release no-op.** The property that made
   `debugPrint` attractive — free in release — moves into `AppLog`:
   `debug` is a no-op below its configured level in a release build, so a
   trace costs nothing shipped. Nothing else about release behaviour
   changes: `warn` / `error` persist exactly as `errorLogger.log` does
   today.

3. **One context-map contract.** Every `warn` / `error` call carries a
   non-`const` `Map<String, Object?>` with these keys, in this vocabulary:

   | key       | type     | meaning                                              |
   |-----------|----------|------------------------------------------------------|
   | `where`   | `String` | the operation, dotted: `search.fetch`, `obd2.reconnect`, `sync.push` |
   | `entity`  | `String?`| the id the operation was about: station id, trip id, vehicle id, fill-up id |
   | `runId`   | `String?`| correlation id shared by every entry of one run (a search, a scan, an export, an OCR pass, a sync episode, an OBD2 session) |
   | `attempt` | `int?`   | 1-based attempt index inside a chain or retry loop   |
   | `country` | `String?`| ISO code when the operation is country-scoped        |

   `level` and `tag` are set by the façade, never by the caller. Extra
   keys are allowed; these five are the ones every consumer (trace export,
   breadcrumb ring, episode gate, the GitHub-issue reporter) may rely on.
   A map that carries an id is by definition not `const`.

4. **Migration order.** Feature by feature, one PR each, so every diff is
   reviewable and the ratchet baseline drops monotonically:
   trips (82) → obd2 (70) → sync (42) → alerts (34), the remainder riding
   the tasks that already touch those files (#3978). The ratchets that make
   this stick are #3977 (raw `errorLogger.log`, re-baselined at the true
   509 / 241) and #3981 (debugPrint-only catches 125, `.catchError((_) …)`
   6, raw `debugPrint` 165 — all of `lib/`, telemetry pipeline exempt).

## Consequences

- **One call shape to learn, one to lint.** "Is this site on the contract?"
  becomes a regex question, which is what lets the ratchets scan all of
  `lib/` with decrease-only baselines and a parse-fidelity self-check.
- **The telemetry pipeline is exempt from its own rule.** `AppLog`,
  `ErrorLogger`, the trace recorder and the isolate spool must not log
  through themselves; they keep an internal `debugPrint` fallback for
  observability faults (the never-throws contract) and are excluded from
  the ratchets by path, narrowly.
- **345 + 509 sites move.** That volume is why the order above exists and
  why Task 3 is four PRs, not one. Each migrated site also gains a `where`
  and, where one exists, an `entity` — which is most of the value.
- **Generalising the episode gate becomes possible** (#3980): with `where`
  uniform, a storm on any layer can be collapsed the way `ErrorLayer.sync`
  already is, and `runId` lets the export group one search or one OBD2
  session after the fact.
- The wiki (`llmwiki/flutter/05`, `27`) must be corrected where it describes
  today's coverage as broader than it is.

## Alternatives Considered

- **Keep `debugPrint` for non-error traces; lint only catch blocks.**
  Migrates 125 sites instead of 345 and keeps the free release no-op.
  Rejected: two paths need a rule for "error-shaped" that every author
  reads differently, and the no-op is trivially owned by the façade
  instead (Decision 2). Considered and rejected by the maintainer on
  2026-09-08.
- **Route everything through `errorLogger.log` directly.** No façade
  layer. Rejected: it has one level, spends a 50-slot ring entry per call,
  and cannot express "this is a trace, do not persist it".
- **One mechanical PR for all 509 sites.** Fastest, but a 241-file diff
  nobody can review, and the per-site judgement (which `where`, which
  `entity`) — most of the task's value — gets skipped.
- **Fold the migration into the feature epics.** No dedicated PRs, but the
  baseline stays at 509 indefinitely and nobody owns "is it done".
