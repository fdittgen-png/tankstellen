#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# file_child_issue.sh — Wrapper around `gh issue create` that automatically
# inherits the parent Epic's milestone and area/* label, derives type/* from
# the title's conventional-commit prefix, and injects a country/* label when
# the scope or body references a known country service.
#
# Usage:
#   bash scripts/file_child_issue.sh <epic_number> <title> <body_file> [extra gh flags...]
#
# Positional arguments:
#   epic_number   GitHub issue number of the parent Epic (e.g. 2290)
#   title         Issue title in conventional-commit form (e.g. "feat(map): …")
#   body_file     Path to a file containing the issue body markdown
#
# Extra flags (optional):
#   Any additional flags are passed verbatim to `gh issue create`
#   (e.g. --assignee @me, --project "Tankstellen Dev").
#
# Label-derivation rules:
#   Conventional-commit prefix → type/* label:
#     fix(     → type/bug
#     feat(    → type/feature
#     refactor( → type/refactor
#     perf(    → type/perf
#     ci:, ci( → type/ci
#     chore    → type/chore
#     docs     → type/docs
#     test     → type/test
#   (Unrecognised prefix → no type/* label; a warning is printed)
#
#   Country scope → country/* label:
#     Extracted from the conventional-commit scope, e.g. feat(map/de) → country/de
#     OR when the body contains a known country-service keyword:
#       tankerkoenig → country/de
#       data.gouv    → country/fr
#       mase         → country/it
#       geoportal    → country/es
#       e-control    → country/at
#       fod economie → country/be
#       ilr          → country/lu
#       elecgas, cepp → country/pt
#       globalpetrolprices, fuelprice.com.au → country/au
#       gasprices    → country/mx
#       fuelspy, petrolspy → country/gb
#
# Graceful degradation:
#   If the Epic has no milestone, a warning is printed and the issue is created
#   without a milestone. If the Epic has no area/* label, a warning is printed
#   and the issue is created without an area label.
#
# Examples:
#   bash scripts/file_child_issue.sh 2290 "feat(map): cluster markers" body.md
#   bash scripts/file_child_issue.sh 2290 "fix(sync/de): token refresh" body.md --assignee @me

set -euo pipefail

# ── Helpers ────────────────────────────────────────────────────────────────────
die()  { echo "ERROR: $1" >&2; exit 1; }
warn() { echo "WARNING: $1" >&2; }
info() { echo "==> $1"; }

# ── Args ───────────────────────────────────────────────────────────────────────
[[ $# -lt 3 ]] && die "Usage: $0 <epic_number> <title> <body_file> [extra gh flags...]"

EPIC_NUM="$1"
TITLE="$2"
BODY_FILE="$3"
shift 3
EXTRA_FLAGS=("$@")

[[ "$EPIC_NUM" =~ ^[0-9]+$ ]] || die "epic_number must be a plain integer, got: $EPIC_NUM"
[[ -f "$BODY_FILE" ]]         || die "body_file not found: $BODY_FILE"

# ── Read Epic metadata ─────────────────────────────────────────────────────────
info "Fetching Epic #${EPIC_NUM} metadata…"
EPIC_JSON="$(gh issue view "$EPIC_NUM" --json milestone,labels 2>/dev/null)" \
  || die "Could not fetch Epic #${EPIC_NUM} — is the issue number correct?"

MILESTONE="$(echo "$EPIC_JSON" | python3 -c \
  'import json,sys; d=json.load(sys.stdin); m=d.get("milestone"); print(m["title"] if m else "")')"

AREA_LABEL="$(echo "$EPIC_JSON" | python3 -c \
  'import json,sys; d=json.load(sys.stdin); labels=[l["name"] for l in d.get("labels",[]) if l["name"].startswith("area/")]; print(labels[0] if labels else "")')"

if [[ -z "$MILESTONE" ]]; then
  warn "Epic #${EPIC_NUM} has no milestone — issue will be created without one."
fi
if [[ -z "$AREA_LABEL" ]]; then
  warn "Epic #${EPIC_NUM} has no area/* label — issue will be created without an area label."
fi

# ── Derive type/* from conventional-commit prefix ─────────────────────────────
TYPE_LABEL=""
case "$TITLE" in
  fix\(*)                   TYPE_LABEL="type/bug"      ;;
  feat\(*)                  TYPE_LABEL="type/feature"   ;;
  refactor\(*)              TYPE_LABEL="type/refactor"  ;;
  perf\(*)                  TYPE_LABEL="type/perf"      ;;
  ci:*|ci\(*)               TYPE_LABEL="type/ci"        ;;
  chore:*|chore\(*)         TYPE_LABEL="type/chore"     ;;
  docs:*|docs\(*)           TYPE_LABEL="type/docs"      ;;
  test:*|test\(*)           TYPE_LABEL="type/test"      ;;
  *)
    warn "Unrecognised conventional-commit prefix in title: \"$TITLE\" — no type/* label will be applied."
    ;;
esac

# ── Extract country from scope or body ────────────────────────────────────────
COUNTRY_LABEL=""

# 1. Try to extract from conventional-commit scope, e.g. feat(map/de) or fix(sync/es)
SCOPE="$(echo "$TITLE" | python3 -c \
  'import sys,re; m=re.match(r"[a-z]+\(([^)]+)\)", sys.stdin.read().strip()); print(m.group(1) if m else "")')"

COUNTRY_CODE="$(echo "$SCOPE" | python3 -c \
  'import sys; parts=sys.stdin.read().strip().split("/"); code=[p for p in parts if len(p)==2 and p.isalpha()]; print(code[-1].lower() if code else "")')"

if [[ -n "$COUNTRY_CODE" ]]; then
  # Verify the country/* label exists in the repo before applying
  COUNTRY_LABEL="country/${COUNTRY_CODE}"
  if ! gh label list --json name 2>/dev/null | python3 -c \
    "import json,sys; names=[l['name'] for l in json.load(sys.stdin)]; exit(0 if 'country/${COUNTRY_CODE}' in names else 1)" 2>/dev/null; then
    warn "Label country/${COUNTRY_CODE} does not exist in this repo — skipping country label from scope."
    COUNTRY_LABEL=""
  fi
fi

# 2. Fallback: scan body for known country-service keywords
if [[ -z "$COUNTRY_LABEL" && -f "$BODY_FILE" ]]; then
  BODY_LOWER="$(tr '[:upper:]' '[:lower:]' < "$BODY_FILE")"
  if   echo "$BODY_LOWER" | grep -q "tankerkoenig";              then COUNTRY_LABEL="country/de"
  elif echo "$BODY_LOWER" | grep -q "data\.gouv";                then COUNTRY_LABEL="country/fr"
  elif echo "$BODY_LOWER" | grep -q "miteco\|geoportal";         then COUNTRY_LABEL="country/es"
  elif echo "$BODY_LOWER" | grep -qE "mase[^r]|mise\.gov";       then COUNTRY_LABEL="country/it"
  elif echo "$BODY_LOWER" | grep -q "e-control\|econtrol";       then COUNTRY_LABEL="country/at"
  elif echo "$BODY_LOWER" | grep -q "fod economie\|fodenomie";   then COUNTRY_LABEL="country/be"
  elif echo "$BODY_LOWER" | grep -qE "\bilr\b";                   then COUNTRY_LABEL="country/lu"
  elif echo "$BODY_LOWER" | grep -q "elecgas\|cepp\|precos";     then COUNTRY_LABEL="country/pt"
  elif echo "$BODY_LOWER" | grep -q "fuelprice\.com\.au\|globalpetrolprices.*au"; then COUNTRY_LABEL="country/au"
  elif echo "$BODY_LOWER" | grep -q "gasprices.*mexico\|cre\.gob"; then COUNTRY_LABEL="country/mx"
  elif echo "$BODY_LOWER" | grep -q "fuelspy\|petrolspy\|gov\.uk.*fuel"; then COUNTRY_LABEL="country/gb"
  fi
fi

# ── Append "Part of #<epic>" to body ──────────────────────────────────────────
BODY_CONTENT="$(cat "$BODY_FILE")"
printf '%s\n\nPart of #%s\n' "$BODY_CONTENT" "$EPIC_NUM" > /tmp/file_child_issue_body_$$.md
trap 'rm -f /tmp/file_child_issue_body_$$.md' EXIT

# ── Build gh issue create command ────────────────────────────────────────────
CMD_LABELS=()
[[ -n "$AREA_LABEL"    ]] && CMD_LABELS+=("--label" "$AREA_LABEL")
[[ -n "$TYPE_LABEL"    ]] && CMD_LABELS+=("--label" "$TYPE_LABEL")
[[ -n "$COUNTRY_LABEL" ]] && CMD_LABELS+=("--label" "$COUNTRY_LABEL")

CMD_MILESTONE=()
[[ -n "$MILESTONE" ]] && CMD_MILESTONE+=("--milestone" "$MILESTONE")

info "Creating child issue of Epic #${EPIC_NUM}…"
info "  Title:     $TITLE"
info "  Type:      ${TYPE_LABEL:-<none>}"
info "  Area:      ${AREA_LABEL:-<none>}"
info "  Country:   ${COUNTRY_LABEL:-<none>}"
info "  Milestone: ${MILESTONE:-<none>}"

gh issue create \
  --title "$TITLE" \
  --body-file /tmp/file_child_issue_body_$$.md \
  "${CMD_LABELS[@]}" \
  "${CMD_MILESTONE[@]}" \
  "${EXTRA_FLAGS[@]}"
