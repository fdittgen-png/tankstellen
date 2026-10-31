<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Release · Promote track

[Workflow source](../../../.github/workflows/promote-release.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Promotes an existing release between tracks without recompilation. dry_run reports intent without committing. Default production promotion is a real store action. For production, prefer the train so its validated_build gate records the device check.

| Property | Contract |
|---|---|
| Target | Android / Play |
| Action/status | promote existing artifact; Publishing |
| Triggers | `workflow_call`; `workflow_dispatch` |
| Token permissions | contents: read |
| Concurrency | `promote-release`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run promote-release.yml --ref master
```

- `from_track`: Source track (newest completed release is promoted) (default: `beta`).
- `to_track`: Target track (default: `production`).
- `dry_run`: Resolve and print the promotion without committing (default: `False`).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `promote` | `ubuntu-latest` | 10 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): `PLAY_STORE_SERVICE_ACCOUNT_JSON`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
