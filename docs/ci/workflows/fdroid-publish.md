<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Publish · F-Droid repo

[Workflow source](../../../.github/workflows/fdroid-publish.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Builds the libre release, signs it, regenerates the repository index and deploys the combined Pages site. Called train legs receive source_sha. Shares the pages concurrency lock with pages.yml because both replace the same site; preserve this deliberate cross-workflow exception.

| Property | Contract |
|---|---|
| Target | Android / F-Droid + Pages |
| Action/status | signed build/repo publication; Publishing |
| Triggers | `push`; `workflow_dispatch`; `workflow_call` |
| Token permissions | contents: read, pages: write, id-token: write |
| Concurrency | `pages`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run fdroid-publish.yml --ref master
```

No inputs.

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `publish` | `ubuntu-latest` | 40 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.
- `source-identity-<leg>-attempt-<n>` records the verified commit/tree.

Referenced configured secrets (required according to the chosen action): `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `FDROID_REPO_KEYSTORE_BASE64`, `FDROID_REPO_KEYSTORE_PASSWORD`, `FDROID_REPO_KEY_PASSWORD`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
