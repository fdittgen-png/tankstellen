<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Release · Play Store deploy

[Workflow source](../../../.github/workflows/deploy.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Version tags wait for successful ci.yml output for the exact SHA and tag. Manual deploy-internal requires aab_run_id and verifies its source, workflow, event and success before download. No latest-success fallback. promote-rollout updates the chosen existing track; it does not rebuild. Only CI version-tag pushes produce signed android-aab artifacts.

| Property | Contract |
|---|---|
| Target | Android / Play |
| Action/status | AAB upload/rollout; Publishing |
| Triggers | `push`; `workflow_dispatch` |
| Token permissions | contents: read; deploy-internal/contents: read, deploy-internal/actions: read |
| Concurrency | `deploy`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run deploy.yml --ref master
```

- `action`: Action to perform (default: `promote-rollout`).
- `rollout_percentage`: Production rollout percentage (for promote-rollout) (default: `5`).
- `track_from`: Source track (for promote-rollout) (default: `beta`).
- `aab_run_id`: CI run ID to download AAB from (for deploy-internal, required for a manual upload; must match the selected source commit) (default: `unset`).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `deploy-internal` | `ubuntu-latest` | 40 |
| `promote-rollout` | `ubuntu-latest` | 40 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): `PLAY_STORE_SERVICE_ACCOUNT_JSON`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
