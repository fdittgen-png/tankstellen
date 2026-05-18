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

// #1936 — force every plugin subproject's Java compilation to JVM 17,
// matching the app module (android/app/build.gradle.kts) and the
// Kotlin tasks. The newer Gradle bundled with Flutter `stable` hard-
// fails on a JVM-target mismatch; the `tflite_flutter` plugin ships
// Java targeting 11 while its Kotlin targets 17. Aligning Java up to
// 17 makes every subproject internally consistent. Uses only core-
// Gradle types so the root script needs no AGP/KGP classpath.
subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
