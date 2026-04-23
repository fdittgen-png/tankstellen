# Autonomous Loop Protocol — Parallel-Worker-Safe

This is the operating protocol for the `/tankstellenfix` autonomous issue-fix loop. It supersedes the single-threaded protocol that produced PRs #802–#832 in one session; those worked but left CI-wait time on the table and had no safety rails when multiple Claude sessions were active simultaneously.

**Design goal:** two or three agent sessions can run `/tankstellenfix` concurrently and produce a stream of merged PRs without stepping on each other, without manual coordination, and without accidentally producing conflicting patches.

## Core rules

### 0. Pre-claim file-intersection check (MANDATORY before every pick)

Before dispatching a worker, compute the forbidden file set from every open PR and reject any candidate that intersects:

```bash
gh pr list --state open --json number --jq '.[].number' \
  | xargs -I{} gh pr diff {} --name-only | sort -u > /tmp/forbidden.txt
# compare against the candidate's likely-touched files (grep issue body mentions,
# scan feature dir, plus the hot-file list below). Non-empty intersection → pick next candidate.
```

Two coordinators shipped duplicate PRs for #838 and #584 in 2026-04 because label-claim is not atomic — they both queried `gh issue list`, both picked the same issue, both dispatched workers. Whoever merged first kept their PR; the other was closed as superseded after its worker finished a full local implementation. **Pre-claim file-intersection catches this before any worker runs.** Labels remain useful for human visibility but are not the mutex.

### 1. File-disjointness is the real mutex, not labels

An `in-progress` label is nice for human visibility, but it doesn't stop two agents from picking issues that both edit `pubspec.yaml` or the same ARB file. The mandatory pre-pick check is:

```bash
# Every open PR's touched files:
gh pr list --state open --json number,headRefName --jq '.[].headRefName' \
  | xargs -I{} git diff --name-only origin/master...origin/{}
```

Cross-reference this against the likely files for your candidate issue. If the intersection is non-empty, **serialize**: either pick a different issue or wait for the conflicting PR to merge.

### 2. Sequential merges, with rebase between

Parallel *work* is fine; parallel *merges* are never. After each merge, every other in-flight branch MUST rebase onto the new `origin/master` before its own merge. The coordinator owns this rebase pass; workers just wait.

```bash
git fetch origin
git rebase origin/master   # from the worker's branch
git push --force-with-lease
```

The existing `feedback_parallel_merge_strategy.md` memory note already codifies this.

### 3. Branch off `origin/master`, never local `master`

With the persistent worktree at `../tankstellen-master`, the local `master` branch is pinned there. `git checkout master` from the main checkout fails:

> fatal: 'master' is already used by worktree at 'C:/working/dittgen/tankstellen-master'

Always use:

```bash
git fetch origin
git checkout -b <type>/<issue-number>-<short-name> origin/master
```

See `docs/guides/DEV-GIT-WORKTREES.md` for the full worktree setup.

### 4. Close issues manually after merge

GitHub's squash-merge on this repo strips commit bodies, so `Closes #N` in a PR body does NOT fire auto-close. After every merge:

```bash
gh issue close <N> --reason completed \
  --comment "Closed by PR #<M> (merged in <sha>)."
```

`feedback_squash_merge_strips_commit_body.md` has the full history.

### 5. Release the claim on every failure path

If a worker fails (CI won't go green, can't resolve conflicts, runs out of context), the coordinator must:

1. Remove `in-progress` label from the issue (so another agent can try later).
2. Close the abandoned PR with a comment explaining why.
3. Not leave a half-pushed branch squatting on a file that will block future attempts.

### 6. Pre-push checklist (every worker, every PR)

Non-negotiable, inlined here so workers don't need to chase down `feedback_agent_prompt_template.md`:

- `flutter analyze` (STRICT — NO `--no-fatal-infos`; CI fails on `prefer_const_constructors` per `feedback_analyze_stricter_in_ci.md`).
- `dart run build_runner build --delete-conflicting-outputs` if any freezed/riverpod model changed.
- `flutter gen-l10n` if any ARB file changed.
- `flutter test` — full suite, not just the new test file.
- Every new ARB key: present in `app_en.arb` AND `app_de.arb` (the `test/l10n/localization_completeness_test.dart` gate fails CI on a missing German translation).
- `flutter analyze` again after generation — generated code occasionally reintroduces lints.

## Coordinator-workers model

One agent is the **coordinator**; it picks the batch, dispatches workers, merges in priority order, rebases survivors. Workers are `Agent(isolation: "worktree")` sub-agents; each gets a dedicated worktree so they can't contaminate each other or the coordinator's checkout.

### Coordinator loop (in pseudocode)

```
loop:
  forbidden = union(gh pr diff --name-only for every open PR)    # pre-claim file intersection
  batch = pick_disjoint_batch(min(3, available))                  # parallel cap
  drop any candidate whose likely files intersect forbidden
  if batch is empty: break
  dispatch workers in parallel (single message, multiple Agent calls, run_in_background=true)
  wait for all worker PRs to open
  merge_order = sort(batch, by_priority)
  for issue in merge_order:
    wait until required checks (analyze + test) are SUCCESS
    if UNSTABLE + required=green + optional (build-android/release) still running:
      admin-merge (don't wait for optional)
    else merge after all green
    TaskStop any monitor armed on that PR in the same turn
    if another in-flight PR is now also green → batch-merge don't eager-merge
    for remaining in-flight: will auto-rebase on next update-branch (cheap)
```

### Worker prompt template — the canonical defensive block

Every dispatched worker gets a prompt that includes:

1. **Issue number + title + link**
2. **Scope / acceptance criteria** (copy the key bullets from the issue body)
3. **Files the worker may touch** (explicit allowlist — keeps workers from drifting into shared files)
4. **Phase marker** — `Refs #N phase X` (not `Closes #N`) if this is a phased PR
5. **Pre-push checklist** (inlined, not a cross-reference). MUST include:
   - Plain `flutter analyze` — no path arg, no `--no-fatal-infos`. Covers `lib/` AND `test/` (unused-import in test/ blocks merge; see `feedback_worker_analyze_test_dir.md`)
   - Verify `git rev-parse --show-toplevel` before every commit (worktree-isolation leaks via `cd`; see `feedback_worker_bash_cd_escape.md`)
   - Revert unrelated `.g.dart` / `.freezed.dart` drift from `build_runner` before staging — the PR must match the allowlist exactly
   - Grep `catch\s*\(\s*\w+\s*\)\s*\{\s*\}` must be empty in new files (the `test/lint/no_silent_catch_test.dart` gate enforces repo-wide)
   - Full `flutter test test/` — not just the new test directory
   - `flutter gen-l10n` after any ARB edit
6. **Branch name** — fixed by coordinator, not chosen by worker. Keeps branch namespace coordinated.
7. **Close / label boundary** — explicit "do NOT call `gh issue close`, do NOT remove the `in-progress` label, do NOT merge the PR — coordinator owns all three."
8. **Phase-0 precedent** — "if a stub entity on master doesn't match the spec, rewrite and document in the PR body; see PR #853 precedent."
9. **Worker report format** — "when done, return: PR URL + files touched + test count + full-suite pass count + anomalies (drift reverts, analyzer edge cases, phase-0 rewrites)."

## Hot-file list — serialize when two candidate issues both touch any of these

Workers touching these files should expect a coordinator-managed rebase. If two candidate issues would both touch the same hot file, serialize them — do not dispatch in parallel:

- `lib/core/storage/hive_boxes.dart` — box registrations
- `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, and the 21 regenerated `lib/l10n/app_localizations_*.dart` files
- `lib/core/services/service_result.dart` — enum shared by every country service
- `lib/core/services/country_service_registry.dart` — every new country appends here
- `lib/core/country/country_config.dart` + `country_bounding_box.dart`
- `lib/features/search/domain/entities/fuel_type.dart` — enum
- `lib/app/app_initializer.dart` — startup sequence
- `lib/core/background/background_service.dart` — WorkManager dispatcher
- `pubspec.yaml` — dep bumps serialize with any dependency-touching work

## Must-not-parallelize list

Issues that touch shared feature areas and MUST be serialized (only one at a time, no concurrent worker):

- **P0 widget fixes** (#753 class) — shared widget files, need focus.
- **Widget-redesign epic** (#607, #609, #610) — same widget-layout files.
- **OBD2 chain** — `obd2_service.dart` and `trip_recording_controller.dart` are converging points; phase-PRs work fine here because each phase is ~1 CI cycle, but do not run two OBD2 workers simultaneously.
- **Brand/icon/splash polish** (#589, #590, #593) — overlap on `android/` and `assets/`.
- **Anything regenerating `.g.dart` / `.freezed.dart` widely** — `dart run build_runner` writes to every model's generated files; two workers running it concurrently race.

## Parallel dispatch cap

Run at most **3 concurrent workers**. Four or more empirically causes merge-thrash (cascading `update-branch` CI cycles) that erases the parallelism gain. Three is the steady-state optimum on this repo's CI duration (~8 min per cycle).

## Phased-PR rubric — when to split an issue

Use phased PRs when the issue meets EITHER condition:

- **> 400 LOC of changes** (excluding generated `.g.dart` / `.freezed.dart` / regenerated locale `.dart`)
- **3+ distinct concerns** (e.g. data model + UI + background job + notifications)

Otherwise ship complete — the tight scope advantage disappears when a competing coordinator ships the whole feature first. Two "phase 1 only" PRs in 2026-04 were closed as superseded by whole-feature PRs from the other coordinator.

**Mark phase PRs with `Refs #N phase X`, NOT `Closes #N`.** The epic stays open until the last phase ships; only then run `gh issue close`. Phase summary comments on the epic document what's shipped vs pending.

## Admin-merge heuristic — don't wait for optional checks

When `mergeStateStatus == UNSTABLE` and required checks (`analyze` + `test`) are SUCCESS but optional checks (`build-android`, `release`) are still IN_PROGRESS or QUEUED, admin-merge is correct:

```bash
gh pr merge <N> --squash --delete-branch --admin \
  && git -C ../tankstellen-master pull --ff-only
```

Required checks gate merging; optional ones don't. On Flutter-only changes, optional checks almost always pass anyway. The chained `pull --ff-only` against the **persistent master worktree** suppresses the "cannot delete branch used by worktree" error from the main checkout.

`--admin` also bypasses the stale "head branch not up to date" lockout when CI was green on the previous commit and only the base branch has moved — common when another coordinator merges while yours is in flight. No rebase cycle needed for trivial catchup.

## ARB conflict resolution recipe

ARB conflicts are nearly guaranteed when two UI PRs are in flight. Don't hand-merge the 23 `app_localizations_*.dart` files — they're generated. Instead:

```bash
git checkout --theirs lib/l10n/app_localizations*.dart
# hand-merge app_en.arb + app_de.arb — combine both key groups
git add lib/l10n/app_en.arb lib/l10n/app_de.arb
flutter gen-l10n    # regenerates all 23 locale files from the merged ARBs
git add lib/l10n/
git commit --no-edit
```

**Future infra TODO (tracked outside this doc):** an ARB-fragment pattern (`lib/l10n/_fragments/<feature>.arb` per feature + a pre-`gen-l10n` script that concatenates) would eliminate the entire class of conflict. Six rebase cycles in one session were attributable to this hot file.

## Monitor filter correctness

When watching CI with `Monitor` or polling, always check `.conclusion`, not just `.status`:

```jq
[.statusCheckRollup[] | .name + "=" + (if .status == "COMPLETED" then .conclusion else .status end)]
```

A COMPLETED check can be SUCCESS, FAILURE, or SKIPPED. A filter that only reads `.status` will report "all-complete" on a FAILURE and mask a red PR. Observed on #868 in 2026-04-22: unused-import in the worker's new test file blocked merge for a full CI cycle because the coordinator's monitor reported green.

## Kill stale watchers after admin-merge

`Monitor` or `gh pr checks --watch` processes launched before an admin-merge will keep firing until their terminal filter catches up, burning a turn per event to acknowledge "already merged." Call `TaskStop <task_id>` in the same turn as the merge.

## First parallel-safe batch to try

- **#574** Luxembourg country API (new file under `lib/core/services/impl/`)
- **#575** Slovenia country API (new file under `lib/core/services/impl/`)
- **#573** UK upgrade to GOV.UK (modifies existing `uk_station_service.dart` only)

All three touch country-service files plus ARB keys. Coordinator handles ARB merge centrally: each worker appends its keys to a dedicated block in `app_en.arb` + `app_de.arb`, coordinator resolves on merge.

## When to stop

- Backlog has no more disjoint work to dispatch (must-not-parallelize + hot-file list exhaust the pickable pool).
- Repeated CI failures suggest a master regression (not flaky tests) — escalate to user.
- Coordinator context approaching the session limit — **stop gracefully**, summarize outstanding state in text, end the turn. Don't save dated per-run state memories (they decay in 72 h per `feedback_no_loop_state_snapshots.md`). The user runs `/compact` and re-invokes `/tankstellenfix` for a fresh window.
- Both in-flight PRs are stuck on the same hot file and neither can progress — escalate to user with a tradeoff to resolve.

## Links

- `docs/guides/DEV-GIT-WORKTREES.md` — worktree setup + `Agent(isolation: "worktree")` pattern
- `feedback_parallel_merge_strategy.md` (memory) — why sequential merges
- `feedback_parallel_agent_lint.md` (memory) — agents must grep for warnings not just errors
- `feedback_agent_prompt_template.md` (memory) — the pre-push checklist origin
- `feedback_squash_merge_strips_commit_body.md` (memory) — why manual `gh issue close`
- `feedback_analyze_stricter_in_ci.md` (memory) — strict `flutter analyze` before push
- `feedback_ci_watch_reliability.md` (memory) — `gh run list` over `gh pr checks --watch` after force-push
- `feedback_worker_analyze_test_dir.md` (memory) — plain `flutter analyze` covers `test/`, not `flutter analyze lib/`
- `feedback_worker_bash_cd_escape.md` (memory) — `isolation: "worktree"` doesn't fence `cd`
- `feedback_no_loop_state_snapshots.md` (memory) — no dated per-run state memories
