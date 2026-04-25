#!/usr/bin/env python3
"""Upload a Flutter-built AAB to a Google Play track via the Android Publisher API.

Usage:
    python tools/upload_to_play.py                          # uses all defaults
    python tools/upload_to_play.py --track internal         # internal testing
    python tools/upload_to_play.py --release-notes "Daily build"
    python tools/upload_to_play.py --dry-run                # validate without committing

Requires:
    - google-api-python-client, google-auth (pip install)
    - Service-account JSON key with Play Console "Release manager" access
    - AAB at build/app/outputs/bundle/release/app-release.aab (or pass --aab)
"""

from __future__ import annotations

import argparse
import os
import sys
from datetime import date
from pathlib import Path

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

DEFAULT_PACKAGE = "de.tankstellen.fuelprices"
DEFAULT_TRACK = "beta"  # 'beta' = open testing, 'internal' = internal, 'alpha' = closed, 'production' = prod
DEFAULT_AAB = "build/app/outputs/bundle/playRelease/app-play-release.aab"
DEFAULT_KEY = os.path.expanduser("~/.play-console-key.json")
DEFAULT_CHANGELOG_DIR = "fastlane/metadata/android"
DEFAULT_LOCALES = ["de-DE", "en-US", "fr-FR"]
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def load_release_notes(
    changelog_dir: Path,
    locales: list[str],
    version_code: int,
    fallback: str,
) -> list[dict]:
    """Build the releaseNotes payload, one entry per locale.

    For each locale, prefer fastlane/metadata/android/{locale}/changelogs/{versionCode}.txt;
    fall back to the provided default text if the file is missing.
    """
    notes = []
    for locale in locales:
        path = changelog_dir / locale / "changelogs" / f"{version_code}.txt"
        if path.is_file():
            text = path.read_text(encoding="utf-8").strip()
            print(f"  [{locale}] using {path}")
        else:
            text = fallback
            print(f"  [{locale}] no per-version changelog, using fallback")
        # Play Store caps release notes at 500 chars per locale
        if len(text) > 500:
            print(f"  [{locale}] WARNING: truncated from {len(text)} to 500 chars")
            text = text[:497] + "..."
        notes.append({"language": locale, "text": text})
    return notes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--package", default=DEFAULT_PACKAGE, help=f"App package name (default: {DEFAULT_PACKAGE})")
    parser.add_argument("--track", default=DEFAULT_TRACK, choices=["internal", "alpha", "beta", "production"],
                        help=f"Play Store track (default: {DEFAULT_TRACK} = open testing)")
    parser.add_argument("--aab", default=DEFAULT_AAB, help=f"Path to AAB (default: {DEFAULT_AAB})")
    parser.add_argument("--key", default=DEFAULT_KEY, help=f"Service-account JSON key path (default: {DEFAULT_KEY})")
    parser.add_argument("--changelog-dir", default=DEFAULT_CHANGELOG_DIR,
                        help=f"Root of fastlane-style changelog metadata (default: {DEFAULT_CHANGELOG_DIR})")
    parser.add_argument("--locales", nargs="+", default=DEFAULT_LOCALES,
                        help=f"Locales to publish release notes for (default: {' '.join(DEFAULT_LOCALES)})")
    parser.add_argument("--release-notes", default=None,
                        help="Fallback release-notes text used when a per-version changelog file is missing. "
                             "Defaults to 'Daily build YYYY-MM-DD'.")
    parser.add_argument("--dry-run", action="store_true",
                        help="Validate the edit without committing (no testers receive the build)")
    args = parser.parse_args()

    aab = Path(args.aab).resolve()
    key = Path(args.key).resolve()
    changelog_dir = Path(args.changelog_dir).resolve()

    if not aab.is_file():
        print(f"ERROR: AAB not found at {aab}", file=sys.stderr)
        print("       Run `flutter build appbundle --release` first.", file=sys.stderr)
        return 2
    if not key.is_file():
        print(f"ERROR: service-account key not found at {key}", file=sys.stderr)
        return 2

    fallback_notes = args.release_notes or f"Daily build {date.today().isoformat()}"

    print(f"Authenticating as service account from {key}")
    creds = service_account.Credentials.from_service_account_file(str(key), scopes=SCOPES)
    service = build("androidpublisher", "v3", credentials=creds, cache_discovery=False)
    edits = service.edits()

    print(f"Opening edit for {args.package}")
    try:
        edit = edits.insert(packageName=args.package, body={}).execute()
    except HttpError as e:
        print(f"ERROR: edits.insert failed: {e}", file=sys.stderr)
        return 3
    edit_id = edit["id"]
    print(f"  edit id: {edit_id}")

    print(f"Uploading {aab} ({aab.stat().st_size / 1_000_000:.2f} MB)")
    media = MediaFileUpload(str(aab), mimetype="application/octet-stream", resumable=True)
    try:
        bundle = edits.bundles().upload(
            packageName=args.package,
            editId=edit_id,
            media_body=media,
        ).execute()
    except HttpError as e:
        print(f"ERROR: bundle upload failed: {e}", file=sys.stderr)
        return 4
    version_code = bundle["versionCode"]
    print(f"  uploaded versionCode: {version_code}")

    print(f"Resolving release notes for versionCode {version_code}")
    release_notes = load_release_notes(changelog_dir, args.locales, version_code, fallback_notes)

    print(f"Assigning to track '{args.track}'")
    try:
        edits.tracks().update(
            packageName=args.package,
            editId=edit_id,
            track=args.track,
            body={
                "track": args.track,
                "releases": [{
                    "name": f"{version_code}",
                    "versionCodes": [str(version_code)],
                    "status": "completed",
                    "releaseNotes": release_notes,
                }],
            },
        ).execute()
    except HttpError as e:
        print(f"ERROR: track update failed: {e}", file=sys.stderr)
        return 5

    if args.dry_run:
        print("Dry-run: validating edit (no commit)")
        try:
            edits.validate(packageName=args.package, editId=edit_id).execute()
            print("Validation OK — edit will NOT be committed (dry-run).")
        except HttpError as e:
            print(f"ERROR: validation failed: {e}", file=sys.stderr)
            return 6
        return 0

    print("Committing edit")
    try:
        edits.commit(packageName=args.package, editId=edit_id).execute()
    except HttpError as e:
        print(f"ERROR: edits.commit failed: {e}", file=sys.stderr)
        return 7

    print(f"\nSUCCESS: versionCode {version_code} published to track '{args.track}'")
    print(f"https://play.google.com/console/u/0/developers/5325652654414690657/app/4973487066249778216/tracks/open-testing")
    return 0


if __name__ == "__main__":
    sys.exit(main())
