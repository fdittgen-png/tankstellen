<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Release · Play open-testing (daily)

[Workflow source](../../../.github/workflows/daily-beta.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Called by the train with an exact source_sha; standalone dispatch uses the event SHA. Default track is beta. skip_upload=true builds without uploading or tagging, but signing credentials are still needed. FGS permissions remain controlled by the existing explicit flags. It has no independent cron.

| Property | Contract |
|---|---|
| Target | Android / Play |
| Action/status | signed build/store upload; Publishing |
| Triggers | `workflow_call`; `workflow_dispatch` |
| Token permissions | contents: read; build-and-upload/contents: write |
| Concurrency | `daily-beta`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run daily-beta.yml --ref master
```

- `track`: Play track (default: `beta`).
- `release_notes`: Release notes (overrides per-version changelog files) (default: `unset`).
- `fgs_bundle`: Build WITH the FGS permissions for this run only (#3695 — surfaces the #3436 declaration; ignores the FGS_FORM_APPROVED variable) (default: `False`).
- `skip_upload`: Skip the Play upload + tag; the AAB is available as a workflow artifact (#3695 — the pre-declaration API 403s on FGS bundles) (default: `False`).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `build-and-upload` | `ubuntu-latest` | 30 |

## Artifacts and credentials

- `app-play-release-${{ steps.bn.outputs.build_number }}`: `build/app/outputs/bundle/playRelease/app-play-release.aab`.
- `source-identity-<leg>-attempt-<n>` records the verified commit/tree.

Referenced configured secrets (required according to the chosen action): `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `PLAY_STORE_SERVICE_ACCOUNT_JSON`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
