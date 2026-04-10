#!/usr/bin/env bash
# Feature-module boundary enforcement for CI and local use.
# Detects cross-feature imports in lib/features/ and fails if any are found.
#
# Each feature module should only import from:
#   - Its own directory (lib/features/<self>/)
#   - Core shared code (lib/core/)
#   - External packages
#   - Dart/Flutter SDK
#
# Usage: bash scripts/check_module_boundaries.sh [--allow-file PATH]
#   --allow-file PATH   Path to allowlist file (default: scripts/module_boundary_allowlist.txt)
#
# Allowlist format (one per line):
#   lib/features/sync/data/sync_service.dart:lib/features/search/domain/station.dart
# Lines starting with # are comments. Blank lines are ignored.

set -uo pipefail

FEATURES_DIR="lib/features"
ALLOW_FILE="scripts/module_boundary_allowlist.txt"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --allow-file)
      ALLOW_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: bash scripts/check_module_boundaries.sh [--allow-file PATH]"
      exit 1
      ;;
  esac
done

if [ ! -d "$FEATURES_DIR" ]; then
  echo "::error::Features directory not found: $FEATURES_DIR"
  exit 1
fi

# Load allowlist entries into an associative array
declare -A ALLOWED
if [ -f "$ALLOW_FILE" ]; then
  while IFS= read -r line; do
    # Skip comments and blank lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line// }" ]] && continue
    ALLOWED["$line"]=1
  done < "$ALLOW_FILE"
fi

VIOLATIONS=0
VIOLATION_LINES=""

# Get list of feature names
FEATURE_NAMES=()
for feature_dir in "$FEATURES_DIR"/*/; do
  [ -d "$feature_dir" ] || continue
  FEATURE_NAMES+=("$(basename "$feature_dir")")
done

if [ ${#FEATURE_NAMES[@]} -eq 0 ]; then
  echo "No feature directories found in $FEATURES_DIR"
  exit 0
fi

# Scan each feature directory for cross-feature imports
for feature in "${FEATURE_NAMES[@]}"; do
  feature_path="$FEATURES_DIR/$feature"

  # Find all Dart files in this feature (excluding generated files)
  while IFS= read -r dart_file; do
    [ -f "$dart_file" ] || continue

    # Skip generated files
    [[ "$dart_file" == *.g.dart ]] && continue
    [[ "$dart_file" == *.freezed.dart ]] && continue

    # Search for imports of other features
    while IFS= read -r import_line; do
      [ -z "$import_line" ] && continue

      # Extract the imported feature name from the import path
      # Pattern: import 'package:tankstellen/features/<other_feature>/...
      imported_feature=$(echo "$import_line" | sed -n "s/.*features\/\([^/]*\)\/.*/\1/p")

      [ -z "$imported_feature" ] && continue
      [ "$imported_feature" = "$feature" ] && continue

      # Check allowlist
      allowlist_key="$dart_file:$imported_feature"
      if [[ -n "${ALLOWED[$allowlist_key]+_}" ]]; then
        continue
      fi

      VIOLATIONS=$((VIOLATIONS + 1))
      msg="  $dart_file imports from features/$imported_feature/"
      VIOLATION_LINES="${VIOLATION_LINES}${msg}\n"
    done < <(grep -n "import 'package:tankstellen/features/" "$dart_file" 2>/dev/null | grep -v "features/$feature/" || true)

  done < <(find "$feature_path" -name "*.dart" -type f 2>/dev/null)
done

# -----------------------------------------------------------------------------
# Presentation -> data layer leak check
#
# Presentation code must depend only on `domain/` (entities, use cases) and
# providers. Importing `data/models/`, `data/repositories/`, or `data/dto/`
# directly from a presentation file re-creates the tight coupling that issue
# #56 eliminated.
# -----------------------------------------------------------------------------
PRESENTATION_VIOLATIONS=0
PRESENTATION_VIOLATION_LINES=""

while IFS= read -r dart_file; do
  [ -f "$dart_file" ] || continue
  [[ "$dart_file" == *.g.dart ]] && continue
  [[ "$dart_file" == *.freezed.dart ]] && continue

  # Match both relative imports (`../../data/models/foo.dart`,
  # `../../../feature/data/repositories/bar.dart`) and absolute package
  # imports (`package:tankstellen/features/<name>/data/models/foo.dart`).
  while IFS= read -r import_line; do
    [ -z "$import_line" ] && continue
    PRESENTATION_VIOLATIONS=$((PRESENTATION_VIOLATIONS + 1))
    msg="  $dart_file: $import_line"
    PRESENTATION_VIOLATION_LINES="${PRESENTATION_VIOLATION_LINES}${msg}\n"
  done < <(grep -nE "^import .*(data/models|data/repositories|data/dto)/" "$dart_file" 2>/dev/null || true)
done < <(find "$FEATURES_DIR" -type f -name "*.dart" -path "*/presentation/*" 2>/dev/null)

if [ "$PRESENTATION_VIOLATIONS" -gt 0 ]; then
  echo "::error::Found $PRESENTATION_VIOLATIONS presentation -> data layer import(s):"
  echo ""
  echo -e "$PRESENTATION_VIOLATION_LINES"
  echo ""
  echo "Presentation code must only depend on domain entities (domain/entities/)."
  echo "Move or re-export the type via lib/features/<feature>/domain/entities/"
  echo "and import the domain path from the widget / screen."
  VIOLATIONS=$((VIOLATIONS + PRESENTATION_VIOLATIONS))
fi

if [ "$VIOLATIONS" -gt 0 ]; then
  echo "::error::Found $VIOLATIONS cross-feature import violation(s):"
  echo ""
  echo -e "$VIOLATION_LINES"
  echo ""
  echo "Feature modules must not import from other feature modules."
  echo "Move shared types to lib/core/ or use dependency injection via providers."
  echo ""
  echo "To temporarily allow a violation, add an entry to $ALLOW_FILE:"
  echo "  <source_file>:<imported_feature_name>"
  exit 1
fi

echo "Module boundary check passed. Scanned ${#FEATURE_NAMES[@]} features, no cross-feature imports found."
