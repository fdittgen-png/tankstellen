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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
