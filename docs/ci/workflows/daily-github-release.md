<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Release · GitHub release (daily)

[Workflow source](../../../.github/workflows/daily-github-release.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

21:00 UTC GitHub prerelease. Skips when no commits landed since the prior nightly. All jobs check out and verify the same event SHA; none reads moving master. Downloads Android and Apple artifacts from this run. It publishes a GitHub release, independently of the tester-store train; these destinations are intentionally distinct.

| Property | Contract |
|---|---|
| Target | Android/iOS device |
| Action/status | signed build/GitHub release; Publishing |
| Triggers | cron `0 21 * * *` (UTC); `workflow_dispatch` |
| Token permissions | contents: write |
| Concurrency | `daily-github-release`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run daily-github-release.yml --ref master
```

No inputs.

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `pre-check` | `ubuntu-latest` | 5 |
| `build-android` | `ubuntu-latest` | 30 |
| `build-ios` | `macos-latest` | 60 |
| `release` | `ubuntu-latest` | 10 |
| `skipped-summary` | `ubuntu-latest` | 5 |

## Artifacts and credentials

- `android-release`: `build/app/outputs/bundle/playRelease/app-play-release.aab
`.
- `android-debug-symbols`: `build/symbols`.
- `ios-release`: `build/ios/ipa/Runner.ipa
build/ios/ipa/*.app.dSYM.zip
`.
- `source-identity-<leg>-attempt-<n>` records the verified commit/tree.

Referenced configured secrets (required according to the chosen action): `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_BASE64`, `APP_STORE_CONNECT_API_KEY_ID`, `MATCH_DEPLOY_KEY`, `MATCH_PASSWORD`, `RELEASE_TOKEN`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
