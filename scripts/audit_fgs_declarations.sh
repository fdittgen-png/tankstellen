#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: AGPL-3.0-or-later

# audit_fgs_declarations.sh — assert, per ARTIFACT, the EXACT set of
# foreground-service permissions and foreground-service declarations an
# Android manifest carries (#4352, Epic #4351; was audit_no_fgs.sh, #2947).
#
# ## Why this grew a second mode
#
# The original audit answered one question — "does the default Play build
# still declare ZERO FOREGROUND_SERVICE* permissions?" — because that is the
# thing that 403s Play's edits.commit until the #1498 "Foreground Service Use"
# form clears. It is still question one, unchanged.
#
# #4351 exposed question two. `FGS_FORM_APPROVED` is a build define: the
# repository variable is NOT set, so the Play artifact ships without the
# foreground service while the F-Droid and dev APKs ship WITH it. One commit,
# two artifacts, different background-recording capability. The Dart side
# (`lib/features/trips/domain/recording_protection.dart`,
# `RecordingProtectionBuild.supports`) makes a claim about which service types
# each artifact can host; an expect-zero audit cannot check that claim,
# because "nothing is declared" is its only passing state.
#
# So the audit is now parameterised:
#
#   * expect-ZERO     — the default Play build. Any FGS permission or
#                       foreground-service declaration is a regression.
#   * expect-EXACTLY  — an FGS_FORM_APPROVED build. The declared set must
#                       match a named list exactly: a MISSING entry means the
#                       capability the app claims does not ship (silent
#                       screen-off failure), and an EXTRA entry means the app
#                       requests a foreground-service type nobody declared to
#                       Play (a review rejection).
#
# Both directions matter, which is why this is set equality and not a grep.
#
# ## What is inspected
#
#   * `<uses-permission android:name="…FOREGROUND_SERVICE…">` — the permission
#     Play's form gates on, and the one `startForeground()` checks.
#   * `<service … android:foregroundServiceType="…">` — the declarations that
#     say WHICH type may be promoted. A service with no `foregroundServiceType`
#     is a plain or bound service (the Android Auto POI service, the Companion
#     presence service) and is deliberately out of scope.
#
# XML comments are stripped first. The play source-set manifests document
# their rationale in prose that names FOREGROUND_SERVICE repeatedly, so a
# naive grep false-positives on the comment block — the reason the original
# audit shelled out to Python, kept verbatim here.
#
# ## Usage
#
#   scripts/audit_fgs_declarations.sh --profile play-default [MANIFEST]
#   scripts/audit_fgs_declarations.sh --profile play-overlay-default
#   scripts/audit_fgs_declarations.sh --profile play-fgs-approved
#   scripts/audit_fgs_declarations.sh --profile play-fgs-approved --merged AAB_MANIFEST
#   scripts/audit_fgs_declarations.sh --profile fdroid-fgs-approved
#   scripts/audit_fgs_declarations.sh --expect-zero MANIFEST
#   scripts/audit_fgs_declarations.sh --expect-exactly \
#       --permissions "android.permission.FOREGROUND_SERVICE,…" \
#       --services ".pkg.Service=connectedDevice" MANIFEST
#
# With `--profile play-default` and no MANIFEST the play debug APK is built
# first so the MERGED manifest exists (the pre-#4352 behaviour). Every other
# profile audits a checked-in source-set overlay and needs no build at all —
# which is what makes this a real CI assertion with no emulator and no matrix.
#
# `--merged` says the manifest is a MERGED one, so the library-contributed
# foreground services belong in the expected set. It composes in BOTH modes:
# in zero mode the libraries' two entries ARE the expected set, and in exact
# mode they are added to the profile's own. Without it, exact mode expects
# only our own services — the right answer for a source-set overlay and the
# wrong one for a built artifact (#4415).
#
# Exit codes: 0 = the declared set matches, 1 = it does not, 2 = usage/setup.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

MODE=""
PROFILE=""
MANIFEST=""
EXPECT_PERMS=""
EXPECT_SERVICES=""
BUILD_IF_MISSING="no"
MERGED="no"

die() { echo "ERROR: $*" >&2; exit 2; }

# The three FGS permissions the FGS-approved Play overlay restores (#3173).
PLAY_APPROVED_PERMS="android.permission.FOREGROUND_SERVICE,android.permission.FOREGROUND_SERVICE_LOCATION,android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE"
# Its one typed foreground service. geolocator's own location-typed service
# lives in the plugin's manifest and only appears after a manifest MERGE, so
# it is not part of a source-set overlay's expected set.
PLAY_APPROVED_SERVICES=".autorecord.AutoRecordForegroundService=connectedDevice"
# The F-Droid overlay is location-only: no connectedDevice permission and no
# service of our own. S4 (#4352b) extends it; until then
# RecordingProtectionBuild.supports() must keep answering false for
# connectedDevice on the libre build, and this line is the proof.
FDROID_APPROVED_PERMS="android.permission.FOREGROUND_SERVICE,android.permission.FOREGROUND_SERVICE_LOCATION"
FDROID_APPROVED_SERVICES=""

apply_profile() {
  case "$1" in
    play-default)
      MODE="zero"
      BUILD_IF_MISSING="yes"
      MERGED="yes"   # a merged manifest carries the libraries' services
      ;;
    play-overlay-default)
      MODE="zero"
      MANIFEST="${MANIFEST:-${REPO_ROOT}/android/app/src/play/AndroidManifest.xml}"
      ;;
    play-fgs-approved)
      MODE="exact"
      EXPECT_PERMS="${PLAY_APPROVED_PERMS}"
      EXPECT_SERVICES="${PLAY_APPROVED_SERVICES}"
      MANIFEST="${MANIFEST:-${REPO_ROOT}/android/app/src/play/AndroidManifestFgsApproved.xml}"
      ;;
    fdroid-fgs-approved)
      MODE="exact"
      EXPECT_PERMS="${FDROID_APPROVED_PERMS}"
      EXPECT_SERVICES="${FDROID_APPROVED_SERVICES}"
      MANIFEST="${MANIFEST:-${REPO_ROOT}/android/app/src/fdroid/AndroidManifestFgsApproved.xml}"
      ;;
    *)
      die "unknown --profile '$1' (play-default | play-overlay-default | play-fgs-approved | fdroid-fgs-approved)"
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)      PROFILE="${2:-}"; [[ -n "${PROFILE}" ]] || die "--profile needs a name"; shift 2 ;;
    --expect-zero)  MODE="zero"; shift ;;
    --merged)       MERGED="yes"; shift ;;
    --expect-exactly) MODE="exact"; shift ;;
    --permissions)  EXPECT_PERMS="${2:-}"; shift 2 ;;
    --services)     EXPECT_SERVICES="${2:-}"; shift 2 ;;
    -h|--help)      sed -n '5,76p' "${BASH_SOURCE[0]}"; exit 0 ;;
    -*)             die "unknown option '$1'" ;;
    *)              [[ -z "${MANIFEST}" ]] || die "more than one manifest given"; MANIFEST="$1"; shift ;;
  esac
done

if [[ -n "${PROFILE}" ]]; then
  apply_profile "${PROFILE}"
elif [[ -z "${MODE}" ]]; then
  # Backwards compatible with the pre-#4352 `audit_no_fgs.sh [MANIFEST]` call.
  MODE="zero"
  BUILD_IF_MISSING="yes"
  MERGED="yes"
fi

if [[ -z "${MANIFEST}" && "${BUILD_IF_MISSING}" == "yes" ]]; then
  echo "==> No manifest given — building the play debug APK to produce the merged manifest"
  (cd "${REPO_ROOT}" && flutter build apk --debug --flavor play >/dev/null)
  MANIFEST="${REPO_ROOT}/build/app/intermediates/merged_manifests/playDebug/processPlayDebugManifest/AndroidManifest.xml"
fi

[[ -n "${MANIFEST}" ]] || die "no manifest to audit (give a path or a --profile)"
if [[ ! -f "${MANIFEST}" ]]; then
  echo "ERROR: manifest not found at: ${MANIFEST}" >&2
  echo "       Build the play flavor first (flutter build apk --flavor play)," >&2
  echo "       or pass a checked-in source-set overlay." >&2
  exit 2
fi

# Strip XML comments, then list the FGS permissions and the typed foreground
# services. Python keeps the comment-stripping robust across the multi-line
# rationale blocks the play manifests carry.
extract() {
  python3 - "$1" "$2" <<'PY'
import re, sys

xml = open(sys.argv[1], encoding="utf-8").read()
what = sys.argv[2]
nocomment = re.sub(r"<!--.*?-->", "", xml, flags=re.DOTALL)

# Every permission whose NAME mentions FOREGROUND_SERVICE — the original
# #2947 net, unchanged, so the expect-zero gate still catches everything it
# used to. It is then partitioned, because one of those names is not a
# foreground-service permission at all:
# REQUEST_COMPANION_START_FOREGROUND_SERVICES_FROM_BACKGROUND is the
# Companion-Device-Manager background-start exemption (#3320) and does not
# trip Play's Foreground Service Use form.
mentions = re.findall(
    r'<uses-permission[^>]*android:name="([^"]*FOREGROUND_SERVICE[^"]*)"',
    nocomment,
)
strict = re.compile(r"^android\.permission\.FOREGROUND_SERVICE(_[A-Z_]+)?$")

if what == "permissions":
    out = [p for p in mentions if strict.match(p)]
elif what == "related":
    out = [p for p in mentions if not strict.match(p)]
else:
    out = []
    for tag in re.findall(r"<service\b[^>]*>", nocomment):
        fst = re.search(r'android:foregroundServiceType="([^"]*)"', tag)
        if not fst:
            continue
        name = re.search(r'android:name="([^"]*)"', tag)
        out.append("%s=%s" % (name.group(1) if name else "?", fst.group(1)))

for item in sorted(set(out)):
    print(item)
PY
}

# Turn a comma-separated expectation into the same sorted-line shape.
as_lines() {
  [[ -z "$1" ]] && return 0
  printf '%s\n' "$1" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | sed '/^$/d' | sort -u
}

ACTUAL_PERMS="$(extract "${MANIFEST}" permissions)"
ACTUAL_RELATED="$(extract "${MANIFEST}" related)"
ACTUAL_SERVICES="$(extract "${MANIFEST}" services)"

# Foreground services the MERGED default-Play manifest carries from
# libraries, with no FGS permission behind them. They are not ours and
# cannot be removed without disabling the library:
#
#   * androidx.work.impl.foreground.SystemForegroundService=shortService
#     — WorkManager's own expedited-work service.
#   * com.baseflow.geolocator.GeolocatorLocationService=location
#     — declared by the geolocator plugin's manifest.
#
# They are pinned as an exact baseline rather than ignored, so an
# APP-declared service (the thing #2947 and #1498 actually guard against,
# and the thing S4 will be tempted to add) still fails this gate.
#
# Note what the pin records: the default Play artifact declares two
# foreground-service TYPES while requesting none of the matching
# FOREGROUND_SERVICE_* permissions. #4415 asked whether that is a latent
# Android-14 crash. Traced end to end, it is not — and the distinction is
# worth writing down, because "declares a type it cannot use" reads like a
# crash and behaves like a downgrade:
#
#   * geolocator's service is BOUND at plugin attach (`bindService`,
#     BIND_AUTO_CREATE) for every position stream. `startForeground` lives
#     only in `enableBackgroundMode`, reached only when the stream carries a
#     `foregroundNotificationConfig` — and `recordingLocationSettings` passes
#     `null` unless `kGpsRecordingForegroundServiceEnabled`, i.e. unless the
#     artifact was built with `FGS_FORM_APPROVED`. A bound, never-promoted
#     service needs no typed permission. The cost is the ~5 s background
#     batching the default artifact already documents, not a SecurityException.
#   * WorkManager's `SystemForegroundService` starts only for expedited /
#     `setForegroundAsync` work. Every enqueue in this repo is a plain
#     periodic task or a plain `OneTimeWorkRequest` (see
#     `android_background_price_fetcher.dart` and `BackgroundScanEnqueuer.kt`),
#     so it is inert. `FOREGROUND_SERVICE_SHORT_SERVICE` is stripped anyway.
#
# So neither entry may be removed and neither needs to be: stripping
# geolocator's would break the bind the plain (non-FGS) stream also uses,
# to prevent a call that is never made. This audit's job is to state the
# fact, not to change the artifact.
ZERO_BASELINE_SERVICES="androidx.work.impl.foreground.SystemForegroundService=shortService,com.baseflow.geolocator.GeolocatorLocationService=location"

if [[ "${MODE}" == "zero" ]]; then
  # The #2947/#1498 net is UNCHANGED: zero FGS permissions, exactly.
  WANT_PERMS=""
  # Only a MERGED manifest contains the libraries' own service entries. A
  # source-set overlay is ours alone, so there the expectation stays a hard
  # zero — which is what keeps `tools:node="remove"` honest.
  if [[ "${MERGED}" == "yes" ]]; then
    WANT_SERVICES="$(as_lines "${ZERO_BASELINE_SERVICES}")"
  else
    WANT_SERVICES=""
  fi
else
  WANT_PERMS="$(as_lines "${EXPECT_PERMS}")"
  # #4415 — a MERGED FGS-approved artifact carries the libraries' services
  # too. Composing them here (rather than hard-coding a fourth profile) is
  # what makes `--profile play-fgs-approved --merged <aab manifest>` the
  # gate for the day the #1498 form clears: the expected set is then our
  # declaration PLUS the same two entries expect-zero already pins, so a
  # library that starts or stops contributing one is caught in both modes.
  if [[ "${MERGED}" == "yes" ]]; then
    WANT_SERVICES="$(as_lines "${EXPECT_SERVICES}${EXPECT_SERVICES:+,}${ZERO_BASELINE_SERVICES}")"
  else
    WANT_SERVICES="$(as_lines "${EXPECT_SERVICES}")"
  fi
fi

echo "==> Auditing FOREGROUND_SERVICE declarations (${MODE}${PROFILE:+, profile ${PROFILE}}):"
echo "    ${MANIFEST}"

FAILED=0
report() { # $1 = label, $2 = expected lines, $3 = actual lines
  local label="$1" want="$2" got="$3"
  local missing extra
  missing="$(comm -23 <(printf '%s\n' "${want}" | sed '/^$/d') <(printf '%s\n' "${got}" | sed '/^$/d') || true)"
  extra="$(comm -13 <(printf '%s\n' "${want}" | sed '/^$/d') <(printf '%s\n' "${got}" | sed '/^$/d') || true)"
  if [[ -n "${got}" ]]; then
    echo "    ${label} declared:"
    echo "${got}" | sed 's/^/      - /'
  else
    echo "    ${label} declared: (none)"
  fi
  if [[ -n "${missing}" ]]; then
    echo "::error::MISSING expected ${label}:" >&2
    echo "${missing}" | sed 's/^/  - /' >&2
    FAILED=1
  fi
  if [[ -n "${extra}" ]]; then
    echo "::error::UNEXPECTED ${label}:" >&2
    echo "${extra}" | sed 's/^/  - /' >&2
    FAILED=1
  fi
}

report "FGS permission(s)" "${WANT_PERMS}" "${ACTUAL_PERMS}"
report "foreground service(s)" "${WANT_SERVICES}" "${ACTUAL_SERVICES}"

# Permissions that merely MENTION foreground services. In zero mode they are
# still a failure (the #2947 net is unchanged — nothing that used to trip this
# audit stops tripping it). In exact mode they are reported but not compared:
# the CDM background-start exemption and the battery-optimization prompt are a
# different Play gate, and pinning them here would couple this audit to
# decisions it does not own.
if [[ -n "${ACTUAL_RELATED}" ]]; then
  echo "    related permission(s) (not foreground-service permissions):"
  echo "${ACTUAL_RELATED}" | sed 's/^/      - /'
  if [[ "${MODE}" == "zero" ]]; then
    echo "::error::UNEXPECTED permission(s) naming FOREGROUND_SERVICE:" >&2
    echo "${ACTUAL_RELATED}" | sed 's/^/  - /' >&2
    FAILED=1
  fi
fi

if [[ "${FAILED}" -ne 0 ]]; then
  echo "" >&2
  if [[ "${MODE}" == "zero" ]]; then
    echo "A default Play artifact must request NO foreground-service permission" >&2
    echo "and declare no foreground service beyond the two the libraries merge" >&2
    echo "in (WorkManager, geolocator). These trip Google Play's Foreground" >&2
    echo "Service Use form (#1498 -> 403 on edits.commit). Strip a new one with" >&2
    echo "tools:node=\"remove\" in android/app/src/main/AndroidManifest.xml, or" >&2
    echo "host it as a BOUND service (the Android Auto bridge is bound — see" >&2
    echo "CarDataBridge / #2947). If a library genuinely added one, update" >&2
    echo "ZERO_BASELINE_SERVICES in this script and say why." >&2
  else
    echo "An FGS_FORM_APPROVED artifact's declared set is the capability the app" >&2
    echo "is allowed to claim (#4352). A MISSING entry means recording silently" >&2
    echo "loses its protection on that artifact; an EXTRA entry means a service" >&2
    echo "type nobody declared to Play. Fix the manifest overlay, or — if the" >&2
    echo "change is intended — update this script's expected set AND" >&2
    echo "RecordingProtectionBuild.supports() in the same commit." >&2
    if [[ "${MERGED}" != "yes" ]]; then
      echo "If this manifest is a MERGED one, pass --merged: the libraries'" >&2
      echo "own foreground services are then expected too (#4415)." >&2
    fi
  fi
  exit 1
fi

echo "==> OK — declared foreground-service set matches."
