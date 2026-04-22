# Autonomous Loop Protocol — Parallel-Worker-Safe

This is the operating protocol for the `/tankstellenfix` autonomous issue-fix loop. It supersedes the single-threaded protocol that produced PRs #802–#832 in one session; those worked but left CI-wait time on the table and had no safety rails when multiple Claude sessions were active simultaneously.

**Design goal:** two or three agent sessions can run `/tankstellenfix` concurrently and produce a stream of merged PRs without stepping on each other, without manual coordination, and without accidentally producing conflicting patches.

## Core rules

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
  batch = pick_disjoint_batch(2 or 3 issues)
  if batch is empty: break
  dispatch workers in parallel (single message, multiple Agent calls, run_in_background=true)
  wait for all worker PRs to open
  merge_order = sort(batch, by_priority)
  for issue in merge_order:
    wait until issue's PR is CI-green
    merge
    for remaining issues in merge_order:
      rebase remaining's branch on new master, force-push
```

### Worker prompt template

Every dispatched worker gets a prompt that includes:

1. **Issue number + title + link**
2. **Scope / acceptance criteria** (copy the key bullets from the issue body)
3. **Files the worker may touch** (explicit allowlist — keeps workers from drifting into shared files)
4. **Pre-push checklist** (inlined, not a cross-reference)
5. **Branch name** (fixed by coordinator, not chosen by worker — keeps branch namespace coordinated)
6. **Close-issue reminder** — no, actually: only the coordinator closes issues, so: "do NOT call `gh issue close` — I'll do it after merge"
7. **Worker report format** — explicit "when done, return: PR URL + list of files touched + test count added"

## Must-not-parallelize list

Issues that touch shared state and MUST be serialized (only one at a time, no concurrent worker):

- **P0 widget fixes** (#753 class) — shared widget files, need focus.
- **Widget-redesign epic** (#607, #609, #610) — same widget-layout files.
- **OBD2 chain** (#800, #811, #812, #815) — recent commits show sequential dependency; `Obd2Service` and `VehicleProfile` are the converging points.
- **Brand/icon/splash polish** (#589, #590, #593) — overlap on `android/` and `assets/`.
- **Anything bumping `pubspec.yaml`** — trivially serial; version conflicts in one field kill both branches.
- **Anything regenerating `.g.dart` / `.freezed.dart` widely** — `dart run build_runner` writes to every model's generated files; two workers running it concurrently race.

## First parallel-safe batch to try

- **#574** Luxembourg country API (new file under `lib/core/services/impl/`)
- **#575** Slovenia country API (new file under `lib/core/services/impl/`)
- **#573** UK upgrade to GOV.UK (modifies existing `uk_station_service.dart` only)

All three touch country-service files plus ARB keys. Coordinator handles ARB merge centrally: each worker appends its keys to a dedicated block in `app_en.arb` + `app_de.arb`, coordinator resolves on merge.

## When to stop

- Backlog has no more disjoint work to dispatch (must-not-parallelize list exhausted).
- Repeated CI failures suggest a master regression (not flaky tests) — escalate to user.
- Coordinator context approaching the session limit — save state via memory, hand off.

## Links

- `docs/guides/DEV-GIT-WORKTREES.md` — worktree setup + `Agent(isolation: "worktree")` pattern
- `feedback_parallel_merge_strategy.md` (memory) — why sequential merges
- `feedback_parallel_agent_lint.md` (memory) — agents must grep for warnings not just errors
- `feedback_agent_prompt_template.md` (memory) — the pre-push checklist origin
- `feedback_squash_merge_strips_commit_body.md` (memory) — why manual `gh issue close`
- `feedback_analyze_stricter_in_ci.md` (memory) — strict `flutter analyze` before push
- `feedback_ci_watch_reliability.md` (memory) — `gh run list` over `gh pr checks --watch` after force-push
