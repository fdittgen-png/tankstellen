#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT
#
# play_track_status.sh — READ-ONLY report of what is currently live on each
# Play Store track (production / beta / alpha / internal). Used to confirm a
# promotion actually published — an API edit commit succeeds even when the
# Console has Managed Publishing on (the change then waits for a manual
# "Publish") or when a first production release is still in Google review.
#
# It creates an edit ONLY to read the track resources, then DELETES the edit
# without committing — it never changes anything.
#
# Required env:
#   PLAY_STORE_SERVICE_ACCOUNT_JSON — service account JSON (contents)
#   PACKAGE_NAME                    — e.g. de.tankstellen.fuelprices
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -z "${PLAY_STORE_SERVICE_ACCOUNT_JSON:-}" ]] && die "PLAY_STORE_SERVICE_ACCOUNT_JSON is not set"
[[ -z "${PACKAGE_NAME:-}" ]] && die "PACKAGE_NAME is not set"

SA_FILE="$(mktemp)"
trap 'rm -f "$SA_FILE"' EXIT
echo "$PLAY_STORE_SERVICE_ACCOUNT_JSON" > "$SA_FILE"

python3 - "$SA_FILE" "$PACKAGE_NAME" << 'PYTHON_EOF'
import sys
from google.oauth2 import service_account
from googleapiclient.discovery import build

sa_file, package_name = sys.argv[1], sys.argv[2]

creds = service_account.Credentials.from_service_account_file(
    sa_file, scopes=['https://www.googleapis.com/auth/androidpublisher'])
service = build('androidpublisher', 'v3', credentials=creds)

edit = service.edits().insert(body={}, packageName=package_name).execute()
edit_id = edit['id']
try:
    print(f"== Play track status for {package_name} ==\n")
    for track in ('production', 'beta', 'alpha', 'internal'):
        try:
            t = service.edits().tracks().get(
                packageName=package_name, editId=edit_id, track=track).execute()
        except Exception as e:  # noqa: BLE001 — a missing track is normal
            print(f"[{track}] (no track / not accessible): {e}")
            continue
        releases = t.get('releases', [])
        if not releases:
            print(f"[{track}] no releases")
            continue
        for r in releases:
            status = r.get('status', '?')
            codes = r.get('versionCodes', [])
            name = r.get('name', '?')
            frac = r.get('userFraction')
            frac_s = f" userFraction={frac}" if frac is not None else ""
            print(f"[{track}] status={status} versionCodes={codes} "
                  f"name={name}{frac_s}")
    print()
    # Explicit production verdict for the confirmation question.
    prod = service.edits().tracks().get(
        packageName=package_name, editId=edit_id, track='production').execute()
    prod_releases = prod.get('releases', [])
    completed = [r for r in prod_releases if r.get('status') == 'completed']
    if completed:
        c = completed[0]
        print(f"PRODUCTION VERDICT: PUBLISHED — versionCodes="
              f"{c.get('versionCodes')} status=completed "
              f"(userFraction={c.get('userFraction', 'full/1.0')})")
    elif prod_releases:
        r = prod_releases[0]
        print(f"PRODUCTION VERDICT: PRESENT but not completed — "
              f"status={r.get('status')} versionCodes={r.get('versionCodes')} "
              f"(may be draft / awaiting Managed-Publishing publish / in review)")
    else:
        print("PRODUCTION VERDICT: NO production release found")
finally:
    # READ-ONLY: discard the edit without committing — changes nothing.
    service.edits().delete(packageName=package_name, editId=edit_id).execute()
    print("\n(read-only: edit discarded, nothing changed)")
PYTHON_EOF
