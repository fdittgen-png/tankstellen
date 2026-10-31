<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# CI workflow catalog

Every GitHub Actions workflow has a dedicated runbook: triggers, inputs,
platform/flavor, required or advisory status, permissions, configured secrets,
artifacts, publication effects and recovery. Read [CI/CD Pipeline](Dev-CI-CD-Pipeline)
for the event matrix and [CI usage](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/CI_USAGE.md)
for safe branch and retry commands.

| Workflow | Source | Documentation |
|---|---|---|
| Publish · App Store listing | [`app-store-listing.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/app-store-listing.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/app-store-listing.md) |
| Status · App Store | [`app-store-status.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/app-store-status.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/app-store-status.md) |
| CI · Analyze, test & build | [`ci.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/ci.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/ci.md) |
| Release · Play open-testing (daily) | [`daily-beta.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/daily-beta.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/daily-beta.md) |
| Release · GitHub release (daily) | [`daily-github-release.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/daily-github-release.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/daily-github-release.md) |
| Release · Play Store deploy | [`deploy.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/deploy.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/deploy.md) |
| Tools · Dev APK (arm64) | [`dev-apk.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/dev-apk.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/dev-apk.md) |
| Nightly · Endpoint canary | [`endpoint-canary.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/endpoint-canary.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/endpoint-canary.md) |
| Tools · Epic checklist back-patch | [`epic-backpatch.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/epic-backpatch.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/epic-backpatch.md) |
| Publish · F-Droid repo | [`fdroid-publish.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/fdroid-publish.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/fdroid-publish.md) |
| CI · F-Droid no-GMS audit | [`fdroid.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/fdroid.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/fdroid.md) |
| Publish · Greek fuel prices | [`gr-fuel-publish.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/gr-fuel-publish.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/gr-fuel-publish.md) |
| Tools · iOS beta review info | [`ios-beta-review.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/ios-beta-review.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/ios-beta-review.md) |
| Tools · Add iOS TestFlight tester | [`ios-testers.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/ios-testers.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/ios-testers.md) |
| Status · iOS TestFlight | [`ios-testflight-status.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/ios-testflight-status.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/ios-testflight-status.md) |
| Release · iOS TestFlight build | [`ios-testflight.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/ios-testflight.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/ios-testflight.md) |
| CI · iOS simulator build | [`ios-validate.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/ios-validate.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/ios-validate.md) |
| Tools · Regenerate lockfiles | [`lock-regen.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/lock-regen.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/lock-regen.md) |
| Publish · Motorway exits | [`motorway-exits-publish.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/motorway-exits-publish.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/motorway-exits-publish.md) |
| Nightly · Flaky & network suite | [`nightly-flaky.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/nightly-flaky.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/nightly-flaky.md) |
| Nightly · Full test suite | [`nightly-full.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/nightly-full.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/nightly-full.md) |
| Publish · GitHub Pages (site + F-Droid repo) | [`pages.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/pages.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/pages.md) |
| Status · Play track | [`play-status.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/play-status.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/play-status.md) |
| Publish · Play Store listing | [`play-store-listing.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/play-store-listing.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/play-store-listing.md) |
| Release · Promote track | [`promote-release.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/promote-release.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/promote-release.md) |
| CI · Release boot check | [`release-boot.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/release-boot.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/release-boot.md) |
| Release · Train (all stores) | [`release-train.yml`](https://github.com/fdittgen-png/tankstellen/blob/master/.github/workflows/release-train.yml) | [Runbook](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/workflows/release-train.md) |

The retired `ci-docs-stub.yml` is replaced by applicability within main CI.
Status and maintenance workflows stay separate from builds and publishers so
an inspection does not start an upload. Only `ci.yml` owns required PR contexts.

This page is maintained in `docs/wiki/`; the GitHub wiki mirrors that directory.
