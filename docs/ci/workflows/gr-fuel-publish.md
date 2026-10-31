<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Publish · Greek fuel prices

[Workflow source](../../../.github/workflows/gr-fuel-publish.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

11:00 UTC daily. Parses official ministry PDFs and updates fuel-gr/latest.json as a rolling release asset, separate from Pages. A weekend without a bulletin is handled by the existing bounded lookback. Re-running replaces the rolling asset.

| Property | Contract |
|---|---|
| Target | Greek fuel dataset |
| Action/status | publish release asset; Publishing |
| Triggers | `workflow_dispatch`; cron `0 11 * * *` (UTC) |
| Token permissions | contents: write |
| Concurrency | `gr-fuel-publish`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run gr-fuel-publish.yml --ref master
```

No inputs.

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `publish` | `ubuntu-latest` | 15 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): none beyond the scoped GitHub token.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
