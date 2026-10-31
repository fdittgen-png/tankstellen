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
follow-up checks do not replace the outstanding matched performance evidence.

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
| Before/after CI speed | NOT MEASURED — three historical event samples and reproduction commands are in CI_BASELINE.md; no speedup percentage is claimed |

SDK: Flutter 3.44.9 / Dart 3.12.2, downloaded to temporary storage rather than
changing the user's Flutter 3.47.5 installation. `pubspec.lock` resolves with
`--enforce-lockfile` and is unchanged.

The workflow-name/status contexts are preserved; main CI is the only PR producer
of the ten protected names. The docs stub and incomplete green-marker cache are
removed. Only version-tag pushes sign/publish through main CI. Relevant iOS
native/dependency changes gain unsigned simulator compilation. Existing
F-Droid, FGS, coverage, localization and license contracts remain enforced at
their prior required/advisory levels.

This is an implementation checkpoint for #4451/#4525. Hosted matched timing,
full native/flavor build evidence and the broader test-usefulness/browser work
in their related issues are not claimed complete by local YAML/tool tests.
