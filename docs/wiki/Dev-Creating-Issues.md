# Creating Issues

Every feature, bug, and chore should be an issue before work starts. Issues are the project's single source of truth for backlog, planning, and retrospectives.

## Templates

`.github/ISSUE_TEMPLATE/` provides three structured templates:

### 🐛 Bug Report

- **Expected behaviour**
- **Actual behaviour**
- **Steps to reproduce** — numbered, minimal
- **Screenshots** (if UI)
- **Device / app version** (use the app's *Settings → About → Copy diagnostics* button)
- **Relevant error trace** (from *Settings → Diagnostics → Export*)

Automatically labeled `type/bug`, `needs-triage`.

### ✨ Feature Request

- **Problem** — what friction does the user feel?
- **Proposal** — your suggested solution
- **Alternatives** — what else could work?
- **Which lens?** — *Pay less at the pump* or *burn less behind the wheel*? Both? Neither? (If neither, discuss the leitmotiv first — see the project conventions doc.)
- **Platform** — Android / iOS / both

Automatically labeled `type/feature`, `needs-triage`.

### 🌍 New Country API

- **Country code** (ISO 3166)
- **Official data source URL**
- **API requires key?** — if yes, the URL to obtain one
- **Rate limit** (if documented)
- **Supported fuel types**
- **Sample response** — paste 1-2 stations

Automatically labeled `type/feature`, `area/api`, `country/??`, `needs-triage`.

## Writing a good issue

### Title

- 50–70 characters.
- Conventional-commit-like prefix helps: `fix: ..`, `feat: ..`.
- Be specific — *"Map is slow"* is useless; *"Map tile load blocks first paint on slow 3G"* is actionable.

### Description

- Start with the symptom or user goal.
- One paragraph of context.
- Bullet points for details.
- Link to related issues / PRs.
- Reproducible steps only — no essay.

### Labels

Add them upfront if you know them:

- **Type** (mandatory) — bug / feature / enhancement / refactor / test / docs / chore
- **Priority** — `P0-critical` only for "users can't use the app"; `P1-high` for "frequent and annoying"; `P2-medium` for "worth fixing"; `P3-low` for nice-to-have
- **Area** — pick one that best describes the affected subsystem
- **Country** — if it's country-specific (API issue, locale string)
- **Effort** — be honest — `small` < 2 h, `medium` 2-8 h, `large` 1+ days

### Milestone

Assign to the target release milestone if you know it. Otherwise leave blank for triage.

## Triage

Unreviewed issues sit in `needs-triage`. During triage (daily or weekly depending on volume):

1. **Verify reproducibility** for bugs. Close as *not-reproducible* with a polite ask for more info if needed.
2. **Assess priority** honestly.
3. **Apply area + effort labels.**
4. **Assign milestone** or leave for backlog.
5. **Remove `needs-triage`.**

Duplicates get closed and linked to the canonical issue. Out-of-scope requests (contrary to the leitmotiv) get a polite explanation and `wontfix`.

## Backlog discipline

Treat the open-issue list as a prioritised queue:

- If an issue is `P3-low` and hasn't moved in 6 months, consider closing with `wontfix` — "a small nice-to-have that no one picked up is the clearest signal it isn't important".
- If an issue is `P0`/`P1` and hasn't moved in a month, it either isn't really P0/P1 or we have a process problem.
- If an issue has >3 emoji reactions from distinct users but low priority label, bump priority.

## Backlog operations

Common tasks against the open-issue list:

- **Full backlog** — `gh issue list --limit 200 --json number,title,labels,milestone,updatedAt`
- **Pick next task** — sort the backlog by priority label (`P0 > P1 > P2 > P3`) then effort label (`effort/small > medium > large`); top of the list is the next task. Filter out anything labelled `blocked`.
- **Start work** — open a branch named `<type>/<short-slug>-<issue-number>` (e.g. `feat/wait-time-pings-1119`), include `Refs #<issue>` in commit footers, and `Closes #<issue>` in the PR body.
- **Ship** — run `flutter analyze` + `flutter test`, push the branch, open the PR with the closing keyword in the body, then update the GitHub Project board column manually if needed.

See the project conventions doc (`docs/CONVENTIONS.md` if it exists, otherwise this wiki's `Dev-GitHub-Workflow` page) for the full specification.

## Linking commits and PRs

- **Commit** that partially addresses an issue: `Refs #123` in the footer.
- **PR** that fully closes an issue: `Closes #123` or `Fixes #123` in the PR body (not the commit — the title/body of the PR is what GitHub parses). Squash-merge preserves this.

Auto-close is configured for `closes / fixes / resolves` keywords (case-insensitive), all three verbs work.

## Don'ts

- Don't file three issues for one theme — bundle and link.
- Don't open PRs without an issue — even tiny fixes benefit from the audit trail and the `closes #` link.
- Don't use the issue as the discussion forum for *everything* — use GitHub Discussions for questions that aren't actionable work.
- Don't label `P0-critical` unless users genuinely can't use the app; it's a forcing function for all-hands focus, not "I think this is important".

## Related

- [GitHub Workflow](Dev-GitHub-Workflow)
- [Contributing](Dev-Contributing)
