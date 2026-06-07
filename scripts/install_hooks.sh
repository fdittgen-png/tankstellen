#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT

# Installs the project pre-push hook into .git/hooks/pre-push.
#
# The hook enforces, locally and BEFORE the ~13-min CI round-trip, the two
# failure modes that have repeatedly slipped to CI (see #2339):
#   * stale generated code (`*.g.dart` / `*.freezed.dart`) — codegen drift
#     hit 4+ times in a single night session plus #2245;
#   * stale l10n fan-out (en+de-only ARB additions that never reached the
#     other locales) — tripped the #1699 coverage gate twice on 2026-05-29.
#
# Run once after cloning (and whenever this installer changes):
#   bash scripts/install_hooks.sh
#
# The hook is skippable for genuine emergencies with an explicit env var:
#   SKIP_PREPUSH=1 git push
#
# Re-running this installer is safe: it overwrites the managed hook in place.

set -euo pipefail

# Resolve the repo root from this script's location so the installer works
# from any CWD and inside linked worktrees (where .git is a file, not a dir).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$REPO_ROOT"

# `git rev-parse --git-path hooks` resolves the correct hooks dir even when
# core.hooksPath is overridden or we are inside a linked worktree.
HOOKS_DIR="$(git rev-parse --git-path hooks)"
mkdir -p "$HOOKS_DIR"
HOOK_PATH="$HOOKS_DIR/pre-push"

cat > "$HOOK_PATH" <<'HOOK'
#!/usr/bin/env bash
# Copyright (c) 2026 Florian DITTGEN
# SPDX-License-Identifier: MIT
#
# MANAGED HOOK — installed by scripts/install_hooks.sh. Do not edit by hand;
# edit the installer and re-run it instead.
#
# Pre-push gate. Runs the cheapest, highest-signal checks first so a failure
# surfaces fast. Emergency bypass (use sparingly, you own the CI red):
#   SKIP_PREPUSH=1 git push

set -uo pipefail

if [ "${SKIP_PREPUSH:-0}" = "1" ]; then
  echo "pre-push: SKIP_PREPUSH=1 set — skipping all local gates (CI still runs)."
  exit 0
fi

# Run from the top-level work tree so all relative paths resolve.
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# git invokes this hook with GIT_DIR / GIT_WORK_TREE / GIT_INDEX_FILE exported
# into the environment, and they leak into every child process — including
# `flutter`, whose version probe runs `git describe` against the SDK checkout.
# With GIT_DIR pointing at THIS repo (most visibly from a worktree push), that
# probe resolves against this repo instead of the SDK, so flutter reports its
# version as `0.0.0-unknown` and `flutter pub get` fails dependency solving —
# which aborted the whole gate and pushed everyone onto SKIP_PREPUSH (#3027).
# Unset them so flutter resolves its own SDK version; the git commands below
# rediscover the repo from $REPO_ROOT (cwd) just fine.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX

# Flutter/Dart are not on the default PATH in this environment.
export PATH="/Users/floriandittgen/development/flutter/bin:/opt/homebrew/bin:$PATH"

if ! command -v flutter >/dev/null 2>&1; then
  echo "pre-push ERROR: flutter not found on PATH." >&2
  echo "  Fix PATH or bypass once with: SKIP_PREPUSH=1 git push" >&2
  exit 1
fi

fail() {
  echo "" >&2
  echo "pre-push BLOCKED: $1" >&2
  echo "  $2" >&2
  echo "  Emergency bypass (you own the CI red): SKIP_PREPUSH=1 git push" >&2
  exit 1
}

echo "pre-push: running local gates (bypass with SKIP_PREPUSH=1)..."

# --- 1. Clean codegen (HARD RULE #3) -------------------------------------
# Clean, not incremental: incremental builds keep stale hashes that CI's
# clean run catches (see feedback_codegen_drift_local_gate memory).
#
# Route every pub/build_runner invocation through the FLUTTER toolchain
# (#2651). This project is Flutter-SDK-pinned, so a bare `dart pub`/`dart
# run` cannot resolve Flutter-pinned transitive deps (e.g.
# url_launcher_platform_interface — it errors with "Flutter users should
# use `flutter pub`"). That bare-dart failure made step 1 always abort in
# worktrees, so everyone bypassed the whole gate with SKIP_PREPUSH=1 and
# the local codegen/l10n drift gate never ran. Resolve deps with
# `flutter pub get` first, then drive build_runner via `flutter pub run`.
echo "pre-push [1/5]: regenerating code (build_runner clean && build)..."
if ! flutter pub get; then
  fail "flutter pub get failed" \
       "Run 'flutter pub get' and read the error."
fi
if ! flutter pub run build_runner clean >/dev/null 2>&1; then
  fail "build_runner clean failed" \
       "Run 'flutter pub run build_runner clean' and read the error."
fi
if ! flutter pub run build_runner build --delete-conflicting-outputs; then
  fail "build_runner build failed" \
       "Run 'flutter pub run build_runner build --delete-conflicting-outputs' and fix the error."
fi

# --- 2. No codegen drift -------------------------------------------------
echo "pre-push [2/5]: checking for stale generated files..."
if ! git diff --exit-code -- '*.g.dart' '*.freezed.dart'; then
  fail "stale generated code (*.g.dart / *.freezed.dart)" \
       "Regeneration changed committed files. Stage the drift and amend/commit: git add -- '*.g.dart' '*.freezed.dart'"
fi

# --- 3. No l10n fan-out drift (HARD RULE #4) -----------------------------
# Every new en key must fan out to all locales via the autofill pipeline.
echo "pre-push [3/5]: regenerating l10n and checking for drift..."
# Route through `flutter pub run` for the same Flutter-pinned-deps reason
# as step 1 (#2651): a bare `dart run` can't resolve this project's
# Flutter-pinned package config and aborts the gate.
if ! flutter pub run tool/build_arb.dart; then
  fail "tool/build_arb.dart failed" "Run 'flutter pub run tool/build_arb.dart' and fix the error."
fi
if ! flutter pub run tool/gen_pseudo_arb.dart; then
  fail "tool/gen_pseudo_arb.dart failed" "Run 'flutter pub run tool/gen_pseudo_arb.dart' and fix the error."
fi
if ! flutter gen-l10n; then
  fail "flutter gen-l10n failed" "Run 'flutter gen-l10n' and fix the error."
fi
if ! git diff --exit-code -- lib/l10n/; then
  fail "stale l10n fan-out (lib/l10n/)" \
       "New en keys did not reach every locale (or pseudo-locale). Run the l10n pipeline, then: git add -- lib/l10n/"
fi

# --- 4. Static analysis --------------------------------------------------
echo "pre-push [4/5]: flutter analyze..."
if ! flutter analyze; then
  fail "flutter analyze reported issues" "Fix the analyzer output above."
fi

# --- 5. Lint + l10n contract tests (cheap, network-free) -----------------
echo "pre-push [5/5]: lint + l10n tests..."
if ! flutter test test/lint/ test/l10n/ --exclude-tags=network; then
  fail "lint / l10n tests failed" "Fix the failing tests above."
fi

echo "pre-push: all local gates passed."
exit 0
HOOK

chmod +x "$HOOK_PATH"

echo "Installed pre-push hook: $HOOK_PATH"
echo "It runs: clean-codegen -> codegen-drift -> l10n fan-out -> analyze -> lint/l10n tests."
echo "Emergency bypass: SKIP_PREPUSH=1 git push"
