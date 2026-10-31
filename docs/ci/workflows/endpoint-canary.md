<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Nightly · Endpoint canary

[Workflow source](../../../.github/workflows/endpoint-canary.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Weekly real-endpoint checks plus a human-readable report. Opens or updates endpoint triage when probes fail. API availability is deliberately outside required PR checks.

| Property | Contract |
|---|---|
| Target | Country endpoints |
| Action/status | live endpoint probe; Scheduled health check |
| Triggers | cron `23 5 * * 1` (UTC); `workflow_dispatch` |
| Token permissions | contents: read, issues: write |
| Concurrency | `endpoint-canary`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run endpoint-canary.yml --ref master
```

No inputs.

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `probe` | `ubuntu-latest` | 15 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): none beyond the scoped GitHub token.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
