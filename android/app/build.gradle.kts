// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import java.util.Base64
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// -----------------------------------------------------------------------------
// Signing config resolution (#48)
//
// Secrets are resolved in this order so env vars (CI, secure local dev via
// direnv) always win over the legacy plaintext file:
//
//   1. Environment variables:
//        ANDROID_KEYSTORE_PATH      — absolute path to the .jks file
//        ANDROID_KEYSTORE_PASSWORD  — store password
//        ANDROID_KEY_ALIAS          — key alias inside the store
//        ANDROID_KEY_PASSWORD       — key password (falls back to store password)
//   2. Legacy `key.properties` file at the project root (still supported for
//      developer convenience; slated for removal once every dev has switched
//      to env vars).
//
// If neither is present AND a release build is requested, the build FAILS
// instead of silently falling back to the debug signing key. That failure is
// the fix for the second half of #48's acceptance criteria: "CI explicitly
// fails without key.properties instead of falling back to debug signing".
// -----------------------------------------------------------------------------
val keystorePropertiesFile = rootProject.file("key.properties")
val legacyKeystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    legacyKeystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

data class ReleaseSigningConfig(
    val storeFile: String,
    val storePassword: String,
    val keyAlias: String,
    val keyPassword: String,
)

fun resolveReleaseSigning(): ReleaseSigningConfig? {
    val envPath = System.getenv("ANDROID_KEYSTORE_PATH")
    val envPass = System.getenv("ANDROID_KEYSTORE_PASSWORD")
    val envAlias = System.getenv("ANDROID_KEY_ALIAS")
    val envKeyPass = System.getenv("ANDROID_KEY_PASSWORD") ?: envPass

    if (!envPath.isNullOrEmpty() && !envPass.isNullOrEmpty() && !envAlias.isNullOrEmpty()) {
        return ReleaseSigningConfig(
            storeFile = envPath,
            storePassword = envPass,
            keyAlias = envAlias,
            keyPassword = envKeyPass ?: envPass,
        )
    }

    if (keystorePropertiesFile.exists()) {
        return ReleaseSigningConfig(
            storeFile = legacyKeystoreProperties["storeFile"] as String,
            storePassword = legacyKeystoreProperties["storePassword"] as String,
            keyAlias = legacyKeystoreProperties["keyAlias"] as String,
            keyPassword = legacyKeystoreProperties["keyPassword"] as String,
        )
    }

    return null
}

val releaseSigning: ReleaseSigningConfig? = resolveReleaseSigning()

// -----------------------------------------------------------------------------
// #3173 — Foreground-service un-throttle trigger (ships dark until the Google
// Play "Foreground Service Use" form (#1498) is approved).
//
// Flutter forwards every --dart-define to Gradle as the `dart-defines`
// project property (comma-separated base64 "KEY=VALUE" entries). Decoding it
// here lets ONE flag flip both halves of the restore in lockstep:
//
//   flutter build appbundle --flavor play --dart-define=FGS_FORM_APPROVED=true
//
//   * Dart   — kGpsRecordingForegroundServiceEnabled (lib/core/location/
//              recording_location_settings.dart) turns true, so the trip
//              recorder requests geolocator's foreground service (the
//              un-throttle lever against Android's ~5 s background batching).
//   * Gradle — the flavor manifest overlay (sourceSets below) swaps to the
//              *FgsApproved variant, which re-declares the FOREGROUND_SERVICE*
//              permissions and (play flavor) the AutoRecordForegroundService.
//
// Without the define (the default, and what every current CI build does) the
// merged manifest keeps today's Play-compliant shape: ZERO FOREGROUND_SERVICE*
// permissions, so edits.commit never 403s on the form. FGS_FORM_APPROVED=1 in
// the environment is accepted as a fallback for plain ./gradlew invocations
// (e.g. manifest-merge inspection without the Flutter tool in front).
// -----------------------------------------------------------------------------
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.mapNotNull { encoded ->
            try {
                val decoded = String(
                    Base64.getDecoder().decode(encoded),
                    Charsets.UTF_8,
                )
                val idx = decoded.indexOf('=')
                if (idx > 0) decoded.take(idx) to decoded.substring(idx + 1) else null
            } catch (_: IllegalArgumentException) {
                null // not base64 (defensive) — skip the entry
            }
        }
        ?.toMap()
        ?: emptyMap()

val fgsFormApproved: Boolean =
    (dartDefines["FGS_FORM_APPROVED"] ?: System.getenv("FGS_FORM_APPROVED") ?: "false")
        .let { it.equals("true", ignoreCase = true) || it == "1" }

android {
    namespace = "de.tankstellen.tankstellen"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // Android Auto v1 (#2948) — the car-screen JVM tests run under Robolectric
    // (androidx.car.app:app-testing + ScreenController), which needs the merged
    // Android resources (string lookups) and unmocked android.* stubs.
    testOptions {
        unitTests.isIncludeAndroidResources = true
        unitTests.isReturnDefaultValues = true
    }

    defaultConfig {
        applicationId = "de.tankstellen.fuelprices"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigning != null) {
            create("release") {
                keyAlias = releaseSigning.keyAlias
                keyPassword = releaseSigning.keyPassword
                storeFile = file(releaseSigning.storeFile)
                storePassword = releaseSigning.storePassword
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // #48 — if a release build is requested but no release signing
            // config is resolvable, FAIL THE BUILD. We never silently fall
            // back to the debug signing key: that produced artefacts that
            // looked valid in CI but would not upgrade an existing install
            // on user devices.
            //
            // The throw is deferred to ACTUAL release tasks only. Without
            // this guard the exception would fire at config-evaluation
            // time even for `assemblePlayDebug` (Dependabot CI runs that
            // legitimately can't read the keystore secrets — GitHub's
            // bot-actor security policy strips them from PRs).
            signingConfig = if (releaseSigning != null) {
                signingConfigs.getByName("release")
            } else {
                val taskNames = gradle.startParameter.taskNames
                    .map { it.lowercase() }
                val isReleaseRequested = taskNames.any { name ->
                    name.contains("release") && !name.contains("debug")
                }
                if (isReleaseRequested) {
                    throw GradleException(
                        "No release signing configuration available. " +
                            "Set ANDROID_KEYSTORE_PATH / ANDROID_KEYSTORE_PASSWORD / " +
                            "ANDROID_KEY_ALIAS environment variables (CI: use GitHub " +
                            "Secrets), or create android/key.properties locally. " +
                            "Release builds never fall back to the debug key — see #48."
                    )
                }
                // Debug-only builds (e.g. `assemblePlayDebug`) don't need
                // a release signing config. Leaving this null lets the
                // configuration phase complete; any subsequent attempt to
                // actually assemble a release variant would fail at the
                // signing task, which is still strictly safer than
                // silently signing with the debug key (the original #48
                // failure mode).
                null
            }
        }
    }

    flavorDimensions += "distribution"
    productFlavors {
        create("play") {
            dimension = "distribution"
            // Default: Google Play distribution (GMS available)
        }
        create("fdroid") {
            dimension = "distribution"
            // F-Droid: no GMS, force Android LocationManager
            buildConfigField("boolean", "FORCE_LOCATION_MANAGER", "true")
            // #2584 — GMS/ML Kit are compile-only stubs for fdroid (see the
            // compile-only wiring in android/build.gradle.kts). The real classes
            // are absent from the runtime/dex, so R8 on the release build would
            // abort with "Missing class …" without these `-dontwarn` rules. The
            // file is fdroid-scoped: the play flavor keeps the real GMS and the
            // base `-keep com.google.mlkit.**` rule.
            proguardFiles("proguard-rules-fdroid.pro")
        }
    }

    // #3173 — see the dart-defines block above. Default (form pending): the
    // checked-in, Play-compliant manifests, byte-identical to before. With
    // FGS_FORM_APPROVED set, each flavor's manifest overlay swaps to its
    // *FgsApproved variant, restoring the FOREGROUND_SERVICE* permissions
    // (+ AutoRecordForegroundService on play). The flavor overlays are
    // higher-priority than src/main in the manifest merge, so their plain
    // permission declarations win over main's tools:node="remove" guards.
    sourceSets {
        getByName("play").manifest.srcFile(
            if (fgsFormApproved) {
                "src/play/AndroidManifestFgsApproved.xml"
            } else {
                "src/play/AndroidManifest.xml"
            }
        )
        if (fgsFormApproved) {
            getByName("fdroid")
                .manifest.srcFile("src/fdroid/AndroidManifestFgsApproved.xml")
        }
    }
}

// -----------------------------------------------------------------------------
// F-Droid GMS/MLKit/Play-Core exclusion (#2574, #3069)
//
// The `fdroid` flavor must ship ZERO proprietary Google libraries. Three
// transitive sources pull proprietary Google code in:
//   1. geolocator_android      -> com.google.android.gms:play-services-location
//   2. google_mlkit_text_recognition (pump/receipt OCR)
//                              -> com.google.mlkit:text-recognition
//                              -> com.google.android.gms:play-services-base/basement
//   3. in_app_review (#3069)   -> com.google.android.play:review (Play Core,
//                                 the In-App Review API)
//
// We strip all three groups from the fdroid `implementation` base configuration
// (geolocator's own documented F-Droid recipe) AND, belt-and-braces, from each
// fdroid runtime classpath. The app module's own Kotlin never references GMS,
// ML Kit or Play Core directly — those deps come in transitively from the
// geolocator_android, google_mlkit_text_recognition and in_app_review plugin
// modules — so removing them from the app's fdroid graph does not break
// compilation; it only drops the classes from the resolved APK. After that the
// OCR plugin channel simply isn't there and ReceiptScanService degrades
// gracefully (MissingPluginException is caught in _recogniseRaw -> returns
// null); likewise the in-app review channel is absent and InAppReviewService
// swallows the NoClassDefFoundError/MissingPluginException and no-ops. Maps are
// already OSM (flutter_map), so after these excludes the fdroid APK is free of
// proprietary Google code. geolocator falls back to Android's LocationManager —
// see GeolocatorWrapper.forceLocationManager.
//
// Scope is the fdroid flavor ONLY: the play flavor keeps GMS+MLKit+Play Core
// unchanged. The exact configuration names below were confirmed against
// `./gradlew -p android app:dependencies`; the audit (scripts/audit_no_gms.sh +
// .github/workflows/fdroid.yml) inspects `fdroidReleaseRuntimeClasspath` and
// the built dex to prove the runtime classpath is clean.
val gmsExcludeGroups =
    listOf("com.google.android.gms", "com.google.mlkit", "com.google.android.play")
val fdroidExcludedConfigs = listOf(
    "fdroidImplementation",
    "fdroidReleaseRuntimeClasspath",
    "fdroidDebugRuntimeClasspath",
    "fdroidProfileRuntimeClasspath",
)
fdroidExcludedConfigs.forEach { configName ->
    configurations.matching { it.name == configName }.configureEach {
        gmsExcludeGroups.forEach { excludedGroup -> exclude(group = excludedGroup) }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.car.app:app:1.4.0")
    // #2412 / #2413 — BootReceiver + the widget-refresh trigger enqueue a
    // WorkManager one-off directly (androidx.work.*). The workmanager plugin
    // pulls work-runtime in as `implementation`, which Gradle does not expose
    // transitively, so the app module declares it explicitly. Version pinned
    // to the plugin's (workmanager_android 0.9.0 → work-runtime 2.10.2) to
    // avoid a resolved-version split.
    implementation("androidx.work:work-runtime-ktx:2.10.2")

    // Android Auto v1 (#2948) — JVM tests for the car screens
    // (MenuScreen/SearchScreen/RadarScreen) drive androidx.car.app's
    // ScreenController under Robolectric, so they need a real CarContext +
    // merged Android resources.
    testImplementation("androidx.car.app:app-testing:1.4.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.12.2")
    testImplementation("androidx.test:core:1.6.1")
}

flutter {
    source = "../.."
}
