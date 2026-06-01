// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// #1936 — force every subproject's Java compilation to JVM 17 so it
// matches the app module and the Kotlin tasks. Newer Gradle hard-fails
// on a Java/Kotlin JVM-target mismatch; the `tflite_flutter` plugin
// ships Java at 11 / Kotlin at 17 and its own build.gradle can't be
// edited, so we normalise it here. Core-Gradle types only — no
// AGP/KGP imports.
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
}

// #1985 — the `home_widget` plugin declares `androidx.glance:
// glance-appwidget:1.+`, a dynamic version. Gradle resolved it up to
// `1.3.0-alpha01`, whose transitive `androidx.compose.remote` alphas
// demand AGP 9.1 / compileSdk 37 — this project is on AGP 8.11 / SDK
// 36, so `bundlePlayRelease` broke. Pin glance to the current stable
// line (the plugin was authored against 1.1.x) across every subproject.
subprojects {
    configurations.all {
        resolutionStrategy {
            force("androidx.glance:glance-appwidget:1.1.1")
            force("androidx.glance:glance:1.1.1")
        }
    }
}

// -----------------------------------------------------------------------------
// F-Droid: compile-only GMS / ML Kit so the fdroid dex is genuinely GMS-free (#2584)
//
// Background. The `:app` fdroid `exclude(group = "com.google.android.gms" / ...)`
// (android/app/build.gradle.kts, #2574/#2580) cleans the APP module's dependency
// graph — Layer A of scripts/audit_no_gms.sh passes. But GMS/ML Kit are pulled in
// by the Flutter *plugin* sub-projects, which are plain UN-FLAVORED Android library
// modules:
//   :geolocator_android            -> implementation com.google.android.gms:play-services-location
//   :google_mlkit_commons          -> implementation com.google.mlkit:vision-common
//   :google_mlkit_text_recognition -> implementation com.google.mlkit:text-recognition
// Each plugin builds ONE `release` AAR that carries those GMS/ML Kit classes, and
// AGP variant-matching merges that same AAR into BOTH the `play` and `fdroid` app
// variants. So Layer B (the shipped dex) still contained
// `Lcom/google/android/gms/...;` and `Lcom/google/mlkit/...;` — the fdroid APK was
// NOT GMS-free, contrary to #2574's acceptance criteria. That is the #2584 defect.
//
// The plugins' Java `import com.google.android.gms.location.*;` unconditionally
// (geolocator has no FOSS compile flag), so a blanket runtime+compile exclude
// BREAKS compilation (`package com.google.android.gms.location does not exist`).
//
// Fix — compile-only API stubs, scoped to the fdroid task graph ONLY:
//   1. RUNTIME exclude: drop the real GMS/ML Kit coordinates from each plugin
//      sub-project's fdroid runtime classpath, so the proprietary classes never
//      reach the merged dex.
//   2. COMPILE-ONLY stub: put the GMS/ML Kit *compile* API back on each plugin's
//      compile classpath as `compileOnly`, so the plugin's Java still compiles
//      against the exact real signatures. `compileOnly` is never packaged, so it
//      adds nothing to the runtime/dex. Net: stub on compile, nothing on runtime
//      ⇒ a GMS-free fdroid dex that still compiles.
//
// Gating. The plugin modules are un-flavored, so there is no `fdroid*` variant to
// hang this on; we gate on the requested Gradle tasks (the same mechanism the #48
// keyless-signing guard uses) — this block only mutates the plugin classpaths when
// an `fdroid` assemble/bundle/build task is in the invocation. A `play` build is
// completely untouched: it keeps the real GMS + full functionality (fused location
// + ML Kit OCR).
//
// Runtime safety. `forceLocationManager=true` is wired for the fdroid flavor
// (FORCE_LOCATION_MANAGER BuildConfig field + --dart-define), so geolocator never
// instantiates FusedLocationProviderClient and falls back to Android's
// LocationManager. ML Kit is absent at runtime, so `TextRecognizer()` throws and
// ReceiptScanService._recogniseRaw swallows it (returns null) — OCR is gracefully
// UNAVAILABLE in the fdroid flavor BY DESIGN. See docs/guides/fdroid-submission.md.
val gmsStubGroups = listOf("com.google.android.gms", "com.google.mlkit")
val gmsStubCompileApi = listOf(
    // geolocator_android -> play-services-location (+ its base/basement/tasks)
    "com.google.android.gms:play-services-location:21.2.0",
    // google_mlkit_text_recognition / _commons -> text recognition + vision-common
    "com.google.mlkit:text-recognition:16.0.1",
    "com.google.mlkit:vision-common:17.3.0",
    // mobile_scanner -> barcode scanning (GMS + ML Kit variants)
    "com.google.android.gms:play-services-mlkit-barcode-scanning:18.3.1",
    "com.google.mlkit:barcode-scanning:17.3.0",
)
val gmsStubPlugins = setOf(
    "geolocator_android",
    "google_mlkit_commons",
    "google_mlkit_text_recognition",
    "mobile_scanner",
)

// True when this Gradle invocation targets the fdroid flavor (assembleFdroid*,
// bundleFdroid*, buildFdroid*, or an explicit fdroid* compile/dependencies task).
val isFdroidInvocation: Boolean =
    gradle.startParameter.taskNames
        .map { it.substringAfterLast(':').lowercase() }
        .any { it.contains("fdroid") }

if (isFdroidInvocation) {
    subprojects {
        if (project.name in gmsStubPlugins) {
            project.afterEvaluate {
                // (1) Runtime exclude — keep GMS/ML Kit out of the merged fdroid dex.
                configurations.matching {
                    it.name.startsWith("fdroid") && it.name.endsWith("RuntimeClasspath")
                }.configureEach {
                    gmsStubGroups.forEach { g -> exclude(group = g) }
                }
                // The plugin modules are un-flavored, so their *plugin-local* runtime
                // configs are debug/profile/release, not fdroid*. Strip GMS/ML Kit from
                // those too — they are the AARs AGP merges into the fdroid app variant.
                configurations.matching {
                    it.name.endsWith("RuntimeClasspath") &&
                        !it.name.startsWith("play")
                }.configureEach {
                    gmsStubGroups.forEach { g -> exclude(group = g) }
                }

                // (2) Compile-only stub — restore the GMS/ML Kit *compile* API so the
                // plugin's Java still compiles. compileOnly is never packaged ⇒ adds
                // nothing to the dex. Declared on the base `compileOnly` config so it
                // applies to every (un-flavored) compile classpath of the plugin.
                dependencies {
                    gmsStubCompileApi.forEach { coord ->
                        add("compileOnly", coord)
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
