#!/usr/bin/env bash
# Dependency freshness and security advisory check for CI.
# - Runs flutter pub outdated and reports results
# - Checks for security advisories via dart pub outdated --json
# - Fails on known security vulnerabilities (advisories)
# - Warns (but doesn't fail) on outdated major versions
#
# Usage: bash scripts/pub_outdated_check.sh

set -uo pipefail

EXIT_CODE=0

echo "=== Dependency Freshness Report ==="
echo ""

# Run flutter pub outdated for human-readable output
echo "--- flutter pub outdated (non-dev) ---"
flutter pub outdated --no-dev-dependencies || true
echo ""

# Run dart pub outdated --json for machine-readable analysis
echo "--- Analyzing outdated packages ---"
JSON_OUTPUT=$(dart pub outdated --json --no-dev-dependencies 2>/dev/null || true)

if [ -z "$JSON_OUTPUT" ]; then
  echo "::warning::Could not get JSON output from dart pub outdated"
else
  # Count packages with major version lag (resolvable > current major)
  MAJOR_LAG=$(echo "$JSON_OUTPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    packages = data.get('packages', [])
    major_lag = []
    for pkg in packages:
        current = pkg.get('current', {}).get('version', '')
        latest = pkg.get('latest', {}).get('version', '')
        resolvable = pkg.get('resolvable', {}).get('version', '')
        if current and latest and current != latest:
            cur_major = current.split('.')[0] if current else '0'
            lat_major = latest.split('.')[0] if latest else '0'
            if cur_major != lat_major:
                major_lag.append(f'{pkg[\"package\"]}: {current} -> {latest}')
    if major_lag:
        print('Major version updates available:')
        for p in major_lag:
            print(f'  - {p}')
    else:
        print('No major version lag detected.')
except Exception as e:
    print(f'Parse error: {e}')
" 2>/dev/null || echo "Could not parse outdated JSON")

  echo "$MAJOR_LAG"
  echo ""

  # Check for advisories — packages flagged with security issues
  ADVISORIES=$(echo "$JSON_OUTPUT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    packages = data.get('packages', [])
    advisories = []
    for pkg in packages:
        # Check if package has advisories field
        pkg_advisories = pkg.get('advisories', [])
        if pkg_advisories:
            for adv in pkg_advisories:
                advisories.append(f'{pkg[\"package\"]}: {adv}')
        # Also check isDiscontinued
        if pkg.get('isDiscontinued', False):
            advisories.append(f'{pkg[\"package\"]}: DISCONTINUED')
    if advisories:
        print('SECURITY_ISSUES_FOUND')
        for a in advisories:
            print(f'  - {a}')
    else:
        print('NO_ISSUES')
except Exception as e:
    print(f'PARSE_ERROR: {e}')
" 2>/dev/null || echo "PARSE_ERROR")

  if echo "$ADVISORIES" | grep -q "SECURITY_ISSUES_FOUND"; then
    echo "::error::Security advisories found in dependencies:"
    echo "$ADVISORIES" | tail -n +2
    EXIT_CODE=1
  elif echo "$ADVISORIES" | grep -q "NO_ISSUES"; then
    echo "No security advisories found."
  else
    echo "::warning::Could not check for security advisories: $ADVISORIES"
  fi
fi

echo ""

# Check for deprecated/discontinued packages
echo "--- Checking for discontinued packages ---"
DISCONTINUED=$(dart pub outdated --json --no-dev-dependencies 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    disc = [p['package'] for p in data.get('packages', []) if p.get('isDiscontinued', False)]
    if disc:
        print('Discontinued packages found:')
        for d in disc:
            print(f'  - {d}')
    else:
        print('No discontinued packages.')
except Exception as e:
    print(f'Could not check: {e}')
" 2>/dev/null || echo "Could not check for discontinued packages")

echo "$DISCONTINUED"
if echo "$DISCONTINUED" | grep -q "Discontinued packages found"; then
  echo "::warning::Some dependencies are discontinued — consider migrating."
fi

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo "Dependency check passed."
else
  echo "Dependency check failed — security issues detected."
fi

exit $EXIT_CODE
