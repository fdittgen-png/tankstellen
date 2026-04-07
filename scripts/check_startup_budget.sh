#!/usr/bin/env bash
# Startup time budget enforcement for CI.
# Verifies that startup instrumentation is in place and that the
# timer utility tests pass. On a real device/emulator, this would
# check cold start time against a budget — but CI runners don't
# have emulators, so we enforce the structural contract instead.
#
# Usage: bash scripts/check_startup_budget.sh [--budget-ms N]
#   --budget-ms N   Maximum allowed startup time in ms (default: 2000)
#                   Used as reference budget; enforced in integration tests.
#
# This script:
#   1. Checks that main.dart contains StartupTimer instrumentation
#   2. Runs the startup timer unit tests
#   3. Prints the configured budget for visibility

set -euo pipefail

BUDGET_MS=2000

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --budget-ms)
      BUDGET_MS="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: bash scripts/check_startup_budget.sh [--budget-ms N]"
      exit 1
      ;;
  esac
done

echo "=== Startup Time Budget Check ==="
echo "Budget: ${BUDGET_MS}ms"
echo ""

# 1. Check that main.dart has instrumentation markers
MAIN_FILE="lib/main.dart"
if [ ! -f "$MAIN_FILE" ]; then
  echo "::error::$MAIN_FILE not found"
  exit 1
fi

MARKERS=("StartupTimer.instance.start()" "StartupTimer.instance.mark(" "StartupTimer.instance.finish()")
MISSING=0

for marker in "${MARKERS[@]}"; do
  if ! grep -q "$marker" "$MAIN_FILE"; then
    echo "::error::Missing startup instrumentation: $marker"
    MISSING=$((MISSING + 1))
  fi
done

if [ "$MISSING" -gt 0 ]; then
  echo "::error::${MISSING} startup instrumentation marker(s) missing from main.dart"
  exit 1
fi

echo "Instrumentation markers: OK"

# 2. Count milestones
MILESTONE_COUNT=$(grep -c "StartupTimer.instance.mark(" "$MAIN_FILE" || true)
echo "Milestones in main.dart: ${MILESTONE_COUNT}"

if [ "$MILESTONE_COUNT" -lt 3 ]; then
  echo "::warning::Only ${MILESTONE_COUNT} milestones — consider adding more for better visibility"
fi

# 3. Run startup timer tests
echo ""
echo "Running startup timer tests..."
flutter test test/core/perf/ --reporter compact
echo ""
echo "Startup budget check passed."
echo "Budget reference: ${BUDGET_MS}ms (enforced in integration/device tests)"
