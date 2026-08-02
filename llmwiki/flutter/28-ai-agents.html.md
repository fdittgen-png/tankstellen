**28 · Collaboration**

# Working with AI agents

> Both source projects are substantially built and maintained with AI agents, and the practice that emerged is neither "let the agent do everything" nor "treat it as autocomplete" — it is an orchestration discipline with a division of labor, a verification loop that trusts nothing, and standing written rules that bind agents and humans identically. This page is that discipline, including the failure modes that taught it.

**Chunk prefix** agents **Updated** 2026-08-02 **Depends on** 03 TDD, 18 GitHub, 23 GitHub craft

#### On this page

1. [Standing rules that bind agents and humans alike](#rules)
1. [Division of labor: agents write, the orchestrator verifies](#division)
1. [File affinity decides the fan-out](#affinity)
1. [Generated files never hand-merge](#generated)
1. [Bundles and the serial merge train](#mergetrain)
1. [Verification traps](#verification)
1. [Observed failure modes](#failures)

<!-- chunk: agents.rules | tags: agents,rules,process,conventions -->

## Standing rules that bind agents and humans alike

Both projects keep a version-controlled agent-rules file — the hard rules (string externalisation, issue-first, clean codegen, key parity), the coding rules, the testing rules and the git rules — addressed explicitly to "humans and AI assistants". Three properties make it work where a style guide would not:

- **It travels with the clone.** A fresh agent session reads it before writing a line; nothing depends on the operator remembering to paste conventions into a prompt.
- **Most of its rules are machine-enforced anyway** ([the lint-test suite](03-tdd-and-testing.html#lint-tests)), so an agent that ignores the file fails CI rather than shipping a violation. The file explains; the tests enforce. Conventions decay, tests do not — and that goes double for agents, which have no memory of last week's review comments unless something writes it down.
- **Authorization boundaries are explicit.** Standing permissions (merge green PRs) and per-request permissions (apply a database migration, trigger an outward-facing workflow that emails real people) are recorded as such. An agent inferring authorization from precedent is how a rehearsal email reaches a customer.

> **[RULE]**

> **Destructive, outward-facing or schema-changing actions need fresh, explicit approval — every time.** Migrations to a live backend, store submissions, tester invitations, force-pushes: the standing rule in both projects is that yesterday's "yes" does not carry. The corollary for the operator: write the standing authorizations down precisely, because "merge on green without asking; migrations still need approval" is a sentence an agent can follow and an unwritten vibe is not.

<!-- chunk: agents.division | tags: agents,orchestration,worktrees,verify-loop -->

## Division of labor: agents write, the orchestrator verifies

The doctrine came out of a marathon run — nine PRs, forty issues, roughly eight parallel agents in git worktrees — and its core insight survives even as agent capabilities grow: **the verify loop belongs to the orchestrator**.

| Role | Does | Does not |
| --- | --- | --- |
| **Implementation agent** (worktree) | Reads, greps, edits, writes; verifies every API it calls by reading its source; reports raw data — files touched and why, formulas to spot-check, APIs it was unsure of, expected codegen drift, deferrals | Commit, push, or claim test results it could not run |
| **Orchestrator** | Runs the loop in the agent's worktree: deps → codegen → asset/l10n pipelines → analyze → targeted tests → fix → commit → rebase → push → PR → merge watcher | Trust a completion report without seeing the diff and, where claimed, the commit SHA |

Expect two to five real defects per agent bundle — an invented helper that was never defined, a test written against an API the platform hides, a formula transposed. The verify loop is where they die, which is the whole argument for it living with the party that can actually run the toolchain. Even when agents *can* run flutter and git themselves, the loop stays: agents report "done, committed" while the branch has no commit, and their writes keep landing in waves after the completion notification fires — treat a worktree as still mutating until its status is stable across two checks, and verify the SHA yourself.

> **[TRAP]**

> **Symptom: 242 test "failures" appear at once in an agent's bundle.** A flood of failures that are all `loading … [E]` is one compile error, not 242 regressions — fix the single analyzer error first and re-run before triaging anything. The matching triage rule for big combined runs: a many-suite invocation can flake on isolation while every suite passes standalone, so re-run per-suite before believing a red — and before "fixing" anything.

Prompt guardrails that pay for themselves, every time: the project's lint contracts, file-size caps and boundary rules go in *every* agent prompt; agents on potentially-stale bases are steered to append-only, disjoint-hunk edits near known conflict magnets ("don't reorder existing entries"); and each agent gets an explicit "don't touch X — another agent owns it" list.

<!-- chunk: agents.affinity | tags: agents,parallelism,file-ownership,forks -->

## File affinity decides the fan-out

Whether work parallelises is a property of the *files*, not of the tasks. The thirty-second ownership check before launching a wave — which files will each task touch? — is the highest-leverage half-minute in multi-agent work.

- **File-disjoint tasks → parallel agents.** Separate worktrees, or for lighter work, parallel forks in the shared checkout when each agent owns a different file (one translator per locale guide). Forks inherit the parent's context, so the prompt needs only the target file and the adaptation rules — and structurally-mirrored outputs should show near-identical `diff --numstat` shapes, which makes drift cheap to spot: the deviating count is the file to check first.
- **Same-file tasks → one agent**, sequenced. Two agents in one area will independently extract the same helper under two names; the reconciliation (keep one, delete the twin, repoint imports) costs more than the parallelism saved.
- **Conflict magnets → serialised.** Localisation aggregates, lockfiles, barrel files, shared test helpers: name them, and route every task that touches one through the same lane. Mechanical repo-wide burndowns go *last* — they touch every area the other bundles are editing.
- **One agent in the shared checkout → the checkout is theirs.** Do not edit alongside it; your edits race its write waves. And parallel *sessions* collide too: when the branch changes under you mid-turn, read the log and the PR list before assuming anything — your uncommitted work may already be adopted and merged by the other session. Stand down rather than fight over a shared checkout.

Worktree mechanics worth knowing cold: a branch held by a worktree cannot be checked out elsewhere — finish the work *in* that worktree; capture an agent's work as a staged diff (`git add -A && git diff --cached HEAD`), which is correct regardless of how stale its base is, and apply elsewhere with `git apply --3way`; a pre-push hook that validates the main checkout's tree does not validate a pushed worktree ref, so the gates must run in the worktree itself.

<!-- chunk: agents.generated | tags: agents,codegen,merges,arb -->

## Generated files never hand-merge

> **[RULE]**

> **Resolve any conflict in a generated file by taking either side whole, then regenerating from the source of truth, then committing the output.** Localisation aggregates, `*.g.dart`, freezed outputs, lockfiles: the fragments/annotations/manifest are the truth, the generated file is a build product, and a hand-merged build product is a third state that matches neither input. One regeneration per bundle, at the end, covers every conflict at once.

The rule has a squash-merge corollary that bites stacked work: when branch B was cut from branch A and A squash-merges to the default branch, B's next merge from that branch conflicts in *every file both touched* — the squash re-applies content B already has under a different commit identity. Resolution: keep B's side (it is the superset), then run the regeneration step so the generated files are rebuilt rather than believed. For hand-written files with two *added* blocks — two test files appending near the same seam — use `git merge-file` with the true base, never regex keep-both concatenation: the classic failure is a silently lost closing brace at the seam that surfaces as a parse error hundreds of lines later.

<!-- chunk: agents.mergetrain | tags: agents,pull-requests,merge-train,ci -->

## Bundles and the serial merge train

CI rounds are the scarce resource, so work ships in bundles — as many related issues per PR as review can bear, locally green *before* the PR exists, because the fix loop belongs in the worktree, not in CI.

- **One auto-merge PR in flight at a time.** With strict-mode branch protection off ([the deliberate trade](18-github.html#protection)), parallel armed PRs create rebase churn; a serial train — ship one, arm a background watcher on its state, let the merge notification trigger the next push — chains five PRs with zero behind-churn.
- **Watchers over polling:** a background check-watcher per PR, after first waiting for checks to exist at all — a watcher armed before the first check registers reports an empty success.
- **GitHub's `mergeable` recomputes asynchronously** after any push: poll until it leaves UNKNOWN before trusting either answer. Auto-merge survives force-pushes, but re-arming is idempotent — re-arm anyway.
- **A rerun is not a retest.** Re-running a failed workflow re-uses the original merge commit — it does *not* recompute the PR's merge ref against the moved base. After the base branch gained the fix your PR needs, update the branch (merge the base in, or the API's update-branch call) and let a fresh run trigger; a rerun will fail identically forever.
- **Push protection rejects provider-shaped fake secrets** in tests (`sk_live_…`). Use neutral fakes that still match the scrubber under test.

<!-- chunk: agents.verification | tags: agents,verification,shell,exit-codes -->

## Verification traps

Agent work amplifies a specific class of shell mistake: the command that *looks* like verification and is not. These recur enough across both projects to earn their own section.

| Trap | Rule |
| --- | --- |
| `flutter test \| tail` reports the *pipe's* exit code — a red suite reads as green to any `$?` check. This shipped a broken commit more than once, including to the authors of the rule. | Run the suite bare; if output must be filtered, capture to a file and take `PIPESTATUS[0]` |
| Backticks inside a double-quoted `gh` comment body are command substitution — the code-formatted words execute as commands and vanish from the posted text | Single-quote or heredoc any body containing backticks; re-read what was actually posted |
| Two identical script invocations returning byte-identical stale-looking output — and the file being inspected is in a different worktree than assumed | Worktrees multiply paths: verify *which* checkout a path resolves into before chasing ghosts; when in doubt, write a new script filename and re-run |
| An agent's "no codegen-affecting changes" claim, with two generated-file diffs sitting in the tree | Run clean codegen in the worktree yourself before pushing; agents under-declare drift |
| A locale-dependent comparison in CI — `printf "%.1f"` emitting a comma under a non-English shell, silently truncating the numeric compare | Integer arithmetic in gates; no float formatting in anything that decides pass/fail |

> **[CHECK]**

> The meta-rule: **every verification claim needs a mechanism the verifier did not produce.** A test suite proves a change; an exit code proves the suite ran; reading the posted comment proves the comment; the commit SHA proves the commit. An agent — or a human — reporting success without naming the mechanism has reported an intention.

<!-- chunk: agents.failures | tags: agents,failure-modes,triage -->

## Observed failure modes

Check these before debugging hard — each was observed at least once, and each has a cheap detection:

| Failure | Detection |
| --- | --- |
| Agent invented a helper it never defined | The first analyze in the verify loop |
| Agent tested against an API the package version hides (re-exports differ between minors) | Check the actual `show` lists before believing the agent's reading |
| Agent re-implemented a feature that already shipped, misled by a stale TODO | Prompt agents to check for existing implementations first; close as already-shipped when found |
| Park-loop: an agent that backgrounds its own test runs stops repeatedly "waiting for the notification" | Nudge once ("read the output files directly, then commit or report"); if it parks again, stop it and finish the tail — the work is usually 90% done and correct |
| Completion report with no commit; writes still landing after "done" | The SHA check and the two-reads-stable rule from the division-of-labor section |
| An agent deletes an earlier fix's defensive code as "redundant" | That is a [page-27 step-5](27-recurring-bugs.html#protocol) event regardless of who authored it — require the reproduction test green with the code removed |

> **[WHY]**

> None of these failure modes is unique to machines — humans invent helpers, trust stale TODOs and misread re-exports too. What changes with agents is *rate and confidence*: an agent produces plausible-but-wrong work faster than a human and reports it with the same tone as correct work. The discipline on this page is therefore not "distrust agents" but "make trust mechanical": rules that travel with the clone, gates that run regardless of author, and verification that names its mechanism. That discipline made the projects better for their human contributors as well — which is the quiet argument that it was the right discipline all along.

#### Sources for this page

- One project's worktree-orchestration playbook, distilled from two recorded multi-agent runs (a 9-PR/40-issue marathon and a later 5-PR audit run with toolchain-capable agents), including the division of labor, diff-capture mechanics, park-loop handling and the serial merge train.
- Both projects' agent-rules files and their standing-versus-per-request authorization records (merge-on-green standing; migrations, store actions and outward-facing workflows per-request).
- Session-logged incidents behind the verification-trap table: the piped-exit-code false green (multiple recurrences), the backtick-eaten PR comments, the stale-merge-ref rerun, the squash-stack conflict recipe, the comma-locale CI gate, and the fake-secret push rejection.
- The fork fan-out pattern from a four-locale documentation translation run, including the numstat-shape drift check.

This page originated as a maintained agent skill in the projects' shared tooling and is promoted here with the session-earned verification traps added. The division-of-labor doctrine is observed practice; its transferability to teams with different agent tooling is a recommendation.
