#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# Startup budget enforcement for CI.
#
# A CI runner has no phone, so this cannot time a cold start. What it CAN
# hold is the structural half: the instrumentation is still in place, and
# the work the budget was measured over has not grown. #4140 is where
# that half became a real gate (test/core/perf/startup_regression_gate_test.dart
# runs HiveFirstFrameBoxes.openAll and pins both the first-frame box set
# and the pre-first-frame await list); this script is its CI entry point.
#
# ## One number, one place (#4140)
#
# This script used to carry `BUDGET_MS=2000` of its own while
# `kColdStartBudget` said 2,500 ms and docs/PROJECT_OVERVIEW.md repeated
# the 2,000. Three statements of one budget, none derived from another,
# and the one with a recorded measurement behind it was not the one CI
# printed. The number is now READ from the constant that carries its
# provenance — a budget this script cannot restate is a budget it cannot
# contradict.
#
# Usage: bash scripts/check_startup_budget.sh

set -euo pipefail

BUDGETS_FILE="lib/core/perf/perf_budgets.dart"
INIT_FILE="lib/app/app_initializer.dart"

echo "=== Startup Budget Check ==="

# 1. The budget, read from the constant that carries its provenance.
if [ ! -f "$BUDGETS_FILE" ]; then
  echo "::error::$BUDGETS_FILE not found — the budgets have no home"
  exit 1
fi

BUDGET_MS=$(awk '/^const kColdStartBudget = PerfBudget\(/,/^\);/' "$BUDGETS_FILE" \
  | sed -n 's/^  limit: \([0-9]*\),$/\1/p')

if [ -z "$BUDGET_MS" ]; then
  echo "::error::could not read kColdStartBudget.limit from $BUDGETS_FILE."
  echo "::error::Refusing to invent a number: a budget nobody can defend is worse than none."
  exit 1
fi

echo "Cold start to a usable map: ${BUDGET_MS} ms (kColdStartBudget)"
echo "Measured on a device, reported in the field export — not asserted here."
echo ""

# 2. The instrumentation that produces it must still be in place.
if [ ! -f "$INIT_FILE" ]; then
  echo "::error::$INIT_FILE not found (cold-start sequence missing)"
  exit 1
fi

MARKERS=("StartupTimer.instance.start()" "StartupTimer.instance.mark(" "StartupTimer.instance.finish()")
MISSING=0

for marker in "${MARKERS[@]}"; do
  if ! grep -q "$marker" "$INIT_FILE"; then
    echo "::error::Missing startup instrumentation: $marker"
    MISSING=$((MISSING + 1))
  fi
done

if [ "$MISSING" -gt 0 ]; then
  echo "::error::${MISSING} startup instrumentation marker(s) missing from ${INIT_FILE}"
  exit 1
fi

echo "Instrumentation markers: OK"

MILESTONE_COUNT=$(grep -c "StartupTimer.instance.mark(" "$INIT_FILE" || true)
echo "Milestones in ${INIT_FILE}: ${MILESTONE_COUNT}"

# 3. The KPI derived from them must still reach the trace export.
if ! grep -q "StartupKpi.exportRow()" lib/core/perf/startup_trace_export.dart; then
  echo "::error::the #4140 KPI no longer reaches the startup trace export —"
  echo "::error::the field read-out is how this budget is ever checked at all."
  exit 1
fi

echo "KPI reported in the startup trace: OK"

# 4. The structural gates, including the #4140 regression gate.
echo ""
echo "Running startup + perf tests..."
flutter test test/core/perf/ --reporter compact

echo ""
echo "Startup budget check passed."
