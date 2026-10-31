<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# CI · Release boot check

[Workflow source](../../../.github/workflows/release-boot.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Builds a release APK for the x86 emulator and checks that the shrunk app stays alive. Runs on relevant master changes or explicit dispatch. Resolves the requested ref once and records its SHA. It does not upload to a store.

| Property | Contract |
|---|---|
| Target | Android / Play |
| Action/status | release boot audit; Advisory |
| Triggers | `workflow_dispatch`; `push` (path filtered) |
| Token permissions | contents: read |
| Concurrency | `release-boot-${{ inputs.ref || github.ref }}`; cancel running: `${{ github.event_name == 'pull_request' }}` |

## Run deliberately

```bash
gh workflow run release-boot.yml --ref master -f ref=YOUR_BRANCH
```

- `ref`: Ref to build (default: the triggering ref) (default: `unset`).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `boot` | `ubuntu-latest` | 45 |

## Artifacts and credentials

- `release-boot-logcat`: `/tmp/release-boot-logcat.txt
/tmp/release-boot-crash.txt
`.
- `source-identity-<leg>-attempt-<n>` records the verified commit/tree.

Referenced configured secrets (required according to the chosen action): none beyond the scoped GitHub token.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
