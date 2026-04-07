#!/usr/bin/env bash
# Tests for scripts/check_coverage.sh
# Run: bash test/scripts/check_coverage_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT="$PROJECT_ROOT/scripts/check_coverage.sh"
TEMP_DIR=$(mktemp -d)
PASS=0
FAIL=0

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

assert_exit_code() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"
  if [ "$actual" -eq "$expected" ]; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name (expected exit $expected, got $actual)"
    FAIL=$((FAIL + 1))
  fi
}

assert_output_contains() {
  local test_name="$1"
  local expected="$2"
  local output="$3"
  if echo "$output" | grep -q "$expected"; then
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $test_name (expected output to contain '$expected')"
    FAIL=$((FAIL + 1))
  fi
}

# Create a sample lcov.info with 60% coverage (3/5 lines hit)
create_lcov() {
  local dir="$1"
  mkdir -p "$dir/coverage"
  cat > "$dir/coverage/lcov.info" << 'LCOV'
SF:lib/core/app.dart
DA:1,1
DA:2,1
DA:3,1
DA:4,0
DA:5,0
end_of_record
LCOV
}

# Create lcov with generated files that should be excluded
create_lcov_with_generated() {
  local dir="$1"
  mkdir -p "$dir/coverage"
  cat > "$dir/coverage/lcov.info" << 'LCOV'
SF:lib/core/app.dart
DA:1,1
DA:2,1
DA:3,0
DA:4,0
end_of_record
SF:lib/models/station.g.dart
DA:1,0
DA:2,0
DA:3,0
DA:4,0
DA:5,0
end_of_record
SF:lib/models/station.freezed.dart
DA:1,0
DA:2,0
end_of_record
SF:lib/l10n/app_localizations_de.dart
DA:1,0
DA:2,0
end_of_record
LCOV
}

echo "=== check_coverage.sh tests ==="
echo ""

# Test 1: Missing lcov file
echo "Test 1: Missing lcov file should fail"
TEST_DIR="$TEMP_DIR/test1"
mkdir -p "$TEST_DIR"
EXIT=0
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" 2>&1) || EXIT=$?
assert_exit_code "exits with error" 1 "$EXIT"
assert_output_contains "shows error message" "Coverage file not found" "$OUTPUT"

# Test 2: Coverage above threshold passes
echo "Test 2: Coverage above threshold passes"
TEST_DIR="$TEMP_DIR/test2"
mkdir -p "$TEST_DIR"
create_lcov "$TEST_DIR"
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" --threshold 50 2>&1)
EXIT=$?
assert_exit_code "exits with 0" 0 "$EXIT"
assert_output_contains "shows coverage percentage" "Coverage: 60%" "$OUTPUT"
assert_output_contains "shows passed message" "Coverage check passed" "$OUTPUT"

# Test 3: Coverage below threshold fails
echo "Test 3: Coverage below threshold fails"
TEST_DIR="$TEMP_DIR/test3"
mkdir -p "$TEST_DIR"
create_lcov "$TEST_DIR"
EXIT=0
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" --threshold 70 2>&1) || EXIT=$?
assert_exit_code "exits with error" 1 "$EXIT"
assert_output_contains "shows threshold error" "below 70% threshold" "$OUTPUT"

# Test 4: Generated files are excluded from coverage calculation
echo "Test 4: Generated files excluded from calculation"
TEST_DIR="$TEMP_DIR/test4"
mkdir -p "$TEST_DIR"
create_lcov_with_generated "$TEST_DIR"
# app.dart has 2/4 hit = 50%, generated files would drag it down if included
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" --threshold 50 2>&1)
EXIT=$?
assert_exit_code "passes when generated files excluded" 0 "$EXIT"
assert_output_contains "coverage is 50%" "Coverage: 50%" "$OUTPUT"

# Test 5: Custom lcov path
echo "Test 5: Custom lcov path"
TEST_DIR="$TEMP_DIR/test5"
mkdir -p "$TEST_DIR/custom"
create_lcov "$TEST_DIR"
mv "$TEST_DIR/coverage/lcov.info" "$TEST_DIR/custom/my_coverage.info"
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" --lcov custom/my_coverage.info --threshold 50 2>&1)
EXIT=$?
assert_exit_code "accepts custom path" 0 "$EXIT"

# Test 6: Invalid threshold
echo "Test 6: Invalid threshold"
TEST_DIR="$TEMP_DIR/test6"
mkdir -p "$TEST_DIR"
create_lcov "$TEST_DIR"
EXIT=0
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" --threshold abc 2>&1) || EXIT=$?
assert_exit_code "exits with error" 1 "$EXIT"
assert_output_contains "shows error" "Threshold must be a positive integer" "$OUTPUT"

# Test 7: Default threshold is 45%
echo "Test 7: Default threshold is 45%"
TEST_DIR="$TEMP_DIR/test7"
mkdir -p "$TEST_DIR"
create_lcov "$TEST_DIR"
# 60% coverage is above default 45%
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" 2>&1)
EXIT=$?
assert_exit_code "passes with default threshold" 0 "$EXIT"
assert_output_contains "shows 45% threshold" "Threshold: 45%" "$OUTPUT"

# Test 8: Unknown argument
echo "Test 8: Unknown argument"
TEST_DIR="$TEMP_DIR/test8"
mkdir -p "$TEST_DIR"
EXIT=0
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" --unknown 2>&1) || EXIT=$?
assert_exit_code "exits with error" 1 "$EXIT"
assert_output_contains "shows usage" "Usage:" "$OUTPUT"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
