<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Publish · Motorway exits

[Workflow source](../../../.github/workflows/motorway-exits-publish.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Monthly on day 3 at 03:00 UTC. Extracts each country from Overpass. Successful country files publish even when another extraction fails; the final result remains red for partial failure. The existing 90-minute timeout reflects country queries, bounded retries and courtesy gaps.

| Property | Contract |
|---|---|
| Target | OSM motorway datasets |
| Action/status | publish release assets; Publishing |
| Triggers | `workflow_dispatch`; cron `0 3 3 * *` (UTC) |
| Token permissions | contents: write |
| Concurrency | `motorway-exits-publish`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run motorway-exits-publish.yml --ref master
```

No inputs.

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `publish` | `ubuntu-latest` | 90 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): none beyond the scoped GitHub token.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
