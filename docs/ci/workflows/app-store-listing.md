<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Publish · App Store listing

[Workflow source](../../../.github/workflows/app-store-listing.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Dispatch defaults to dry_run=true and submit=false. Uploading metadata and submitting for review are separate explicit inputs. Existing demo-video/review-note safeguards remain. macOS is retained for the existing Fastlane environment; no speculative runner migration.

| Property | Contract |
|---|---|
| Target | App Store metadata/screenshots |
| Action/status | publish/submit listing; Publishing |
| Triggers | `workflow_dispatch` |
| Token permissions | contents: read |
| Concurrency | `app-store-listing`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run app-store-listing.yml --ref master
```

- `dry_run`: Dry-run (deliver --verify_only — validate metadata, no upload) (default: `True`).
- `submit`: Submit for review after upload (DANGER — only when intentional; ignored on a dry run) (default: `False`).
- `build_number`: Build to submit (#3849 — the ASC build number, e.g. 2026701964). Empty leaves whatever ASC has selected. (default: `unset`).
- `upload_screenshots`: Also upload ios/fastlane/screenshots/<locale>/ (#3521) (default: `False`).
- `overwrite_screenshots`: Delete existing ASC screenshots first (#3525 — set false when the version state blocks deletion: "Can't Delete Screenshot After Submit for review") (default: `True`).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `publish` | `macos-latest` | 15 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_BASE64`, `APP_STORE_CONNECT_API_KEY_ID`, `DEMO_VIDEO_URL`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
