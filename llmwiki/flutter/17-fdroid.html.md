**17 · Platforms**

# F-Droid

> F-Droid is the only channel that inspects your bytecode. A dependency-graph audit that satisfies you will not satisfy their scanner, because it reads the shipped artifact and rejects even a dangling reference to a proprietary class. Everything on this page follows from that one fact.

**Chunk prefix** fdroid **Updated** 2026-08-01 **Depends on** 13 Android · 09 Confidentiality

#### On this page

1. [Two channels: self-hosted and catalog](#channels)
1. [Making a build genuinely libre](#libre)
1. [Swapping dependencies before resolution](#swap)
1. [The three-layer audit](#audit)
1. [The reproducible-build recipe](#recipe)
1. [The second lockfile](#lockfile)
1. [Running your own repository](#selfhosted)
1. [What users need to be told](#userfacing)

<!-- chunk: fdroid.channels | tags: fdroid,distribution,strategy -->

## Two channels: self-hosted and catalog

You can publish immediately from your own repository, and separately submit to the official catalog. Do both, in that order.

|   | Self-hosted repository | Official catalog |
| --- | --- | --- |
| Who builds | You | **Their buildserver, from your tagged source** |
| Who signs | You, with a repo signing key | They do, with theirs |
| Time to first release | An afternoon | Weeks — a merge request plus review |
| Discoverability | Users must add your repository URL | Listed in every F-Droid client |
| Audit bar | Yours to enforce | Their scanner, strictly |
| Update mechanism | You regenerate the index | Automatic from your tags |

> **[RULE]**

> **Stand up the self-hosted repository first.** It gets a libre build into users' hands in an afternoon, and it forces you to solve the actual hard problem — making the build libre — before you are also waiting on someone else's review queue. The catalog submission then becomes a packaging exercise on a build you already trust.

> **[WHY]**

> The whole proposition is that the binary corresponds to the published source. Their buildserver checks out your tagged commit, builds in a controlled environment, and signs the result. That means your build must be reproducible from a clean checkout with no secrets, no network beyond dependency resolution, and no manual steps — which is a genuinely useful constraint to satisfy even if you never submit.

<!-- chunk: fdroid.libre | tags: gms,dependencies,libre -->

## Making a build genuinely libre

Find every proprietary dependency, including the transitive ones, and give each a replacement or a removal. In one project this was five sources.

| What pulled it in | Proprietary payload | Resolution |
| --- | --- | --- |
| Location plugin | Play Services location | Exclude the group; the plugin falls back to the platform's own location manager, selected by a build-config flag |
| Text-recognition plugin | ML Kit, Play Services base | Excluded. The feature detects the missing channel and degrades — the recognition call catches the missing-plugin exception and returns null |
| In-app review plugin | Play Core | Excluded. The service swallows the resulting error and no-ops. |
| Barcode scanner | ML Kit barcode backend | Replaced with an FFI binding to a free scanning library, selected when the flavor is libre. See [page 11](11-barcode-qr.html#swap). |
| Crash reporter | A tracking SDK | **Compiled out entirely.** Catalogs classify reporting SDKs as tracking. |

```kotlin
// Exclude the proprietary groups from the libre flavor's graph.
// Scope is the libre flavor ONLY — the store flavor is untouched.
val excluded = listOf(
    "com.google.android.gms",
    "com.google.mlkit",
    "com.google.android.play",
    "io.sentry",
)
listOf(
    "fdroidImplementation",
    "fdroidReleaseRuntimeClasspath",
    "fdroidDebugRuntimeClasspath",
    "fdroidProfileRuntimeClasspath",
).forEach { name ->
    configurations.matching { it.name == name }.configureEach {
        excluded.forEach { g -> exclude(group = g) }
    }
}
```

> **[RULE]**

> **Every excluded dependency needs a graceful-degradation path and a test for it.** Excluding a group means the plugin's platform channel simply is not there, and calling it raises a missing-plugin exception at runtime. Catch it at the service boundary and return a named unavailable state — never let it reach the UI as a crash. Then write the test that injects that exception and asserts the app stays usable.

```proguard
# proguard-rules-fdroid.pro — libre flavor ONLY.
# The real classes are absent from this flavor's graph, so R8 would abort
# with "Missing class …" without these.
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.play.**
-dontwarn io.sentry.**
```

<!-- chunk: fdroid.swap | tags: dependencies,build,overrides -->

## Swapping dependencies before resolution

Gradle exclusions handle the Android side. The Dart side needs the package itself replaced, before dependency resolution, or its symbols remain in the artifact.

```text
tool/apply_fdroid_overrides.dart          # runs BEFORE `flutter pub get`
  ├─ pubspec_overrides.fdroid.yaml → pubspec_overrides.yaml
  │     mobile_scanner:  { path: tool/fdroid_stubs/mobile_scanner }
  │     in_app_review:   { path: tool/fdroid_stubs/in_app_review }
  │     sentry_flutter:  { path: tool/fdroid_stubs/sentry_flutter }
  └─ pubspec.fdroid.lock → pubspec.lock
```

Each stub is a package with the same public API whose implementations are no-ops or throw a named unavailable error. Nothing imports a stub directly — the application code selects the libre path at runtime — but the stub is what removes the real package's symbols from the build.

> **[RULE]**

> **A runtime branch is not enough.** Writing `if (isLibre) useFreeScanner() else useMlKit()` selects correctly and still links both libraries into the artifact, where the scanner will find them. The swap must happen at dependency-resolution time. This is the single most common way a libre build fails an audit while appearing correct in every functional test.

Run the override tool as the first step of both the audit workflow and the catalog recipe's prebuild, so the audit runs against exactly the graph the catalog will build.

<!-- chunk: fdroid.audit | tags: audit,dex,r8,verification -->

## The three-layer audit

Three layers, any of which failing fails the audit. The third is the one that matters and the one most projects skip.

| Layer | Inspects | Bar |
| --- | --- | --- |
| **A — dependency graph** | The resolved runtime classpath, via Gradle | No proprietary coordinates. Fast, deterministic, always runs. This is what the reproducible build itself inspects. |
| **B — bytecode definitions** | Every dex in the built APK | No proprietary class is *defined* in the shipped bytecode |
| **C — strict references** | The same dex, on a **release** APK | Not even a **dangling reference** to a proprietary type. **This is the bar the catalog's scanner applies.** |

```bash
# Coordinates in the resolved graph (layer A).
GRAPH='com\.google\.android\.gms|com\.google\.mlkit|com\.google\.android\.play|io\.sentry'

# Type descriptors in the dex (layers B and C). Note the SLASH after
# "google": the project's own plugin packages are com.google_mlkit_* with
# an underscore, which this pattern correctly never matches.
DEX='Lcom/google/android/gms/|Lcom/google/mlkit/|Lcom/google/android/play/|Lio/sentry/'

unzip -o "$APK" 'classes*.dex' -d "$TMP"
for d in "$TMP"/classes*.dex; do
  dexdump -f "$d" 2>/dev/null | grep -Eo "$DEX" && fail=1
done
```

> **[TRAP]**

> **Symptom: a catalog merge request is rejected on references your own audit reported clean.** Two causes, both real:

1. **You audited a debug build.** Only the release-mode shrinker removes the Flutter embedding's own dead references to optional store libraries. A debug dex retains them permanently, so a debug audit can never reach zero references — and a definition-only audit will not see them at all.
1. **You audited the dependency graph only.** A graph tells you what was declared, not what survived into the artifact.

> **Fix:** build a **release** APK and run layers B and C on it. A correctly-prepared libre release dex audits at zero for every pattern. One project's submission was rejected on exactly these invisible references, and the strict reference gate was added afterwards specifically to catch them before a reviewer does.

> **[RULE]**

> **Keep the audit workflow advisory, not a required check.** It builds a full release APK and runs Gradle — a transient infrastructure failure must never block an unrelated merge. The authoritative fast gate is layer A; the artifact layers are the belt-and-braces proof you run on every push and read when it fails.

> **[WHY]**

> A libre-only release with no keystore produces an unsigned APK, and that is the sanctioned shape: the catalog signs downstream with its own key. Your signing configuration must permit this exact case while still refusing to fall back to a debug key for any other release — see the deferred-throw pattern on [page 13](13-android.html#signing).

<!-- chunk: fdroid.recipe | tags: metadata,recipe,reproducible-build -->

## The reproducible-build recipe

The catalog metadata file tells their buildserver how to build your app. For a Flutter app with split APKs it is one build block per architecture.

```yaml
Categories: [ Internet, Navigation ]
License: MIT
AuthorName: Example
SourceCode: https://github.com/org/app
IssueTracker: https://github.com/org/app/issues
Name: MyApp

RepoType: git
Repo: https://github.com/org/app.git

Builds:
  - versionName: 6.0.4
    versionCode: 51372                  # base × 10 + abi index
    commit: f85f238007aa7a85e6b52ebd24ac94604fb34051
    output: build/app/outputs/flutter-apk/app-*-fdroid-release.apk
    srclibs: [ flutter@stable ]
    prebuild:
      # Read the pinned SDK version out of the CI workflow — ONE source
      # of truth for the toolchain version.
      - flutterVersion=$(sed -n -E 's/.*flutter-version:\ "(.*)"/\1/p' .github/workflows/fdroid.yml)
      - '[[ $flutterVersion ]]'
      - git -C $$flutter$$ checkout -f $flutterVersion
      - cp pubspec_overrides.fdroid.yaml pubspec_overrides.yaml
      - cp pubspec.fdroid.lock pubspec.lock
      - export PUB_CACHE=$(pwd)/.pub-cache
      - $$flutter$$/bin/flutter config --no-analytics
      - $$flutter$$/bin/flutter pub get --enforce-lockfile
      - $$flutter$$/bin/dart run build_runner build --delete-conflicting-outputs
    scanignore:
      - third_party/vendored_plugin_a
      - third_party/vendored_plugin_b
    scandelete:
      - .pub-cache
    build:
      - export PUB_CACHE=$(pwd)/.pub-cache
      - $$flutter$$/bin/flutter build apk --release --flavor fdroid --split-per-abi
        --target-platform android-arm64 --build-number=$(( $$VERCODE$$ / 10 ))
        --dart-define=FORCE_LOCATION_MANAGER=true

AutoUpdateMode: Version
UpdateCheckMode: Tags ^v[0-9.]+$
VercodeOperation:
  - '%c * 10 + 1'
```

| Element | Why it is written that way |
| --- | --- |
| `srclibs: flutter@stable` plus a checkout of the parsed version | Their buildserver needs the SDK. Parsing it from your CI workflow keeps one source of truth instead of a version that silently drifts. |
| `--enforce-lockfile` | The build must be reproducible. Without it, resolution can pick different versions than you tested. |
| `scanignore` | Their scanner flags vendored third-party source. List each vendored directory explicitly, with a comment saying why it is vendored. |
| `scandelete` | Remove the local package cache before scanning, or the scan walks every downloaded dependency. |
| `--build-number=$(( VERCODE / 10 ))` | Reverse the per-ABI multiplier so the app's internal build number matches the store's. |
| `AutoUpdateMode` / `UpdateCheckMode` | New versions are picked up from your tags automatically — no further merge requests for routine releases. |

Submit by forking the catalog's metadata repository, adding your file, and opening a merge request. Expect review iterations; the ones observed in practice were about dropping unnecessary keys and about the bytecode audit, not about the app.

<!-- chunk: fdroid.lockfile | tags: lockfile,dependencies,maintenance -->

## The second lockfile

> **[TRAP]**

> **Symptom: the libre audit goes red on every dependency-update pull request, forever.** A libre build has a different dependency graph — stubs instead of real packages — so it needs its own lockfile. That lockfile does not regenerate itself when the main one changes, so every routine dependency bump leaves it stale and the enforced-lockfile step fails.

> **Countermeasure:** automate the regeneration in the same pull request, or add it as an explicit item in the dependency-update checklist. One project pays this cost manually on every such PR and names it in its own notes as a recurring, avoidable annoyance — which is exactly the shape of a task that should be scripted.

```bash
# Regenerate the libre lockfile after any dependency change.
dart run tool/apply_fdroid_overrides.dart   # swap in stubs + libre lock
flutter pub get                             # resolve and rewrite it
cp pubspec.lock pubspec.fdroid.lock
git checkout -- pubspec.lock pubspec_overrides.yaml   # restore the normal build
git add pubspec.fdroid.lock
```

> **[CHECK]**

> Enforce the lockfile in the audit workflow with `flutter pub get --enforce-lockfile`. That makes a stale libre lockfile fail in *your* CI rather than on the catalog's buildserver, where the feedback loop is measured in days.

<!-- chunk: fdroid.selfhosted | tags: self-hosted,repository,pages -->

## Running your own repository

A repository is a signed index plus APKs, served over static hosting. The tooling generates both.

```yaml
# fdroid/config.yml — secrets are NEVER inlined.
repo_url: https://org.github.io/app/fdroid/repo
repo_name: MyApp
repo_description: >-
  The Google-services-free build — no proprietary services, open maps,
  platform location only.
repo_icon: icon.png

keystore: keystore.p12                          # git-ignored
keystorepass: {env: FDROID_REPO_KEYSTORE_PASSWORD}
keypass:      {env: FDROID_REPO_KEY_PASSWORD}
repo_keyalias: myapp-fdroid-repo
```

| Point | Detail |
| --- | --- |
| **The repo key is not the app key** | Two separate keystores. The repo key signs the index; the app key signs the APK. |
| **Passwords come from the environment** | The tooling supports an environment indirection. The same configuration then works locally and in CI with no secret in the file. |
| **The keystore file is git-ignored** | Base64 it into a CI secret; decode it to a temporary path at build time and delete it in an `if: always()` step. |
| **Single-version repository** | Unless you need an archive, drop older builds rather than accumulating them. |
| **Publish on a version tag** | Build, sign, regenerate the index, deploy the static site. |

> **[TRAP]**

> **Symptom: the repository disappears after an unrelated documentation deploy.** If your static site deploy does a full replace and the repository index is generated rather than committed, a docs-only deploy wipes it — the site publishes without the directory that was never in the repository. One project hit exactly this. Two fixes, and you want both: commit the generated index so it is part of the source tree, and give the two workflows a shared concurrency group so they can never deploy simultaneously.

<!-- chunk: fdroid.userfacing | tags: documentation,users,signing -->

## What users need to be told

> **[RULE]**

> **Document the signature incompatibility prominently.** An APK signed by you and one signed by the catalog cannot upgrade each other — Android refuses an install whose signature differs from the installed app's. A user switching channels must uninstall first, which loses local data unless they export it. Say this on the download page, next to both links, and make sure your export/import flow actually works before you publish to a second channel.

Also worth stating plainly, because it is the reason someone chose this channel:

- **What the libre build does not have.** If a feature depends on an excluded dependency, say which and why — an honest "text recognition is unavailable in this build because it required a proprietary library" is better than a button that silently does nothing.
- **What replaced what.** Platform location instead of the fused provider; a free scanning library instead of the proprietary one; no crash reporting at all.
- **How to add the repository.** The URL, and a note that it is added under repositories in the client.
- **That there is no telemetry whatsoever** in this build — which, if you compiled the reporter out, is a claim you can actually make.

> **[WHY]**

> The audience for a libre build self-selected for exactly this information. A clear statement of what was removed and what replaced it is not a list of limitations to them — it is the product description. Burying it reads as evasion.

#### Sources for this page

- One project's libre build: the Gradle group exclusions scoped to the libre flavor, the flavor-only ProGuard rules, the override tool that swaps stub packages before resolution, the separate libre lockfile enforced in CI, and the graceful-degradation paths for each excluded dependency.
- Its three-layer audit script — dependency graph, dex definitions, and the strict reference gate — together with the recorded catalog rejection on references that a debug-dex audit could not see, and the finding that only release-mode shrinking removes the framework's own dead references.
- Its catalog metadata recipe (three per-ABI builds, SDK version parsed from the CI workflow, enforced lockfile, scan ignores for vendored plugins) and its self-hosted repository configuration with environment-indirected passwords.
- The static-site deploy incident that wiped the self-hosted repository index, and the two-part fix.
