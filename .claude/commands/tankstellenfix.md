Autonomous issue-fix loop for the Tankstellen project. Resolves GitHub issues one by one until all are done or context runs out.

## Loop protocol (MANDATORY — every dev, every time)

For each issue:

### 1. Pick the best next issue
- Run `gh issue list --state open --limit 100 --json number,title,labels`
- Pick the highest-priority, lowest-risk issue that isn't blocked
- Prefer issues that can be mutualized (e.g., fix multiple related issues in one PR if they touch the same files)
- Skip #9 (iOS — deferred)

### 2. Analyze
- Read the issue description
- Read all files mentioned
- Identify ALL files that need changes
- Check if the fix overlaps with other open issues — if so, bundle them

### 3. Implement
- `git checkout master && git pull`
- `git checkout -b <type>/<issue-number>-<short-name>`
- Make changes following CLAUDE.md conventions
- Write tests for every change (no exceptions)
- Run `flutter analyze --no-fatal-infos` — must be zero warnings/errors
- Run `flutter test` — must pass

### 4. Ship
- `git add -A && git commit` with conventional commit message + `Closes #N`
- `git push -u origin <branch>`
- `gh pr create` with summary, test plan, `Closes #N`
- `gh pr checks --watch` — wait for ALL CI checks to pass
- `gh pr merge --squash --delete-branch`
- `git checkout master && git pull`

### 5. Validate
- Verify issue is closed on GitHub
- Run `flutter analyze` + `flutter test` on master to confirm clean state

### 6. Compact & loop
- Call /compact to free context
- Immediately start the next issue (step 1)

## Rules
- **One concern per branch** — don't mix unrelated fixes
- **Always write tests** — no exceptions
- **Never commit directly to master** — always PR
- **Never skip CI** — wait for all checks green before merge
- **Bundle related issues** — if fixing #134 touches the same files as #135, do both in one PR
- **Close issues that are already fixed** — investigate before coding
- **Stop gracefully** — if context is running low, save state to memory and stop

## Mutualization strategy
Before starting a new issue, scan the backlog for related work:
- Same file? Bundle.
- Same abstraction? Do the abstraction first, then the consumers.
- Dependency chain? Do prerequisites first (e.g., #136 StorageRepository before #69 split HiveStorage).
