#!/usr/bin/env bash
# promote_play_store.sh — Promote a Play Store release to production with staged rollout.
#
# Used by the deploy.yml workflow dispatch action. Reads the latest release from
# TRACK_FROM and promotes it to production at ROLLOUT_PERCENTAGE%.
#
# Required environment variables:
#   PLAY_STORE_SERVICE_ACCOUNT_JSON — Service account JSON (contents, not path)
#   PACKAGE_NAME                    — Android package name
#   TRACK_FROM                      — Source track (internal, alpha, beta)
#   ROLLOUT_PERCENTAGE              — Target rollout percentage (1-100)
#
# Usage:
#   PLAY_STORE_SERVICE_ACCOUNT_JSON='{"..."}' \
#   PACKAGE_NAME=com.dittgen.tankstellen \
#   TRACK_FROM=internal \
#   ROLLOUT_PERCENTAGE=5 \
#   bash scripts/promote_play_store.sh

set -euo pipefail

die() { echo "ERROR: $1" >&2; exit 1; }
info() { echo "==> $1"; }

# --- Validate environment ---
[[ -z "${PLAY_STORE_SERVICE_ACCOUNT_JSON:-}" ]] && die "PLAY_STORE_SERVICE_ACCOUNT_JSON is not set"
[[ -z "${PACKAGE_NAME:-}" ]] && die "PACKAGE_NAME is not set"
[[ -z "${TRACK_FROM:-}" ]] && die "TRACK_FROM is not set"
[[ -z "${ROLLOUT_PERCENTAGE:-}" ]] && die "ROLLOUT_PERCENTAGE is not set"

# Validate percentage
if ! [[ "$ROLLOUT_PERCENTAGE" =~ ^[0-9]+$ ]] || [[ "$ROLLOUT_PERCENTAGE" -lt 1 ]] || [[ "$ROLLOUT_PERCENTAGE" -gt 100 ]]; then
  die "ROLLOUT_PERCENTAGE must be between 1 and 100, got: $ROLLOUT_PERCENTAGE"
fi

# Validate track
case "$TRACK_FROM" in
  internal|alpha|beta) ;;
  *) die "TRACK_FROM must be internal, alpha, or beta — got: $TRACK_FROM" ;;
esac

info "Promoting from '$TRACK_FROM' to production at ${ROLLOUT_PERCENTAGE}%"

# --- Write service account JSON to temp file ---
SA_FILE=$(mktemp)
trap 'rm -f "$SA_FILE"' EXIT
echo "$PLAY_STORE_SERVICE_ACCOUNT_JSON" > "$SA_FILE"

# --- Execute promotion via Python Google API client ---
python3 - "$SA_FILE" "$PACKAGE_NAME" "$TRACK_FROM" "$ROLLOUT_PERCENTAGE" << 'PYTHON_EOF'
import sys
import json
from google.oauth2 import service_account
from googleapiclient.discovery import build

sa_file = sys.argv[1]
package_name = sys.argv[2]
track_from = sys.argv[3]
rollout_pct = int(sys.argv[4])

# Authenticate
credentials = service_account.Credentials.from_service_account_file(
    sa_file,
    scopes=['https://www.googleapis.com/auth/androidpublisher']
)
service = build('androidpublisher', 'v3', credentials=credentials)

# Create an edit
edit = service.edits().insert(body={}, packageName=package_name).execute()
edit_id = edit['id']
print(f"Created edit: {edit_id}")

# Get current release from source track
source = service.edits().tracks().get(
    packageName=package_name, editId=edit_id, track=track_from
).execute()

releases = source.get('releases', [])
if not releases:
    print(f"ERROR: No releases found on '{track_from}' track", file=sys.stderr)
    sys.exit(1)

# Find the latest completed release
latest = None
for r in releases:
    if r.get('status') in ('completed', 'inProgress'):
        latest = r
        break

if not latest:
    print(f"ERROR: No completed/inProgress release on '{track_from}'", file=sys.stderr)
    sys.exit(1)

version_codes = latest.get('versionCodes', [])
release_name = latest.get('name', 'Unknown')
print(f"Found release '{release_name}' with version codes: {version_codes}")

# Build production track update
if rollout_pct >= 100:
    status = 'completed'
    user_fraction = None
    print("Setting production to full rollout (completed)")
else:
    status = 'inProgress'
    user_fraction = rollout_pct / 100.0
    print(f"Setting production to {rollout_pct}% staged rollout")

new_release = {
    'versionCodes': version_codes,
    'name': release_name,
    'status': status,
}
if user_fraction is not None:
    new_release['userFraction'] = user_fraction

# Update production track
service.edits().tracks().update(
    packageName=package_name,
    editId=edit_id,
    track='production',
    body={'track': 'production', 'releases': [new_release]}
).execute()

# Commit the edit
service.edits().commit(packageName=package_name, editId=edit_id).execute()
print(f"Successfully promoted to production at {rollout_pct}%")
PYTHON_EOF

info "Promotion complete."
