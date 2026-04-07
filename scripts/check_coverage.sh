#!/usr/bin/env bash
# Coverage threshold enforcement for CI and local use.
# Parses lcov.info, excludes generated files, and fails if coverage is below threshold.
#
# Usage: bash scripts/check_coverage.sh [--threshold N] [--lcov PATH]
#   --threshold N   Minimum coverage percentage (default: 45)
#   --lcov PATH     Path to lcov.info file (default: coverage/lcov.info)
#
# Coverage roadmap (update threshold as coverage improves):
#   v4.2.0: 45%  (current)
#   v4.3.0: 50%
#   v5.0.0-beta: 60%

set -uo pipefail

# Defaults
THRESHOLD=45
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

if [ "$TOTAL_LINES" -eq 0 ]; then
  echo "::warning::No coverage data found after filtering generated files."
  exit 0
fi

COVERAGE=$((HIT_LINES * 100 / TOTAL_LINES))
echo "Coverage: ${COVERAGE}% (${HIT_LINES}/${TOTAL_LINES} lines, excluding generated code)"
echo "Threshold: ${THRESHOLD}%"

if [ "$COVERAGE" -lt "$THRESHOLD" ]; then
  echo "::error::Coverage ${COVERAGE}% is below ${THRESHOLD}% threshold"
  exit 1
fi

echo "Coverage check passed."
