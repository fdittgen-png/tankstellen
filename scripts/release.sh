#!/usr/bin/env bash
# release.sh — Bump version, generate changelog entry, commit, tag, and push.
#
# Usage:
#   bash scripts/release.sh 4.3.1
#   bash scripts/release.sh 4.3.1 --dry-run
#
# The script:
#   1. Validates the version argument (semver format)
#   2. Bumps version in pubspec.yaml (increments build number)
#   3. Generates a changelog entry from conventional commits since last tag
#   4. Commits the version bump + changelog
#   5. Creates an annotated tag
#   6. Pushes branch + tag to trigger CI release
#
# Flags:
#   --dry-run    Show what would happen without making changes

set -euo pipefail

# --- Configuration ---
PUBSPEC="pubspec.yaml"
CHANGELOG="CHANGELOG.md"

# --- Helpers ---
die() { echo "ERROR: $1" >&2; exit 1; }
info() { echo "==> $1"; }

# --- Parse arguments ---
VERSION=""
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    -*)        die "Unknown flag: $arg" ;;
    *)         VERSION="$arg" ;;
  esac
done

# --- Validate version ---
if [[ -z "$VERSION" ]]; then
  die "Usage: bash scripts/release.sh <version> [--dry-run]
  Example: bash scripts/release.sh 4.3.1"
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  die "Invalid version format: '$VERSION'. Expected semver (e.g., 4.3.1)"
fi

# --- Check prerequisites ---
if ! [[ -f "$PUBSPEC" ]]; then
  die "pubspec.yaml not found. Run this script from the project root."
fi

if ! git diff --quiet && [[ "$DRY_RUN" == "false" ]]; then
  die "Working directory has uncommitted changes. Commit or stash first."
fi

if ! git diff --cached --quiet && [[ "$DRY_RUN" == "false" ]]; then
  die "Staging area has uncommitted changes. Commit or stash first."
fi

# --- Check tag doesn't already exist ---
if git rev-parse "v$VERSION" >/dev/null 2>&1; then
  die "Tag v$VERSION already exists. Choose a different version."
fi

# --- Extract current version info ---
CURRENT_LINE=$(grep -E '^version:' "$PUBSPEC")
if [[ -z "$CURRENT_LINE" ]]; then
  die "Could not find 'version:' line in $PUBSPEC"
fi

# Extract current build number and increment
CURRENT_BUILD=$(echo "$CURRENT_LINE" | sed -E 's/.*\+([0-9]+)/\1/')
if [[ -z "$CURRENT_BUILD" ]] || ! [[ "$CURRENT_BUILD" =~ ^[0-9]+$ ]]; then
  CURRENT_BUILD=0
fi
NEW_BUILD=$((CURRENT_BUILD + 1))
NEW_VERSION_LINE="version: $VERSION+$NEW_BUILD"

info "Version: $VERSION+$NEW_BUILD (was: $CURRENT_LINE)"

# --- Determine last tag for changelog ---
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [[ -n "$LAST_TAG" ]]; then
  COMMIT_RANGE="$LAST_TAG..HEAD"
  info "Generating changelog from $LAST_TAG to HEAD"
else
  COMMIT_RANGE="HEAD"
  info "No previous tag found — including all commits"
fi

# --- Generate changelog entry from conventional commits ---
generate_changelog() {
  local range="$1"
  local features="" fixes="" refactors="" chores="" others=""

  while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue
    # Skip merge commits
    [[ "$line" =~ ^Merge ]] && continue

    if [[ "$line" =~ ^feat ]]; then
      local msg="${line#feat:}"
      msg="${msg#feat(*)}"
      msg="${msg#: }"
      msg="$(echo "$msg" | sed 's/^[[:space:]]*//')"
      features+="- $msg"$'\n'
    elif [[ "$line" =~ ^fix ]]; then
      local msg="${line#fix:}"
      msg="${msg#fix(*)}"
      msg="${msg#: }"
      msg="$(echo "$msg" | sed 's/^[[:space:]]*//')"
      fixes+="- $msg"$'\n'
    elif [[ "$line" =~ ^refactor ]]; then
      local msg="${line#refactor:}"
      msg="${msg#refactor(*)}"
      msg="${msg#: }"
      msg="$(echo "$msg" | sed 's/^[[:space:]]*//')"
      refactors+="- $msg"$'\n'
    elif [[ "$line" =~ ^(chore|ci|docs|test|build) ]]; then
      local msg="$line"
      msg="$(echo "$msg" | sed 's/^[a-z]*(\?[^)]*)\?: //')"
      msg="$(echo "$msg" | sed 's/^[[:space:]]*//')"
      chores+="- $msg"$'\n'
    else
      others+="- $line"$'\n'
    fi
  done < <(git log --pretty=format:"%s" "$range" 2>/dev/null)

  local entry=""
  entry+="## [$VERSION] - $(date +%Y-%m-%d) (Build $NEW_BUILD)"$'\n'
  entry+=""$'\n'

  if [[ -n "$features" ]]; then
    entry+="### Added"$'\n'$'\n'
    entry+="$features"$'\n'
  fi

  if [[ -n "$fixes" ]]; then
    entry+="### Fixed"$'\n'$'\n'
    entry+="$fixes"$'\n'
  fi

  if [[ -n "$refactors" ]]; then
    entry+="### Changed"$'\n'$'\n'
    entry+="$refactors"$'\n'
  fi

  if [[ -n "$chores" ]]; then
    entry+="### Maintenance"$'\n'$'\n'
    entry+="$chores"$'\n'
  fi

  if [[ -n "$others" ]]; then
    entry+="### Other"$'\n'$'\n'
    entry+="$others"$'\n'
  fi

  # If no conventional commits found, add a placeholder
  if [[ -z "$features" && -z "$fixes" && -z "$refactors" && -z "$chores" && -z "$others" ]]; then
    entry+="*No conventional commits since last release.*"$'\n'$'\n'
  fi

  echo "$entry"
}

CHANGELOG_ENTRY=$(generate_changelog "$COMMIT_RANGE")

# --- Dry run: just show what would happen ---
if [[ "$DRY_RUN" == "true" ]]; then
  info "[DRY RUN] Would update $PUBSPEC:"
  echo "  $CURRENT_LINE  ->  $NEW_VERSION_LINE"
  echo ""
  info "[DRY RUN] Would prepend to $CHANGELOG:"
  echo "$CHANGELOG_ENTRY"
  echo ""
  info "[DRY RUN] Would commit: 'chore: release v$VERSION'"
  info "[DRY RUN] Would tag: v$VERSION"
  info "[DRY RUN] Would push branch + tag"
  exit 0
fi

# --- Apply changes ---

# 1. Bump pubspec.yaml version
info "Bumping $PUBSPEC to $NEW_VERSION_LINE"
sed -i "s/^version:.*/$NEW_VERSION_LINE/" "$PUBSPEC"

# 2. Update CHANGELOG.md
info "Updating $CHANGELOG"
if [[ -f "$CHANGELOG" ]]; then
  # Insert new entry after the header lines (line 1-2)
  TEMP_FILE=$(mktemp)
  {
    head -2 "$CHANGELOG"
    echo ""
    echo "$CHANGELOG_ENTRY"
    echo "---"
    echo ""
    tail -n +3 "$CHANGELOG"
  } > "$TEMP_FILE"
  mv "$TEMP_FILE" "$CHANGELOG"
else
  {
    echo "# Changelog"
    echo ""
    echo "All notable changes to this project will be documented in this file."
    echo "Format based on [Keep a Changelog](https://keepachangelog.com/)."
    echo ""
    echo "$CHANGELOG_ENTRY"
  } > "$CHANGELOG"
fi

# 3. Commit
info "Committing version bump"
git add "$PUBSPEC" "$CHANGELOG"
git commit -m "chore: release v$VERSION"

# 4. Tag
info "Creating tag v$VERSION"
git tag -a "v$VERSION" -m "Release $VERSION"

# 5. Push
info "Pushing branch and tag"
BRANCH=$(git branch --show-current)
git push origin "$BRANCH" --follow-tags

info "Done! Release v$VERSION tagged and pushed."
info "CI will build artifacts and create the GitHub Release."
echo ""
echo "Track the release: https://github.com/$(git remote get-url origin | sed 's|.*github.com[:/]||;s|\.git$||')/actions"
