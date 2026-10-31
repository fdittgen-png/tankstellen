<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Publish · GitHub Pages (site + F-Droid repo)

[Workflow source](../../../.github/workflows/pages.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Only relevant site assets trigger a deployment. No Flutter app is built. Reassembles the combined site, preserving the live F-Droid repository when it is not committed. Shares pages with fdroid-publish.yml to serialize writes to the single deployment target.

| Property | Contract |
|---|---|
| Target | Marketing/privacy/F-Droid site |
| Action/status | publish static site; Publishing |
| Triggers | `push` (path filtered); `workflow_dispatch` |
| Token permissions | contents: read, pages: write, id-token: write |
| Concurrency | `pages`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run pages.yml --ref master
```

No inputs.

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `deploy` | `ubuntu-latest` | 10 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): none beyond the scoped GitHub token.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
