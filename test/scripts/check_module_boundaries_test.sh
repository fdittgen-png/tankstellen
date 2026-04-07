#!/usr/bin/env bash
# Tests for scripts/check_module_boundaries.sh
# Run: bash test/scripts/check_module_boundaries_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT="$PROJECT_ROOT/scripts/check_module_boundaries.sh"
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

assert_output_not_contains() {
  local test_name="$1"
  local expected="$2"
  local output="$3"
  if echo "$output" | grep -q "$expected"; then
    echo "  FAIL: $test_name (output should NOT contain '$expected')"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $test_name"
    PASS=$((PASS + 1))
  fi
}

# Helper: create a clean feature structure with no violations
create_clean_features() {
  local dir="$1"
  mkdir -p "$dir/lib/features/search/data"
  mkdir -p "$dir/lib/features/search/domain"
  mkdir -p "$dir/lib/features/favorites/data"
  mkdir -p "$dir/lib/features/favorites/presentation"

  cat > "$dir/lib/features/search/data/search_service.dart" << 'DART'
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/features/search/domain/search_result.dart';
import 'package:flutter/material.dart';
DART

  cat > "$dir/lib/features/search/domain/search_result.dart" << 'DART'
class SearchResult {}
DART

  cat > "$dir/lib/features/favorites/data/favorites_repo.dart" << 'DART'
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/favorites/presentation/favorites_screen.dart';
DART

  cat > "$dir/lib/features/favorites/presentation/favorites_screen.dart" << 'DART'
import 'package:flutter/material.dart';
DART
}

# Helper: create features with cross-feature violations
create_violating_features() {
  local dir="$1"
  create_clean_features "$dir"

  # Add a cross-feature import: favorites importing from search
  cat > "$dir/lib/features/favorites/data/favorites_repo.dart" << 'DART'
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/features/search/domain/search_result.dart';
DART
}

# Helper: create features with multiple violations
create_multiple_violations() {
  local dir="$1"
  create_violating_features "$dir"

  mkdir -p "$dir/lib/features/sync/data"
  cat > "$dir/lib/features/sync/data/sync_service.dart" << 'DART'
import 'package:tankstellen/features/search/domain/search_result.dart';
import 'package:tankstellen/features/favorites/data/favorites_repo.dart';
DART
}

echo "=== check_module_boundaries.sh tests ==="
echo ""

# Test 1: Clean features pass
echo "Test 1: Clean features with no cross-imports pass"
TEST_DIR="$TEMP_DIR/test1"
create_clean_features "$TEST_DIR"
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" 2>&1)
EXIT=$?
assert_exit_code "exits with 0" 0 "$EXIT"
assert_output_contains "shows passed" "Module boundary check passed" "$OUTPUT"
assert_output_contains "shows feature count" "Scanned 2 features" "$OUTPUT"

# Test 2: Cross-feature import detected
echo "Test 2: Cross-feature import detected"
TEST_DIR="$TEMP_DIR/test2"
create_violating_features "$TEST_DIR"
EXIT=0
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" 2>&1) || EXIT=$?
assert_exit_code "exits with error" 1 "$EXIT"
assert_output_contains "shows violation count" "1 cross-feature import violation" "$OUTPUT"
assert_output_contains "shows violating file" "favorites/data/favorites_repo.dart" "$OUTPUT"
assert_output_contains "shows imported feature" "features/search/" "$OUTPUT"

# Test 3: Multiple violations reported
echo "Test 3: Multiple violations reported"
TEST_DIR="$TEMP_DIR/test3"
create_multiple_violations "$TEST_DIR"
EXIT=0
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" 2>&1) || EXIT=$?
assert_exit_code "exits with error" 1 "$EXIT"
assert_output_contains "shows violation count" "3 cross-feature import violation" "$OUTPUT"

# Test 4: Generated files are skipped
echo "Test 4: Generated files (.g.dart, .freezed.dart) are skipped"
TEST_DIR="$TEMP_DIR/test4"
create_clean_features "$TEST_DIR"

# Add violation only in generated files
cat > "$TEST_DIR/lib/features/favorites/data/model.g.dart" << 'DART'
import 'package:tankstellen/features/search/domain/search_result.dart';
DART
cat > "$TEST_DIR/lib/features/favorites/data/model.freezed.dart" << 'DART'
import 'package:tankstellen/features/search/domain/search_result.dart';
DART

OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" 2>&1)
EXIT=$?
assert_exit_code "passes ignoring generated files" 0 "$EXIT"

# Test 5: Allowlist suppresses violations
echo "Test 5: Allowlist suppresses violations"
TEST_DIR="$TEMP_DIR/test5"
create_violating_features "$TEST_DIR"
mkdir -p "$TEST_DIR/scripts"
cat > "$TEST_DIR/scripts/module_boundary_allowlist.txt" << 'ALLOW'
# Allow favorites to import search until refactored
lib/features/favorites/data/favorites_repo.dart:search
ALLOW

OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" 2>&1)
EXIT=$?
assert_exit_code "passes with allowlist" 0 "$EXIT"
assert_output_contains "shows passed" "Module boundary check passed" "$OUTPUT"

# Test 6: Missing features directory
echo "Test 6: Missing features directory"
TEST_DIR="$TEMP_DIR/test6"
mkdir -p "$TEST_DIR"
EXIT=0
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" 2>&1) || EXIT=$?
assert_exit_code "exits with error" 1 "$EXIT"
assert_output_contains "shows error" "Features directory not found" "$OUTPUT"

# Test 7: Unknown argument
echo "Test 7: Unknown argument"
TEST_DIR="$TEMP_DIR/test7"
create_clean_features "$TEST_DIR"
EXIT=0
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" --unknown 2>&1) || EXIT=$?
assert_exit_code "exits with error" 1 "$EXIT"
assert_output_contains "shows usage" "Usage:" "$OUTPUT"

# Test 8: Custom allowlist path
echo "Test 8: Custom allowlist path"
TEST_DIR="$TEMP_DIR/test8"
create_violating_features "$TEST_DIR"
mkdir -p "$TEST_DIR/config"
cat > "$TEST_DIR/config/my_allowlist.txt" << 'ALLOW'
lib/features/favorites/data/favorites_repo.dart:search
ALLOW

OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" --allow-file config/my_allowlist.txt 2>&1)
EXIT=$?
assert_exit_code "passes with custom allowlist" 0 "$EXIT"

# Test 9: Self-imports are not flagged
echo "Test 9: Self-imports within same feature are allowed"
TEST_DIR="$TEMP_DIR/test9"
create_clean_features "$TEST_DIR"
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" 2>&1)
EXIT=$?
assert_exit_code "self-imports pass" 0 "$EXIT"

# Test 10: Guidance message on failure
echo "Test 10: Guidance message on failure"
TEST_DIR="$TEMP_DIR/test10"
create_violating_features "$TEST_DIR"
EXIT=0
OUTPUT=$(cd "$TEST_DIR" && bash "$SCRIPT" 2>&1) || EXIT=$?
assert_output_contains "suggests lib/core/" "Move shared types to lib/core/" "$OUTPUT"
assert_output_contains "mentions allowlist" "allowlist" "$OUTPUT"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
