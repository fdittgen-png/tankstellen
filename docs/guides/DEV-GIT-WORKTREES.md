# Git Worktrees — Dev Setup

This project uses **git worktrees** to keep a clean `master` checkout available while feature work is in flight. The persistent worktree lets you run release builds, pull upstream, check issue state, and apply hotfixes without stashing or blocking the feature branch's `build/` + `.dart_tool/`.

Also: `Agent(isolation: "worktree")` creates transient per-agent worktrees under `.claude/worktrees/` — covered at the bottom.

## Honest expectations (read before setting up)

Measured over a ~20-iteration autonomous-loop session, the persistent master worktree saves roughly **one CI cycle's worth** (10–15 min) in aggregate — about **5–10 % productivity uplift on average**, concentrated in the few moments release-builds or hotfixes actually happen.

**Where worktrees don't help:**

- **CI wait between iterations.** Same 12–14 min whether you have 1 worktree or 10. Not a worktree problem.
- **Implementation speed.** Zero change — you still type into the same editor.
- **Local `flutter build` / `flutter test`.** The feature checkout owns its own `build/` and `.dart_tool/`. Running tests in the master worktree doesn't speed up tests in the feature checkout.
- **Parallel PRs.** `#807+#808` and `#810+#817` shipped simultaneously in this repo off a single checkout — non-conflicting files branch fine without worktrees.

**Where the bigger multiplier actually lives:**

- **Skip `build-android` on doc-only PRs.** A single workflow gate on `paths-ignore: ['docs/**', '*.md']` saves ~12 min per doc PR. That's a bigger win than worktrees.
- **Tighter test caching.** `flutter test` spends ~4 min on setup; faster pub resolution / test-shard caching could cut 2–3 min per CI run. Applies to *every* PR.

**What worktrees genuinely win at:**

- **Correctness insurance.** Fewer "oh I had uncommitted changes on the wrong branch" moments. Release builds can't accidentally pollute a feature branch.
- **`Agent(isolation: "worktree")` pattern** (bottom of this doc). More valuable long-term than the persistent master one — it makes multi-agent workflows safe when several speculative agents run in parallel.

Set this up because you want the *hygiene*, not because you expect raw speed. It's a seatbelt, not a nitrous injection.

## Setup (one-time)

From the main repo root:

```bash
git worktree add ../tankstellen-master master
```

After this, the layout is:

```
C:\working\dittgen\
├── tankstellen\             # main feature checkout — your active branch lives here
└── tankstellen-master\      # persistent worktree pinned to master — always clean
```

The `.git` directory is shared; only the working tree is duplicated. Disk cost: ~5 GB once Flutter + Gradle artefacts build in the second checkout.

## How to use it

### Pull `master` without leaving your feature branch

```bash
git -C ../tankstellen-master pull --ff-only
```

Your current checkout stays on the feature branch. `origin/master` gets updated via `git fetch` as usual, but the local `master` branch (owned by the worktree) advances cleanly.

### Branch off the latest `master` from inside the main checkout

```bash
git fetch origin
git checkout -b fix/some-issue origin/master
```

**Do not** `git checkout master` in the main checkout — master is owned by the other worktree. You'll see:

> fatal: 'master' is already used by worktree at 'C:/working/dittgen/tankstellen-master'

That's the worktree working correctly; branch off `origin/master` instead.

### Release builds in parallel

```bash
cd ../tankstellen-master
flutter build apk --release
# build/ + .dart_tool/ live in this worktree, not in your feature checkout
```

Your feature checkout keeps its own `.dart_tool/`; `flutter run` there is unaffected.

### Hotfix flow

```bash
# in the master worktree
cd ../tankstellen-master
git checkout -b fix/p0-prod-crash
# edit, commit, push, PR, merge
git checkout master
git pull --ff-only
```

No stash needed on the feature branch.

## Agent(isolation: "worktree") — transient per-agent worktrees

Claude Code's `Agent` tool supports `isolation: "worktree"`. When set, the agent gets its own temporary worktree under `.claude/worktrees/agent-<hash>` so speculative writes can't contaminate the parent checkout. The runtime auto-cleans worktrees where the agent made no changes.

When to pass `isolation: "worktree"`:

- Agent will **write or edit** code speculatively (exploratory refactor, research build).
- Multiple agents may run in parallel and touch overlapping files.

When *not* to:

- Read-only Explore agents (they don't write — isolation is pure overhead).
- Short tool-use-only agents.

## Cleaning stale agent worktrees

`git worktree list` may show dozens of entries under `.claude/worktrees/` from prior Claude sessions. Old ones whose branches have been merged or abandoned are cruft. To sweep:

```bash
git worktree prune         # remove worktrees whose directory is gone
# OR for specific entries:
git worktree remove .claude/worktrees/agent-<hash>
```

Check `git worktree list` after to confirm.

## Gotchas

- **Gradle cache is shared globally** (`~/.gradle/caches`). Worktrees don't isolate it. See `feedback_gradle_cache.md` in the per-user memory — stale-cache symptoms show up faster with worktrees because more varied builds run through the same cache.
- **`flutter pub get` runs per worktree.** One-time ~2-minute cost per branch switch in the second checkout.
- **Android emulator sees one `applicationId`.** Installing side-by-side from two worktrees overwrites. Not worth working around.
- **Don't `git worktree remove ../tankstellen-master`** accidentally when trying to prune. It's the persistent one, not an agent worktree.
