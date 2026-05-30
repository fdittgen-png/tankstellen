#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# issue_file_affinity.sh — Cluster GitHub issues by declared file paths so no
# file (especially shared surfaces) appears in two clusters.
#
# USAGE
#   bash scripts/issue_file_affinity.sh <issue1> [<issue2> ...]
#
# OUTPUT (one line per cluster):
#   CLUSTER <n>: <issue_numbers...> [SHARED-SURFACE: <files...>]
#
# SHARED-SURFACE FLAG
#   A cluster is flagged when it contains issues that touch one or more of the
#   known shared surfaces:
#     - lib/l10n/app_*.arb      (ARB locale files — l10n fan-out surface)
#     - *.g.dart / *.freezed.dart (codegen outputs — build_runner surface)
#     - .github/workflows/ci.yml  (single CI workflow file)
#     - test/lint/file_length_test.dart (grandfathered baseline — updated frequently)
#
#   ARB-touching and codegen-touching issues are each forced into their own
#   singleton cluster (they must never share a cluster with another ARB/codegen
#   issue, and should not share with each other to avoid ordering hazards).
#
# CLUSTERING ALGORITHM
#   1. For each issue, fetch its body via `gh issue view --json body` and extract
#      declared file paths (lines matching lib/…, test/…, tool/…, .github/…,
#      scripts/…).
#   2. Separate issues into three buckets before general clustering:
#        ARB bucket    — issues that touch lib/l10n/app_*.arb
#        Codegen bucket — issues that touch *.g.dart or *.freezed.dart
#        General bucket — everything else
#   3. Each ARB-bucket issue becomes its own singleton cluster.
#   4. Each codegen-bucket issue becomes its own singleton cluster.
#   5. For the general bucket, greedily assign each issue to the first existing
#      cluster whose file set is disjoint from the issue's files. If no such
#      cluster exists, open a new cluster.
#   6. Emit clusters in order, printing each issue's numbers and a SHARED-SURFACE
#      flag when the cluster touches any known shared surface.
#
# RATIONALE
#   Parallel sld agents that touch the same file race to a DIRTY merge conflict.
#   The ARB and codegen surfaces are the highest-frequency collision points
#   (incidents documented in GitHub issues #2360 and #2361). Isolating them to
#   singleton clusters means at most one agent modifies l10n or codegen per wave.
#
# REQUIREMENTS
#   - gh CLI authenticated (`gh auth status`)
#   - python3 on PATH (used for JSON parsing — no external deps)
#
# EXAMPLES
#   # Cluster a set of open issues before assigning worktrees:
#   bash scripts/issue_file_affinity.sh 2168 2169 2170 2171 2172
#
#   # Pipe into the orchestrator's bundle-planning step:
#   OPEN=$(gh issue list --label area/core --state open --json number \
#            --jq '.[].number' | tr '\n' ' ')
#   bash scripts/issue_file_affinity.sh $OPEN

set -euo pipefail

# ---------------------------------------------------------------------------
# Shared-surface patterns (ERE, used with grep -E)
# ---------------------------------------------------------------------------
ARB_PATTERN='lib/l10n/app_[^[:space:]]*.arb'
CODEGEN_PATTERN='\.(g|freezed)\.dart'
SHARED_SURFACES=(
  'lib/l10n/app_.*\.arb'
  '\.g\.dart'
  '\.freezed\.dart'
  '\.github/workflows/ci\.yml'
  'test/lint/file_length_test\.dart'
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

die() { echo "ERROR: $*" >&2; exit 1; }

require_commands() {
  for cmd in gh python3; do
    command -v "$cmd" >/dev/null 2>&1 || die "'$cmd' not found on PATH."
  done
}

# Fetch the body of a GitHub issue and extract declared file paths.
# Recognised path prefixes: lib/ test/ tool/ .github/ scripts/
# Paths are grepped from the raw markdown — no YAML parsing required.
extract_paths() {
  local issue="$1"
  gh issue view "$issue" --json body \
    --jq '.body // ""' 2>/dev/null \
  | grep -oE '(lib|test|tool|\.github|scripts)/[A-Za-z0-9_./*-]+' \
  | sort -u \
  || true
}

# Check whether a path list (one per line) matches a given ERE.
paths_match() {
  local paths="$1" pattern="$2"
  echo "$paths" | grep -qE "$pattern" 2>/dev/null
}

# Check whether a path list touches any known shared surface.
# Prints matching surface patterns, space-separated, or nothing.
shared_surfaces_hit() {
  local paths="$1"
  local hits=()
  for pat in "${SHARED_SURFACES[@]}"; do
    if echo "$paths" | grep -qE "$pat" 2>/dev/null; then
      hits+=("$pat")
    fi
  done
  if [ "${#hits[@]}" -gt 0 ]; then
    printf '%s ' "${hits[@]}"
  fi
}

# Test whether two newline-separated file lists are disjoint.
# Returns 0 (true) if disjoint, 1 if they share at least one path.
lists_disjoint() {
  local a="$1" b="$2"
  # Normalise: expand glob-style wildcards in the issue body paths to
  # plain prefix matching. We compare literal extracted paths from each
  # issue body — no filesystem globs are expanded; the match is textual.
  if [ -z "$a" ] || [ -z "$b" ]; then
    return 0  # empty list is disjoint with everything
  fi
  # Use python3 for set intersection (handles whitespace robustly).
  python3 - "$a" "$b" <<'PYEOF'
import sys
a = set(sys.argv[1].split())
b = set(sys.argv[2].split())
sys.exit(0 if a.isdisjoint(b) else 1)
PYEOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  require_commands

  if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <issue1> [<issue2> ...]" >&2
    exit 1
  fi

  local issues=("$@")

  # --- Step 1: fetch file lists for every issue ---------------------------
  declare -A issue_paths  # issue# -> newline-joined path list

  echo "Fetching file lists for ${#issues[@]} issue(s)..." >&2
  for issue in "${issues[@]}"; do
    issue_paths["$issue"]="$(extract_paths "$issue")"
    echo "  #$issue: $(echo "${issue_paths[$issue]}" | grep -c '' || echo 0) path(s) declared" >&2
  done

  # --- Step 2: bucket into ARB / Codegen / General -----------------------
  arb_issues=()
  codegen_issues=()
  general_issues=()

  for issue in "${issues[@]}"; do
    paths="${issue_paths[$issue]}"
    if paths_match "$paths" "$ARB_PATTERN"; then
      arb_issues+=("$issue")
    elif paths_match "$paths" "$CODEGEN_PATTERN"; then
      codegen_issues+=("$issue")
    else
      general_issues+=("$issue")
    fi
  done

  # --- Step 3–4: singleton clusters for ARB and codegen ------------------
  # cluster_issues: array of space-joined issue-number strings (one per cluster)
  # cluster_paths:  array of space-joined path strings (one per cluster)
  cluster_issues=()
  cluster_paths=()
  cluster_flags=()   # SHARED-SURFACE annotation (empty string if none)

  for issue in "${arb_issues[@]}"; do
    cluster_issues+=("$issue")
    cluster_paths+=("${issue_paths[$issue]}")
    cluster_flags+=("lib/l10n/app_*.arb")
  done

  for issue in "${codegen_issues[@]}"; do
    cluster_issues+=("$issue")
    cluster_paths+=("${issue_paths[$issue]}")
    cluster_flags+=("*.g.dart / *.freezed.dart")
  done

  # --- Step 5: greedy disjoint clustering for general issues -------------
  for issue in "${general_issues[@]}"; do
    paths="${issue_paths[$issue]}"
    placed=0
    for i in "${!cluster_issues[@]}"; do
      # Only consider clusters that started in the general bucket
      # (ARB/codegen singletons are never extended).
      # Identify general clusters by absence of the ARB/codegen flag.
      flag="${cluster_flags[$i]}"
      if [ -n "$flag" ]; then
        continue  # skip ARB / codegen singletons
      fi
      if lists_disjoint "$paths" "${cluster_paths[$i]}"; then
        # Merge into this cluster.
        cluster_issues[$i]="${cluster_issues[$i]} $issue"
        # Union the path sets.
        merged_paths="$(printf '%s\n%s' "${cluster_paths[$i]}" "$paths" | sort -u | tr '\n' ' ')"
        cluster_paths[$i]="$merged_paths"
        placed=1
        break
      fi
    done
    if [ "$placed" -eq 0 ]; then
      # No disjoint cluster found — open a new one.
      cluster_issues+=("$issue")
      cluster_paths+=("$paths")
      cluster_flags+=("")
    fi
  done

  # --- Step 6: emit output -----------------------------------------------
  local n="${#cluster_issues[@]}"
  echo "" >&2
  echo "=== File-affinity clusters ($n cluster(s)) ===" >&2

  for i in "${!cluster_issues[@]}"; do
    label=$((i + 1))
    nums="${cluster_issues[$i]}"
    flag="${cluster_flags[$i]}"

    # Compute shared-surface hit from the cluster's accumulated paths.
    surf="$(shared_surfaces_hit "${cluster_paths[$i]}")"

    line="CLUSTER $label: $nums"
    if [ -n "$surf" ] || [ -n "$flag" ]; then
      annotation="${flag:-$surf}"
      line="$line  [SHARED-SURFACE: $annotation]"
    fi
    echo "$line"
  done
}

main "$@"
