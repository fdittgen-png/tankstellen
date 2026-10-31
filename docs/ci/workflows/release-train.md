<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Release · Train (all stores)

[Workflow source](../../../.github/workflows/release-train.yml) · [CI usage](../CI_USAGE.md) · [All workflows](../../../.github/workflows/README.md)

The only daily tester cut, 16:00 UTC. Resolves one event SHA and passes it to every build leg. Beta builds Play and TestFlight. Production requires validated_build, promotes the existing Play beta and publishes F-Droid; App Store remains manual. Notification counts failed resolution, blocked production gate and unexpectedly skipped legs as failures. Nothing is auto-rebased.

| Property | Contract |
|---|---|
| Target | Play, TestFlight, F-Droid |
| Action/status | orchestrate publication; Publishing |
| Triggers | cron `0 16 * * *` (UTC); `workflow_dispatch` |
| Token permissions | contents: write, issues: write, pages: write, id-token: write, actions: read |
| Concurrency | `release-train`; cancel running: `False` |

## Run deliberately

```bash
gh workflow run release-train.yml --ref master -f channel=beta
```

- `channel`: Release channel (default: `beta`).
- `release_notes`: Release notes (Play + TestFlight; per-version changelogs used when empty) (default: `unset`).
- `validated_build`: PRODUCTION ONLY (#4161): the Play-signed beta build number you drove through docs/guides/production-artifact-gate.md. Blank blocks the promotion. (default: `unset`).

## Jobs

| Job | Runner or reusable workflow | Limit (minutes) |
|---|---|---|
| `resolve` | `ubuntu-latest` | 5 |
| `android-beta` | `./.github/workflows/daily-beta.yml` | callee |
| `production-artifact-gate` | `ubuntu-latest` | 20 |
| `android-production` | `./.github/workflows/promote-release.yml` | callee |
| `ios-testflight` | `./.github/workflows/ios-testflight.yml` | callee |
| `fdroid` | `./.github/workflows/fdroid-publish.yml` | callee |
| `notify` | `ubuntu-latest` | 10 |

## Artifacts and credentials

No downloadable build artifact; inspect the step summary and external destination described above.

Referenced configured secrets (required according to the chosen action): `MAIL_PASSWORD`, `MAIL_SMTP_SERVER`, `MAIL_TO`, `MAIL_USERNAME`.

## Recovery

Inspect the failed job and source identity before retrying. Fix deterministic failures on the feature branch. For an unchanged CI candidate, rerun the **entire workflow** once so plan and reports share the new attempt. For a publishing workflow, inspect the destination first: a failed final step does not prove that nothing was uploaded. GitHub concurrency permits at most one pending run per group; it is not a FIFO release queue.
