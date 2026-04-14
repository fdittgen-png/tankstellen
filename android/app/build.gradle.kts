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
            signingConfig = if (releaseSigning != null) {
                signingConfigs.getByName("release")
            } else {
                throw GradleException(
                    "No release signing configuration available. " +
                        "Set ANDROID_KEYSTORE_PATH / ANDROID_KEYSTORE_PASSWORD / " +
                        "ANDROID_KEY_ALIAS environment variables (CI: use GitHub " +
                        "Secrets), or create android/key.properties locally. " +
                        "Release builds never fall back to the debug key — see #48."
                )
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
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.car.app:app:1.4.0")
}

flutter {
    source = "../.."
}
