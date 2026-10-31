<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Nightly · Flaky & network suite

[Workflow source](../../../.github/workflows/nightly-flaky.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Runs flaky OR network tests, which are excluded from deterministic PR CI. Zero matches fail. A second job checks decomposition-issue references. These jobs can create/close triage issues; they are not PR gates.

| Property | Contract |
|---|---|
| Target | Flutter tests/live APIs |
| Action/status | tagged tests/audit; Scheduled health check |
| Triggers | cron `0 5 * * *` (UTC); `workflow_dispatch` |
| Token permissions | contents: read, issues: write |
| Concurrency | `nightly-flaky`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run nightly-flaky.yml --ref master
```

No inputs.

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `flaky-suite` | `ubuntu-latest` | 30 |
| `decomposition-issue-audit` | `ubuntu-latest` | 10 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): none beyond the scoped GitHub token.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
