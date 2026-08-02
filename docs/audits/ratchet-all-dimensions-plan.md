<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Action plan: a ratchet in every quality dimension

**Status:** PROPOSAL — Epic breakdown awaiting maintainer validation (HARD
RULE #2: children are filed only after this breakdown is validated).
**Measured:** 2026-08-01, against the working tree (post guarded-helper +
scan-readiness work). Every number below was counted, not recalled.

## The doctrine

A quality dimension is *ratcheted* when it has all four of:

1. **A number** — measured by a test or script, not estimated.
2. **A direction** — the number may only move one way (usually down).
3. **An enforcement point** — a build fails when it moves the wrong way.
4. **An owner issue** — the burn-down is tracked, not aspirational.

Lifecycle per dimension: *measure → pin baseline → forbid regression →
burn down in slices → pin at zero → keep the machinery*. The
guarded-error ratchet (`test/lint/guarded_error_helper_test.dart`) is the
reference implementation: its grandfathered set went 26 files → 12 → **0**
in two passes and stays pinned at zero with the scan still running.

**Standing constraint (binding):** no new ratchet may add a required
check that can transiently fail, block `gh pr merge --auto`, or add a
human step to the start→merge path. New gates start **advisory or
post-merge** and are promoted only deliberately.

## Dimension inventory (measured 2026-08-01)

| # | Dimension | Mechanism today | Number now | Direction enforced? | Gap |
|---|-----------|-----------------|-----------:|---------------------|-----|
| 1 | Hardcoded UI strings | `no_hardcoded_ui_strings_test` baseline | **0** | ✅ decrease-only | **Zero reached — needs the zero-pin** (forbid raising, celebrate #1657) |
| 2 | Inline border radii | `no_inline_border_radius_test` baseline | **122** | ✅ decrease-only | Largest numeric baseline; no burn-down issue exists |
| 3 | File length (god classes) | `file_length_test` snapshot map + bumps | **23 files** | ✅ grow-needs-justification | Burn-down tracked only for 2 files (#3139, #3140) |
| 4 | Never-throws contracts | `never_throws_contract_test` grandfathered set | **13** | ✅ shrink-only | No burn-down issue |
| 5 | Raw `Card` in screens | `no_raw_card_in_features_test` allowlist | **9** | ✅ shrink-only | #923-followup never filed as issues |
| 6 | Raw `AppBar` in features | allowlist | **0** | ✅ | Done — verify zero-pin exists |
| 7 | Guarded-error blocks | `guarded_error_helper_test` | **0** | ✅ pinned at 0 | Done (reference implementation) |
| 8 | Feature-boundary imports | `feature_boundary_test` pair counts | 2 entries | ✅ decrease-only | Healthy |
| 9 | debugPrint-only catches | allowlist | **1** | ✅ shrink-only | Falls out when the #3077 branch lands |
| 10 | Module boundaries | `module_boundary_allowlist.txt` | **0** | ✅ | Done |
| 11 | Lint opt-out comments | *none* — `// ignore: silent_catch` (29) + `catch_no_st` (14) | **43** | ❌ | The escape hatch of ratchets 4/7/9 is itself unratcheted — opt-outs can inflate silently |
| 12 | Test coverage | `check_coverage.sh --threshold 40`, post-merge only | 40 % static floor | ❌ never fires | §22-A: a floor that never fires is not a control |
| 13 | Cross-file duplication | *none* (one-off scan found the errorLogger block) | **≈130 dup groups** | ❌ | No mechanism at all; this is how the 26-file block accumulated |
| 14 | Startup time | `check_startup_budget.sh` | 2000 ms static | ⚠️ static ceiling | Never re-measured or lowered since set |
| 15 | Artifact size (AAB/APK) | *none* | unmeasured | ❌ | A dependency bump can add 10 MB silently (it has — the iOS ML Kit pods, #3172) |
| 16 | TODO/FIXME debt | *none* | **5** | ❌ | Small enough to pin at ~0 immediately |

Binary (pass/fail, already enforced, no ratchet needed): no-GMS audit,
licence audit, l10n parity, codegen drift, analyzer-fatal-infos, ARB
fragment consistency.

## Phased actions

### Phase 0 — visibility + decisions *(1 bundled PR + 1 decision issue)*

- **R0.1 — Ratchet dashboard.** `tool/ratchet_report.dart`: one command
  that prints every number in the table above (recomputing, not parsing
  the tests), so drift is visible in seconds and the §22 quarterly audit
  becomes `dart run tool/ratchet_report.dart` + diff. Effort: S.
- **R0.2 — Decision task → ADR** (owner input required, blocks R1.2/R1.3):
  - Coverage: high-water-mark ratchet (fail post-merge if coverage drops
    > 0.5 pt below the best green run) vs. quarterly manual floor raises.
    *Recommendation: high-water mark, post-merge only — preserves the
    #2338 autonomy decision; red master is the tripwire, not a blocked PR.*
  - Artifact size: pick the budget (current play-AAB size + 5 % headroom)
    and the enforcement point (warning in `build-android` first,
    promotion later). *Recommendation: warn for one month, then fail.*
  - Duplication: normalisation rules (window size 6, strip
    strings/numbers, exclude l10n + generated) and whether the unit is
    duplicate *groups* (recommended) or instances.

### Phase 1 — new ratchets for the unratcheted dimensions *(independent slices)*

- **R1.1 — Duplication ratchet** (dim 13). Port the session's scanner to
  `test/lint/duplication_ratchet_test.dart`; pin baseline ≈130 groups,
  decrease-only, failure message prints the worst new group. Effort: M.
- **R1.2 — Artifact-size budget** (dim 15). Measure AAB in
  `build-android`, compare against a committed budget file. Depends R0.2.
  Effort: S.
- **R1.3 — Coverage high-water ratchet** (dim 12). `coverage-merge`
  stores the high-water % (cache or committed file); fails on a > 0.5 pt
  drop; raises the mark automatically on improvement. Depends R0.2.
  Effort: M.
- **R1.4 — Opt-out-comment ratchet** (dim 11). Count
  `// ignore: silent_catch|catch_no_st` in `lib/`, pin at 43,
  decrease-only. Closes the inflation hatch of the catch ratchets.
  Effort: S.
- **R1.5 — TODO ratchet** (dim 16). Convention: only `// TODO(#NNN):`
  with a live issue number allowed; lint-test it; fix or file the 5.
  Effort: S.
- **R1.6 — Startup re-baseline** (dim 14). Re-measure on the reference
  device/emulator, lower 2000 ms to measured p95 + margin; revisit
  quarterly via the dashboard. Effort: S.

### Phase 2 — burn-downs on the existing baselines *(slices; bundle per feature)*

- **R2.1 — Border radii 122 → 0** (dim 2): mechanical `AppRadius` token
  swaps, ~4 slices of ~30 grouped by feature to limit conflict surface.
- **R2.2 — Never-throws 13 → 0** (dim 4): one fault-injection test per
  grandfathered boundary; each removal shrinks the set.
- **R2.3 — Raw Card 9 → 0** (dim 5): the #923-followup SectionCard
  migrations, finally filed and finished.
- **R2.4 — File length** (dim 3): finish the two *forced* decompositions
  first (#3139 app_initializer, #3140 obd2 picker/recording trio — both
  already past the bump limit), then largest-remaining-first. These are
  the named conflict magnets: **serialize, never parallelise.**
- **R2.5 — debugPrint-only → 0** (dim 9): remove the allowlist entry when
  the #3077 branch lands (blocked on that branch; do not touch the file
  before — file-ownership boundary).

### Phase 3 — zero-pins + maintenance

- As each dimension reaches 0, convert to the guarded-ratchet shape:
  empty set kept, count pinned with `lessThanOrEqualTo(0)`, machinery
  retained. Start **now** with dim 1 (already at zero) and verify dim 6.
- The §22 known-gaps quarterly audit runs the dashboard and updates the
  inventory table above; wiki page 24's "what both are missing →
  meaningful coverage ratchet" is updated when R1.3 lands.

## Sequencing & rules of engagement

```
R0.1 ──────────────────────────┐
R0.2 (decision) ── R1.2, R1.3  │   Phase 2 slices run independently,
R1.1, R1.4, R1.5, R1.6 ────────┼── except R2.4 (serialize) and
Phase-1 zero-pin of dim 1, 6 ──┘   R2.5 (blocked on #3077)
```

- One conflict-magnet PR in flight at a time (R2.4; any slice touching
  `ci.yml` bundles with other workflow changes).
- Every new lint test follows the house style: a docstring naming the
  failure that motivated it, a failure message that shows the offending
  lines, and a shrink-only allowlist with a pinned length.
- Nothing in Phase 1 becomes a *required* check at introduction.

## Definition of done

`dart run tool/ratchet_report.dart` shows, for all 16 dimensions, either
**0** or an explicitly-accepted floor with an owner decision recorded —
and every non-zero number has an open burn-down issue attached.
