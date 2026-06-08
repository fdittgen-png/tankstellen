#!/usr/bin/env python3
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

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
import time
from datetime import date
from pathlib import Path

import httplib2
from google.oauth2 import service_account
from google_auth_httplib2 import AuthorizedHttp
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaFileUpload

# #2009 part 2 — httplib2 lists 308 in `REDIRECT_CODES` and follows it
# as a normal redirect. Google's resumable-upload protocol abuses 308
# ("Resume Incomplete") to mean "I've received N bytes — please POST
# the next range to the SAME session URI" and intentionally omits the
# `Location` header (the session URI is sticky). httplib2's redirect-
# follow code then raises `RedirectMissingLocation` and the upload
# dies even though googleapiclient's `next_chunk` is itself designed
# to recognise a 308 + sticky URI and continue the upload (see
# googleapiclient/http.py `next_chunk` — it reads `resp["range"]` and
# loops). Removing 308 from `REDIRECT_CODES` lets the 308 pass
# through to googleapiclient so it can resume correctly. Affects
# only our process — the frozenset is class-level, not per-instance.
httplib2.REDIRECT_CODES = frozenset(httplib2.REDIRECT_CODES - {308})

DEFAULT_PACKAGE = "de.tankstellen.fuelprices"
DEFAULT_TRACK = "beta"  # 'beta' = open testing, 'internal' = internal, 'alpha' = closed, 'production' = prod
DEFAULT_AAB = "build/app/outputs/bundle/playRelease/app-play-release.aab"
DEFAULT_KEY = os.path.expanduser("~/.play-console-key.json")
DEFAULT_CHANGELOG_DIR = "fastlane/metadata/android"
DEFAULT_LOCALES = ["de-DE", "en-US", "fr-FR"]
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]

# Sparkilo's supported markets — one official government fuel-data provider per
# country (lib/core/country/country_config.dart). The PRODUCTION release must
# target an explicit country set: a brand-new production track targets NO
# countries by default, so edits.commit() fails with "Release in track
# targeting no countries". We target exactly the supported markets (NOT
# rest-of-world) because a fuel app published in a country with no provider
# would show empty data and draw 1-star reviews. Testing tracks
# (internal/alpha/beta) are global by default and unaffected.
SUPPORTED_PRODUCTION_COUNTRIES = [
    "DE", "FR", "AT", "ES", "IT", "PT", "GB", "AU", "MX",
    "AR", "DK", "LU", "SI", "KR", "CL", "GR", "RO",
]

# #1983 — every Android Publisher call is a network round-trip; a daily
# CI build must not die on a single transient socket timeout / 5xx.
# `num_retries` makes googleapiclient retry those with exponential
# backoff. `UPLOAD_CHUNK_BYTES` splits the resumable AAB upload into
# smaller, individually-retryable requests (must be a 256 KB multiple).
#
# #1999 — #1983's retries don't help when the failure mode is a *slow*
# chunk (server still processing the previous one, the PUT response
# read stalls past httplib2's default ~60 s socket timeout). Two
# follow-ups:
#   1. Drop the chunk size from 8 MiB to 4 MiB — a retry replays half
#      as much data, and the per-chunk wall-clock shrinks so a slow
#      server is less likely to push us past the read timeout.
#   2. Wrap the credentialed client in an [AuthorizedHttp] backed by
#      an [httplib2.Http] with a 300 s (5 min) socket timeout, well
#      above the worst slow-chunk window observed in CI (~65 s).
#
# #2009 — #1999 still leaves one failure mode uncovered. The Play
# upload server occasionally returns HTTP 308 ("Resume Incomplete")
# WITHOUT a `Location` header, and httplib2 misreads that as a
# malformed redirect and raises `RedirectMissingLocation` straight
# out of `next_chunk`. The googleapiclient inner `num_retries` DOES
# catch it (it's a `httplib2.HttpLib2Error` subclass) but every
# retry hits the same server window with the same response. The fix:
# wrap each Android-Publisher .execute() through `_execute_with_retry`,
# which catches both `HttpError` AND `httplib2.HttpLib2Error` and
# retries the WHOLE edit call (3 attempts, 2 s / 8 s / 30 s backoff)
# so each outer attempt starts a fresh resumable session — that's
# what actually clears the flaky 308.
MAX_API_RETRIES = 5
UPLOAD_CHUNK_BYTES = 4 * 1024 * 1024
HTTP_SOCKET_TIMEOUT_S = 300
OUTER_RETRY_BACKOFFS_S = (2, 8, 30)


def _execute_with_retry(call_factory, *, label: str):
    """Run a Google API request through layered retry (#2009).

    `call_factory` is a zero-arg callable that builds a fresh request
    object each invocation. We don't reuse the same request across
    outer retries — a `MediaFileUpload` becomes useless after a
    failed resumable session because its internal byte-offset state
    is stale. Building fresh each attempt keeps the retry idempotent.

    Catches:
        - `googleapiclient.errors.HttpError` (real HTTP-level errors
          surfaced after the inner `num_retries=MAX_API_RETRIES` gave
          up).
        - `httplib2.error.HttpLib2Error` (covers `RedirectMissingLocation`
          and the parse-level errors httplib2 raises when the
          upstream returns a malformed response — exactly the 308-
          without-Location case from #2009).
        - `TimeoutError` (the per-chunk socket read timed out even
          past the 300 s `HTTP_SOCKET_TIMEOUT_S` ceiling).

    Returns the result of the successful `.execute(...)` call.
    Re-raises the last exception when all attempts fail.
    """
    last_error: Exception | None = None
    attempts = len(OUTER_RETRY_BACKOFFS_S) + 1
    for attempt in range(attempts):
        try:
            request = call_factory()
            return request.execute(num_retries=MAX_API_RETRIES)
        except (HttpError, httplib2.HttpLib2Error, TimeoutError) as e:
            last_error = e
            if attempt == attempts - 1:
                break
            delay = OUTER_RETRY_BACKOFFS_S[attempt]
            print(
                f"  {label} attempt {attempt + 1}/{attempts} failed "
                f"({type(e).__name__}); retrying in {delay}s",
                file=sys.stderr,
            )
            time.sleep(delay)
    # Re-raise so the per-step `except` blocks in main() can map to
    # the right exit code. The original traceback is preserved.
    assert last_error is not None
    raise last_error


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
    # #1999 — route the API client through an httplib2.Http with a
    # 5-minute socket timeout so the chunked AAB upload doesn't die on
    # one slow-server response read. The default httplib2 timeout
    # (~60 s) was the trigger for the Daily Open-Testing Build failures
    # logged on 2026-05-19 / 2026-05-20.
    authed_http = AuthorizedHttp(creds, http=httplib2.Http(timeout=HTTP_SOCKET_TIMEOUT_S))
    service = build("androidpublisher", "v3", http=authed_http, cache_discovery=False)
    edits = service.edits()

    # All Android-Publisher edit calls below route through
    # `_execute_with_retry` so each layered failure mode has the same
    # 3-attempt safety net (#2009). The same `except` mapping each
    # step had before stays — only the call itself is wrapped.
    print(f"Opening edit for {args.package}")
    try:
        edit = _execute_with_retry(
            lambda: edits.insert(packageName=args.package, body={}),
            label="edits.insert",
        )
    except (HttpError, httplib2.HttpLib2Error, TimeoutError) as e:
        print(f"ERROR: edits.insert failed: {e}", file=sys.stderr)
        return 3
    edit_id = edit["id"]
    print(f"  edit id: {edit_id}")

    print(f"Uploading {aab} ({aab.stat().st_size / 1_000_000:.2f} MB)")
    # #2009 — build a FRESH MediaFileUpload inside each outer retry.
    # A `MediaFileUpload` carries internal resumable-session state
    # (byte-offset, session URI) that becomes stale after a failed
    # session; reusing it across outer retries would resend a chunk
    # to a dead URI. The lambda below is re-evaluated on every
    # outer attempt so each one starts a clean resumable session.
    def _build_upload_request():
        media = MediaFileUpload(
            str(aab),
            mimetype="application/octet-stream",
            resumable=True,
            chunksize=UPLOAD_CHUNK_BYTES,
        )
        return edits.bundles().upload(
            packageName=args.package,
            editId=edit_id,
            media_body=media,
        )

    try:
        bundle = _execute_with_retry(
            _build_upload_request,
            label="bundles.upload",
        )
    except (HttpError, httplib2.HttpLib2Error, TimeoutError) as e:
        print(f"ERROR: bundle upload failed: {e}", file=sys.stderr)
        return 4
    version_code = bundle["versionCode"]
    print(f"  uploaded versionCode: {version_code}")

    print(f"Resolving release notes for versionCode {version_code}")
    release_notes = load_release_notes(changelog_dir, args.locales, version_code, fallback_notes)

    print(f"Assigning to track '{args.track}'")

    def _assign_and_commit(target_edit_id, release_body):
        """Assign one release to the track then validate (dry-run) or commit.
        Raises the underlying API error on a hard failure."""
        _execute_with_retry(
            lambda: edits.tracks().update(
                packageName=args.package,
                editId=target_edit_id,
                track=args.track,
                body={"track": args.track, "releases": [release_body]},
            ),
            label="tracks.update",
        )
        if args.dry_run:
            _execute_with_retry(
                lambda: edits.validate(
                    packageName=args.package, editId=target_edit_id,
                ),
                label="edits.validate",
            )
            print("Validation OK — edit will NOT be committed (dry-run).")
            return
        _execute_with_retry(
            lambda: edits.commit(
                packageName=args.package, editId=target_edit_id,
            ),
            label="edits.commit",
        )

    base_release = {
        "name": f"{version_code}",
        "versionCodes": [str(version_code)],
        "releaseNotes": release_notes,
    }

    try:
        if args.track == "production":
            # Play rejects countryTargeting on a 'completed' release, AND a
            # never-published production track targets no countries — so a
            # single 'completed' release 403s with "targeting no countries".
            # Two-phase launch:
            #   Phase 1 — a STAGED (inProgress) release WITH countryTargeting
            #             establishes the production track's availability in the
            #             supported markets and goes live to ~all users there.
            #   Phase 2 — COMPLETE that release to 100% (countries are now
            #             established, so countryTargeting is no longer
            #             needed/allowed). This mirrors the Console "Go to 100%".
            print(f"  production countryTargeting: "
                  f"{len(SUPPORTED_PRODUCTION_COUNTRIES)} markets "
                  f"({', '.join(SUPPORTED_PRODUCTION_COUNTRIES)})")
            staged = {
                **base_release,
                "status": "inProgress",
                "userFraction": 0.99,
                "countryTargeting": {
                    "countries": SUPPORTED_PRODUCTION_COUNTRIES,
                    "includeRestOfWorld": False,
                },
            }
            print("Phase 1/2: staged rollout to the supported markets")
            _assign_and_commit(edit_id, staged)
            if args.dry_run:
                return 0
            print("  phase 1 committed — production now available in the "
                  "supported markets")
            try:
                edit2 = _execute_with_retry(
                    lambda: edits.insert(packageName=args.package, body={}),
                    label="edits.insert (phase 2)",
                )["id"]
                print("Phase 2/2: completing to 100% production")
                _assign_and_commit(
                    edit2, {**base_release, "status": "completed"})
                print("  phase 2 committed — 100% production rollout")
            except (HttpError, httplib2.HttpLib2Error, TimeoutError) as e2:
                # Phase 1 already made the release LIVE in the supported markets
                # (99% staged). Completing to 100% can fail transiently while
                # Play processes phase 1 — recoverable (re-run, or "Go to 100%"
                # in the Console), NOT a deploy failure.
                print(f"WARNING: phase 2 (complete to 100%) deferred: {e2}",
                      file=sys.stderr)
                print("  release is LIVE in the supported markets (99%); "
                      "complete to 100% via a re-run or the Play Console.")
        else:
            _assign_and_commit(
                edit_id, {**base_release, "status": "completed"})
            if args.dry_run:
                return 0
    except (HttpError, httplib2.HttpLib2Error, TimeoutError) as e:
        print(f"ERROR: track assign/commit failed: {e}", file=sys.stderr)
        return 5

    print(f"\nSUCCESS: versionCode {version_code} published to track '{args.track}'")
    print(f"https://play.google.com/console/u/0/developers/5325652654414690657/app/4973487066249778216/tracks/open-testing")
    return 0


if __name__ == "__main__":
    sys.exit(main())
