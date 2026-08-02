**23 · Collaboration**

# GitHub craft

> Page 18 covers the machinery — workflows, required checks, branch protection. This page covers the writing: issues someone can act on, commits that still explain themselves in two years, pull requests that get reviewed rather than rubber-stamped, and the three surfaces (README, wiki, project board) that most repositories get wrong in the same three ways.

**Chunk prefix** craft **Updated** 2026-08-01 **Depends on** 18 GitHub CI · 02 Specification · 05 Traceability

#### On this page

1. [Writing an issue](#issues)
1. [Labels, milestones and triage](#labels)
1. [GitHub Projects](#projects)
1. [Branches](#branches)
1. [Commit messages](#commits)
1. [Pull requests](#prs)
1. [Reviewing](#review)
1. [Merge strategy](#merge)
1. [Running and debugging CI](#ci-run)
1. [The README](#readme)
1. [The wiki](#wiki)
1. [Releases and release notes](#releases)
1. [The repository's own metadata](#meta)

<!-- chunk: craft.issues | tags: issues,writing,process -->

## Writing an issue

An issue exists so that someone other than you, at some later date, can act on it without asking you anything. Everything below follows from that.

| Element | Rule | Bad → good |
| --- | --- | --- |
| **Title** | State the *problem or outcome*, not the area. Readable in a list of 200. | "Map issues" → "Map renders grey tiles after panning quickly" |
| **First line** | One sentence a stranger understands. No context needed. | "See Slack" → "Tiles fail to load and are never retried once they scroll off-screen." |
| **Reproduction** | Numbered steps, actual result, expected result. Include the build number. | "Doesn't work on my phone" → steps 1–4 plus "6.0.4+5137, Android 14, Pixel 6" |
| **Evidence** | Screenshot, log excerpt, trace export. Redact secrets. | — |
| **Scope** | What is explicitly *not* in scope. Prevents the fix ballooning. | — |
| **Acceptance** | How you will know it is done. For a bug: the test that would have caught it. | "Fix the map" → "A test asserts a failed tile is re-requested after leaving and re-entering the viewport." |

> **[RULE]**

> **Require the app version and build number in the bug template.** It is the single highest-yield field. A large share of "still broken" reports are a stale build from a testing channel, and without the number you cannot tell — you will debug a fixed bug. Put the version on an about screen where a user can copy it, and make the field required.

> **[RULE]**

> **Never develop without an issue.** Every change traces to one. This is not bureaucracy — it is the first link of the chain in [page 05](05-traceability.html#chain), and a commit with no issue is a change whose motivation is unrecoverable in six months. If the work is genuinely trivial, the issue is one line and takes twenty seconds.

### Templates worth having

Use the form-based template format (a YAML file per template in the issue-template directory) rather than free-form markdown — you get required fields, dropdowns and checkboxes, which is what makes the rules above enforceable rather than aspirational.

| Template | Required | Why it exists |
| --- | --- | --- |
| **Bug** | What happened · steps · **version + build** · platform | The default. Optional prompts for screenshots, locale, role. |
| **Feature** | Problem · proposal · **a checkbox group for the product's goals** | Turns [the feature filter](02-specification-driven-development.html#leitmotiv) into a workflow step. State plainly: a feature serving none of these will be pushed back on. |
| **Epic** | Goal in user terms + spec link · dependency-ordered children · risks · **a validation-gate checkbox** | Children may only be filed after the breakdown is validated |
| **Recurring domain task** | Whatever that task needs | If you add a country, a provider or a device profile repeatedly, make it a form. It turns tribal knowledge into a checklist. |

```yaml
# .github/ISSUE_TEMPLATE/bug_report.yml
name: Bug report
description: Something behaves incorrectly
labels: [bug]
body:
  - type: textarea
    id: what
    attributes: { label: What happened?, description: One sentence, then detail. }
    validations: { required: true }
  - type: textarea
    id: steps
    attributes:
      label: Steps to reproduce
      value: |
        1.
        2.
        3.
        Actual:
        Expected:
    validations: { required: true }
  - type: input
    id: version
    attributes:
      label: App version and build number
      description: Settings → About. Copy it exactly.
      placeholder: "6.0.4+5137"
    validations: { required: true }      # ← the highest-yield field
  - type: dropdown
    id: platform
    attributes: { label: Platform, options: [Android, iOS, macOS, Windows, Web] }
    validations: { required: true }
```

### Epics

Work larger than one pull request, or touching more than one subsystem, becomes an epic — and the breakdown is validated *before* any child is filed. Filing twelve children from an unvalidated breakdown produces twelve issues that all need re-scoping plus the social cost of closing them.

> **[RULE]**

> **Close the epic after every child has merged, not while they are in flight.** A premature close pollutes the open-issue list if any child is reverted, and it removes the tracking surface exactly when you still need it.

> **[TRAP]**

> **Symptom: an issue sits open for weeks and nobody realises it is waiting on *you*.** When work is parked pending a decision, an untouched open issue is indistinguishable from an unstarted one. Make the state explicit: a `needs-decision` label, a comment naming exactly what is being asked, and a **proposed default** so the answer can be "yes, do that". One project had a parked issue read as "still open" until the user had to ask why the count was not dropping.

<!-- chunk: craft.labels | tags: labels,triage,milestones -->

## Labels, milestones and triage

Keep the label set small enough to hold in your head. Three axes is usually enough, and a fourth is usually someone's abandoned experiment.

| Axis | Values | Who sets it |
| --- | --- | --- |
| **Type** | `bug` · `enhancement` · `epic` · `docs` · `chore` | The template, automatically |
| **Area** | `backend` · `l10n` · `ci` · `android` · `ios` — one per subsystem you actually route by | Triage |
| **State** | `needs-decision` · `blocked` · `good-first-issue` | Triage |

> **[WHY]**

> Priority labels rot faster than anything else in a tracker: everything becomes high, nothing is ever demoted, and the label stops carrying information within a quarter. If you need ordering, use a **milestone** (what ships next) or a project-board field with a single-select you actively groom. If you do use priority labels, put a recurring calendar entry on re-grooming them, or do not bother.

**Milestones** answer "what is in the next release" and nothing else. Keep a small fixed set — one project uses five iteration milestones as its roadmap — and give every new issue project + milestone + status at triage time, so the board is never lying about scope.

### A triage pass

1. **Reproducible?** If not, ask exactly one question and label it as awaiting information. Close it after a stated period with a friendly note inviting a reopen.
1. **Duplicate?** Close with a link. Never leave two live threads for one problem.
1. **Actionable?** If the acceptance criterion is unclear, write one — or ask the reporter for the outcome they wanted.
1. **Size?** One pull request, or an epic? See [page 02](02-specification-driven-development.html#epics).
1. **Assign an area label and a milestone,** or explicitly the backlog.

> **[RULE]**

> **Close stale issues, kindly and with a reason.** An issue nobody will act on is noise that hides the ones you will. "Closing as we are not planning to do this; comment to reopen if it is still affecting you" is honest and reversible. A tracker with 400 open issues nobody reads is worse than one with 40 that are all live.

<!-- chunk: craft.projects | tags: github-projects,planning,board -->

## GitHub Projects

A project board is a *view* over issues, not a second source of truth. The moment work exists on the board and not in an issue, the board has become a place where information goes to be forgotten.

| Element | Guidance |
| --- | --- |
| **Scope** | One project per repository (or per product across repositories). Not one per epic — epics are issues. |
| **Fields** | Fewer than you think. *Status* (single-select), *Iteration* or milestone, and at most one sizing field. Every extra field is one more thing that goes stale. |
| **Status values** | `Backlog` → `Ready` → `In progress` → `In review` → `Done`. Five is enough; the distinction between "ready" and "backlog" is the one that earns its keep. |
| **Views** | A board grouped by status for daily work; a table grouped by milestone for planning; a filtered view of `needs-decision` for the maintainer. |
| **Automation** | The built-in workflows: item added → Backlog; pull request opened → In review; issue closed → Done. Turn these on; they are what stops the board drifting. |
| **Draft items** | Useful for a five-minute thought. Convert to a real issue the moment anyone might work on it — a draft is invisible outside the board. |

> **[RULE]**

> **Every new issue gets added to the project, given a status and a milestone at triage.** An issue that exists only in the tracker is invisible on the board, and an issue on the board with no status sits in a column nobody looks at. Both failure modes end with "I thought someone was doing that".

> **[WHY]**

> Two reasons that survive having no team. It answers "what is actually next" without re-reading forty issues, which is the question that costs the most time at the start of a session. And a status field with an *In review* column makes stalled pull requests visible — which is exactly the failure described in [page 18](18-github.html#economics), where a serialised merge chain quietly stops moving and nothing surfaces it.

<!-- chunk: craft.branches | tags: git,branching,workflow -->

## Branches

```text
feat/     a user-visible capability
fix/      a defect
refactor/ no behaviour change
perf/     measurable performance work
test/     tests only
docs/     documentation only
chore/    dependencies, tooling, housekeeping
ci/       workflow and pipeline changes
style/    formatting only
```

| Rule | Reason |
| --- | --- |
| Branch from the default branch, always | Stacked branches make auto-merge dangerous — see below |
| One concern per branch | A branch doing two things cannot be reviewed as either |
| Short-lived: one to three days | A week-old branch is a merge conflict with a countdown |
| Include the issue number or a slug in the name | `fix/3641-cpu-watchdog` is self-documenting in a branch list |
| Delete on merge (enable the repository setting) | A branch list with 60 merged branches is unusable |

> **[TRAP]**

> **Symptom: arming auto-merge on a stacked pull request merges it immediately and the parent balloons.** A pull request whose base is a *feature branch* rather than the default branch targets an unprotected branch — so there is nothing for auto-merge to wait for and it fires at once. The change lands in the parent branch, whose pull request is now much larger than reviewed. Never arm auto-merge on a stacked pull request; merge those by hand, bottom-up.

> **[RULE]**

> Direct commits to the default branch. Force-push to the default branch. Bypassing hooks with the no-verify flag. Amending a commit that has been pushed and reviewed. Interactive rebase inside a script or CI. Each of these has a legitimate-seeming use and each destroys either review history or someone else's clone.

<!-- chunk: craft.commits | tags: commits,conventional-commits,git -->

## Commit messages

Conventional commits, because a machine reads the subject to generate release notes and a human reads the body to understand why.

```text
type(scope): imperative subject under 72 chars, no trailing period

Why this change exists — the situation before, and what made it wrong.
What was decided and what was rejected. Anything a reviewer would ask.
Wrap at 72 columns.

Closes #3641
```

| Part | Rule |
| --- | --- |
| **Type** | The same set as the branch prefixes. `feat` and `fix` are user-visible; the rest are not, which is how release-note generation filters them. |
| **Scope** | The subsystem, in the codebase's own vocabulary: `fix(obd2):`, `feat(search):`. Optional but nearly always worth it. |
| **Subject** | Imperative mood ("add", not "added"), under 72 characters, no trailing period. It completes the sentence "if applied, this commit will…". |
| **Body** | **Why, not what.** The diff already says what. The body is where the reasoning lives, and it is the only place it will survive. |
| **Trailers** | `Closes #NN`, co-authors, references to a decision record. |

> **[RULE]**

> **One commit per closed issue, even inside a bundled pull request.** Bundling several issues into one pull request is often correct for CI economics. Squashing them into a single commit is not — the per-issue rationale becomes unrecoverable. Keep one commit per issue inside the branch and let the pull-request title summarise the bundle.

> **[WHY]**

> Subjects are read in bulk when scanning history. Bodies are read exactly once — by the person doing archaeology on a line of code, six months later, deciding whether they may change it. That reader is the highest-value audience any text in the repository has, and the body is the only thing written for them. A commit that changes a timeout from 30 to 7 seconds and says "adjust timeout" has thrown away the measurement that justified it.

Two smaller habits: do not `dart format` whole generated files, because it turns every regeneration into an unreviewable whole-file diff; and keep formatting-only changes in their own commit so a functional diff stays readable.

<!-- chunk: craft.prs | tags: pull-requests,review,writing -->

## Pull requests

| Element | Guidance |
| --- | --- |
| **Title** | Written for a *user*, not a reviewer — release notes are generated from it. "Fix grey map tiles after fast panning", not "Refactor tile provider". |
| **Size** | **Under 400 lines** excluding generated files. Above that, review quality collapses and approvals become rubber stamps. |
| **What** | One sentence. |
| **Why** | The problem, with `Closes #NN`. |
| **How** | The technical approach, only if it is not obvious from the diff. |
| **Testing** | What you ran, what you tested manually, on what device. |
| **Screenshots** | Before and after, for anything visual. Non-negotiable. |
| **Checklist** | The repository's standing requirements — see below. |

```markdown
## What
<one sentence>

## Why
Closes #

## Testing
- [ ] `flutter analyze` clean, including `test/`
- [ ] `flutter test` passes
- [ ] Manually tested on a device
- [ ] New tests added; bug fixes started from a failing test

## Checklist
- [ ] Under 400 lines excluding generated files
- [ ] No hard-coded user-facing strings; all locales updated
- [ ] Clean codegen run; zero drift
- [ ] No secrets, keys or credentials in the diff
- [ ] No proprietary dependency or tracking introduced
```

> **[RULE]**

> **Self-review the diff on GitHub before requesting review.** Read every line in the web interface, not your editor. You will find debug prints, a commented-out block, a stray file, and at least one thing you meant to rename. This takes three minutes and removes the most common review comments entirely — which means the reviewer spends their attention on the parts that need judgement.

> **[RULE]**

> **Use a draft pull request for work in progress, and say what feedback you want.** "Draft — the approach in `tile_provider.dart` is what I want an opinion on; the tests are not written yet" gets useful feedback. A silent draft gets none, and a non-draft pull request that is not ready wastes a reviewer's pass.

### Bundling

Bundling several issues into one pull request is often the right call: five sequential pull requests cost five full CI runs plus four rebases, and each merge pushes the others out of date. Bundle when the changes are related or touch the same files; keep them separate when a reviewer would need different context for each.

> **[RULE]**

> **Always bundle changes touching a known conflict-magnet surface.** Localisation fan-outs, generated files and the CI configuration itself: two concurrent pull requests touching one of these will conflict, and the conflict costs a rebase plus a full re-run each. Keep at most one localisation-touching pull request in flight at a time.

<!-- chunk: craft.review | tags: code-review,collaboration -->

## Reviewing

Review in a fixed order, because the expensive problems are the ones you stop looking for after the first nitpick.

1. **Does it solve the stated problem?** Read the issue first, then the diff. A correct implementation of the wrong thing is the costliest outcome.
1. **Is there a test that would have caught the bug?** For a fix, this is the whole review. No test means the fix is unverified.
1. **What breaks elsewhere?** Look for other callers of a changed function, other screens sharing a widget, the same anti-pattern in a sibling file — the [twin-bug audit](03-tdd-and-testing.html#twin), applied by the reviewer.
1. **Error paths.** What happens when the network fails, the permission is denied, the value is null, the list is empty?
1. **Then** style, naming, structure.

| Comment type | Convention |
| --- | --- |
| **Blocking** | State the problem and why it matters. Request changes. |
| **Non-blocking** | Prefix with `nit:` or `optional:` so the author knows they may decline |
| **Question** | Ask it as a question. Often the answer is good and the code needs a comment, not a change. |
| **Praise** | Worth doing, briefly, for a genuinely good solution. It calibrates what "good" means here. |

> **[RULE]**

> **If a review comment is about a rule, the outcome is a lint test — not a repeated comment.** Any convention you have explained twice should be machine-checked. Reviewers should spend their attention on judgement, not on enforcement a forty-line test can do forever. See [page 03](03-tdd-and-testing.html#lint-tests).

> **[WHY]**

> The pull request is still worth it even with nobody else to approve it. The diff view catches things the editor does not, the description forces you to state the why while you still know it, and the checklist is a second pair of eyes you can actually rely on. Open the pull request, walk away for an hour, then read it as a stranger.

<!-- chunk: craft.merge | tags: merge,squash,auto-merge -->

## Merge strategy

| Strategy | History | Use when |
| --- | --- | --- |
| **Squash** | One commit per pull request on the default branch | **The default.** Clean, bisectable, and the branch's messy intermediate commits disappear. |
| **Merge commit** | Preserves every branch commit plus a merge node | When the individual commits are each meaningful and reviewed — for example a bundled pull request with one commit per issue. |
| **Rebase** | Linear, no merge node, all commits preserved | Rarely. It rewrites hashes, so anything referencing them breaks. |

> **[RULE]**

> **Pick one strategy, enable only that button in the repository settings, and enable auto-delete of head branches.** A repository where three merge buttons are available will accumulate three histories. If you bundle issues into one pull request and want the per-issue commits preserved, choose merge commits for those deliberately — but decide once, not per pull request.

### Auto-merge

Arm auto-merge and let the required checks gate it. Two constraints come with that:

- **Serialise.** Without strict mode and without a merge queue, each merge pushes every other open pull request out of date. Open pull request N+1 only after N has merged, or you get quadratic CI churn.
- **Never on a stacked pull request.** See the trap in [§Branches](#branches).

> **[TRAP]**

> **Symptom: a chain of armed pull requests stops moving and nothing surfaces it.** When the head of a serialised chain stays red, the watchers on the ones behind eventually die and nothing recovers. Verify the *remote* state — is auto-merge still armed, is the fix actually pushed to the branch you think — rather than the local state, then re-arm manually. Serialised chains need a person to check on them.

If you have enough throughput for it, a **merge queue** removes the whole class: it tests each pull request against the post-merge state and merges in order. It is the correct answer to "should strict mode be on"; strict mode without a queue is the trade discussed in [page 18](18-github.html#protection).

<!-- chunk: craft.ci-run | tags: ci,debugging,workflow -->

## Running and debugging CI

| Situation | Do |
| --- | --- |
| A check failed | Read the *first* failure, not the last. Later failures are usually consequences. |
| It passes locally and fails in CI | Suspect, in order: a case-sensitive filesystem, line endings, a missing generated file, an unpinned toolchain, a time zone, a test that depends on the wall clock. |
| It failed once and passed on re-run | **Do not shrug.** Tag it as flaky and move it out of the gate into a nightly job, so a genuine regression still surfaces within a day. An untracked flake trains everyone to re-run red checks. |
| You need to re-fire on an unchanged ref | Use a manual dispatch with a reason input, not an empty commit. |
| A required check never reports | A skipped matrix job, or a path filter with no stub mirror. See [page 18](18-github.html#sharding). |
| You need to debug a runner | Add a temporary step that prints the environment and uploads the working directory as an artifact. Remove it in the same pull request that fixes the problem. |

```bash
gh run list --workflow=ci.yml --branch=my-branch --limit 5
gh run view <run-id> --log-failed        # only the failing steps
gh run rerun <run-id> --failed           # re-run just those jobs
gh workflow run ci.yml -f reason="retry after runner outage"
gh pr checks <pr> --watch                # live status while you work
```

> **[RULE]**

> **Run the gates locally before pushing.** A pre-push hook that runs analysis, clean codegen and the localisation pipeline turns a thirteen-minute CI round-trip into a thirty-second local failure. Ship the hook in the repository, install it with a script, and give it a documented emergency bypass so nobody reaches for the blanket hook-skipping flag — which also skips the hooks you actually need.

> **[WHY]**

> When a pull request is armed and green on everything except the slow full-suite shards, trust it. Schedule one confirmation rather than checking every few minutes. Repeated polling of a run that is going to pass is pure overhead — the check that matters is the single one after it completes.

<!-- chunk: craft.readme | tags: readme,documentation,onboarding -->

## The README

The README answers four questions for four different readers in the first screen: what is this, can I use it, how do I run it, how do I contribute.

| Section | Content | Common mistake |
| --- | --- | --- |
| **Name and one-line description** | What it is, for whom, in one sentence | A slogan instead of a description |
| **Install badges** | Direct links to every channel you publish on | Only one channel linked |
| **Status badges** | CI, licence, framework version. Three, not nine. | A badge wall nobody reads |
| **The pitch** | Two or three paragraphs on the problem and your approach | Jumping straight to installation |
| **Screenshots** | **Real ones, with captions.** The highest-value content in the file. | None, or unlabelled |
| **Features** | Grouped by user outcome, not by subsystem | A flat list of 60 bullets |
| **Getting started** | Prerequisites with versions, then copy-pasteable commands | Commands that assume your machine |
| **Architecture** | A directory tree with one line each, and the key patterns | An essay; link to it instead |
| **Contributing** | Five numbered rules, then link the full guide | The whole guide inline |
| **Licence** | Named and linked | Missing |

> **[RULE]**

> **Screenshots with captions, in a table, grouped by what the user is trying to do.** A README with a captioned screenshot grid communicates more in ten seconds than the feature list does in two minutes — and it is the only part most visitors read. Caption each one with what it shows and why it matters, and add alt text describing the screen for anyone who cannot see it.

> **[RULE]**

> **Every number in the README is a staleness liability.** "30 migrations", "600+ tests", "supports 12 countries" — all of these were true once. One project's README claimed 30 migrations when the tree had 73, and 600 tests when it had over a thousand. Either generate them, or round them ("a thousand-plus tests"), or leave them out. A precise wrong number damages trust in everything else on the page.

Keep the README under roughly a screen-and-a-half of reading before the fold, and link out for depth. If your README is the only documentation, it is too long; if it is a stub, nobody will get as far as the rest.

<!-- chunk: craft.wiki | tags: wiki,documentation,github -->

## The wiki

GitHub's wiki is a separate git repository with no pull requests and no review. That single property should decide what you put in it.

| Content | Where | Why |
| --- | --- | --- |
| Anything that must stay in sync with code | `docs/` in the repository | Reviewed in the same pull request as the change; a stale doc is a visible diff |
| Decision records, guides, specifications | `docs/` | Versioned with the code they describe |
| End-user guides, FAQ, troubleshooting | **The wiki** | Edited frequently, not tied to a release, and readable without cloning |
| Screenshots-heavy walkthroughs | **The wiki** | Large binaries you do not want in the source history |

> **[RULE]**

> **Keep the wiki's source in the repository and publish it, rather than editing the wiki directly.** Then wiki content gets review, history and CI like anything else. One project keeps its wiki pages in a `docs/wiki/` directory, and a build tool compiles the same user guides into the app's offline help — so documentation that fails to render fails the build. Documentation that is also a shipped artifact does not rot quietly.

Wiki structure that works:

- **A Home page that is a table of contents** with one line per page saying who it is for and what it covers — not a welcome message.
- **A sidebar** grouping pages by audience: developer pages, then user guides, one per language.
- **One page per audience-and-topic**, not one per feature. "User guide" beats twelve feature pages nobody can navigate.
- **Link back into the repository** for anything authoritative — the specification, decision records, migrations.
- **Say plainly which pages are user-facing and which are developer-facing.** Mixing them makes both audiences bounce.

> **[WHY]**

> Fact-check every claim against the code as you write it. One project discovered a months-old bug — a screen silently serving demo data because it bypassed an accessor — precisely while writing the wiki chapter that described that feature. Documenting behaviour from memory is how a false claim gets published; documenting it from the code is a free audit.

<!-- chunk: craft.releases | tags: releases,changelog,notes -->

## Releases and release notes

| Artifact | Audience | Source |
| --- | --- | --- |
| **`CHANGELOG.md`** | Users and contributors | Written by hand, per change, in an `[Unreleased]` section |
| **GitHub release notes** | Contributors | Auto-generated from pull-request titles, categorised by label |
| **Store release notes** | Users only | Per-locale files in the store metadata directory |

```yaml
# .github/release.yml — categorise auto-generated notes
changelog:
  exclude:
    labels: [chore, ci, dependencies]
  categories:
    - title: Added
      labels: [enhancement]
    - title: Fixed
      labels: [bug]
    - title: Documentation
      labels: [docs]
```

> **[RULE]**

> **Keep an `[Unreleased]` section and gate the release on the entry existing.** Every user-visible change lands there with its pull request; cutting a release renames the section. Make the release workflow refuse to ship a version with no matching entry. A changelog written retrospectively from a commit log is guesswork by someone reconstructing what a change meant to a user, and it reads like it.

Write user-facing notes in the user's terms. "Fixed a race in the tile provider's abort handling" is a commit subject; "Maps no longer show grey squares after panning quickly" is a release note. The translation is the work, and it is why generating store notes directly from commit subjects produces something nobody can read.

<!-- chunk: craft.meta | tags: repository,metadata,configuration -->

## The repository's own metadata

| File / setting | Worth it because |
| --- | --- |
| `.github/CODEOWNERS` | Auto-requests review from the right person per path. Even solo, it documents ownership. |
| `.github/dependabot.yml` | Weekly grouped updates. See [page 18](18-github.html#dependabot) for the lockstep-cluster trap. |
| `.github/release.yml` | Categorised auto-generated notes |
| `.github/FUNDING.yml` | A sponsor button. Note that some app stores forbid linking external donations *from inside the app* — the repository is unaffected. |
| `SECURITY.md` | Where to report a vulnerability privately. Enable private vulnerability reporting. |
| `CODE_OF_CONDUCT.md` | Standard text; takes two minutes and matters the one time it is needed. |
| `CONTRIBUTING.md` | The full version of the README's five rules |
| `.gitattributes` | `* text=auto`. Without it a Windows CI runner produces spurious generated-file diffs — see [page 16](16-windows.html#platform). |
| `.editorconfig` | Indentation and line endings agreed across editors |
| Topics and description | Repository discovery. Two minutes, permanently. |
| Discussions | Enable if you get questions that are not issues. It keeps the tracker for actionable work. |

> **[RULE]**

> **An agent-facing rules file must be version-controlled.** If your assistant configuration file is deliberately untracked, keep a committed mirror — one project keeps its binding rules at `docs/AGENT_RULES.md` for exactly this reason, so a fresh clone on another machine still carries them. Rules that live only on one developer's disk are not rules.

> **[CHECK]**

> Clone your own repository into a fresh directory and follow your own getting-started instructions on a machine that is not your daily one. Every assumption you did not know you were making surfaces in the first ten minutes — a missing toolchain version, an environment variable, a hook that was never installed, a step that only works because of something in your shell profile.

#### Sources for this page

- Both projects' issue templates (bug with a required version field, feature with a goals checkbox group, epic with a validation gate), pull-request templates, label sets, milestone usage and project-board conventions.
- Their commit and branch conventions, the one-commit-per-issue rule, the under-400-line pull-request rule, the squash-merge policy, and the serialised auto-merge discipline with its stall failure mode.
- One project's changelog discipline with the release-workflow gate, its release-notes categorisation, and its committed agent-rules mirror.
- The other project's wiki-in-repository arrangement, where the same source is compiled into the app's offline help, and its README staleness findings — which supplied the rule about numbers.

The review ordering, the label-axis model and the project-board field guidance are syntheses of both projects' practice rather than quotations from either.
