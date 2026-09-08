# CI / CD Pipeline

GitHub Actions. Definitions live in `.github/workflows/`.

## Triggers

| Event | Workflow | Action |
|---|---|---|
| PR opened / updated | `ci.yml` | `flutter analyze` + `flutter test` in parallel |
| Push to `master` | `ci.yml` + `build.yml` | Above + build Android APKs (per-ABI) and AAB |
| Tag `v*` pushed | `release.yml` | Create GitHub Release with artefacts + auto-notes |
| Weekly | Dependabot | Dependency bump PRs |

## `ci.yml` — every PR

The current pipeline runs as a fan-out of focused jobs, most of them parallel:

| Job | Purpose |
|---|---|
| `changes` | Detects which paths changed so downstream jobs can skip irrelevant work |
| `analyze` | `flutter analyze` — must be zero warnings |
| `codegen-drift` | `dart run build_runner clean && build`, then asserts the generated `*.g.dart` / `*.freezed.dart` files match what's checked in (hash check). Catches stale Riverpod / Freezed codegen — see the standing rule below |
| `test` | `flutter test --coverage` sharded into 4 partitions (`test 0..3`) for wall-clock parallelism |
| `coverage-merge` | Merges the four shard `lcov.info` reports + enforces the **45 %** threshold on app code (excludes `lib/l10n/`, `*.g.dart`, `*.freezed.dart`) |
| `startup-budget` | Asserts the app cold-starts within the configured budget — guards perf regressions |
| `integration` | `integration_test/` flows on the emulator |
| `security-scan` / `license-audit` / `dependency-check` | Third-party hygiene gates |
| `build-android` | Per-ABI APK + AAB build on PRs touching code; gated on `changes.code` |
| `release` | Tag-only — publishes the release artefacts to GitHub Releases |

`analyze`, `codegen-drift`, the four `test` shards and `startup-budget` all run in parallel to keep the PR cycle under ~6 min.

Pub and pub-cache are cached across runs keyed on `pubspec.lock`.

### Codegen-drift gate — the standing rule

Whenever you add a new Riverpod provider or a `freezed` class, run **clean** before pushing, not incremental:

```bash
dart run build_runner clean && \
  dart run build_runner build --delete-conflicting-outputs
```

Incremental builds keep stale hashes from the previous run; CI's clean run regenerates from scratch and fails the drift gate if you forgot to commit the new `*.g.dart` / `*.freezed.dart`. This is the most common reason a green-locally PR fails in CI.

## Coverage threshold

`ci.yml` post-processes `lcov.info`:

- Excludes `lib/l10n/`, `**.g.dart`, `**.freezed.dart`, `**.config.dart`, `test/**`.
- Fails the job if line coverage on the remaining files drops below **45 %**.

Historical rationale: UI is tested via widget tests which aren't cleanly attributed by lcov; counting them toward a higher number would give a false sense of safety.

## `build.yml` — master push

Produces three artefacts:

- `app-armeabi-v7a-release.apk` — ~20 MB
- `app-arm64-v8a-release.apk` — ~22 MB
- `app-release.aab` — fat bundle for Play Store

Build parameters:

- Build number auto-incremented from GitHub run number
- Signing: upload keystore from GitHub Secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`)
- `--obfuscate --split-debug-info=build/symbols` — stack traces stay readable locally but binary is harder to analyse
- ABI split via `flutter build apk --split-per-abi`

Artefacts are uploaded to the workflow run; the release workflow fetches them on tag.

## `release.yml` — on tag

Triggered by `git push origin v5.0.0`:

1. Download the artefacts from the last `master` build
2. `gh release create v5.0.0 --generate-notes` — GitHub composes notes from PR titles since the previous tag
3. Upload all three APKs + the AAB

The `CHANGELOG.md` is NOT auto-updated — update it on the release PR, not after the tag.

## iOS

Disabled. `iOS.yml` exists but is commented out. Enabling it requires:

- Apple Developer account ($99/year)
- Certificate + provisioning profile in GitHub Secrets
- An iOS runner (macOS)
- iOS privacy disclosures + App Store review passes

## Dependabot

`.github/dependabot.yml` enables weekly PRs for:

- pub (Dart/Flutter packages)
- github-actions (workflow versions)

Review policy:

- Minor / patch → merge if CI passes
- Major → dedicated `chore/bump-<package>` branch, tested thoroughly, check the changelog for breaking changes
- License check: all deps must be MIT / BSD / Apache-compatible. No GPL.

## Running CI locally

The same checks run with:

```bash
flutter analyze          # zero warnings
flutter test --coverage  # must pass, coverage ≥ 45 %
```

Pre-push hook (optional, `.git/hooks/pre-push`):

```bash
#!/usr/bin/env bash
set -e
flutter analyze
flutter test
```

## Secrets

| Secret | Used by | Purpose |
|---|---|---|
| `KEYSTORE_BASE64` | `build.yml` | Release signing |
| `KEYSTORE_PASSWORD` | `build.yml` | Keystore pwd |
| `KEY_ALIAS` | `build.yml` | Key alias in keystore |
| `KEY_PASSWORD` | `build.yml` | Key pwd |

Only the repo owner can touch these. Dependabot PRs don't receive secrets, so they can analyze + test but can't build.

## Troubleshooting

**"gradle cache" errors** — full Gradle wipe fixes them after dep updates. Locally: `cd android && ./gradlew clean` + `rm -rf ~/.gradle/caches`. CI handles this automatically.

**Coverage flakes** — one flaky integration test on slow runners. Mark with `@Tags(['flaky'])` and exclude in CI only while investigating. Never silently add `skip: true`.

**"Signing config failed"** — `KEYSTORE_BASE64` didn't expand. Re-check `docs/CONTRIBUTING.md` for the env var layout.

## Related

- [GitHub Workflow](Dev-GitHub-Workflow) — how PRs flow through the pipeline
- [Testing & TDD](Dev-Testing-TDD-Pyramid) — what the `test` job checks
