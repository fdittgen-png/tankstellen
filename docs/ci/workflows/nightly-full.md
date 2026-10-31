<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Nightly · Full test suite

[Workflow source](../../../.github/workflows/nightly-full.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Bypasses selection to catch missing graph or runtime dependencies. Uses the immutable event commit. No redundant code generation over the committed outputs; the main codegen-drift gate owns freshness. Failure triage issues are deduplicated per UTC day and closed by a later green run.

| Property | Contract |
|---|---|
| Target | Flutter tests |
| Action/status | full suite/coverage; Scheduled health check |
| Triggers | cron `0 4 * * *` (UTC); `workflow_dispatch` |
| Token permissions | contents: read, issues: write |
| Concurrency | `nightly-full`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run nightly-full.yml --ref master
```

No inputs.

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `full-test` | `ubuntu-latest` | 60 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): none beyond the scoped GitHub token.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
