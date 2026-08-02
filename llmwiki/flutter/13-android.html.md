**13 · Platforms**

# Android

> Android is where most Flutter apps ship first and where the build system has the most ways to produce an artifact that looks correct and is not. Signing, shrinking, manifest merging and version codes each have a failure mode that passes CI and breaks on a user's device.

**Chunk prefix** android **Updated** 2026-08-01 **Depends on** 01 Foundations · 09 Confidentiality

#### On this page

1. [Flavors: store channels, not feature sets](#flavors)
1. [Signing that never falls back to debug](#signing)
1. [Play App Signing](#playsigning)
1. [R8 and the class it silently strips](#r8)
1. [Manifest merging and overlays](#manifest)
1. [Foreground services and the Play declaration](#fgs)
1. [Version codes, including per-ABI](#versioncodes)
1. [Toolchain pinning](#toolchain)
1. [Android Auto](#auto)
1. [Release checklist](#checklist)

<!-- chunk: android.flavors | tags: gradle,flavors,build -->

## Flavors: store channels, not feature sets

Use product flavors for *distribution channels* that differ in what they may link, never for feature variants — those belong in the feature-flag system.

```kotlin
flavorDimensions += "distribution"
productFlavors {
    create("play") {
        dimension = "distribution"
        // Google Play: proprietary services available.
    }
    create("fdroid") {
        dimension = "distribution"
        buildConfigField("boolean", "FORCE_LOCATION_MANAGER", "true")
        proguardFiles("proguard-rules-fdroid.pro")
    }
}
```

> **[RULE]**

> **One code base; channels differ only in what they may depend on.** A flavor is not a place to put a feature. If two channels should behave differently for a product reason, that is a feature flag with a per-channel default — see [the manifest pattern](01-foundations-architecture.html#feature-flags). Flavors multiply build combinations, and each combination is a thing CI must build and you must test.

> **[TRAP]**

> **Symptom: a Gradle command that works in a single-flavor project fails with "task not found".** Once flavors exist, every task name carries the flavor: `compilePlayDebugKotlin`, not `compileDebugKotlin`; `assembleFdroidRelease`, not `assembleRelease`. Update every script, every documentation snippet and every CI step at the moment you add the first flavor, or you will rediscover this one command at a time.

<!-- chunk: android.signing | tags: signing,keystore,gradle,security -->

## Signing that never falls back to debug

Resolve signing from environment variables first, a local properties file second — and if a release build is requested with neither, **fail the build**.

```kotlin
fun resolveReleaseSigning(): ReleaseSigningConfig? {
    val envPath  = System.getenv("ANDROID_KEYSTORE_PATH")
    val envPass  = System.getenv("ANDROID_KEYSTORE_PASSWORD")
    val envAlias = System.getenv("ANDROID_KEY_ALIAS")
    val envKey   = System.getenv("ANDROID_KEY_PASSWORD") ?: envPass

    if (!envPath.isNullOrEmpty() && !envPass.isNullOrEmpty() && !envAlias.isNullOrEmpty()) {
        return ReleaseSigningConfig(envPath, envPass, envAlias, envKey!!)
    }
    if (keystorePropertiesFile.exists()) { /* legacy local path */ }
    return null
}
```

```kotlin
signingConfig = if (releaseSigning != null) {
    signingConfigs.getByName("release")
} else {
    val tasks = gradle.startParameter.taskNames.map { it.lowercase() }
    val releaseTasks = tasks.filter { it.contains("release") && !it.contains("debug") }
    val isReleaseRequested = releaseTasks.isNotEmpty()

    // A libre-only release is legitimately UNSIGNED: that catalog's
    // buildserver signs with its own key downstream.
    val isLibreOnlyRelease =
        isReleaseRequested && releaseTasks.all { it.contains("fdroid") }

    if (isReleaseRequested && !isLibreOnlyRelease) {
        throw GradleException(
            "No release signing configuration available. Set " +
            "ANDROID_KEYSTORE_PATH / ANDROID_KEYSTORE_PASSWORD / " +
            "ANDROID_KEY_ALIAS, or create android/key.properties. " +
            "Release builds never fall back to the debug key."
        )
    }
    null   // debug builds, and the libre unsigned release
}
```

> **[WHY]**

> Evaluating the throw at configuration time breaks every debug build — including the ones an automated dependency-update bot runs, which legitimately cannot read the signing secrets because the platform strips them from bot-authored pull requests. Inspecting the requested task names is ugly and it is the mechanism that keeps both requirements true at once.

> **[TRAP]**

> **Symptom: an artifact builds and installs on a test device but will not upgrade an existing install, or the store rejects it.** The debug key signed it. This is the failure the throw exists to prevent: a silent debug-key fallback produces something that looks like a valid release in every way until it reaches a real user. Never make the fallback silent; make it a build failure.

> **[RULE]**

> **Delete restored signing material in an `if: always()` step.** A keystore left on a runner after a failed build is exactly when an artifact-upload step is most likely to pick it up. See [page 09](09-confidentiality.html#secrets).

<!-- chunk: android.playsigning | tags: play,signing,keys -->

## Play App Signing

Two keys exist and conflating them causes a whole class of confusion.

|   | Upload key | App signing key |
| --- | --- | --- |
| You hold it | Yes | No — the store does |
| Signs | The bundle you upload | The APKs delivered to devices |
| If lost | Recoverable — request a reset | **Not applicable**; the store holds it |
| Fingerprint used by third-party services | Only for pre-store testing | **This one**, for anything checking the installed app's signature |

> **[TRAP]**

> **Symptom: a signature-verified integration works in debug and on internal test, then fails in production.** You registered the upload-key fingerprint. Production APKs are signed with the *app signing key*, whose fingerprint is different and is shown in the console under app integrity. Register both. This is one of the strongest arguments for [browser-based OAuth](08-authentication.html#choice), which has no fingerprint dependency at all.

Sideload-signature note worth documenting for users: an artifact signed by your key and one signed by a third-party catalog's key cannot upgrade each other. A user switching between channels must uninstall first, which loses local data unless they export it. Say so in the install instructions.

<!-- chunk: android.r8 | tags: r8,proguard,release,crash -->

## R8 and the class it silently strips

Code shrinking runs only on release builds, so an entire class of crash exists exclusively in the artifact your users get and never in anything you tested.

> **[TRAP]**

> **Symptom: the release build dies before the first frame. Every unit test passes. The debug build is fine.** R8 removed a class that nothing references statically — because it is used through reflection, or by a serialisation library, or by a platform callback. One project's release builds crashed at launch because the shrinker stripped a library's reflective serialisation usage.

> **The countermeasure is not a better rule set. It is a test that runs the artifact:**

> ```yaml
> - name: Build the R8-shrunk release APK
>   run: flutter build apk --release --flavor play
>
> - name: Boot it on a real emulator and assert it survives
>   uses: reactivecircus/android-emulator-runner@v2
>   with:
>     api-level: 34
>     arch: x86_64
>     profile: pixel_6
>     script: |
>       adb install -r build/app/outputs/flutter-apk/app-play-release.apk
>       adb logcat -c
>       adb shell am start -W -n de.example.app/.MainActivity
>       sleep 15
>       adb shell pidof de.example.app || {
>         echo "::error::App died within 15s of launch"; adb logcat -d; exit 1; }
> ```

> Crude, and it catches the entire class. Cache the emulator snapshot — one project cut this job from 8–10 minutes to about 2 that way — and upload the full log as an artifact on every outcome, because when it fails the log is the whole investigation.

Keep rules where they belong:

```proguard
# proguard-rules.pro — base, all flavors
-keep class com.example.model.** { *; }              # reflective serialisation
-keepattributes Signature,*Annotation*,EnclosingMethod
-keepclassmembers class * { @com.example.Keep *; }

# proguard-rules-fdroid.pro — libre flavor ONLY
# The proprietary classes are excluded from this flavor's graph, so R8
# would abort with "Missing class …" without these.
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.play.**
```

> **[WHY]**

> Only R8 removes the framework's own dead references to optional store libraries. A debug artifact retains them, so a bytecode audit of a debug build can never reach the zero-reference bar that a catalog scanner applies. Build release, audit release. See [page 17](17-fdroid.html#audit).

<!-- chunk: android.manifest | tags: manifest,merging,permissions -->

## Manifest merging and overlays

Your final manifest is the merge of yours and every dependency's — and dependencies add permissions you did not ask for.

> **[TRAP]**

> **Symptom: the store listing shows permissions your app never uses.** One project shipped microphone, phone-state and legacy-storage permissions purely from merged library manifests. Users read the permission list; so do reviewers. Remove them explicitly:

> ```xml
> <manifest xmlns:tools="http://schemas.android.com/tools">
>   <uses-permission android:name="android.permission.RECORD_AUDIO"
>                    tools:node="remove" />
>   <uses-permission android:name="android.permission.READ_PHONE_STATE"
>                    tools:node="remove" />
> </manifest>
> ```

**Flavor manifest overlays** let a flavor add or restore declarations. Because a flavor source set outranks `main` in the merge, an overlay's plain declaration wins over a `tools:node="remove"` guard in `main` — which is the mechanism behind the foreground-service gate below.

```kotlin
sourceSets {
    getByName("play").manifest.srcFile(
        if (fgsFormApproved) "src/play/AndroidManifestFgsApproved.xml"
        else                 "src/play/AndroidManifest.xml"
    )
}
```

> **[CHECK]**

> Read the merged manifest after every dependency change, and assert on it:

> ```bash
> ./gradlew :app:processPlayReleaseManifest
> cat app/build/intermediates/merged_manifests/playRelease/AndroidManifest.xml
> ```

> Then write a test that compares the permission set against an expected list, so a new dependency's additions fail the build rather than surprising you in the store console.

<!-- chunk: android.fgs | tags: foreground-service,play-policy,background -->

## Foreground services and the Play declaration

Android has no "work in the background" permission. An app that keeps running with the screen off runs a **foreground service** — a service the OS keeps alive because it shows a persistent notification — and since recent policy changes, each service type needs a store-approved declaration.

| Type | Permission | Typical use |
| --- | --- | --- |
| `location` | `FOREGROUND_SERVICE_LOCATION` | Trip or activity recording started by the user |
| `connectedDevice` | `FOREGROUND_SERVICE_CONNECTED_DEVICE` | Holding a Bluetooth link to a paired device |
| `dataSync` | `FOREGROUND_SERVICE_DATA_SYNC` | A user-initiated upload or sync |
| `mediaPlayback` | `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Audio |

> **[TRAP]**

> **Symptom: the publishing API rejects your bundle with "you must let us know whether your app uses any foreground service permissions" — and the declaration form does not exist in the console.** A catch-22: the form appears only once an artifact declaring those permissions exists in a track, and the API refuses to accept such an artifact until the form is filled.

> **The way out is a manual browser upload.** Build the declaring bundle locally, upload it through the console into a draft release (it need not roll out to anyone), and the declaration task appears under app content. Fill it, submit, and once approved the API accepts the same artifact.

> **[RULE]**

> **Gate the whole feature behind one build-time flag that flips both halves in lockstep.** The Dart code that requests the service and the manifest that declares the permissions must never disagree. One flag, read in both places:

> ```bash
> flutter build appbundle --release --flavor play \
>   --dart-define=FGS_FORM_APPROVED=true
> ```

> ```kotlin
> // Gradle decodes Flutter's dart-defines and selects the manifest overlay.
> val dartDefines: Map<String, String> =
>     (project.findProperty("dart-defines") as String?)
>         ?.split(",")
>         ?.mapNotNull { runCatching {
>             String(Base64.getDecoder().decode(it)).split("=", limit = 2)
>                 .let { p -> if (p.size == 2) p[0] to p[1] else null }
>         }.getOrNull() }
>         ?.toMap() ?: emptyMap()
>
> val fgsFormApproved =
>     (dartDefines["FGS_FORM_APPROVED"] ?: System.getenv("FGS_FORM_APPROVED") ?: "false")
>         .let { it.equals("true", true) || it == "1" }
> ```

> The default build ships with **zero** foreground-service permissions, so uploads never hit the rejection. After approval, one repository variable flips it for every subsequent build with no code change. Add a script that asserts the default artifact really carries none — the guard is worthless if it can silently regress.

> **[WHY]**

> A foreground service *started while the app is visible* continues to receive location updates on the ordinary while-in-use permission. That means you can often avoid requesting the background-location permission entirely — which avoids a separate, stricter store declaration and a permission users refuse. Check whether your feature genuinely needs location while the app has never been opened; usually it does not.

<!-- chunk: android.versioncodes | tags: versioning,abi,release -->

## Version codes, including per-ABI

The version code is a signed 32-bit integer that must strictly increase, across every track and every workflow that can publish.

```bash
# Monotonic across workflows and machines; unique per minute.
BUILD_NUMBER=$(( 1000000 + ( $(date -u +%s) - 1751760000 ) / 60 ))
```

Split APKs need a distinct code per ABI, and the conventional scheme is `base × 10 + abiIndex`:

```kotlin
// GATED to the libre flavor: the store flavor carries the large shared
// wall-clock code, and ×10 would overflow the signed 32-bit ceiling.
val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
android.applicationVariants.configureEach {
    if (flavorName == "fdroid") {
        outputs.forEach { out ->
            val abi = out.filters.find { it.filterType == "ABI" }?.identifier
            abiCodes[abi]?.let {
                (out as ApkVariantOutputImpl).versionCodeOverride = versionCode * 10 + it
            }
        }
    }
}
```

> **[TRAP]**

> **Symptom: version codes go negative, or the build fails on an integer overflow.** A wall-clock-derived base is already around 2.03 × 10⁹; multiplying by ten exceeds 2 147 483 647. Apply the multiplier only to the flavor that needs split codes, and keep the store flavor on the shared value. See [page 05](05-traceability.html#build-to-commit).

App bundles do not need per-ABI codes — the store generates per-device APKs from one bundle. Per-ABI codes are for channels that distribute APKs directly.

<!-- chunk: android.toolchain | tags: gradle,jdk,pinning -->

## Toolchain pinning

| Component | Practice |
| --- | --- |
| Flutter SDK | Pinned exactly in every workflow. A floating stable channel once picked up an SDK whose bundled Gradle plugin hard-failed on a plugin's JVM-target mismatch. |
| JDK | 17, declared in both `compileOptions` and `kotlinOptions`. A mismatch between the two produces a confusing incremental-compilation failure. |
| Core library desugaring | Enabled if any dependency needs modern `java.time` on older API levels — notification libraries commonly do. |
| Gradle / AGP | Pinned in the wrapper and the plugin block. Let the update bot propose bumps; never float. |
| NDK | Pinned via the Flutter-provided value so all plugins agree. Mismatched NDK versions across plugins is a common Gradle failure. |

```kotlin
compileOptions {
    isCoreLibraryDesugaringEnabled = true
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}
kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

On a development machine where the JDK is not the system default, export `JAVA_HOME` explicitly before any Gradle invocation — and write that into the contributing guide, because the resulting error message does not name the cause.

<!-- chunk: android.auto | tags: android-auto,car,testing -->

## Android Auto

Car support is a separate library and a separate set of screens, and it is one of the few Android-specific surfaces that is genuinely unit-testable.

- `androidx.car.app` is a plain support library with no proprietary-services dependency, so a libre build is unaffected — but register the car components only in the store flavor's manifest if that is where you want them.
- Car screens are testable under a JVM test runner with the library's own screen controller. That requires merged Android resources and unmocked platform stubs in your test options.
- The in-car permission flow goes through the car context, not the normal activity flow. Version the library carefully: the in-car location-permission path stabilised in a specific release, and earlier versions will not do it.

```kotlin
testOptions {
    unitTests.isIncludeAndroidResources = true
    unitTests.isReturnDefaultValues = true
}
```

<!-- chunk: android.checklist | tags: release,checklist -->

## Release checklist

| # | Check | How |
| --- | --- | --- |
| 1 | Release build is signed with the real upload key | `apksigner verify --print-certs`; confirm it is not the debug certificate |
| 2 | The release artifact actually launches | The emulator aliveness job in [§R8](#r8) |
| 3 | Merged manifest declares only intended permissions | `processPlayReleaseManifest` + the assertion test |
| 4 | Foreground-service permissions match the approval state | The audit script; zero unless the flag is set |
| 5 | Version code strictly exceeds every published track | Read the console or the API before uploading |
| 6 | Changelog entry exists for this version | The CI gate in [page 05](05-traceability.html#changelog) |
| 7 | Per-locale release notes contain no embedded double quotes | See the trap below |
| 8 | Bundle size is not unexpectedly larger | Compare against the previous release; a jump means a dependency pulled something in |
| 9 | The build maps back to a commit | The tag push-back step |

> **[TRAP]**

> **Symptom: the build succeeds and the upload step fails on an argument error.** Release notes containing embedded double quotes get argument-split by the shell when passed through a CI invocation. The build has already succeeded, so it reads as a late, mysterious failure. Phrase release notes with single quotes, or pass them via a file. Re-dispatching is safe — a fresh build number is minted.

> **[TRAP]**

> **Symptom: a user insists a fixed bug is still present.** Check the version they are running before anything else. Open-testing channels lag, and a tester who joined a testing programme keeps receiving that channel's builds rather than production. The fastest resolution is to sideload a build from the current mainline and confirm against that. Put the version and build number on an about screen where a user can read them out.

#### Sources for this page

- One project's `build.gradle.kts`: the environment-first signing resolution with its deferred throw and its libre-unsigned exception, the two-flavor distribution dimension, the dart-defines decoder driving the manifest overlay, the flavor-gated per-ABI version-code override, and the car-app test options.
- Its foreground-service declaration guide, including the catch-22 and the manual-browser-upload workaround, and the observation that a foreground service started while visible avoids needing background location.
- The other project's emulator aliveness workflow, written specifically after an R8-stripped reflective dependency crashed release builds before the first frame, with a cached emulator snapshot.
- Post-mortems supplying the remaining traps: the merged-in unused permissions, the quoted release notes, and the stale testing-channel build.
