#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# audit_no_fgs.sh — prove the MERGED `play` manifest declares ZERO
# FOREGROUND_SERVICE* permissions (#2947 / epic #2946).
#
# ## Why
# Google Play's "Foreground Service Use" declaration form is a hard gate on
# every reviewed track: edits.commit returns 403 until the form is submitted
# (#1498). The app therefore strips every FOREGROUND_SERVICE* permission with
# `tools:node="remove"` in the main manifest (androidx.work / car.app declare
# it in their own manifests and would otherwise be merged back in). The
# Android Auto v2 live bridge (#2947) hosts a headless FlutterEngine inside the
# BOUND CarAppService/Session — never a started/foreground service — so it adds
# NO FGS permission. This audit makes a future accidental FGS re-merge trip CI
# here, instead of surfacing as the opaque #1498 403 on the Open-Testing upload.
#
# ## What it checks
# The MERGED play manifest (after manifest-merge pulls in every dependency's
# manifest) must contain ZERO `<uses-permission android:name="…FOREGROUND_SERVICE…">`
# entries. XML comments are stripped first — the play source-set manifest
# documents the rationale in a comment block that mentions FOREGROUND_SERVICE,
# and a naive grep would false-positive on that prose.
#
# A geolocator/work plugin may still declare a service with
# `foregroundServiceType="…"` in its OWN manifest; without a matching
# FOREGROUND_SERVICE *permission* that service can never actually run as an FGS,
# and Play's form gate keys off the permission, so this audit gates the
# permission (the thing that 403s), not the plugin's service attribute.
#
# Usage:
#   scripts/audit_no_fgs.sh                       # builds the play debug APK, then audits
#   scripts/audit_no_fgs.sh path/to/AndroidManifest.xml   # audits a pre-built merged manifest
#
# Exit codes: 0 = clean (zero FGS permissions), 1 = an FGS permission survived,
# 2 = setup/usage error.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MANIFEST="${1:-}"

# When no manifest path is given, build the unsigned play debug APK (same path
# CI's build-android PR validation uses) so the merged manifest exists.
if [[ -z "${MANIFEST}" ]]; then
  echo "==> No manifest given — building the play debug APK to produce the merged manifest"
  (cd "${REPO_ROOT}" && flutter build apk --debug --flavor play >/dev/null)
  MANIFEST="${REPO_ROOT}/build/app/intermediates/merged_manifests/playDebug/processPlayDebugManifest/AndroidManifest.xml"
fi

if [[ ! -f "${MANIFEST}" ]]; then
  echo "ERROR: merged manifest not found at: ${MANIFEST}" >&2
  echo "       Build the play flavor first (flutter build apk --flavor play)." >&2
  exit 2
fi

echo "==> Auditing merged play manifest for FOREGROUND_SERVICE permissions:"
echo "    ${MANIFEST}"

# Strip XML comments, then count uses-permission entries naming any
# FOREGROUND_SERVICE* permission. Python keeps the comment-stripping robust
# across multi-line comment blocks (the play manifest's rationale block).
HITS="$(python3 - "${MANIFEST}" <<'PY'
import re, sys
xml = open(sys.argv[1], encoding="utf-8").read()
nocomment = re.sub(r"<!--.*?-->", "", xml, flags=re.DOTALL)
perms = re.findall(
    r'<uses-permission[^>]*android:name="([^"]*FOREGROUND_SERVICE[^"]*)"',
    nocomment,
)
for p in sorted(set(perms)):
    print(p)
PY
)"

if [[ -n "${HITS}" ]]; then
  echo "::error::Merged play manifest declares FOREGROUND_SERVICE permission(s):" >&2
  echo "${HITS}" | sed 's/^/  - /' >&2
  echo "" >&2
  echo "These trip Google Play's Foreground Service Use form (#1498 → 403 on" >&2
  echo "edits.commit). Strip them with tools:node=\"remove\" in" >&2
  echo "android/app/src/main/AndroidManifest.xml, or do not host the new" >&2
  echo "service as a foreground service (the Android Auto bridge is a BOUND" >&2
  echo "service — see CarDataBridge / #2947)." >&2
  exit 1
fi

echo "==> OK — zero FOREGROUND_SERVICE permissions in the merged play manifest."
