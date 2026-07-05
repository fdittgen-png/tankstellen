# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# Flutter — keep the reflection-reached embedding entry points explicitly.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
# #3479 — everything else under io.flutter is kept only IF REACHABLE
# (`allowshrinking`). The app declares no deferred components, so R8 can now
# tree-shake away the dead `io.flutter.embedding.engine.deferredcomponents`
# manager + `FlutterPlayStoreSplitApplication`, which are the ONLY classes that
# reference Play Core split-install (`com.google.android.play.core.*`). The old
# blanket `-keep io.flutter.** {*;}` force-kept them, dragging those references
# into the dex — which `fdroid scanner` rejects. Every io.flutter class the
# running app actually reaches is still kept intact.
-keep,allowshrinking,allowobfuscation class io.flutter.** { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Sentry
-keep class io.sentry.** { *; }
-dontwarn io.sentry.**

# Google Play Core (required by Flutter)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# Hive database models
-keep class io.flutter.plugins.** { *; }

# Supabase / GoTrue / PostgREST
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Freezed/json_serializable generated classes
-keep class **.freezed.** { *; }
-keep class **.g.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Location plugins
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geocoding.** { *; }

# WorkManager
-keep class androidx.work.** { *; }

# Google ML Kit (on-device text recognition)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
