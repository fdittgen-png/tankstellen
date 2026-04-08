#!/usr/bin/env bash
# test_deploy.sh — Validate deploy scripts and workflow YAML syntax.
#
# Usage:
#   bash scripts/test_deploy.sh
#
# Tests:
#   1. deploy_play_store.sh --dry-run argument parsing and validation
#   2. promote_play_store.sh environment variable validation
#   3. deploy.yml workflow YAML syntax validation
#   4. Script file permissions and shebangs

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Deploy Script Tests ==="
echo ""

# --- Test 1: deploy_play_store.sh exists and has correct shebang ---
echo "Test 1: deploy_play_store.sh file structure"
if [[ -f "$SCRIPT_DIR/deploy_play_store.sh" ]]; then
  pass "deploy_play_store.sh exists"
else
  fail "deploy_play_store.sh not found"
fi

if head -1 "$SCRIPT_DIR/deploy_play_store.sh" | grep -q '#!/usr/bin/env bash'; then
  pass "deploy_play_store.sh has correct shebang"
else
  fail "deploy_play_store.sh missing shebang"
fi

# --- Test 2: deploy_play_store.sh rejects missing AAB argument ---
echo ""
echo "Test 2: deploy_play_store.sh argument validation"
OUTPUT=$(bash "$SCRIPT_DIR/deploy_play_store.sh" 2>&1 || true)
if echo "$OUTPUT" | grep -qi "usage\|error"; then
  pass "Rejects missing AAB argument"
else
  fail "Should reject missing AAB argument"
fi

# --- Test 3: deploy_play_store.sh rejects non-existent file ---
echo ""
echo "Test 3: deploy_play_store.sh file validation"
OUTPUT=$(bash "$SCRIPT_DIR/deploy_play_store.sh" "/nonexistent/fake.aab" 2>&1 || true)
if echo "$OUTPUT" | grep -qi "not found\|error"; then
  pass "Rejects non-existent AAB file"
else
  fail "Should reject non-existent AAB file"
fi

# --- Test 4: deploy_play_store.sh rejects non-AAB file ---
echo ""
echo "Test 4: deploy_play_store.sh file extension validation"
TEMP_APK=$(mktemp --suffix=.apk)
trap 'rm -f "$TEMP_APK"' EXIT
OUTPUT=$(bash "$SCRIPT_DIR/deploy_play_store.sh" "$TEMP_APK" 2>&1 || true)
if echo "$OUTPUT" | grep -qi "\.aab\|error"; then
  pass "Rejects non-AAB file extension"
else
  fail "Should reject non-AAB file extension"
fi

# --- Test 5: deploy_play_store.sh rejects invalid track ---
echo ""
echo "Test 5: deploy_play_store.sh track validation"
TEMP_AAB=$(mktemp --suffix=.aab)
trap 'rm -f "$TEMP_AAB" "$TEMP_APK"' EXIT
OUTPUT=$(bash "$SCRIPT_DIR/deploy_play_store.sh" "$TEMP_AAB" --track bogus 2>&1 || true)
if echo "$OUTPUT" | grep -qi "invalid track\|error"; then
  pass "Rejects invalid track name"
else
  fail "Should reject invalid track name"
fi

# --- Test 6: promote_play_store.sh rejects missing env vars ---
echo ""
echo "Test 6: promote_play_store.sh environment validation"
OUTPUT=$(PLAY_STORE_SERVICE_ACCOUNT_JSON="" PACKAGE_NAME="" TRACK_FROM="" ROLLOUT_PERCENTAGE="" \
  bash "$SCRIPT_DIR/promote_play_store.sh" 2>&1 || true)
if echo "$OUTPUT" | grep -qi "not set\|error"; then
  pass "Rejects missing environment variables"
else
  fail "Should reject missing environment variables"
fi

# --- Test 7: promote_play_store.sh rejects invalid percentage ---
echo ""
echo "Test 7: promote_play_store.sh percentage validation"
OUTPUT=$(PLAY_STORE_SERVICE_ACCOUNT_JSON='{}' PACKAGE_NAME="test" TRACK_FROM="internal" \
  ROLLOUT_PERCENTAGE="150" bash "$SCRIPT_DIR/promote_play_store.sh" 2>&1 || true)
if echo "$OUTPUT" | grep -qi "between 1 and 100\|error"; then
  pass "Rejects invalid rollout percentage"
else
  fail "Should reject invalid rollout percentage"
fi

# --- Test 8: promote_play_store.sh rejects invalid track ---
echo ""
echo "Test 8: promote_play_store.sh track validation"
OUTPUT=$(PLAY_STORE_SERVICE_ACCOUNT_JSON='{}' PACKAGE_NAME="test" TRACK_FROM="gamma" \
  ROLLOUT_PERCENTAGE="5" bash "$SCRIPT_DIR/promote_play_store.sh" 2>&1 || true)
if echo "$OUTPUT" | grep -qi "must be internal\|error"; then
  pass "Rejects invalid source track"
else
  fail "Should reject invalid source track"
fi

# --- Test 9: deploy.yml exists and has valid YAML structure ---
echo ""
echo "Test 9: deploy.yml workflow validation"
WORKFLOW="$PROJECT_ROOT/.github/workflows/deploy.yml"
if [[ -f "$WORKFLOW" ]]; then
  pass "deploy.yml exists"
else
  fail "deploy.yml not found"
fi

# Check required top-level keys
if grep -q '^name:' "$WORKFLOW"; then
  pass "deploy.yml has 'name' key"
else
  fail "deploy.yml missing 'name' key"
fi

if grep -q '^on:' "$WORKFLOW"; then
  pass "deploy.yml has 'on' trigger key"
else
  fail "deploy.yml missing 'on' trigger key"
fi

if grep -q '^jobs:' "$WORKFLOW"; then
  pass "deploy.yml has 'jobs' key"
else
  fail "deploy.yml missing 'jobs' key"
fi

# Check for version tag trigger
if grep -q "tags:.*v\*\|tags:$" "$WORKFLOW"; then
  pass "deploy.yml triggers on version tags"
else
  fail "deploy.yml should trigger on version tags"
fi

# Check for workflow_dispatch
if grep -q 'workflow_dispatch' "$WORKFLOW"; then
  pass "deploy.yml supports manual dispatch"
else
  fail "deploy.yml should support workflow_dispatch"
fi

# Check for service account secret reference
if grep -q 'PLAY_STORE_SERVICE_ACCOUNT_JSON' "$WORKFLOW"; then
  pass "deploy.yml references service account secret"
else
  fail "deploy.yml should reference PLAY_STORE_SERVICE_ACCOUNT_JSON"
fi

# Check that no secrets are hardcoded
if grep -qE '(private_key|client_email.*iam)' "$WORKFLOW"; then
  fail "deploy.yml contains hardcoded credentials!"
else
  pass "deploy.yml has no hardcoded credentials"
fi

# --- Test 10: All deploy scripts are executable-ready (have shebang) ---
echo ""
echo "Test 10: Script shebangs"
for script in deploy_play_store.sh promote_play_store.sh; do
  if head -1 "$SCRIPT_DIR/$script" | grep -q '#!/usr/bin/env bash'; then
    pass "$script has bash shebang"
  else
    fail "$script missing bash shebang"
  fi
done

# --- Summary ---
echo ""
echo "==========================="
echo "Results: $PASS passed, $FAIL failed"
echo "==========================="

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
