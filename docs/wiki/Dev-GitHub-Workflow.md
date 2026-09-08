# GitHub Workflow

GitHub Flow (not Git Flow). `master` is always deployable. Work lives on short-lived branches that are PR'd and squash-merged.

## Branches

- **Branch off `master`** for every change.
- **Naming**: `feat/`, `fix/`, `refactor/`, `test/`, `docs/`, `chore/`, `ci/` — prefix matches conventional commit type.
- **One concern per branch** — don't mix a bug fix with a refactor.
- **Short-lived** — 1 to 3 days max. If you need longer, split the work.
- **Rebase on master before pushing**: `git fetch origin master && git rebase origin/master`

## Commits

### Conventional commit messages

```
feat(search): add route segment strategy selector
fix(ev): await toggle() in detail screens so star persists
refactor(storage): extract FavoritesHiveStore
test(consumption): cover EcoScoreCalculator edge cases
chore(deps): bump dio to 5.6.0
docs(wiki): reorganise user vs developer
ci(workflows): cache pub across jobs
```

- **Type**: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`, `ci`, `perf`, `style`
- **Scope** (optional but preferred): feature folder name or `area/*` label
- **Subject**: imperative mood, no trailing period, under 72 chars

### The body

- Focus on **why**, not **what** — the diff shows what changed.
- Wrap at 72 chars.
- Reference issues: `Refs #123` to link, `Closes #123` / `Fixes #123` to auto-close on PR merge.

### Split large changes

One logical change per commit. `git add -p` helps. For a feature that touches data, provider, UI — separate commits per layer makes review easier, even within the same PR.

## Pull Requests

Every change is a PR — even one-line fixes. No direct pushes to `master` (protected).

### Title

- Matches the conventional-commit format.
- Becomes the squash-merge commit message — choose it well.

### Body template

```markdown
## What
One sentence on the change.

## Why
The reason — user impact, bug consequence, or refactor motivation.

## Testing
- [x] Unit: cases A, B, C
- [x] Widget: X screen renders Y
- [x] Manual: installed on Pixel 7, confirmed Z

## Screenshots
(before / after for UI PRs)

Closes #NN
```

### Rules

- **Under 400 lines changed** (excluding generated files). Split if larger.
- **CI must pass.** `analyze` and `test` green before request-review.
- **Link an issue.** `Closes #NN` or `Fixes #NN` in the body. If no issue exists, consider opening one first — the `/backlog` skill can audit.
- **No review-amended force-pushes if discussion is ongoing.** Reviewers need to see the diff you responded to.

## Merging

- **Squash and merge only** (enforced in repo settings).
- Use `gh pr merge --squash --auto <num>` to arm auto-merge once CI is green — the standing pattern for keeping the merge cycle hands-off. Never use `--auto` on a stacked PR whose base is a feature branch: the auto-merge fires the moment the base is unprotected and balloons the parent PR.
- Auto-delete head branches is enabled.
- One commit per closed issue, even when bundled into a single PR — the PR title summarises the bundle, the individual commits preserve per-issue rationale forever.
- After merge: `git checkout master && git pull`.

## Releases

1. Update `CHANGELOG.md` as part of the release PR (don't do it after).
2. After the PR merges and CI passes on master, tag:
   ```bash
   git tag -a v5.0.0 -m "Release 5.0.0"
   git push origin v5.0.0
   ```
3. `release.yml` creates the GitHub Release with auto-generated notes and uploads the APK/AAB artefacts from the last master build.
4. Play Console upload is manual — see the build-release skill.

## Labels

Every issue and PR is labelled:

| Category | Labels | What it means |
|---|---|---|
| Type | `type/bug`, `type/feature`, `type/enhancement`, `type/refactor`, `type/test`, `type/docs`, `type/chore`, `type/ci` | Kind of work |
| Priority | `P0-critical`, `P1-high`, `P2-medium`, `P3-low` | Urgency |
| Area | `area/core`, `area/ui`, `area/api`, `area/sync`, `area/ci`, `area/maps`, `area/alerts`, `area/route`, `area/ev`, `area/obd2`, `area/consumption`, `area/predictions` | Which subsystem |
| Country | `country/de`, `country/fr`, `country/it`, `country/es`, `country/at`, `country/be`, `country/lu`, `country/pt`, `country/uk`, `country/ar`, `country/au`, `country/mx`, `country/dk` | Country-specific API |
| Effort | `effort/small` (< 2 h), `effort/medium` (2-8 h), `effort/large` (1+ days) | Size estimation |
| Status | `needs-triage`, `blocked` | Workflow state |

A PR typically inherits labels from the issue it closes.

## Milestones

- `v5.0.0` — Current release (public beta launch) — target: 2026-07
- `v5.1.0` — Post-beta iteration
- `v5.0.0-beta` — Beta launch, fresh public repo, production Play Store
- `Backlog` — Not yet scheduled

## Backlog → branch → ship workflow

The standing routine for any contribution:

1. **Pick a task** from the open-issue list. Sort by priority (`P0 > P1 > P2 > P3`) then effort (`effort/small > medium > large`); skip anything labelled `blocked`. `gh issue list --limit 200` is a fine starting point.
2. **Branch** named `<type>/<short-slug>-<issue-number>` (e.g. `feat/wait-time-pings-1119`).
3. **Implement.** Keep commits small and squashable; commit footers reference the issue with `Refs #<n>`.
4. **Check locally** — `flutter analyze` clean, `flutter test` green for the area you touched.
5. **Push + PR** — open the PR with `Closes #<n>` in the body so the merge auto-closes the issue.
6. **Review your own branch first** (`git diff master...HEAD`) before requesting review — easier to catch noise.
7. **Squash-merge** once CI is green.

## Forbidden

- **No direct commits to `master`.** Branch protection enforces it.
- **No force-push to `master`.** Disabled.
- **No `--no-verify`** on commits — bypasses hooks and signing. Don't.
- **No `git commit --amend` on pushed commits** — creates confusing review diffs. Use a fresh commit.
- **No `-i` rebase interactively** in automated workflows — interactive editors aren't supported in CI/scripts.

## Related

- [Creating Issues](Dev-Creating-Issues)
- [Contributing](Dev-Contributing)
- [CI / CD Pipeline](Dev-CI-CD-Pipeline)
