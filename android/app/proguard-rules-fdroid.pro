# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# F-Droid flavor — GMS / ML Kit are compile-only stubs (#2584): the real
# proprietary classes are NEVER on the fdroid runtime/dex (see the compile-only
# wiring in android/build.gradle.kts). The plugins' own compiled code still
# *references* those absent GMS / ML Kit types in method signatures, so R8 would
# abort the fdroid release build with "Missing class …" unless we tell it those
# references are expected to be absent. `-dontwarn` lets R8 finish; nothing
# reachable instantiates them (forceLocationManager=true routes location through
# Android's LocationManager; ML Kit OCR/barcode degrade to the caught
# MissingPluginException path), so the proprietary code is never executed.
#
# Applied ONLY to the fdroid flavor (productFlavors.fdroid.proguardFiles in
# android/app/build.gradle.kts); the play flavor keeps the real GMS and the base
# proguard-rules.pro `-keep com.google.mlkit.**` rule untouched.
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**
