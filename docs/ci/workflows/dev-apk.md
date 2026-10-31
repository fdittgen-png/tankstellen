<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Tools · Dev APK (arm64)

[Workflow source](../../../.github/workflows/dev-apk.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

Builds a private sideload APK, with no store upload. Resolves the requested ref once and verifies the checkout. Signing secrets are still needed. The upload-key-signed APK is a different install channel from Play App Signing. Use ci.yml dispatch for unsigned debug validation.

| Property | Contract |
|---|---|
| Target | Android / Play arm64 |
| Action/status | signed build only; Manual maintenance |
| Triggers | `workflow_dispatch` |
| Token permissions | contents: read |
| Concurrency | `dev-apk-${{ inputs.ref || github.ref }}`; cancel running: `${{ github.event_name == 'pull_request' }}` |

## Run deliberately

```bash
gh workflow run dev-apk.yml --ref master -f ref=YOUR_BRANCH
```

- `ref`: Branch, tag, or SHA to build (defaults to master) (default: `master`).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `build` | `ubuntu-latest` | 30 |

## Artifacts and credentials

- `dev-apk-arm64-${{ github.event.inputs.ref }}-${{ github.run_number }}`: `build/app/outputs/flutter-apk/app-play-release.apk`.
- `source-identity-<leg>-attempt-<n>` records the verified commit/tree.

Referenced configured secrets (required according to the chosen action): `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
