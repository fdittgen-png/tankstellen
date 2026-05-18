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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
