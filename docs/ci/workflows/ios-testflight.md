<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Release · iOS TestFlight build

[Workflow source](../../../.github/workflows/ios-testflight.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

The train supplies the exact source_sha; standalone dispatch uses the event SHA. distribute controls external distribution/Beta App Review; sync_certs is explicit repair mode. No independent cron. Signing success is not evidence that external testers can install; verify the status workflow.

| Property | Contract |
|---|---|
| Target | iOS device |
| Action/status | signed build/TestFlight; Publishing |
| Triggers | `workflow_call`; `workflow_dispatch` |
| Token permissions | contents: read; build-and-upload/contents: write |
| Concurrency | `ios-testflight`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run ios-testflight.yml --ref master
```

- `release_notes`: TestFlight changelog (max 4000 chars) (default: `Daily build.`).
- `distribute`: Distribute to external "extern" testers (submits for Beta App Review). Scheduled runs always distribute. (default: `False`).
- `sync_certs`: Repair mode: run write-mode match (appstore) to generate MISSING provisioning profiles into the certs repo instead of building. Use when match fails with "No matching provisioning profiles found" (e.g. a new signed target like the widget extension was added). (default: `False`).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `build-and-upload` | `macos-15` | 60 |

## Artifacts and credentials

- `ios-debug-symbols`: `build/symbols`.
- `source-identity-<leg>-attempt-<n>` records the verified commit/tree.

Referenced configured secrets (required according to the chosen action): `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_BASE64`, `APP_STORE_CONNECT_API_KEY_ID`, `BETA_CONTACT_FIRST`, `BETA_CONTACT_LAST`, `BETA_CONTACT_PHONE`, `BETA_FEEDBACK_EMAIL`, `DEMO_VIDEO_URL`, `MATCH_DEPLOY_KEY`, `MATCH_PASSWORD`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
