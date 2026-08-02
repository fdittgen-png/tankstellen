#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# assert_release_boots.sh — install the R8-shrunk release APK on a running
# emulator, launch it, and assert the process is still alive afterwards.
#
# ## Why this script exists
#
# Code shrinking runs only on release builds, so a class of crash exists
# exclusively in the artifact users receive: R8 removes a type that nothing
# references statically (reflection, a serialisation library, a platform
# callback), and the app dies before its first frame. Every unit test passes.
# The debug build is fine. Nothing in a headless suite can observe it.
#
# The check is deliberately crude — install, launch, wait, is the pid still
# there — because that is precisely the bar the failure clears: a process
# that survives fifteen seconds has run its bootstrap, opened its storage,
# and built its first frame.
#
# ## What a failure means
#
# The uploaded logcat contains the reason. In order of likelihood:
#   1. `ClassNotFoundException` / `NoSuchMethodError` — a missing `-keep`.
#   2. A Hive/codec error — a schema or adapter registration problem that
#      only manifests on a cold install.
#   3. A plugin channel error — a dependency whose consumer rules changed.
#
# Usage: bash scripts/assert_release_boots.sh [apk-path]
# Exit:  0 = the app is alive, 1 = it died or never started.

set -euo pipefail

PACKAGE="de.tankstellen.fuelprices"
ACTIVITY="de.tankstellen.tankstellen.MainActivity"
SETTLE_SECONDS="${SETTLE_SECONDS:-15}"
LOGCAT_OUT="/tmp/release-boot-logcat.txt"
CRASH_OUT="/tmp/release-boot-crash.txt"

APK="${1:-}"
if [[ -z "$APK" ]]; then
  APK="$(find build/app/outputs/flutter-apk -name 'app-play-release.apk' \
         -o -name 'app-*-play-release.apk' 2>/dev/null | head -1)"
fi

if [[ -z "$APK" || ! -f "$APK" ]]; then
  echo "::error::No release APK found. Did 'flutter build apk --release' run?" >&2
  exit 1
fi

echo "==> APK: $APK ($(du -h "$APK" | cut -f1))"

# A fresh install every time: an upgrade would reuse existing storage and
# hide a cold-start migration failure, which is one of the things this
# check exists to catch.
adb uninstall "$PACKAGE" >/dev/null 2>&1 || true
echo "==> Installing"
adb install -r "$APK"

echo "==> Clearing logcat"
adb logcat -c

echo "==> Launching $PACKAGE/$ACTIVITY"
# -W waits for the launch to complete and prints the result; a
# deterministic component name avoids depending on the launcher intent.
# `|| true`: a nonzero exit must reach the grep below as a diagnosable
# message, not kill the script via `set -e` before it can explain itself.
LAUNCH_OUT="$(adb shell am start -W -n "$PACKAGE/$ACTIVITY" 2>&1 || true)"
echo "$LAUNCH_OUT"

if echo "$LAUNCH_OUT" | grep -qiE 'Error type|Error:|does not exist'; then
  echo "::error::Launch was rejected by the activity manager." >&2
  adb logcat -d > "$LOGCAT_OUT" 2>/dev/null || true
  exit 1
fi

echo "==> Letting it settle for ${SETTLE_SECONDS}s"
sleep "$SETTLE_SECONDS"

echo "==> Capturing logcat"
adb logcat -d > "$LOGCAT_OUT" 2>/dev/null || true

# The assertion. A process that is gone after the settle window either
# crashed or was killed; either way the artifact is not shippable.
if ! PID="$(adb shell pidof "$PACKAGE" 2>/dev/null | tr -d '\r')" || [[ -z "$PID" ]]; then
  echo "::error::$PACKAGE died within ${SETTLE_SECONDS}s of launch." >&2
  echo "--- Fatal exceptions and shrinker symptoms -----------------------" >&2
  grep -iE 'FATAL EXCEPTION|AndroidRuntime|ClassNotFoundException|NoSuchMethodError|NoClassDefFoundError|Caused by' \
    "$LOGCAT_OUT" | head -60 | tee "$CRASH_OUT" >&2 || true
  echo "------------------------------------------------------------------" >&2
  echo "Full logcat uploaded as the 'release-boot-logcat' artifact." >&2
  exit 1
fi

# A surviving pid is necessary but not sufficient: an app that logged a
# fatal exception and was restarted by the system would also show one.
if grep -q 'FATAL EXCEPTION' "$LOGCAT_OUT"; then
  echo "::error::$PACKAGE is running but logged a FATAL EXCEPTION." >&2
  grep -A 25 'FATAL EXCEPTION' "$LOGCAT_OUT" | head -60 | tee "$CRASH_OUT" >&2 || true
  exit 1
fi

echo "==> OK — $PACKAGE alive after ${SETTLE_SECONDS}s (pid $PID), no fatal exceptions"
