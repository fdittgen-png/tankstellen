<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# CI refactor validation — 2026-10-31

Owner follow-up: required independent review was enabled on `master` and read
back on 2026-10-31: eleven contexts (the ten CI checks plus
`independent-session-review`), `strict=false`, administrator enforcement enabled.
The reviewer helper/protection reapply regressions pass all 20 Python tests;
the affected workflow suite plus repository lints pass 233 tests. Clean
codegen and ARB/pseudo/localization regeneration produce no drift. These
follow-up checks are separate from the hosted performance evidence below.

Branch `ci/4451-pragmatic-workflows`, based on master
`13f2809838b6b947b931ef2a94faab9a0ea96a47`, in an isolated worktree.
The original checkout's `analysis_options.yaml` and `pubspec.lock` edits were
preserved. No branch protection setting, store deployment or wiki mirror was
published as part of implementation. The versioned wiki source is in this PR.

| Check | Result |
|---|---|
| All 27 workflows + shared-action YAML parse; `actionlint` | PASS |
| Python planner/real-Git/process/branch-guard regressions | PASS — 10 tests, including >300 paths, rename/delete, Unicode/newlines, missing base, partial/nonzero/noisy selector output, source/attempt mismatch, partition validation, duplicate/incomplete streams and wrong branch refs |
| `flutter test --no-pub test/ci test/lint test/l10n test/tool/test_selector_edges_test.dart test/tool/test_selector_test.dart test/tool/ci_selection_test.dart --exclude-tags=network,flaky` | 416 passed initially; the new referenced-doc test required staging its wiki page. Staged it and reran that test plus workflow policy tests: all seven passed. All 417 cases passed across these checks. |
| Real covered Flutter invocation through `scripts/ci/run_shard.py` | PASS — conso-mode suite; machine completion, original exit 0, covered report and per-file timing parsed |
| `flutter analyze --no-pub` | PASS — no issues, Flutter 3.44.9 |
| Clean `build_runner clean` + `build --delete-conflicting-outputs` | PASS — 550 outputs, no committed generated drift |
| ARB rebuild + pseudo-locale + `flutter gen-l10n` | PASS — no committed localization drift |
| `bash test/scripts/check_coverage_test.sh` | PASS — 18 assertions |
| `bash -n scripts/install_hooks.sh`; CI Markdown local links; `git diff --check` | PASS |
| Existing module-boundary shell fixtures | NOT VALIDATED on this host: macOS Bash 3.2 rejects the unchanged scanner's `declare -A`. Same 11 fixture failures reproduced in the untouched checkout. Linux CI uses a compatible Bash. Do not cite the scanner's local success message as execution proof after that interpreter error. |
| Full app suite, Android release/emulator, macOS simulator, hosted Actions and publishing credentials | NOT RUN locally — hosted checks must validate the PR; nothing was deployed |
| Before/after CI speed | Measured after merge using existing covered master runs; see the bounded hosted comparison below. CI_BASELINE.md remains historical. |

SDK: Flutter 3.44.9 / Dart 3.12.2, downloaded to temporary storage rather than
changing the user's Flutter 3.47.5 installation. `pubspec.lock` resolves with
`--enforce-lockfile` and is unchanged.

The workflow-name/status contexts are preserved; main CI is the only PR producer
of the ten protected names. The docs stub and incomplete green-marker cache are
removed. Only version-tag pushes sign/publish through main CI. Relevant iOS
native/dependency changes gain unsigned simulator compilation. Existing
F-Droid, FGS, coverage, localization and license contracts remain enforced at
their prior required/advisory levels.

This is an implementation checkpoint for #4451/#4525. Full native/flavor build
evidence and the broader test-usefulness/browser work in their related issues
are not claimed complete by local YAML/tool tests.

## Existing hosted before/after observation — 2026-10-31

Both completed master runs execute the full suite with coverage and the same
40% coverage gate. No workflow was dispatched or retried for this measurement.

| Observation | [Before: 41225272427](https://github.com/fdittgen-png/tankstellen/actions/runs/41225272427) | [After: 41241309496](https://github.com/fdittgen-png/tankstellen/actions/runs/41241309496) |
|---|---:|---:|
| Source | `f16377fe008184dbab55d8ef061cd5fd01b797b4` | `966d774cefe2a24edbc85ecef74c63f54c500c76` |
| Four test jobs: earliest start to latest completion | 72m17s | 23m42s |
| Sum of the four test-job runner intervals | 279m57s | 89m40s |
| Whole workflow: creation to final update | 75m00s | 25m45s |
| Filtered coverage; gate result | 73119/82794 (88.31%); PASS | 73117/82794 (88.31%); PASS |
| Dependency cache state | Warm legacy pub/build caches | Cold `pub-v2` on all four runners |

Application sources are identical (`lib` tree
`c7391c5bf2b1399a51bdd3e78848093f7b92cd14`), as are `pubspec.yaml`,
`pubspec.lock`, `dart_test.yaml` and `build.yaml`. Both use Flutter 3.44.9,
SDK revision `6b182d2c7585eba26d4edce0f97630effd256c33`.
The inventory grows from 2028 to 2030 runnable files because five CI test files
changed: `ci_workflow`, `coverage_policy_workflow`, `workflow_policy`,
`ci_selection` and `test_selector`. This is an application-workload match,
with disclosed test changes, rather than byte-identical entire test sources.

Old logs and new machine reports preserve every 20157 visible passed
`(file, case name)` pair in unchanged test files. Three GitHub-masked names
were matched by unique same-file prefix/pattern against identical source.
New master reports 20258 visible passes and the same one pre-existing skip;
its case multiset also matches both completed plain PR runs. All four planned
shards complete with exit 0; file allocations cover the 2030-file plan once.
The six existing network/flaky file exclusions remain unchanged. Hidden
loading/setup events are excluded from these case counts.

These single hosted observations include setup, artifact and teardown time;
summed runner intervals are neither CPU measurements nor billing invoices.
Cache ownership and partitioning changed together, and runner scheduling
varies. The new master dependency cache was cold while the SDK cache was warm
in both runs. Do not attribute the elapsed difference to a cache speedup,
compare covered master with plain PR tests, or promise this ratio for future
runs. The small covered-line variation does not alter the denominator or gate.
