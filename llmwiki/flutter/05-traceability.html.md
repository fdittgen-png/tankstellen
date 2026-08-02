**05 · Method**

# Traceability & observability

> Traceability is the ability to answer "why does the code look like this?" and "which commit is the user running?" without guessing. Observability is the ability to answer "what happened on that device?" without a debugger attached. Both are cheap to build in and effectively impossible to retrofit.

**Chunk prefix** trace **Updated** 2026-08-01 **Depends on** 02 Specification · 04 Robustness

#### On this page

1. [The traceability chain](#chain)
1. [Mapping a shipped build to a commit](#build-to-commit)
1. [Changelog discipline as a release gate](#changelog)
1. [The always-on trace ring buffer](#trace-logger)
1. [Crash forensics](#crash)
1. [Consent-gated error reporting](#reporting)
1. [Endpoint canaries](#canary)
1. [Decision records](#decisions)

<!-- chunk: trace.chain | tags: traceability,process,git -->

## The traceability chain

Every artifact in the pipeline carries the identifier of the one before it, so any line of shipped code can be walked back to the intent that produced it.

```text
specification section
   └─ issue (links the section)
       └─ branch  feat/<slug>
           └─ commit  feat(scope): subject          ← one per issue
               └─ pull request  "Closes #NN"
                   └─ squash merge to master
                       └─ tag  vX.Y.Z+<buildNumber>
                           └─ store build  (versionCode / CFBundleVersion)
                               └─ user's About screen
```

The chain is only as strong as its weakest link, and in practice two links are the ones that break.

> **[RULE]**

> **One commit per closed issue, even inside a bundled pull request.** Bundling several issues into one PR is often the right call for CI economics. Squashing them into a single commit is not: the per-issue rationale is then unrecoverable. Keep one commit per issue inside the branch, and let the PR title summarise.

> **[RULE]**

> **Every CI-minted build number must be tagged back to its commit.** A build number generated at build time — which is the correct way to guarantee monotonicity — exists nowhere in the repository unless the workflow pushes a tag. Without the tag, a user reporting "build 5137 crashes" is reporting against a commit nobody can identify.

<!-- chunk: trace.build-to-commit | tags: versioning,ci,release -->

## Mapping a shipped build to a commit

Build numbers must be strictly monotonic across every workflow that can publish, and must map back to a commit. Those two requirements together rule out most naive schemes.

| Scheme | Monotonic? | Verdict |
| --- | --- | --- |
| Manual `+N` in `pubspec.yaml` | Only if humans never make a mistake | Fine as the *human* version; not as the build number |
| CI run number | Per workflow only | **Fails** when two workflows can publish — they leapfrog and the store rejects the lower one |
| Date stamp `YYYYMMDDNN` | Yes, until the daily counter overflows | Works, but wastes range and collides on same-minute reruns |
| **Wall-clock minutes since an epoch, on a base** | Yes, across workflows and machines | **Recommended** |

```bash
# Strictly monotonic across runs AND workflows, unique per minute.
# 1_000_000 base keeps it clear of any hand-set number;
# 1751760000 is an arbitrary fixed project epoch (2025-07-06 UTC).
BUILD_NUMBER=$(( 1000000 + ( $(date -u +%s) - 1751760000 ) / 60 ))
```

Roughly four thousand years of headroom before it approaches Android's signed-32-bit version-code ceiling. iOS uses the identical value, which means a single number identifies a build across both stores.

> **[TRAP]**

> **Symptom: an upload is rejected because the version code is not higher than an existing one, even though your workflow incremented.** Two workflows — say, a daily beta and a tagged release — each using their own counter will produce overlapping numbers. Both stores reject a non-increasing code, and Play rejects it *per track*, so the failure appears on promotion rather than on upload. One shared time-derived scheme eliminates the class.

> **[TRAP]**

> **Symptom: per-ABI split builds overflow the version-code ceiling.** F-Droid's convention for split APKs is `base × 10 + abiIndex`. If your base is already a large wall-clock number (~2.03 × 10⁹), multiplying by ten overflows a signed 32-bit integer. Gate the multiplication to the flavor that needs it and leave the store flavor on the shared code. See [page 17](17-fdroid.html).

> **[CHECK]**

> Pick a build number from a store console at random and run `git tag --list '*+<that number>*'`. If nothing comes back, the chain is broken and you will discover it during an incident rather than during a drill.

<!-- chunk: trace.changelog | tags: changelog,release,ci-gate -->

## Changelog discipline as a release gate

Keep an `[Unreleased]` section at the top, land every user-visible change in it with its pull request, and make the release workflow refuse to ship a version with no entry.

```markdown
## [Unreleased]

## [6.0.4] - 2026-07-06 (Build 5137)

### Changed
- F-Droid: standard per-ABI versionCode scheme (base×10+ABI) — three ~40 MB
  APKs instead of one 124 MB universal APK.
```

```bash
# In the tag-triggered release job, before anything expensive runs:
SEMVER="${VERSION%%+*}"
if ! grep -qF "## [${SEMVER}]" CHANGELOG.md; then
  echo "::error::CHANGELOG.md has no '## [${SEMVER}]' entry." >&2
  exit 1
fi
```

> **[WHY]**

> A changelog maintained "when we remember" is written retrospectively from a commit log, by someone reconstructing what a change meant to a user. That reconstruction is guesswork and it shows. Gating the release on the entry's existence forces it to be written by the person who made the change, while they still know why it mattered.

> Gate only the tag-triggered path. Promoting an already-shipped build through tracks must not be blocked retroactively by a documentation rule.

<!-- chunk: trace.trace-logger | tags: logging,observability,privacy -->

## The always-on trace ring buffer

A bounded in-memory ring buffer with best-effort file persistence, always on, that the user can export — this covers most of what a crash-reporting service would, without sending anything anywhere.

```dart
enum TraceLevel { debug, info, warn, error }

class TraceEntry {
  const TraceEntry({
    required this.ts,       // UTC
    required this.level,
    required this.area,     // 'sync', 'obd2', 'nfc', 'storage' …
    required this.message,
    this.error,
    this.stack,
  });
  final DateTime ts;
  final TraceLevel level;
  final String area;
  final String message;
  final String? error;
  final String? stack;
}
```

Design properties that matter, each one earned:

| Property | Why |
| --- | --- |
| **Bounded ring buffer** (e.g. 500 entries) | Memory cost is fixed and known. Pair it with [episode gating](04-robustness.html#episode) or one outage evicts everything useful. |
| **Lazy, serialised file append with rotation** | Survives a process death, which the memory buffer does not. Serialise the IO so appends, rotations and clears cannot interleave. |
| **Degrades to memory-only on any IO failure** | Missing directory, full disk, sandbox denial. Set a flag once and stop trying; do not fail per-call. |
| **Never throws** | It is called from catch blocks. See [the contract rule](04-robustness.html#never-throws). |
| **A static fallback instance** | Call sites without a provider ref — bootstrap hooks, repositories, isolates — still have a target. Default it to memory-only. |
| **A change stream** | So an in-app diagnostics screen can render live. |
| **An `area` tag on every entry** | Filtering by subsystem is the difference between a usable export and a wall of text. |

> **[RULE]**

> **Decide what the trace log must never contain, and enforce it.** Both projects exclude: precise location, API keys and tokens, personal identifiers, profile names, backend anon keys, and raw domain values that could identify behaviour. Write the exclusion list into the privacy documentation and add a test that greps the export for known-sensitive key names. An export the user can share is only safe if you know what is in it.

<!-- chunk: trace.crash | tags: crash,forensics,android -->

## Crash forensics

The hardest report to act on is "it crashed and there is nothing in the logs". The countermeasure is breadcrumbs that survive the process, plus the OS's own record of why the process died.

| Source | What it gives you | How to reach it |
| --- | --- | --- |
| **Process-death records** (Android `ApplicationExitInfo`) | The OS's own reason for the kill: low memory, ANR, excessive CPU, user request, crash — plus a trace for some reasons | Query on next launch, fold into the trace log as a synthetic entry |
| **Crash-surviving breadcrumbs** | The last N actions before the death, from the persisted trace file | Read the rotated file at startup before appending to it |
| **Platform crash log** | Native stack for a native crash | Only via the platform console or an on-device log; not always available |
| **The user's export** | Everything above, in one file they can attach | A "save error log" button in the privacy or diagnostics screen |

> **[TRAP]**

> **Symptom: an app is killed repeatedly with no crash and no stack.** The cause was a background CPU watchdog kill — the OS terminated the process for excessive CPU with a reason code and no exception. Nothing in the Dart layer could have logged it, because nothing in the Dart layer knew. Reading the process-death record on the next launch is the only way that failure becomes visible at all; without it, the report is permanently "it just closes".

> **Countermeasure:** harvest exit records at startup, and when the reason indicates resource pressure, attribute it — per-thread CPU sampling, an isolate inventory, whatever the platform allows — because "excessive CPU" without attribution is not actionable either.

> **[CHECK]**

> Force each failure mode once, deliberately, and confirm it appears in the export: a Dart exception, an unhandled async error, a platform-channel failure, and a low-memory kill (easy to induce on an emulator). A forensics pipeline that has never been tested against a real death is a hypothesis.

<!-- chunk: trace.reporting | tags: privacy,error-reporting,consent -->

## Consent-gated error reporting

The app composes a report and hands it to the user. The user decides whether to send it. The app itself uploads nothing.

The mechanism is deliberately low-tech: build a pre-filled issue body — device model, OS version, app version and build, the redacted trace excerpt — and open it in the platform browser with `launchUrl` against the issue tracker's new-issue URL. The user sees exactly what will be submitted, can edit it, and can walk away.

> **[WHY]**

> Three reasons, in ascending order of importance. It is one fewer dependency and one fewer network permission. It is compatible with a build channel that forbids proprietary or tracking libraries — one project compiles its crash reporter out entirely for the libre build, which would be impossible if reporting were the only diagnostic path. And it is honest: "your GPS position and API keys never leave the device" is a claim you can only make if nothing uploads automatically.

> The trade is real: you get far fewer reports, and no aggregate crash-rate signal. If you need aggregate rates, use the platform's own vitals dashboards, which do not require an SDK in your binary.

If you *do* ship an SDK-based reporter, gate it behind explicit consent with a default of off, exclude it from any build channel that forbids it, and document exactly what it transmits in the privacy policy and the store data-safety declaration. See [page 09](09-confidentiality.html).

<!-- chunk: trace.canary | tags: monitoring,ci,third-party -->

## Endpoint canaries

If your app depends on third-party endpoints you do not control, probe them on a schedule from CI — otherwise a silently dead endpoint is discovered by a user, months later.

```yaml
name: Endpoint Canary
on:
  schedule: [{ cron: '23 5 * * 1' }]   # weekly, off-peak, off-the-hour
  workflow_dispatch:
jobs:
  probe:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with: { channel: stable, flutter-version: "3.41.9" }
      - run: dart run tool/endpoint_canary.dart   # probes every registered source
```

Design notes that make the difference between a useful canary and an alert-fatigue generator:

- **Track outages in one rolling issue**, updated in place, rather than opening a new issue per failure. A weekly cron that opens an issue every week is noise.
- **Distinguish "endpoint down" from "endpoint changed shape".** A 200 response with an unparseable body is the more dangerous failure and the one a naive HTTP check misses.
- **Run it off the critical path.** Never a required check — a third party's outage must not block your merges.
- **Record the last-good timestamp per source** so "has been failing for six weeks" is visible at a glance.

> **[WHY]**

> You are not building an uptime monitor; you are building a tripwire against permanent death. A source that fails for an afternoon is handled by the stale-cache tier of [the service chain](01-foundations-architecture.html#service-chain). A source that has been gone for two months needs a human. Weekly catches the second without generating alerts for the first.

<!-- chunk: trace.decisions | tags: adr,documentation,decisions -->

## Decision records

An architecture decision record captures why a choice was made, in a form that lets a future reader disagree with the reasoning rather than rediscover the problem.

```markdown
# ADR 0015: Per-fuel efficiency comparison v2 — composition buckets

**Status:** Accepted
**Date:** 2026-06-05
**Issue:** #2928 · **Parent Epic:** #2881
**Supersedes:** ADR 0014 (dominant-fuel collapse)

## Context
<what was true, what forced a decision, what constraints applied>

## Decision
<what was chosen, stated as a rule>

## Consequences
<what this makes easy, what it makes hard, what it forecloses>
```

> **[RULE]**

> **Supersede; never rewrite.** When a decision is replaced, mark the old record `Superseded` with a forward link and write a new one with a back link. The superseded record still explains why the shipped code has the shape it does, which is often exactly what the next reader needs. One project's decision set has fifteen records, one of which is superseded and still load-bearing.

Two practices that keep the set trustworthy:

- **Link the issue and the parent epic in the header.** That is the join back to the traceability chain.
- **Test the format.** A test asserting every record has a status, a date and the required headings costs twenty lines and stops the set degrading into free-form notes.

> **[WHY]**

> Because the alternative is three implementation issues built on three incompatible assumptions, discovered at integration. Making the record the deliverable of its own issue also means the reasoning gets reviewed *before* code exists to defend.

#### Sources for this page

- Both projects' release workflows (the monotonic build-number expression, the tag-push-back step, the changelog gate) and their decision-record sets.
- One project's `TraceLogger` — the ring buffer, the serialised lazy file IO, the degrade-to-memory flag, the static fallback instance and the change stream.
- The other project's crash-forensics work: process-death record harvesting, crash-surviving breadcrumbs, and the CPU-kill attribution incident; plus its weekly endpoint-canary workflow.

The build-number scheme comparison table is a synthesis; only the wall-clock scheme is quoted from a real workflow.
