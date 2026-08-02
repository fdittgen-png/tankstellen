**18 · Ship**

# GitHub: repo, CI & traceable process

> A Flutter app with five distribution channels ends up with around twenty workflows. The question that decides whether that is manageable or miserable is which of them can block a merge — and the answer should be: as few as possible, all fast, all deterministic.

**Chunk prefix** gh **Updated** 2026-08-01 **Depends on** 03 TDD · 05 Traceability

#### On this page

1. [Workflow topology](#topology)
1. [The gate workflow](#gates)
1. [Sharding, and the matrix-skip trap](#sharding)
1. [Green-tree skipping](#greentree)
1. [The codegen-drift gate](#codegen)
1. [Branch protection as data](#protection)
1. [The docs-stub mirror](#docsstub)
1. [Dependency updates and lockstep clusters](#dependabot)
1. [Issues, PRs and templates](#templates)
1. [CI economics](#economics)

<!-- chunk: gh.topology | tags: ci,workflows,architecture -->

## Workflow topology

Sort every workflow into one of four classes, and let the class determine its trigger, its cost and whether it can block a merge.

| Class | Trigger | Blocks a merge? | Examples |
| --- | --- | --- | --- |
| **Gate** | Every push and pull request | **Yes** | Analyze, test shards, codegen drift, localisation, one platform build, integration, startup budget |
| **Advisory** | Every push and pull request | **No** | The libre no-proprietary-code audit, licence audit, security scan |
| **Release** | Tags and dispatch | No | Store uploads, TestFlight, notarised DMG, MSI, catalog publish, listing sync |
| **Scheduled** | Cron | No | Nightly full suite, flaky re-runs, endpoint canaries, daily beta builds |

> **[RULE]**

> **An advisory workflow must never become a required check.** The libre audit builds a full release artifact and runs Gradle — a transient infrastructure failure would block every unrelated merge. Keep the fast, deterministic layer of such a check as the gate and the expensive layer as advisory. Say so in a comment at the top of the file, or someone will "helpfully" promote it.

> **[RULE]**

> **Stagger every cron.** Seven scheduled workflows all at midnight contend for runners and for whatever third parties they touch. Spread them across the day and off the hour — a schedule at `:23` is measurably less contended than one at `:00`. One project runs its dailies at 04:00, 04:30, 05:00, 05:23, 11:00, 16:00 and 21:00, deliberately.

<!-- chunk: gh.gates | tags: ci,gates,workflow -->

## The gate workflow

One workflow, one job per concern, so a failure names itself in the check list rather than requiring someone to open a log.

| Job | Asserts | Typical |
| --- | --- | --- |
| `analyze` | Zero diagnostics, fatal on infos, over `lib/` **and** `test/` | 2–3 min |
| `codegen-drift` | A clean regeneration produces no diff | 4–6 min |
| `l10n-gate` | The localisation pipeline produces no diff; every locale is complete | 3–4 min |
| `test (0..3)` | The suite, sharded, excluding untrusted tags | 6–10 min each, in parallel |
| `build-android` | A release artifact actually builds | 8–12 min |
| `integration` | End-to-end flows | 5–8 min |
| `startup-budget` | Cold start under the budget | 3–5 min |

```yaml
on:
  push:
    branches: [master]
    tags: ['v*']
    paths-ignore: ['**/*.md', 'docs/**', 'LICENSE', '.gitignore',
                   'fastlane/metadata/**', 'ios/fastlane/**']
  pull_request:
    branches: [master]
    paths-ignore: [ '…same list…' ]
  schedule: [{ cron: '0 6 * * 0' }]     # weekly full run
  workflow_dispatch:                     # manual re-fire, with a reason input
    inputs:
      reason: { description: 'Why (audit trail)', default: 'manual' }

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

> **[WHY]**

> Because you will need to re-fire CI on an unchanged ref — after a branch update performed with the platform's own token (which does not trigger downstream workflows), or to retry a genuinely flaky run. The alternative is an empty commit, which pollutes history. A `reason` input makes the manual run self-documenting in the run list.

Cache aggressively and key precisely: the package cache on the lockfile, the build directory on the lockfile plus the Dart sources, Gradle caches on the Gradle files. A wrong cache key is worse than no cache, because it serves stale artifacts silently.

<!-- chunk: gh.sharding | tags: ci,matrix,branch-protection,trap -->

## Sharding, and the matrix-skip trap

Once the suite passes about twenty minutes, split it across a matrix. That introduces one specific hazard that will lock your repository if you meet it unprepared.

```yaml
test:
  strategy:
    fail-fast: false        # show EVERY failing shard in one run
    matrix:
      shard: [0, 1, 2, 3]
  steps:
    - uses: actions/checkout@v7
      with: { fetch-depth: 0 }   # a diff-aware selector needs history
    - run: flutter test --exclude-tags=network,flaky \
             --total-shards=4 --shard-index=${{ matrix.shard }}
```

> **[TRAP]**

> **Symptom: a pull request can never merge. Required checks sit as "Expected — waiting for status to be reported", indefinitely, and auto-merge never fires.**

> **Cause:** a **matrix** job skipped at *job* level never expands. The contexts `test (0)` … `test (3)` are therefore never reported at all — and branch protection waits for a status that will never arrive. This differs from a single-context job, whose `skipped` conclusion branch protection counts as a pass.

> **Fix:** a matrix job must *always run*; gate each expensive **step** instead. On a skip every shard completes in seconds (just the checkout) and still reports success.

> ```yaml
> test:
>   needs: [gate]
>   # NO job-level `if:` — the matrix must expand.
>   strategy: { matrix: { shard: [0,1,2,3] }, fail-fast: false }
>   steps:
>     - uses: actions/checkout@v7
>     - if: ${{ needs.gate.outputs.cached != 'true' }}
>       uses: subosito/flutter-action@v2
>       with: { channel: stable, flutter-version: "3.41.9" }
>     - if: ${{ needs.gate.outputs.cached != 'true' }}
>       run: flutter test --total-shards=4 --shard-index=${{ matrix.shard }}
> ```

> **[RULE]**

> **Single-context jobs may skip at job level; matrix jobs must skip at step level.** Write this as a comment above every matrix job. It is non-obvious, it is unrecoverable without an admin override when it bites, and it costs an afternoon to diagnose from scratch.

<!-- chunk: gh.greentree | tags: ci,caching,optimisation -->

## Green-tree skipping

The heavy jobs are a pure function of the build-relevant source tree. If that exact tree has already passed, re-running them proves nothing.

```text
record-green   after a full green pass, save a cache marker keyed on a
               hash of the build-relevant tree
green-gate     on the next run, probe that marker with lookup-only
               → HIT: every gated job/step skips
               → MISS: everything runs
```

What this buys you, concretely: a rebase with no content change, a base-branch retarget, and a manual re-fire all become seconds instead of thirty minutes. On a repository where pull requests are frequently rebased, that is the single largest CI saving available.

> **[RULE]**

> **Hash the build-relevant tree, not the commit.** A commit hash changes on every rebase even when the content does not. Hash exactly the paths that can affect the result — sources, lockfiles, build configuration — and exclude documentation and store metadata, which the trigger already ignores.

> **[CHECK]**

> Verify the skip is safe by construction: the marker must only be written after *every* gate passed, and the probe must be lookup-only so a probe cannot create the marker. Then reason about it once: a hit means this exact tree already produced a full green run, so skipping is not a shortcut but a deduplication.

<!-- chunk: gh.codegen | tags: codegen,ci,gate -->

## The codegen-drift gate

Generated files are committed, so CI must prove a clean regeneration produces no diff.

```yaml
- run: dart run build_runner clean
- run: dart run build_runner build --delete-conflicting-outputs
- name: Fail on any drift
  run: |
    if ! git diff --quiet -- '*.g.dart' '*.freezed.dart'; then
      echo "::error::Generated files are stale. Run clean codegen and commit."
      git diff --stat -- '*.g.dart' '*.freezed.dart'
      exit 1
    fi
```

> **[RULE]**

> **Enforce it locally with a pre-push hook, or you will pay for it in CI round-trips.** One project recorded codegen drift reaching CI four times in a single working session at roughly thirteen minutes each. A hook that runs the same clean regeneration and rejects the push turns that into a thirty-second local failure. Ship the hook in the repository, install it with a script, and provide a documented emergency bypass so nobody reaches for the blanket hook-skipping flag.

The same shape applies to the localisation pipeline: run the generator, then `git diff --exit-code` on the generated directory, with an error message naming the exact commands to run. An error message that tells you what to do is worth more than one that tells you what failed.

<!-- chunk: gh.protection | tags: branch-protection,configuration,drift -->

## Branch protection as data

Codify the required-check set in a script you can diff, and give it a verify mode that reports drift against the live configuration.

```bash
# The source of truth. Reviewable in a pull request; the console is not.
TARGET_CHECKS=(
  "analyze"
  "test (0)" "test (1)" "test (2)" "test (3)"
  "codegen-drift" "l10n-gate"
  "build-android" "integration" "startup-budget"
)

verify() {   # report drift, exit non-zero
  diff <(printf '%s\n' "${TARGET_CHECKS[@]}" | sort) \
       <(gh api "$API" --jq '.contexts[]' | sort)
}

apply()  {   # idempotent PATCH
  gh api -X PATCH "$API" --input - <<JSON
{ "strict": false, "contexts": $(printf '%s\n' "${TARGET_CHECKS[@]}" | jq -R . | jq -s .) }
JSON
}
```

> **[TRAP]**

> **Symptom: your documentation says direct pushes are blocked and CI must be green, and the API reports no protection at all.** This is real: one project's wiki, contributing guide and agent rules all asserted branch protection that did not exist — no protection, no rulesets, nothing on the server. The rules were honoured by convention only, and nothing would have stopped a red merge. Documentation describing a guarantee your infrastructure does not provide is worse than none, because it stops people checking.

> **Countermeasure:** the verify mode above, run periodically or in a scheduled workflow. Either the live configuration matches the committed target, or you get a diff.

> **[WHY]**

> Strict mode requires every branch to be up to date with the base before merging. With no merge queue, each merge pushes every other open pull request out of date, and they all re-run CI — quadratic churn for no correctness benefit when the changes are file-disjoint. Turning it off is a deliberate trade: you accept the small risk of a semantic conflict between two independently-green branches in exchange for linear rather than quadratic CI cost. Record the reasoning next to the setting.

The corollary is a merge discipline: with strict mode off and no queue, **serialise auto-merges** — open pull request N+1 only after N has merged. And never arm auto-merge on a stacked pull request whose base is a feature branch: merging into an unprotected branch fires immediately and silently balloons the parent.

<!-- chunk: gh.docsstub | tags: ci,path-filters,required-checks -->

## The docs-stub mirror

> **[TRAP]**

> **Symptom: a documentation-only pull request can never merge, because the required checks never run.** Path filters that skip CI for documentation changes also skip the *reporting* of the required contexts. Branch protection waits forever.

> **Fix:** a second workflow with the *same name*, triggered on exactly the paths the first one ignores, whose jobs are named identically and do nothing.

> ```yaml
> name: CI                     # ← same workflow name
> on:
>   pull_request:
>     paths: ['**/*.md', 'docs/**', 'LICENSE', 'fastlane/metadata/**']
> jobs:
>   analyze:        { runs-on: ubuntu-latest, steps: [{ run: 'echo docs-only' }] }
>   codegen-drift:  { runs-on: ubuntu-latest, steps: [{ run: 'echo docs-only' }] }
>   l10n-gate:      { runs-on: ubuntu-latest, steps: [{ run: 'echo docs-only' }] }
>   build-android:  { runs-on: ubuntu-latest, steps: [{ run: 'echo docs-only' }] }
>   integration:    { runs-on: ubuntu-latest, steps: [{ run: 'echo docs-only' }] }
>   startup-budget: { runs-on: ubuntu-latest, steps: [{ run: 'echo docs-only' }] }
>   test:
>     strategy: { matrix: { shard: [0,1,2,3] } }
>     runs-on: ubuntu-latest
>     steps: [{ run: 'echo docs-only' }]
> ```

> Note the matrix in the stub too — it must produce the same four contexts.

> **[RULE]**

> **Keep the stub's job names and matrix in sync with the real workflow.** Add a test that parses both YAML files and asserts the emitted context sets are identical. One project unit-tests its CI configuration for exactly this; without it, adding a gate job silently makes every documentation pull request unmergeable.

<!-- chunk: gh.dependabot | tags: dependabot,dependencies,maintenance -->

## Dependency updates and lockstep clusters

```yaml
version: 2
updates:
  - package-ecosystem: "pub"
    directory: "/"
    schedule: { interval: "weekly", day: "monday" }
    groups:
      minor-and-patch: { update-types: ["minor", "patch"] }
    open-pull-requests-limit: 5
    ignore:
      # Licence decision, not a drift update: the 2.x line moved to a
      # commercial-only licence.
      - dependency-name: "some_ble_package"
        update-types: ["version-update:semver-major"]

      # LOCKSTEP CLUSTER — every member must be listed. See the trap.
      - dependency-name: "state_lint"
      - dependency-name: "state_core"
      - dependency-name: "state_annotation"
      - dependency-name: "state_generator"
      - dependency-name: "json_serializable"
      - dependency-name: "json_annotation"

      # Prereleases only, never stable holds.
      - dependency-name: "codegen_package"
        versions: [">=3.2.6-dev <3.2.6"]

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule: { interval: "weekly", day: "monday" }
    groups: { actions: { patterns: ["*"] } }
```

> **[TRAP]**

> **Symptom: you ignore a package and the bot bumps it anyway.** Ignoring one member of a transitively-coupled cluster does *not* stop the bot co-bumping it while resolving another member. One project was defeated by this twice before listing every member. When you find a cluster, add all of it in one edit, with a comment naming the upstream event that unblocks it.

> **[RULE]**

> **Triage a red dependency pull request; do not close it.** Three recurring causes, in order of frequency: a lockstep cluster (above); a secondary lockfile that needs regenerating (see [page 17](17-fdroid.html#lockfile)); and a package whose new version references a platform SDK symbol newer than your CI runner's toolchain. All three are diagnosable in minutes once you know they exist, and all three recur weekly if left unaddressed.

Note that bot-authored pull requests cannot read repository secrets — a platform security policy, not a bug. Your build must therefore succeed without signing material. See [the deferred-throw pattern](13-android.html#signing).

<!-- chunk: gh.templates | tags: issues,pull-requests,templates -->

## Issues, PRs and templates

| Template | Required fields worth enforcing |
| --- | --- |
| **Bug** | What happened · steps to reproduce · **app version and build number** · platform. The version field alone resolves a large share of reports — see the stale-build trap on [page 13](13-android.html#checklist). |
| **Feature** | Problem · proposal · **a required checkbox group for the product's goals**, with the note that a feature serving none will be pushed back on. This is where [the feature filter](02-specification-driven-development.html#leitmotiv) becomes a workflow step. |
| **Epic** | Goal in user-visible terms linking the spec section · dependency-ordered child breakdown · risks and open questions · **a validation-gate checkbox** — children may only be filed after the breakdown is validated. |
| **New integration** | A domain-specific template for whatever you add repeatedly — a new country, a new provider, a new device profile. It turns a recurring task into a form. |

The pull-request template is a checklist, and every item should map to something a reviewer would otherwise have to remember:

```markdown
## What
<one sentence>

Closes #

## Checklist
- [ ] Linked issue
- [ ] Under 400 lines excluding generated files
- [ ] No hard-coded user-facing strings; all locales updated
- [ ] Clean codegen run; zero drift
- [ ] Tests added/updated — bug fixes started from a failing test
- [ ] `flutter analyze` clean, including `test/`
- [ ] No proprietary dependency or tracking introduced
```

> **[WHY]**

> Because it needs judgement — a generated-file-heavy change or a mechanical rename legitimately exceeds it. A checklist item prompts the author to justify; an automated block would be gamed by splitting into artificial commits. Automate the objective rules; check-list the ones needing a human.

<!-- chunk: gh.economics | tags: ci,cost,optimisation -->

## CI economics

| Lever | Effect |
| --- | --- |
| **Path filters plus a stub mirror** | Documentation changes cost seconds instead of half an hour |
| **Green-tree skipping** | Rebases and re-fires cost seconds |
| **Change-scoped jobs** | Security and licence audits run only when dependencies changed |
| **Concurrency with cancel-in-progress** | A force-push cancels the superseded run instead of racing it |
| **Dispatch-only expensive platforms** | macOS runners bill at a multiple of Linux; never run them per-PR |
| **Precise cache keys** | Large saving; a wrong key is worse than none |
| **Bundling related issues into one pull request** | The largest lever of all — five sequential PRs cost five CI runs plus four rebases |

> **[RULE]**

> **Bundle changes that touch the same conflict-prone surface.** Localisation fan-outs, generated files and the CI configuration itself are shared surfaces: two concurrent pull requests touching one of them will conflict, and the conflict costs a rebase plus a full re-run each. Keep at most one localisation-touching pull request in flight, and collapse workflow-file changes into a single change rather than a series.

> **[TRAP]**

> **Symptom: a chain of auto-merge-armed pull requests stalls, and the ones behind go stale on the remote.** When the head of a serialised chain stays red, the watchers on the ones behind eventually die and nothing recovers on its own. Verify the remote state — is auto-merge actually still armed, is the fix actually pushed to the branch you think — rather than the local state. Then re-arm manually. Serialised chains need a person to check on them; they are not fire-and-forget.

#### Sources for this page

- One project's twenty-workflow topology: the gate workflow with its green-tree cache marker, four-way test sharding, the codegen-drift and localisation gates, the docs-stub mirror re-emitting every required context, and the branch-protection script with its verify mode and target-check list.
- Its recorded matrix-skip incident and the resulting rule that matrix jobs gate per step, and its unit test over the CI YAML.
- Its dependency-bot configuration with the lockstep-cluster ignore list and the two recorded failures that produced it.
- The other project's documented-but-absent branch protection, recorded in its own known-gaps section — the source of the protection-drift trap.

The CI-economics table is a synthesis of both projects' practice; the individual levers are observed, the ordering is a judgement.
