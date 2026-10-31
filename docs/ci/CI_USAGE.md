<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# CI usage and branch discipline

The [workflow catalog](../../.github/workflows/README.md) links a runbook for
**every workflow**. The [wiki overview](../wiki/Dev-CI-CD-Pipeline.md) is its
short entry point. Changes implement the shared CI seams tracked by #4451 and
#4525; they do not claim those broader issues' performance/platform acceptance
is complete. The approach follows Deskilo's complete change classification,
source identity and dependency-only caching, while preserving Sparkilo's ten
existing protected check names.

## Start on the intended branch

Use a separate worktree for each task. This preserves another session's branch
and uncommitted edits:

```bash
git fetch origin master
git worktree add -b ci/ISSUE-short-name ../tankstellen-ci-ISSUE origin/master
cd ../tankstellen-ci-ISSUE
git branch --show-current
git status --short
bash scripts/install_hooks.sh
```

Before committing or pushing, inspect `git branch --show-current` and
`git diff --stat`. Push the explicit task branch with
`git push -u origin ci/ISSUE-short-name`. The installed pre-push hook checks the
actual ref records before generation: branch pushes must come from the current
named branch and go to that same branch; pushing master is rejected. Tags and
branch deletions do not pretend to push a working branch. The existing explicit
`SKIP_PREPUSH=1` emergency escape remains, with its existing accountability.

Live protection read on 2026-10-31 has **strict=false**. Preserve that setting.
An independently green, conflict-free PR does not need a rebase just because
another PR merged. Merge one PR at a time, then check the next for actual file
or semantic conflicts. Update a branch only to resolve a real conflict, bring
in a prerequisite, or test a known interaction. If needed, merge `origin/master`
once in the task worktree; do not repeatedly rewrite published commits or
force-push other sessions' branches. Use a merge queue if strict freshness
becomes necessary; changing strictness is a repository-settings decision.

After a squash merge, leave the task worktree alone until its work is saved.
Start the next task in a fresh worktree from `origin/master`; do not silently
switch the shared checkout to master.

## Local feedback loop

Use **Flutter 3.44.9**, pinned in
[flutter-setup](../../.github/actions/flutter-setup/action.yml). A newer local
SDK is not evidence the pinned build passes.

```bash
flutter pub get --enforce-lockfile
flutter analyze
flutter test test/path/to_changed_test.dart --exclude-tags=network,flaky
python3 -m unittest discover -s test/scripts -p 'ci_*_test.py'
actionlint
```

Run focused tests while editing, and inspect a compact failure summary first.
The shared hook still enforces clean codegen and locale fan-out before pushing:

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
dart tool/build_arb.dart
dart tool/gen_pseudo_arb.dart
flutter gen-l10n
git diff --stat
```

Commit resulting generated drift as required by [AGENT_RULES](../AGENT_RULES.md).
Do not format entire generated files or raise baselines to pass a check.

## What a PR runs

`ci.yml` starts on **every** PR to master. It alone owns the protected contexts:
`analyze`, `test (0..3)`, `codegen-drift`, `l10n-gate`, `build-android`,
`integration`, `startup-budget`. No duplicate docs stub can supply a passing
check alongside failed code validation.

| Change | Tests | Other work |
|---|---|---|
| Markdown in `docs/wiki/`, `docs/ci/`, `docs/decisions/`, or the small explicit root prose list | Real `test/lint/` contracts, in four planned allocations | App analysis/codegen/localization/native build deliberately not applicable |
| Mixed prose + Dart | Affected tests, their transitive imports/exports/parts, always-run contracts and coverage subset | Normal app gates; Android when app inputs change |
| Test-only Dart | Changed tests and dependents, always-run contracts | No Android packaging |
| Deleted helper, native, tool, workflow, dependency, packaged help, fixture, asset or unknown input | Full deterministic suite | Relevant app/build/audit gates |
| Missing base, empty diff, failed/partial/invalid selector | Full deterministic suite, or a failed prerequisite if no trustworthy plan can be produced | Never a partial passing selection |
| Master, weekly schedule or manual dispatch | Full deterministic suite with coverage | Full analysis/drift/dependency checks; unsigned debug Android build |

The positive prose allow-list lives in `scripts/ci/plan.py`. Broad `docs/**`,
`**/*.md` and Fastfile ignores are unsafe. Unknown paths require work. Git uses
a complete NUL-delimited diff with renames represented under both names; it is
not constrained by the trigger API's path limit. The PR base SHA and checked-out
merge-candidate SHA are immutable inputs. No branch name is reread by the shards.

`changes` runs the existing selector and coverage graph once through the
SDK-only `tool/ci_selection.dart` adapter. CI opts into export edges; the legacy
selector CLI keeps its documented historical behavior. Shards download and
validate the same JSON plan: source, base, tree/config, SDK/flavor, run, attempt,
diff hash and exact allocation. Nonzero selector output is discarded in full.
Selected files run once across the four shards, split into plain and measured
files. The small dedicated localization, startup and integration gates retain
their existing focused checks; these are intentional additional checks, not a
claim of global test deduplication.

Network/flaky tags remain excluded from deterministic CI and live in their own
nightly. The full nightly bypasses selection. iOS native/dependency edits also
run advisory unsigned simulator compilation; dispatch it for Dart-only iOS
validation. F-Droid runs its existing strict libre release audit for
flavor-relevant paths. Neither becomes a new required context.

## Coverage, evidence and caches

The whole-project **40%** floor remains enforced on the main workflow's full
non-PR coverage.
Changed-line coverage remains **advisory** with
`COVERAGE_POLICY_ENFORCE=false`; a warning is not enforced coverage. Security,
license, F-Droid reference and foreground-service invariants remain intact.

Artifacts are on the Actions run:

- `ci-plan-attempt-N`: exact identities, complete changed paths/diff, selected
  files, allocation, fallback reason and selector stderr/exit.
- `test-results-S-attempt-N`: the original machine stream and `result.json`
  containing commands, original/validated exits, elapsed seconds and test timing
  observations. A zero allocation or tag-excluded slice is explicit. Timings do
  not decide whether a test passed; the original process and complete stream do.
- `[pr-]coverage-shard-S-attempt-N`: reports from the same run attempt. An
  explicitly empty slice differs from a missing report. Full-suite merge fails
  if a shard report is missing. Changed-line evidence errors obey its existing
  advisory/enforced switch.
- Debug/simulator/unsigned APK and source identity artifacts are documented in
  each platform runbook; they cannot substitute for a signed store artifact.

Only dependencies/toolchains are cached. Pub keys include OS, architecture,
SDK and flavor lockfile; the shared action disables the upstream action's pub
cache to avoid two owners. No `.dart_tool`, `build/`, test verdict, green marker
or mutated fixture state is restored. A plan is same-run evidence, never a cache.
The removed green-tree marker did not bind the tested base/selection/config.

## Manual validation, builds and publication

These commands are examples, not instructions to deploy while reviewing CI:

```bash
# Full validation: no signing or store/release publication.
gh workflow run ci.yml --ref YOUR_BRANCH -f reason='full validation'
# Independent build/audit paths; no publication.
gh workflow run ios-validate.yml --ref YOUR_BRANCH
gh workflow run fdroid.yml --ref YOUR_BRANCH
# Signed developer APK only; needs Android signing secrets.
gh workflow run dev-apk.yml --ref master -f ref=YOUR_BRANCH
# Repair derived lockfiles with a trusted workflow and explicit target branch.
gh workflow run lock-regen.yml --ref master -f branch=YOUR_BRANCH
```

Publishing is separate: `release-train.yml`, `daily-beta.yml`,
`ios-testflight.yml`, `fdroid-publish.yml`, version-tag CI, listing/data/site
publishers and promotion workflows can change external destinations. Consult
their runbooks and input defaults. The train pins one SHA before any platform
build. Production still requires the Play-signed device validation record.
Build workflows accepting older refs load shared actions from the workflow's
own revision, then verify the candidate checkout; old sources need not contain
the new composite action files.

Version-tag CI is the signed APK/AAB producer consumed by `deploy.yml`. That
consumer requires successful `ci.yml` output from the exact tag/source. A manual
internal upload requires an explicit `aab_run_id`; it never picks an unrelated
latest successful PR build. Regular master CI no longer signs redundant app
artifacts: daily store/GitHub release workflows own their distribution builds.

## Retry without churn or large log dumps

```bash
gh pr checks PR_NUMBER
gh run view RUN_ID --json conclusion,jobs,url
gh run view RUN_ID --log-failed
gh run download RUN_ID --name ci-plan-attempt-1 --dir /tmp/ci-plan-review
# One retry for unchanged source and a transient failure:
gh run rerun RUN_ID
```

Use a **whole-workflow rerun**, not `--failed` or `--job`, for main CI. A partial
rerun of shards or coverage has no complete current-attempt plan/reports and
fails closed. A leaf-only retry does not create a new complete run. A new source
commit needs a new PR run. Fix deterministic failures instead of retrying them.
Cancel superseded PR validation only; schedules, intentional dispatches, tags
and uploads are not interrupted by this policy. GitHub allows at most one
pending run per concurrency group, so concurrency is not a FIFO work queue.

A lock-regeneration push made with `GITHUB_TOKEN` does not start ordinary PR
workflows. Inspect its summary. A branch dispatch is useful for diagnostics, but
GitHub documents that it need not satisfy required PR contexts. To restore real
PR-event checks on the new head, use your own authenticated account to close and
reopen that PR once, or make the next genuine correction commit. Do not create
empty commits, perpetual update-branch loops, or repeated rebases as a retry
mechanism. Before retrying a publisher, query the destination's status: an
upload may have succeeded before a later step failed.

## Measurement and remaining limits

[CI baseline](CI_BASELINE.md) records actual sampled runs. No end-to-end speedup
is claimed before matched hosted runs exist. Compare the same candidate and
plan, SDK/flavor, tags and coverage mode; label warm/cold/partial cache state.
Report queue time separately from wall time and summed runner time. Raw streams
allow per-file/concurrency/coverage profiling without another test invocation.
The longest historical cost is full-suite coverage, not YAML setup. Rebalance
from compatible measurements rather than changing shard count by guesswork.

Sources: [GitHub required checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks),
[workflow concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency),
[rerunning workflows](https://cli.github.com/manual/gh_run_rerun),
[Flutter action inputs](https://github.com/subosito/flutter-action/blob/v2/action.yaml).
