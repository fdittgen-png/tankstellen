#!/usr/bin/env bash
# deploy_play_store.sh — Upload AAB to Play Store internal track from local machine.
#
# Usage:
#   bash scripts/deploy_play_store.sh path/to/app.aab
#   bash scripts/deploy_play_store.sh path/to/app.aab --dry-run
#
# Prerequisites:
#   - PLAY_STORE_SERVICE_ACCOUNT_JSON env var (or --sa-file path)
#   - Python 3 with google-api-python-client and google-auth
#     pip install google-api-python-client google-auth
#
# Flags:
#   --dry-run       Validate inputs without uploading
#   --sa-file PATH  Path to service account JSON file (instead of env var)
#   --track TRACK   Target track (default: internal)
#   --package PKG   Package name (default: com.dittgen.tankstellen)

set -euo pipefail

# --- Configuration ---
DEFAULT_PACKAGE="com.dittgen.tankstellen"
DEFAULT_TRACK="internal"

# --- Helpers ---
die() { echo "ERROR: $1" >&2; exit 1; }
info() { echo "==> $1"; }

# --- Parse arguments ---
AAB_FILE=""
SA_FILE=""
DRY_RUN=false
TRACK="$DEFAULT_TRACK"
PACKAGE="$DEFAULT_PACKAGE"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=true; shift ;;
    --sa-file)   SA_FILE="$2"; shift 2 ;;
    --track)     TRACK="$2"; shift 2 ;;
    --package)   PACKAGE="$2"; shift 2 ;;
    -*)          die "Unknown flag: $1" ;;
    *)           AAB_FILE="$1"; shift ;;
  esac
done

# --- Validate inputs ---
if [[ -z "$AAB_FILE" ]]; then
  die "Usage: bash scripts/deploy_play_store.sh <aab-file> [--dry-run] [--sa-file path] [--track track]"
fi

if [[ ! -f "$AAB_FILE" ]]; then
  die "AAB file not found: $AAB_FILE"
fi

if [[ ! "$AAB_FILE" == *.aab ]]; then
  die "File must be an .aab bundle: $AAB_FILE"
fi

case "$TRACK" in
  internal|alpha|beta|production) ;;
  *) die "Invalid track: $TRACK. Must be: internal, alpha, beta, or production" ;;
esac

# Resolve service account
if [[ -n "$SA_FILE" ]]; then
  if [[ ! -f "$SA_FILE" ]]; then
    die "Service account file not found: $SA_FILE"
  fi
  info "Using service account from file: $SA_FILE"
elif [[ -n "${PLAY_STORE_SERVICE_ACCOUNT_JSON:-}" ]]; then
  SA_FILE=$(mktemp)
  trap 'rm -f "$SA_FILE"' EXIT
  echo "$PLAY_STORE_SERVICE_ACCOUNT_JSON" > "$SA_FILE"
  info "Using service account from environment variable"
else
  die "No service account provided. Set PLAY_STORE_SERVICE_ACCOUNT_JSON or use --sa-file"
fi

# Check Python dependencies
if ! python3 -c "import googleapiclient, google.oauth2" 2>/dev/null; then
  die "Missing Python dependencies. Install: pip install google-api-python-client google-auth"
fi

AAB_SIZE=$(stat -f%z "$AAB_FILE" 2>/dev/null || stat --printf="%s" "$AAB_FILE" 2>/dev/null || echo "unknown")
info "AAB file: $AAB_FILE ($AAB_SIZE bytes)"
info "Package: $PACKAGE"
info "Track: $TRACK"

# --- Dry run ---
if [[ "$DRY_RUN" == "true" ]]; then
  info "[DRY RUN] Would upload $AAB_FILE to '$TRACK' track for $PACKAGE"
  info "[DRY RUN] Service account file validated"
  # Validate the SA JSON is parseable
  python3 -c "
import json, sys
with open('$SA_FILE') as f:
    data = json.load(f)
required = ['type', 'project_id', 'private_key', 'client_email']
missing = [k for k in required if k not in data]
if missing:
    print(f'WARNING: Service account JSON missing fields: {missing}', file=sys.stderr)
    sys.exit(1)
print(f'Service account: {data[\"client_email\"]}')
print('Service account JSON is valid.')
"
  info "[DRY RUN] All validations passed. Ready to deploy."
  exit 0
fi

# --- Upload to Play Store ---
info "Uploading to Play Store..."

python3 - "$SA_FILE" "$PACKAGE" "$TRACK" "$AAB_FILE" << 'PYTHON_EOF'
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

sa_file = sys.argv[1]
package_name = sys.argv[2]
track = sys.argv[3]
aab_file = sys.argv[4]

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

# Upload the AAB
media = MediaFileUpload(aab_file, mimetype='application/octet-stream')
upload = service.edits().bundles().upload(
    packageName=package_name, editId=edit_id, media_body=media
).execute()
version_code = upload['versionCode']
print(f"Uploaded AAB: version code {version_code}")

# Assign to track
service.edits().tracks().update(
    packageName=package_name,
    editId=edit_id,
    track=track,
    body={
        'track': track,
        'releases': [{
            'versionCodes': [version_code],
            'status': 'completed',
        }]
    }
).execute()
print(f"Assigned to '{track}' track")

# Commit
service.edits().commit(packageName=package_name, editId=edit_id).execute()
print(f"Edit committed. AAB is now on the '{track}' track.")
PYTHON_EOF

info "Upload complete! AAB is now on the '$TRACK' track."
