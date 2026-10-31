<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Tools · Epic checklist back-patch

[Workflow source](../../../.github/workflows/epic-backpatch.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

On a newly opened child issue, replaces a matching title-only checklist item in its referenced epic with the numbered issue link. No app build or branch mutation. Per-issue concurrency prevents unrelated children from cancelling each other.

| Property | Contract |
|---|---|
| Target | GitHub issues |
| Action/status | update epic checklist; Issue automation |
| Triggers | `issues` |
| Token permissions | issues: write, contents: read |
| Concurrency | `epic-backpatch-${{ github.event.issue.number || github.ref }}`; cancel running: `False` |

## Run deliberately

No manual dispatch. Use the event listed above.

No inputs.

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `backpatch` | `ubuntu-latest` | 5 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): none beyond the scoped GitHub token.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
