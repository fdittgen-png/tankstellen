#!/usr/bin/env python3
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT
"""Promote the newest release from one Play track to another at 100%.

#3713 — the Console's promote flow pre-fills the staged-rollout
percentage from the LAST staged release, which silently shipped a
production release at 5% (2 of 35 devices). This tool is the durable
replacement: it reads the newest completed release off the source
track and assigns its version codes + release notes to the target
track with status 'completed' — always a full rollout, no percentage
field anywhere.

Usage:
    python tools/promote_release.py                          # beta -> production
    python tools/promote_release.py --from-track internal --to-track beta
    python tools/promote_release.py --dry-run                # validate, no commit

Reuses the retry/timeout hardening from upload_to_play.py (#1983/#1999/
#2009) by importing it — both tools live in tools/ and run from the
repo root.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from upload_to_play import (  # noqa: E402
    DEFAULT_KEY,
    DEFAULT_PACKAGE,
    HTTP_SOCKET_TIMEOUT_S,
    SCOPES,
    _execute_with_retry,
)

import httplib2  # noqa: E402
from google.oauth2 import service_account  # noqa: E402
from google_auth_httplib2 import AuthorizedHttp  # noqa: E402
from googleapiclient.discovery import build  # noqa: E402

TRACKS = ["internal", "alpha", "beta", "production"]


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--package", default=DEFAULT_PACKAGE)
    parser.add_argument("--from-track", default="beta", choices=TRACKS)
    parser.add_argument("--to-track", default="production", choices=TRACKS)
    parser.add_argument("--key", default=DEFAULT_KEY)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Resolve and print the promotion, then abandon the edit "
        "instead of committing.",
    )
    args = parser.parse_args()

    if args.from_track == args.to_track:
        print(f"ERROR: source and target track are both '{args.to_track}'")
        return 2

    credentials = service_account.Credentials.from_service_account_file(
        args.key, scopes=SCOPES
    )
    http = AuthorizedHttp(
        credentials, http=httplib2.Http(timeout=HTTP_SOCKET_TIMEOUT_S)
    )
    service = build("androidpublisher", "v3", http=http, cache_discovery=False)
    edits = service.edits()

    edit = _execute_with_retry(
        lambda: edits.insert(packageName=args.package), label="edits.insert"
    )
    edit_id = edit["id"]

    source = _execute_with_retry(
        lambda: edits.tracks().get(
            packageName=args.package, editId=edit_id, track=args.from_track
        ),
        label=f"tracks.get({args.from_track})",
    )
    releases = source.get("releases", [])
    completed = [r for r in releases if r.get("status") == "completed"]
    if not completed:
        print(
            f"ERROR: no completed release on '{args.from_track}' "
            f"(found: {[r.get('status') for r in releases]})"
        )
        return 3
    # The Play API lists the newest release first; guard on version codes
    # so a notes-only phantom release can never be promoted.
    release = completed[0]
    codes = release.get("versionCodes", [])
    if not codes:
        print(f"ERROR: newest completed '{args.from_track}' release has no "
              "version codes")
        return 3

    promoted = {
        "versionCodes": codes,
        "status": "completed",  # THE point: always 100%, never staged
        "releaseNotes": release.get("releaseNotes", []),
        "name": release.get("name"),
    }
    print(
        f"Promoting {args.from_track} -> {args.to_track}: "
        f"versionCodes={codes} name={promoted['name']!r} "
        f"notes={len(promoted['releaseNotes'])} locale(s), status=completed"
    )

    if args.dry_run:
        print("DRY RUN — abandoning the edit, nothing committed.")
        _execute_with_retry(
            lambda: edits.delete(packageName=args.package, editId=edit_id),
            label="edits.delete",
        )
        return 0

    _execute_with_retry(
        lambda: edits.tracks().update(
            packageName=args.package,
            editId=edit_id,
            track=args.to_track,
            body={"track": args.to_track, "releases": [promoted]},
        ),
        label=f"tracks.update({args.to_track})",
    )
    committed = _execute_with_retry(
        lambda: edits.commit(packageName=args.package, editId=edit_id),
        label="edits.commit",
    )
    print(f"Committed edit {committed['id']} — '{args.to_track}' now carries "
          f"{codes} at 100%.")
    print("Managed publishing: if enabled, the change waits in the "
          "publishing overview for the final publish click after review.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
