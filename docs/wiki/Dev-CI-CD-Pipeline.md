<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# CI / CD pipeline

All CI/CD workflows are documented in the [CI workflow catalog](Dev-CI-Workflow-Catalog).
The repository's [CI usage guide](https://github.com/fdittgen-png/tankstellen/blob/master/docs/ci/CI_USAGE.md)
contains safe commands, retry rules, artifact provenance and the local feedback loop.

`ci.yml` alone supplies all ten protected check names on every PR. Prose-only
changes run real lint contracts; mixed docs/code changes run normal validation.
A complete Git diff produces one current test/coverage plan for all four shards.
Invalid selection falls back to the full suite. Previous-green verdict caches
and the duplicate docs stub have been removed.

| Event | Validation/build | Publication |
|---|---|---|
| PR | Main planned tests and app gates; F-Droid for flavor inputs; iOS simulator for native/dependency inputs | None |
| Master push | Full deterministic suite, 40% coverage floor, unsigned Android debug build; relevant flavor/boot checks | Only site/listing paths with an existing publish trigger |
| Nightly/weekly | Full-suite safety net, flaky/network tests, endpoint probes | Daily tester train and GitHub prerelease retain their separate schedules |
| Version tag | Full CI and signed APK/AAB from the exact tag commit | GitHub release, Play internal upload, F-Droid repository |
| Manual | Explicit validation, simulator, F-Droid audit or developer APK action | Explicit release/publish/promote workflows; see their defaults |

Changed-line coverage is advisory (`COVERAGE_POLICY_ENFORCE=false`). The full
non-PR coverage floor remains enforced at 40%. iOS simulator and F-Droid audit
are advisory; a built artifact is not proof of store availability.

All release-train builds receive one pinned SHA. Artifact consumers verify the
source and successful producing run. Dependency caches contain no `.dart_tool`,
build output or test verdict. Superseded PR validation can cancel; intentional
releases and dispatches are preserved. Both Pages writers intentionally share a
deployment lock.

Branch protection keeps `strict=false`: merge conflict-free green PRs one at a
time, without rebasing after every unrelated merge. Work in separate worktrees;
the pre-push hook validates the current branch and pushed ref. See
[GitHub Workflow](Dev-GitHub-Workflow) and [Contributing](Dev-Contributing).
