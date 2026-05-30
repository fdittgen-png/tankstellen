#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# Source of truth for master's required-status-check protection (#2343).
#
# Why this exists: required checks + strict-mode used to live only in the
# GitHub API + memory, so they regressed silently across sessions. PR #2322
# auto-merged with `codegen-drift` RED because that check was non-required
# at the time, and `strict=false` (set to kill O(N^2) BEHIND-churn) was an
# undocumented API tweak. Encoding both here makes them auditable and safe
# to re-apply.
#
# Usage:
#   bash scripts/configure_branch_protection.sh            # PATCH live config
#   bash scripts/configure_branch_protection.sh --verify   # GET + diff only
#
# Idempotent: re-running the PATCH converges to the same TARGET set.
# `--verify` mutates nothing; it exits non-zero (printing the diff) when the
# live required-check set diverges from TARGET.

set -euo pipefail

REPO="fdittgen-png/tankstellen"
BRANCH="master"
API_PATH="repos/${REPO}/branches/${BRANCH}/protection/required_status_checks"

# TARGET required checks (dev-factory epic #2332).
#
# NOTE — this is the source of truth once the sibling issues land:
#   * build-android / integration / startup-budget / l10n-gate are ADDED as
#     required by issues #2337 / #2336 (the jobs themselves ship there).
#   * coverage-merge is REMOVED by #2338 (phantom check, never produced a
#     real status) — it MUST NOT appear in TARGET.
# Until those merge, `--verify` will legitimately report drift against live.
TARGET_CHECKS=(
  "analyze"
  "test (0)"
  "test (1)"
  "test (2)"
  "test (3)"
  "codegen-drift"
  "build-android"
  "integration"
  "startup-budget"
  "l10n-gate"
)

require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: gh CLI not found on PATH." >&2
    exit 2
  fi
}

# Emit the TARGET set, one check per line, sorted — for stable diffing.
target_sorted() {
  printf '%s\n' "${TARGET_CHECKS[@]}" | LC_ALL=C sort
}

# Fetch the live required-check contexts, one per line, sorted.
live_sorted() {
  gh api "$API_PATH" --jq '.contexts[]' 2>/dev/null | LC_ALL=C sort || true
}

# Fetch live strict flag ("true"/"false").
live_strict() {
  gh api "$API_PATH" --jq '.strict' 2>/dev/null || echo "unknown"
}

verify() {
  require_gh
  local target live strict status=0
  target="$(target_sorted)"
  live="$(live_sorted)"
  strict="$(live_strict)"

  echo "=== branch protection --verify: ${REPO}@${BRANCH} ==="
  echo "strict (live): ${strict}   (target: false)"
  echo ""

  if [ "$strict" != "false" ]; then
    echo "DRIFT: strict mode is '${strict}', target is 'false'." >&2
    status=1
  fi

  if [ "$live" = "$target" ]; then
    echo "Required checks: MATCH TARGET (${#TARGET_CHECKS[@]} checks)."
    printf '  %s\n' "${TARGET_CHECKS[@]}"
  else
    echo "DRIFT: live required checks differ from TARGET." >&2
    echo ""
    echo "  Only in TARGET (missing from live — add these):"
    comm -23 <(printf '%s\n' "$target") <(printf '%s\n' "$live") \
      | sed 's/^/    + /' || true
    echo "  Only in live (not in TARGET — remove these):"
    comm -13 <(printf '%s\n' "$target") <(printf '%s\n' "$live") \
      | sed 's/^/    - /' || true
    status=1
  fi

  if [ "$status" -ne 0 ]; then
    echo "" >&2
    echo "Re-apply with: bash scripts/configure_branch_protection.sh" >&2
  fi
  return "$status"
}

apply() {
  require_gh
  # Build the JSON body: required_status_checks with strict=false and the
  # TARGET contexts. PATCH is idempotent — same TARGET => same result.
  local contexts_json
  contexts_json="$(printf '%s\n' "${TARGET_CHECKS[@]}" \
    | python3 -c 'import json,sys; print(json.dumps([l.rstrip("\n") for l in sys.stdin if l.strip()]))')"

  echo "PATCHing ${API_PATH} -> strict=false, ${#TARGET_CHECKS[@]} required checks..."
  gh api -X PATCH "$API_PATH" \
    -H "Accept: application/vnd.github+json" \
    --input - <<JSON
{ "strict": false, "contexts": ${contexts_json} }
JSON
  echo "Done. Verifying..."
  verify
}

main() {
  case "${1:-}" in
    --verify)
      verify
      ;;
    "")
      apply
      ;;
    *)
      echo "Usage: $0 [--verify]" >&2
      exit 2
      ;;
  esac
}

main "$@"
