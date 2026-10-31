<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Status · Play track

[Workflow source](../../../.github/workflows/play-status.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Queries track availability without committing a Play edit. Does not share a concurrency group with deployments, so a status query cannot displace a queued release. Inspect Managed Publishing after promotions.

| Property | Contract |
|---|---|
| Target | Play tracks |
| Action/status | read status; Read-only report |
| Triggers | `workflow_dispatch` |
| Token permissions | contents: read; status/contents: read |
| Concurrency | `play-status`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run play-status.yml --ref master
```

No inputs.

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `status` | `ubuntu-latest` | 10 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): `PLAY_STORE_SERVICE_ACCOUNT_JSON`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
