#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# audit_no_gms.sh — prove the F-Droid (`fdroid`) flavor is free of proprietary
# Google Mobile Services (#2574).
#
# Two independent layers, EITHER of which fails the audit:
#
#   (A) Dependency-graph layer (always runs): resolve the fdroid release runtime
#       classpath via Gradle and assert it contains NO `com.google.android.gms`
#       and NO `com.google.mlkit` coordinates. This is the authoritative proof —
#       it is what the official fdroiddata reproducible build inspects.
#
#   (B) Bytecode layer (runs when an APK path is given): unzip the APK, dexdump
#       every classesN.dex, and assert no `Lcom/google/android/gms/...;` or
#       `Lcom/google/mlkit/...;` type reference survives into the shipped dex.
#       Falls back to `strings` on the dex when dexdump is unavailable.
#
# Usage:
#   scripts/audit_no_gms.sh                 # layer A only (dependency graph)
#   scripts/audit_no_gms.sh path/to.apk     # layer A + layer B on the APK
#
# Exit codes: 0 = clean, 1 = a GMS/MLKit hit was found, 2 = setup/usage error.

set -euo pipefail

# Resolve repo root so the script works from any CWD (CI, hooks, local).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Pattern that matches a GMS or ML Kit coordinate in `:app:dependencies` output
# (group:artifact form) and a dexed type descriptor (Lcom/google/...;).
GMS_GRAPH_PATTERN='com\.google\.android\.gms|com\.google\.mlkit'
GMS_DEX_PATTERN='Lcom/google/android/gms/|Lcom/google/mlkit/'

APK_PATH="${1:-}"
FAILED=0

echo "==> [A] fdroid release runtime classpath — must contain no GMS/MLKit"

GRADLE_CMD=(./gradlew)
if [[ ! -x "${REPO_ROOT}/android/gradlew" ]]; then
  echo "ERROR: ${REPO_ROOT}/android/gradlew not found or not executable." >&2
  exit 2
fi

# `:app:dependencies` for a single configuration is the fastest authoritative
# resolution. `--console=plain` keeps the output greppable.
GRAPH_OUT="$(
  (cd "${REPO_ROOT}" && ./gradlew -p android --console=plain -q \
    app:dependencies --configuration fdroidReleaseRuntimeClasspath) 2>&1
)" || {
  echo "ERROR: gradle dependency resolution failed:" >&2
  echo "${GRAPH_OUT}" >&2
  exit 2
}

if echo "${GRAPH_OUT}" | grep -Eq "${GMS_GRAPH_PATTERN}"; then
  echo "FAIL: GMS/MLKit coordinates present on fdroidReleaseRuntimeClasspath:" >&2
  echo "${GRAPH_OUT}" | grep -E "${GMS_GRAPH_PATTERN}" >&2
  FAILED=1
else
  echo "OK: no com.google.android.gms / com.google.mlkit on the runtime classpath."
fi

if [[ -n "${APK_PATH}" ]]; then
  echo "==> [B] dex bytecode audit — ${APK_PATH}"
  if [[ ! -f "${APK_PATH}" ]]; then
    echo "ERROR: APK not found: ${APK_PATH}" >&2
    exit 2
  fi

  WORK_DIR="$(mktemp -d)"
  trap 'rm -rf "${WORK_DIR}"' EXIT
  unzip -q -o "${APK_PATH}" 'classes*.dex' -d "${WORK_DIR}" || {
    echo "ERROR: failed to extract classes*.dex from APK." >&2
    exit 2
  }

  # Locate dexdump (Android build-tools). Optional — fall back to `strings`.
  DEXDUMP_BIN=""
  if command -v dexdump >/dev/null 2>&1; then
    DEXDUMP_BIN="$(command -v dexdump)"
  else
    SDK_ROOT="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
    if [[ -n "${SDK_ROOT}" && -d "${SDK_ROOT}/build-tools" ]]; then
      # newest build-tools wins
      CAND="$(ls -1 "${SDK_ROOT}/build-tools" 2>/dev/null | sort -V | tail -1)"
      if [[ -n "${CAND}" && -x "${SDK_ROOT}/build-tools/${CAND}/dexdump" ]]; then
        DEXDUMP_BIN="${SDK_ROOT}/build-tools/${CAND}/dexdump"
      fi
    fi
  fi

  DEX_HIT=0
  shopt -s nullglob
  for dex in "${WORK_DIR}"/classes*.dex; do
    if [[ -n "${DEXDUMP_BIN}" ]]; then
      if "${DEXDUMP_BIN}" "${dex}" 2>/dev/null | grep -Eq "${GMS_DEX_PATTERN}"; then
        echo "FAIL: GMS/MLKit type references in $(basename "${dex}") (dexdump):" >&2
        "${DEXDUMP_BIN}" "${dex}" 2>/dev/null | grep -E "${GMS_DEX_PATTERN}" | sort -u | head -40 >&2
        DEX_HIT=1
      fi
    else
      # Fallback: raw type descriptors are stored as UTF-8 strings in the dex.
      if strings -a "${dex}" | grep -Eq "${GMS_DEX_PATTERN}"; then
        echo "FAIL: GMS/MLKit type strings in $(basename "${dex}") (strings fallback):" >&2
        strings -a "${dex}" | grep -E "${GMS_DEX_PATTERN}" | sort -u | head -40 >&2
        DEX_HIT=1
      fi
    fi
  done
  shopt -u nullglob

  if [[ -z "${DEXDUMP_BIN}" ]]; then
    echo "NOTE: dexdump not found — used 'strings' fallback (set ANDROID_HOME for dexdump)."
  fi
  if [[ "${DEX_HIT}" -eq 0 ]]; then
    echo "OK: no GMS/MLKit type references in any dex."
  else
    FAILED=1
  fi
fi

if [[ "${FAILED}" -ne 0 ]]; then
  echo "==> AUDIT FAILED: the fdroid flavor still references GMS/MLKit." >&2
  exit 1
fi

echo "==> AUDIT PASSED: fdroid flavor is GMS/MLKit-free."
exit 0
