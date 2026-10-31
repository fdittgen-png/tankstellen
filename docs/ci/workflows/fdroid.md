<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# CI · F-Droid no-GMS audit

[Workflow source](../../../.github/workflows/fdroid.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Builds the actual libre release graph with pubspec.fdroid.lock and the committed overrides. The strict audit rejects proprietary dependency/class references, including dangling dex references. Produces an unsigned APK for inspection. Flavor-relevant paths trigger it; pure prose and unrelated test-only edits do not.

| Property | Contract |
|---|---|
| Target | Android / F-Droid |
| Action/status | audit/build; Advisory |
| Triggers | `pull_request` (path filtered); `push` (path filtered); `workflow_dispatch` |
| Token permissions | contents: read |
| Concurrency | `fdroid-${{ github.event_name }}-${{ github.event.pull_request.number || github.ref }}`; cancel running: `${{ github.event_name == 'pull_request' }}` |

## Run deliberately

```bash
gh workflow run fdroid.yml --ref YOUR_BRANCH
```

- `reason`: Reason for the manual run (audit trail) (default: `unset`).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `build-fdroid` | `ubuntu-latest` | 40 |

## Artifacts and credentials

- `fdroid-unsigned-apk-attempt-${{ github.run_attempt }}`: `build/app/outputs/flutter-apk/app-fdroid-release.apk`.

Referenced configured secrets (required according to the chosen action): none beyond the scoped GitHub token.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
