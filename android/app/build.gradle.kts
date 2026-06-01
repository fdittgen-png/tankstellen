// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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
}

// -----------------------------------------------------------------------------
// F-Droid GMS/MLKit exclusion (#2574)
//
// The `fdroid` flavor must ship ZERO proprietary Google Mobile Services. Two
// transitive sources pull GMS in:
//   1. geolocator_android      -> com.google.android.gms:play-services-location
//   2. google_mlkit_text_recognition (pump/receipt OCR)
//                              -> com.google.mlkit:text-recognition
//                              -> com.google.android.gms:play-services-base/basement
//
// We strip both groups from the fdroid `implementation` base configuration
// (geolocator's own documented F-Droid recipe) AND, belt-and-braces, from each
// fdroid runtime classpath. The app module's own Kotlin never references GMS or
// ML Kit directly — those deps come in transitively from the geolocator_android
// and google_mlkit_text_recognition plugin modules — so removing them from the
// app's fdroid graph does not break compilation; it only drops the classes from
// the resolved APK. After that the OCR plugin channel simply isn't there and
// ReceiptScanService degrades gracefully (MissingPluginException is caught in
// _recogniseRaw -> returns null). Maps are already OSM (flutter_map), so after
// these two excludes the fdroid APK is GMS-free. geolocator falls back to
// Android's LocationManager — see GeolocatorWrapper.forceLocationManager.
//
// Scope is the fdroid flavor ONLY: the play flavor keeps GMS+MLKit unchanged.
// The exact configuration names below were confirmed against
// `./gradlew -p android app:dependencies`; the audit (scripts/audit_no_gms.sh +
// .github/workflows/fdroid.yml) inspects `fdroidReleaseRuntimeClasspath` and
// the built dex to prove the runtime classpath is clean.
val gmsExcludeGroups = listOf("com.google.android.gms", "com.google.mlkit")
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
}

flutter {
    source = "../.."
}
