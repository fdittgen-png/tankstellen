#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# fdroid_publish.sh — build + sign the GMS-free fdroid APK and (re)generate the
# self-hosted F-Droid repo under ./fdroid (#2576). This is the LOCAL-Mac path
# the maintainer runs to publish tonight; CI's fdroid-publish.yml runs the same
# steps for tag/dispatch deploys.
#
# Idempotent: re-running rebuilds the APK, re-audits, and re-runs
# `fdroid update`. `fdroid init` is run only on the first run (no keystore yet).
#
# PREREQUISITES (the script checks and instructs):
#   * fdroidserver — `brew install fdroidserver`
#   * The APP release keystore, via env (same vars android/app/build.gradle.kts
#     resolveReleaseSigning() reads):
#       ANDROID_KEYSTORE_PATH ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS
#       (ANDROID_KEY_PASSWORD optional — falls back to the store password)
#   * The F-DROID REPO signing key (separate from the app key). config.yml reads
#     the passwords from the env via {env: …}:
#       FDROID_REPO_KEYSTORE_PASSWORD  FDROID_REPO_KEY_PASSWORD
#     Optionally FDROID_REPO_KEYSTORE — an explicit path to an existing repo
#     keystore; it is copied to fdroid/keystore.p12 (the config's default path).
#     On the first run with no keystore present, `fdroid init` creates one.
#
# Usage:  bash scripts/fdroid_publish.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

FDROID_DIR="${REPO_ROOT}/fdroid"
APP_ID="de.tankstellen.fuelprices"
APK_OUT="build/app/outputs/flutter-apk/app-fdroid-release.apk"

fail() { echo "ERROR: $*" >&2; exit 1; }

# --- 1. fdroidserver present? ------------------------------------------------
echo "==> Checking fdroidserver"
command -v fdroid >/dev/null 2>&1 || fail \
  "fdroidserver not found. Install it with:  brew install fdroidserver"

# --- 2. App release keystore env present? ------------------------------------
echo "==> Checking app release signing env"
[[ -n "${ANDROID_KEYSTORE_PATH:-}" ]] || fail "ANDROID_KEYSTORE_PATH is unset"
[[ -n "${ANDROID_KEYSTORE_PASSWORD:-}" ]] || fail "ANDROID_KEYSTORE_PASSWORD is unset"
[[ -n "${ANDROID_KEY_ALIAS:-}" ]] || fail "ANDROID_KEY_ALIAS is unset"
[[ -f "${ANDROID_KEYSTORE_PATH}" ]] || fail "ANDROID_KEYSTORE_PATH does not point at a file: ${ANDROID_KEYSTORE_PATH}"

# --- 2b. F-Droid repo signing-key env present? -------------------------------
echo "==> Checking F-Droid repo signing env"
[[ -n "${FDROID_REPO_KEYSTORE_PASSWORD:-}" ]] || fail \
  "FDROID_REPO_KEYSTORE_PASSWORD is unset (config.yml reads it via {env: …})"
[[ -n "${FDROID_REPO_KEY_PASSWORD:-}" ]] || fail \
  "FDROID_REPO_KEY_PASSWORD is unset (config.yml reads it via {env: …})"

# --- 3. Libre stubs + clean codegen (HARD RULE #3) ---------------------------
# #3480 (epic #3473) — swap the GMS/ML-Kit/Play-Core/Sentry-pulling plugins
# for the Dart-only stubs BEFORE resolving, exactly as the fdroiddata recipe
# prebuild does; the strict release audit below fails on any residual
# reference. NB this leaves pubspec_overrides.yaml modified in the working
# tree — restore it after publishing (git checkout -- pubspec_overrides.yaml).
echo "==> Applying fdroid pubspec overrides (libre stubs)"
dart run tool/apply_fdroid_overrides.dart
echo "==> Clean codegen"
flutter pub get
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs

# --- 4. Build the signed, GMS-free release APK -------------------------------
# #3435 — FGS define parity with fdroid-publish.yml: F-Droid ships the GPS
# foreground service unconditionally (no Play declaration applies).
echo "==> Building signed fdroid release APK"
flutter build apk --release --flavor fdroid \
  --dart-define=FORCE_LOCATION_MANAGER=true \
  --dart-define=FGS_FORM_APPROVED=true
[[ -f "${APK_OUT}" ]] || fail "expected APK not found at ${APK_OUT}"

# --- 5. Audit the release APK — abort on any GMS/MLKit hit -------------------
echo "==> Auditing the release APK for GMS/MLKit"
bash "${SCRIPT_DIR}/audit_no_gms.sh" "${APK_OUT}" \
  || fail "GMS/MLKit audit FAILED — refusing to publish a non-libre APK"

# --- 6. Stage the repo keystore + first-run init -----------------------------
mkdir -p "${FDROID_DIR}"
# fdroid/config.yml reads `keystore: keystore.p12` (relative to fdroid/) and the
# passwords from the env via {env: …}. If an explicit keystore path is provided
# (e.g. the runner-temp path CI decodes into), copy it to that configured path
# so fdroidserver finds it.
if [[ -n "${FDROID_REPO_KEYSTORE:-}" && "${FDROID_REPO_KEYSTORE}" != "${FDROID_DIR}/keystore.p12" ]]; then
  if [[ -f "${FDROID_REPO_KEYSTORE}" ]]; then
    echo "==> Staging repo keystore -> fdroid/keystore.p12"
    cp -f "${FDROID_REPO_KEYSTORE}" "${FDROID_DIR}/keystore.p12"
  fi
fi
if [[ ! -d "${FDROID_DIR}/repo" || ! -f "${FDROID_DIR}/keystore.p12" ]]; then
  echo "==> First run — initialising the F-Droid repo (fdroid init)"
  # `fdroid init` reads fdroid/config.yml; it creates the repo signing keystore
  # at the configured path (keystore.p12) if it does not yet exist.
  (cd "${FDROID_DIR}" && fdroid init)
else
  echo "==> Existing repo + keystore found — skipping fdroid init"
fi

# --- 7. Stage Play-store metadata into the fdroid metadata tree --------------
echo "==> Syncing fastlane metadata -> fdroid/metadata/${APP_ID}/"
mkdir -p "${FDROID_DIR}/metadata/${APP_ID}"
# fastlane's android metadata layout (en-US/, de-DE/, …, with
# short_description.txt / full_description.txt / changelogs/<code>.txt /
# images/) is the same layout fdroidserver reads under metadata/<appid>/.
rsync -a "${REPO_ROOT}/fastlane/metadata/android/" \
  "${FDROID_DIR}/metadata/${APP_ID}/"

# --- 8. Drop the APK into the repo and (re)build the index -------------------
echo "==> Copying APK into fdroid/repo/"
mkdir -p "${FDROID_DIR}/repo"
cp -f "${APK_OUT}" "${FDROID_DIR}/repo/"

echo "==> fdroid update"
(cd "${FDROID_DIR}" && fdroid update --create-metadata --pretty)

# --- 9. Print the repo fingerprint + next steps ------------------------------
echo ""
echo "==> Repo SHA-256 fingerprint (paste into docs/index.html):"
(cd "${FDROID_DIR}" && fdroid signindex --help >/dev/null 2>&1 || true)
# `fdroid update` prints the fingerprint, but surface it explicitly too:
if [[ -f "${FDROID_DIR}/repo/index-v1.json" ]]; then
  python3 - "${FDROID_DIR}/repo/index-v1.json" <<'PY' || true
import json, sys
try:
    repo = json.load(open(sys.argv[1])).get("repo", {})
    fp = repo.get("fingerprint")
    if fp:
        print(f"    {fp}")
    else:
        print("    (fingerprint not in index — run `fdroid update -v` and read the log)")
except Exception as e:
    print(f"    (could not read fingerprint: {e})")
PY
fi

cat <<EOF

==> DONE. Next git steps (commit the generated repo, then deploy):

    git add fdroid/repo fdroid/metadata fdroid/config.yml
    # paste the fingerprint above into docs/index.html (<REPO_FINGERPRINT>)
    git add docs/index.html
    git commit -m "chore(fdroid): publish repo index + APK"
    git push                # pages.yml deploys docs/ + fdroid/repo to Pages

    Repo URL (add in any F-Droid client):
      https://fdittgen-png.github.io/tankstellen/fdroid
EOF
