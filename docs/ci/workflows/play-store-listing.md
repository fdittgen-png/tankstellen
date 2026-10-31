<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Publish · Play Store listing

[Workflow source](../../../.github/workflows/play-store-listing.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Relevant metadata merges publish the listing; manual dry_run validates only. Uses the selected track and its current release version. Does not build an AAB. Published screenshots are mirrored to locale metadata directories before upload.

| Property | Contract |
|---|---|
| Target | Play metadata/screenshots |
| Action/status | publish listing; Publishing |
| Triggers | `workflow_dispatch`; `push` (path filtered) |
| Token permissions | contents: read |
| Concurrency | `play-store-listing`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run play-store-listing.yml --ref master
```

- `track`: Play Console track to publish to (default: `internal`).
- `dry_run`: Dry-run (validate only, no upload) (default: `False`).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `publish` | `ubuntu-latest` | 15 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): `PLAY_STORE_SERVICE_ACCOUNT_JSON`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
