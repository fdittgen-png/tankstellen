#!/usr/bin/env bash
# Tests for scripts/release.sh
#
# Run: bash test/scripts/release_script_test.sh
#
# Creates a temporary git repo, exercises the release script, and verifies
# that pubspec.yaml, CHANGELOG.md, commits, and tags are created correctly.

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RELEASE_SCRIPT="$PROJECT_ROOT/scripts/release.sh"
ORIG_DIR="$(pwd)"
TEMP_DIR=""
BARE=""

# --- Helpers ---
setup_temp_repo() {
  TEMP_DIR=$(mktemp -d)
  cd "$TEMP_DIR"
  git init -q
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create a minimal pubspec.yaml
  printf 'name: tankstellen\ndescription: "Test project"\npublish_to: '"'"'none'"'"'\nversion: 4.3.0+4020\n\nenvironment:\n  sdk: ^3.11.3\n' > pubspec.yaml

  # Create CHANGELOG.md
  printf '# Changelog\n\nAll notable changes to this project will be documented in this file.\nFormat based on [Keep a Changelog](https://keepachangelog.com/).\n' > CHANGELOG.md

  # Copy the release script
  mkdir -p scripts
  cp "$RELEASE_SCRIPT" scripts/release.sh

  # Initial commit
  git add -A
  git commit -q -m "feat: initial commit"
}

cleanup() {
  cd "$ORIG_DIR"
  if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
  if [[ -n "${BARE:-}" && -d "$BARE" ]]; then
    rm -rf "$BARE"
  fi
  TEMP_DIR=""
  BARE=""
}

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $desc"
    echo "    Expected: $expected"
    echo "    Actual:   $actual"
    FAIL=$((FAIL+1))
  fi
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF "$needle"; then
    echo "  PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $desc"
    echo "    Expected to contain: $needle"
    echo "    Actual: $haystack"
    FAIL=$((FAIL+1))
  fi
}

assert_not_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if ! echo "$haystack" | grep -qF "$needle"; then
    echo "  PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $desc"
    echo "    Expected NOT to contain: $needle"
    FAIL=$((FAIL+1))
  fi
}

assert_exit_code() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $desc (exit code $actual, expected $expected)"
    FAIL=$((FAIL+1))
  fi
}

# --- Tests ---

echo "=== Release Script Tests ==="
echo ""

# Test 1: Missing version argument
echo "Test 1: Rejects missing version argument"
setup_temp_repo
OUTPUT=$(bash scripts/release.sh 2>&1 || true)
EXIT=$?
assert_contains "shows usage message" "Usage:" "$OUTPUT"
cleanup

# Test 2: Invalid version format
echo "Test 2: Rejects invalid version format"
setup_temp_repo
OUTPUT=$(bash scripts/release.sh "abc" 2>&1 || true)
assert_contains "shows invalid format error" "Invalid version format" "$OUTPUT"

OUTPUT=$(bash scripts/release.sh "4.3" 2>&1 || true)
assert_contains "rejects two-part version" "Invalid version format" "$OUTPUT"

OUTPUT=$(bash scripts/release.sh "4.3.1.2" 2>&1 || true)
assert_contains "rejects four-part version" "Invalid version format" "$OUTPUT"
cleanup

# Test 3: Dry run doesn't change files
echo "Test 3: Dry run makes no changes"
setup_temp_repo
BEFORE=$(cat pubspec.yaml)
bash scripts/release.sh 4.4.0 --dry-run >/dev/null 2>&1
AFTER=$(cat pubspec.yaml)
assert_eq "pubspec unchanged after dry-run" "$BEFORE" "$AFTER"

TAG_COUNT=$(git tag -l 'v*' | wc -l | tr -d ' ')
assert_eq "no tags created in dry-run" "0" "$TAG_COUNT"
cleanup

# Test 4: Dry run shows correct output
echo "Test 4: Dry run output contains expected info"
setup_temp_repo
OUTPUT=$(bash scripts/release.sh 5.0.0 --dry-run 2>&1)
assert_contains "shows version bump" "5.0.0+4021" "$OUTPUT"
assert_contains "shows commit message" "chore: release v5.0.0" "$OUTPUT"
assert_contains "shows tag name" "v5.0.0" "$OUTPUT"
assert_contains "shows DRY RUN label" "DRY RUN" "$OUTPUT"
cleanup

# Test 5: Version bump in pubspec.yaml
echo "Test 5: Bumps version in pubspec.yaml correctly"
setup_temp_repo
# We need a remote for push — create a bare repo
BARE=$(mktemp -d)
git clone -q --bare "$TEMP_DIR" "$BARE"
git remote remove origin 2>/dev/null || true
git remote add origin "$BARE"

bash scripts/release.sh 4.4.0 2>&1 >/dev/null
VERSION_LINE=$(grep '^version:' pubspec.yaml)
assert_eq "pubspec version bumped" "version: 4.4.0+4021" "$VERSION_LINE"
cleanup

# Test 6: Build number increments
echo "Test 6: Build number increments from current"
setup_temp_repo
BARE=$(mktemp -d)
git clone -q --bare "$TEMP_DIR" "$BARE"
git remote remove origin 2>/dev/null || true
git remote add origin "$BARE"

# Modify build number to a known value
sed -i 's/version: 4.3.0+4020/version: 4.3.0+100/' pubspec.yaml
git add pubspec.yaml
git commit -q -m "chore: set build to 100"

bash scripts/release.sh 4.4.0 2>&1 >/dev/null
VERSION_LINE=$(grep '^version:' pubspec.yaml)
assert_eq "build number incremented from 100" "version: 4.4.0+101" "$VERSION_LINE"
cleanup

# Test 7: Tag created
echo "Test 7: Creates annotated git tag"
setup_temp_repo
BARE=$(mktemp -d)
git clone -q --bare "$TEMP_DIR" "$BARE"
git remote remove origin 2>/dev/null || true
git remote add origin "$BARE"

bash scripts/release.sh 4.4.0 2>&1 >/dev/null
TAG_EXISTS=$(git tag -l 'v4.4.0')
assert_eq "tag v4.4.0 exists" "v4.4.0" "$TAG_EXISTS"

TAG_TYPE=$(git cat-file -t v4.4.0)
assert_eq "tag is annotated" "tag" "$TAG_TYPE"
cleanup

# Test 8: Duplicate tag rejected
echo "Test 8: Rejects duplicate tag"
setup_temp_repo
git tag -a "v4.4.0" -m "Existing tag"
OUTPUT=$(bash scripts/release.sh 4.4.0 2>&1 || true)
assert_contains "rejects duplicate" "already exists" "$OUTPUT"
cleanup

# Test 9: CHANGELOG.md updated
echo "Test 9: Updates CHANGELOG.md with new entry"
setup_temp_repo
BARE=$(mktemp -d)
git clone -q --bare "$TEMP_DIR" "$BARE"
git remote remove origin 2>/dev/null || true
git remote add origin "$BARE"

# Add some conventional commits
git commit -q --allow-empty -m "feat: add dark mode support"
git commit -q --allow-empty -m "fix: resolve crash on startup"

bash scripts/release.sh 4.4.0 2>&1 >/dev/null
CHANGELOG_CONTENT=$(cat CHANGELOG.md)
assert_contains "changelog has version header" "[4.4.0]" "$CHANGELOG_CONTENT"
assert_contains "changelog has Added section" "### Added" "$CHANGELOG_CONTENT"
assert_contains "changelog has Fixed section" "### Fixed" "$CHANGELOG_CONTENT"
assert_contains "changelog has feat entry" "dark mode" "$CHANGELOG_CONTENT"
assert_contains "changelog has fix entry" "crash on startup" "$CHANGELOG_CONTENT"
cleanup

# Test 10: Commit message is correct
echo "Test 10: Creates correct commit message"
setup_temp_repo
BARE=$(mktemp -d)
git clone -q --bare "$TEMP_DIR" "$BARE"
git remote remove origin 2>/dev/null || true
git remote add origin "$BARE"

bash scripts/release.sh 4.4.0 2>&1 >/dev/null
LAST_COMMIT=$(git log -1 --pretty=format:"%s")
assert_eq "commit message" "chore: release v4.4.0" "$LAST_COMMIT"
cleanup

# Test 11: Uncommitted changes rejected
echo "Test 11: Rejects uncommitted changes"
setup_temp_repo
echo "dirty" >> pubspec.yaml
OUTPUT=$(bash scripts/release.sh 4.4.0 2>&1 || true)
assert_contains "rejects dirty tree" "uncommitted changes" "$OUTPUT"
cleanup

# Test 12: Staged changes rejected
echo "Test 12: Rejects staged changes"
setup_temp_repo
echo "dirty" >> pubspec.yaml
git add pubspec.yaml
OUTPUT=$(bash scripts/release.sh 4.4.0 2>&1 || true)
assert_contains "rejects staged changes" "uncommitted changes" "$OUTPUT"
cleanup

# Test 13: Changelog entry for non-conventional commits
echo "Test 13: Handles non-conventional commits"
setup_temp_repo
BARE=$(mktemp -d)
git clone -q --bare "$TEMP_DIR" "$BARE"
git remote remove origin 2>/dev/null || true
git remote add origin "$BARE"

git commit -q --allow-empty -m "random commit without prefix"
bash scripts/release.sh 4.4.0 2>&1 >/dev/null
CHANGELOG_CONTENT=$(cat CHANGELOG.md)
assert_contains "has Other section" "### Other" "$CHANGELOG_CONTENT"
cleanup

# Test 14: Unknown flag rejected
echo "Test 14: Rejects unknown flags"
setup_temp_repo
OUTPUT=$(bash scripts/release.sh --invalid 2>&1 || true)
assert_contains "rejects unknown flag" "Unknown flag" "$OUTPUT"
cleanup

# --- Summary ---
echo ""
echo "=== Results ==="
TOTAL=$((PASS + FAIL))
echo "$PASS/$TOTAL passed"
if [[ $FAIL -gt 0 ]]; then
  echo "$FAIL FAILED"
  exit 1
else
  echo "All tests passed!"
  exit 0
fi
