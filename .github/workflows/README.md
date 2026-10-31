<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# GitHub Actions

[CI usage and safe branch workflow](../../docs/ci/CI_USAGE.md) ·
[Wiki overview](../../docs/wiki/Dev-CI-CD-Pipeline.md).

Every workflow has a linked runbook covering inputs, jobs, permissions,
configured secrets, artifacts, side effects and recovery. Workflow names use
`<CI|Nightly|Release|Publish|Status|Tools> · <sentence case>`.
Job names are check contexts: preserve them when changing implementation.

| Workflow/runbook | File | Trigger | Platform/data | Action | Merge role |
|---|---|---|---|---|---|
| [Publish · App Store listing](../../docs/ci/workflows/app-store-listing.md) | `app-store-listing.yml` | manual | App Store metadata/screenshots | publish/submit listing | Publishing |
| [Status · App Store](../../docs/ci/workflows/app-store-status.md) | `app-store-status.yml` | manual | App Store versions | read status | Read-only report |
| [CI · Analyze, test & build](../../docs/ci/workflows/ci.md) | `ci.yml` | `push`; `pull_request`; cron `0 6 * * 0` (UTC); manual | All app targets | validate/build; tag release | Required (ten existing contexts) |
| [Release · Play open-testing (daily)](../../docs/ci/workflows/daily-beta.md) | `daily-beta.yml` | called; manual | Android / Play | signed build/store upload | Publishing |
| [Release · GitHub release (daily)](../../docs/ci/workflows/daily-github-release.md) | `daily-github-release.yml` | cron `0 21 * * *` (UTC); manual | Android/iOS device | signed build/GitHub release | Publishing |
| [Release · Play Store deploy](../../docs/ci/workflows/deploy.md) | `deploy.yml` | `push`; manual | Android / Play | AAB upload/rollout | Publishing |
| [Tools · Dev APK (arm64)](../../docs/ci/workflows/dev-apk.md) | `dev-apk.yml` | manual | Android / Play arm64 | signed build only | Manual maintenance |
| [Nightly · Endpoint canary](../../docs/ci/workflows/endpoint-canary.md) | `endpoint-canary.yml` | cron `23 5 * * 1` (UTC); manual | Country endpoints | live endpoint probe | Scheduled health check |
| [Tools · Epic checklist back-patch](../../docs/ci/workflows/epic-backpatch.md) | `epic-backpatch.yml` | `issues` | GitHub issues | update epic checklist | Issue automation |
| [Publish · F-Droid repo](../../docs/ci/workflows/fdroid-publish.md) | `fdroid-publish.yml` | `push`; manual; called | Android / F-Droid + Pages | signed build/repo publication | Publishing |
| [CI · F-Droid no-GMS audit](../../docs/ci/workflows/fdroid.md) | `fdroid.yml` | `pull_request` (path filtered); `push` (path filtered); manual | Android / F-Droid | audit/build | Advisory |
| [Publish · Greek fuel prices](../../docs/ci/workflows/gr-fuel-publish.md) | `gr-fuel-publish.yml` | manual; cron `0 11 * * *` (UTC) | Greek fuel dataset | publish release asset | Publishing |
| [Tools · iOS beta review info](../../docs/ci/workflows/ios-beta-review.md) | `ios-beta-review.yml` | manual | TestFlight review configuration | update review info | Manual maintenance |
| [Tools · Add iOS TestFlight tester](../../docs/ci/workflows/ios-testers.md) | `ios-testers.yml` | manual | TestFlight testers | invite/manage testers | Manual maintenance |
| [Status · iOS TestFlight](../../docs/ci/workflows/ios-testflight-status.md) | `ios-testflight-status.yml` | manual | TestFlight/testers | read status | Read-only report |
| [Release · iOS TestFlight build](../../docs/ci/workflows/ios-testflight.md) | `ios-testflight.yml` | called; manual | iOS device | signed build/TestFlight | Publishing |
| [CI · iOS simulator build](../../docs/ci/workflows/ios-validate.md) | `ios-validate.yml` | `pull_request` (path filtered); manual | iOS simulator | build | Advisory |
| [Tools · Regenerate lockfiles](../../docs/ci/workflows/lock-regen.md) | `lock-regen.yml` | manual | Play/F-Droid dependencies | regenerate branch files | Manual maintenance |
| [Publish · Motorway exits](../../docs/ci/workflows/motorway-exits-publish.md) | `motorway-exits-publish.yml` | manual; cron `0 3 3 * *` (UTC) | OSM motorway datasets | publish release assets | Publishing |
| [Nightly · Flaky & network suite](../../docs/ci/workflows/nightly-flaky.md) | `nightly-flaky.yml` | cron `0 5 * * *` (UTC); manual | Flutter tests/live APIs | tagged tests/audit | Scheduled health check |
| [Nightly · Full test suite](../../docs/ci/workflows/nightly-full.md) | `nightly-full.yml` | cron `0 4 * * *` (UTC); manual | Flutter tests | full suite/coverage | Scheduled health check |
| [Publish · GitHub Pages (site + F-Droid repo)](../../docs/ci/workflows/pages.md) | `pages.yml` | `push` (path filtered); manual | Marketing/privacy/F-Droid site | publish static site | Publishing |
| [Status · Play track](../../docs/ci/workflows/play-status.md) | `play-status.yml` | manual | Play tracks | read status | Read-only report |
| [Publish · Play Store listing](../../docs/ci/workflows/play-store-listing.md) | `play-store-listing.yml` | manual; `push` (path filtered) | Play metadata/screenshots | publish listing | Publishing |
| [Release · Promote track](../../docs/ci/workflows/promote-release.md) | `promote-release.yml` | called; manual | Android / Play | promote existing artifact | Publishing |
| [CI · Release boot check](../../docs/ci/workflows/release-boot.md) | `release-boot.yml` | manual; `push` (path filtered) | Android / Play | release boot audit | Advisory |
| [Release · Train (all stores)](../../docs/ci/workflows/release-train.md) | `release-train.yml` | cron `0 16 * * *` (UTC); manual | Play, TestFlight, F-Droid | orchestrate publication | Publishing |

The ten protected contexts belong to `ci.yml`: `analyze`, `test (0)` through
`test (3)`, `codegen-drift`, `l10n-gate`, `build-android`, `integration`,
`startup-budget`. The unsafe `ci-docs-stub.yml` duplicate producer was retired.
The main workflow has no PR path filters. Prose-only changes run real lint
contracts through its normal four contexts; mixed changes run actual validation.

`coverage-policy` stays advisory (`COVERAGE_POLICY_ENFORCE=false`); the full-suite
40% floor stays enforced. The F-Droid and iOS simulator audits are advisory.
Status, listing, dataset and release workflows remain separate because they have
different triggers and external side effects. Pages publishers intentionally
share `pages`; all other concurrency groups are namespaced by workflow.

Flutter 3.44.9 and dependency-only caching live in
[flutter-setup](../actions/flutter-setup/action.yml). It disables the upstream
pub-cache owner and owns one cache keyed by OS, architecture, SDK and flavor
lockfile. No `.dart_tool`, build output or previous-green verdict is cached.
Runtime changes affect all consumers through this one reviewed action.
