<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# CI · Analyze, test & build

[Workflow source](../../../.github/workflows/ci.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

One complete same-attempt plan; real lint contracts for prose-only PRs. Native/shared/runtime changes run the full suite. Master, weekly and dispatch run all deterministic tests with the 40% whole-project floor. Changed-line coverage remains advisory. Only version-tag pushes sign APK/AAB output and publish a release. Manual dispatch is unsigned validation. Shards emit raw JSON timing and original process exits.

| Property | Contract |
|---|---|
| Target | All app targets |
| Action/status | validate/build; tag release; Required (ten existing contexts) |
| Triggers | `push`; `pull_request`; cron `0 6 * * 0` (UTC); `workflow_dispatch` |
| Token permissions | contents: read; release/contents: write |
| Concurrency | `ci-${{ github.event_name }}-${{ github.event.pull_request.number || github.ref }}`; cancel running: `${{ github.event_name == 'pull_request' }}` |

## Run deliberately

```bash
gh workflow run ci.yml --ref YOUR_BRANCH -f reason="full validation"
```

- `reason`: Reason for the manual run (audit trail) (default: `manual validation (no signing or publication)`).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `changes` | `ubuntu-latest` | 15 |
| `analyze` | `ubuntu-latest` | 15 |
| `codegen-drift` | `ubuntu-latest` | 15 |
| `l10n-gate` | `ubuntu-latest` | 15 |
| `test` | `ubuntu-latest` | 80 |
| `coverage-merge` | `ubuntu-latest` | 15 |
| `coverage-policy` | `ubuntu-latest` | 15 |
| `startup-budget` | `ubuntu-latest` | 15 |
| `integration` | `ubuntu-latest` | 15 |
| `security-scan` | `ubuntu-latest` | 15 |
| `license-audit` | `ubuntu-latest` | 15 |
| `dependency-check` | `ubuntu-latest` | 15 |
| `build-android` | `ubuntu-latest` | 40 |
| `release` | `ubuntu-latest` | 15 |

## Artifacts and credentials

- `ci-plan-attempt-${{ github.run_attempt }}`: `ci-plan/`.
- `test-results-${{ matrix.shard }}-attempt-${{ github.run_attempt }}`: `ci-results/`.
- `${{ github.event_name == 'pull_request' && 'pr-coverage' || 'coverage' }}-shard-${{ matrix.shard }}-attempt-${{ github.run_attempt }}`: `coverage/lcov.info`.
- `android-apk`: `build/app/outputs/flutter-apk/app-*-play-release.apk`.
- `android-aab`: `build/app/outputs/bundle/playRelease/app-play-release.aab`.
- `android-play-debug-attempt-${{ github.run_attempt }}`: `build/app/outputs/flutter-apk/app-play-debug.apk`.

Referenced configured secrets (required according to the chosen action): `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
