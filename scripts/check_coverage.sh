#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: AGPL-3.0-or-later

# Coverage threshold enforcement for CI and local use.
# Parses lcov.info, excludes generated files, and fails if coverage is below threshold.
#
# Usage: bash scripts/check_coverage.sh [--threshold N] [--lcov PATH]
#   --threshold N   Minimum coverage percentage (default: 40)
#   --lcov PATH     Path to lcov.info file (default: coverage/lcov.info)
#
# The CI gate is intentionally a floor, not a target — TDD practice
# remains the rule for new code. The floor is set low enough that a
# transient infra hang or one untestable platform-channel boundary does
# not red-CI an otherwise good PR.

set -uo pipefail

# Defaults
THRESHOLD=40
LCOV_FILE="coverage/lcov.info"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --threshold)
      THRESHOLD="$2"
      shift 2
      ;;
    --lcov)
      LCOV_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: bash scripts/check_coverage.sh [--threshold N] [--lcov PATH]"
      exit 1
      ;;
  esac
done

# Validate threshold is a number
if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
  echo "::error::Threshold must be a positive integer, got: $THRESHOLD"
  exit 1
fi

if [ ! -f "$LCOV_FILE" ]; then
  echo "::error::Coverage file not found: $LCOV_FILE"
  echo "Run 'flutter test --coverage' first."
  exit 1
fi

# Filter out generated files (l10n, .g.dart, .freezed.dart) from lcov
FILTERED_FILE="${LCOV_FILE%.info}_filtered.info"

python3 -c "
import sys
skip = False
with open('$LCOV_FILE') as f:
    with open('$FILTERED_FILE', 'w') as out:
        for line in f:
            if line.startswith('SF:'):
                skip = '.g.dart' in line or '.freezed.dart' in line or 'l10n/app_localizations' in line
            if not skip:
                out.write(line)
            if line.startswith('end_of_record'):
                skip = False
"

TOTAL_LINES=$(grep -c "^DA:" "$FILTERED_FILE" || true)
HIT_LINES=$(grep "^DA:" "$FILTERED_FILE" | grep -cv ",0$" || true)

# #4347 — an empty or fully filtered report is not positive coverage
# evidence: nothing was measured, so it must not satisfy the gate. (This
# branch used to warn and exit 0.)
if [ "$TOTAL_LINES" -eq 0 ]; then
  echo "::error::No coverage data left after filtering generated files ($LCOV_FILE has no maintained-source DA records) — refusing to report a pass."
  exit 1
fi

# #4347 — report the exact ratio to two decimals (62,680 / 72,069 is
# 86.97 %, which integer division printed as 86 %). The gate compares the
# exact rational, HIT/TOTAL < THRESHOLD/100, which for an integer threshold
# decides exactly as the old truncated comparison did.
COVERAGE_2DP=$(LC_ALL=C awk -v h="$HIT_LINES" -v t="$TOTAL_LINES" 'BEGIN { printf "%.2f", h * 100 / t }')
echo "Coverage: ${COVERAGE_2DP}% (${HIT_LINES}/${TOTAL_LINES} lines, excluding generated code)"
echo "Threshold: ${THRESHOLD}%"

if [ $((HIT_LINES * 100)) -lt $((THRESHOLD * TOTAL_LINES)) ]; then
  echo "::error::Coverage ${COVERAGE_2DP}% is below ${THRESHOLD}% threshold"
  exit 1
fi

echo "Coverage check passed."
