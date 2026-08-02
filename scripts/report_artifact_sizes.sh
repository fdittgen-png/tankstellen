#!/usr/bin/env bash
# #3661 — release-artifact size visibility (llmwiki page 25, "app size").
#
# Size has no failing test unless you build one: it drifts in dependency
# bumps and asset additions that each look innocent. This prints every
# release artifact's size into the job summary so the number is visible
# on every build, and FAILS when an artifact is implausibly small — the
# empty-harvest trap in reverse (a truncated/empty artifact shipping as
# if it were the app).
#
# Usage: report_artifact_sizes.sh <glob-or-file>...
#   MIN_ARTIFACT_MB (env, default 20) — hard floor per artifact.
#
# Integer arithmetic only: a locale-dependent float format (printf %.1f
# emitting a comma under a non-English shell) once silently broke a
# numeric CI gate in this repo's ecosystem.
set -euo pipefail

MIN_MB="${MIN_ARTIFACT_MB:-20}"
MIN_BYTES=$((MIN_MB * 1024 * 1024))
SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

found=0
fail=0
{
  echo ""
  echo "### Release artifact sizes"
} >> "$SUMMARY"

for pattern in "$@"; do
  for f in $pattern; do
    [ -f "$f" ] || continue
    found=1
    bytes=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f")
    mb=$((bytes / 1024 / 1024))
    echo "- \`$(basename "$f")\`: ${mb} MB (${bytes} bytes)" >> "$SUMMARY"
    if [ "$bytes" -lt "$MIN_BYTES" ]; then
      echo "::error file=$f::implausibly small release artifact (< ${MIN_MB} MB): $f is ${bytes} bytes"
      fail=1
    fi
  done
done

if [ "$found" -eq 0 ]; then
  echo "::error::report_artifact_sizes: no artifacts matched: $*"
  exit 1
fi
exit "$fail"
