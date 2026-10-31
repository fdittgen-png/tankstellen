<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Tools · Regenerate lockfiles

[Workflow source](../../../.github/workflows/lock-regen.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Dispatch from master with an explicit feature branch. Rejects master as a target, resolves both lockfiles with the pinned SDK, verifies both and uses a normal fast-forward push. Refuses a moved branch rather than force-pushing/rebasing. Shared actions come from the workflow revision so pre-refactor dependency branches still work. A GITHUB_TOKEN push does not trigger normal PR checks: follow the recovery instructions in CI_USAGE.md.

| Property | Contract |
|---|---|
| Target | Play/F-Droid dependencies |
| Action/status | regenerate branch files; Manual maintenance |
| Triggers | `workflow_dispatch` |
| Token permissions | contents: read; regen/contents: write |
| Concurrency | `lock-regen-${{ inputs.branch }}`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run lock-regen.yml --ref master -f branch=chore/ISSUE-dependency-fix
```

- `branch`: Branch to regenerate on (e.g. a dependabot/pub/... branch) (default: `unset`).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `regen` | `ubuntu-latest` | 20 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): none beyond the scoped GitHub token.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
