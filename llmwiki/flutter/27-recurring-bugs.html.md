**27 · Method**

# Recurring bugs & regressions

> A bug that comes back is not the same bug being fixed badly — it is usually a symptom with more than one cause, and each patch closes one path while leaving another open. The moment a bug recurs, the job changes: stop patching, start diagnosing. This page is the protocol for that moment, and the eight-month, nine-fix saga that paid for it.

**Chunk prefix** rebug **Updated** 2026-08-02 **Depends on** 03 TDD, 04 Robustness, 05 Traceability

#### On this page

1. [When this protocol applies](#trigger)
1. [The cautionary tale: nine fixes, one symptom](#tale)
1. [The seven steps](#protocol)
1. [Detector blind spots and circular gates](#detectors)
1. [Cycle-time fingerprinting](#fingerprint)
1. [Crashes with no traces](#notraces)
1. [Anti-patterns](#antipatterns)

<!-- chunk: rebug.trigger | tags: regressions,process,triage -->

## When this protocol applies

The protocol has a mechanical trigger, because the whole point is to interrupt the instinct to write one more quick patch. Invoke it when *any* of these is true:

- An issue title contains *regression of #NN*, *despite #NN*, *leaks past #NN*, *twin of #NN*, or *#NN follow-up* — for a bug, not a planned phase.
- You are about to write the **third or later** fix for the same user-visible symptom.
- A fix you are reviewing **deletes defensive code** added by an earlier fix for the same symptom.

> **[WHY]**

> Two fixes for one symptom can be honest bad luck. Three is a pattern, and the pattern almost always means the model of the bug is wrong — not the patches. From the third fix on, every additional patch has negative expected value: it costs a CI round-trip, adds a defensive layer someone will later have to reason about, and postpones the diagnosis that was needed at fix two.

<!-- chunk: rebug.tale | tags: regressions,case-study,root-cause -->

## The cautionary tale: nine fixes, one symptom

One source project's map showed grey tiles on cold start. The issue chain ran **#473 → #498 → #709 → #843 → #930 → #1164 → #1240 → #1268 → #1316** — nine "fixes" across eight months for one symptom. Step by step, what actually happened:

| Stage | What went wrong |
| --- | --- |
| The symptom hid two causes | Grey tiles came from (a) a *failed* HTTP tile fetch, and (b) a fetch that was *never issued* because the tile layer captured a zero-size viewport from an offstage pre-mount. Identical on screen; unrelated in code. |
| #843: right fix, wrong conclusion | Correctly fixed cause (a) — then declared it "the root cause" and **deleted the cause-(b) defenses** earlier fixes had added. Cold start regressed immediately; #1164 had to re-add the deleted scaffolding. Pure churn. |
| #930, #1240: self-inflicted | Bugs in #843's own new code. |
| #1164, #1268, #1316: trigger-patching | Each guarded one more *situation* that exposed cause (b) — tab-flip, app-resume, cold-start-direct — without ever fixing cause (b) itself. |
| #1316: the confession | Shipped an in-app debug overlay so the user could collect evidence — a tacit admission the root cause was still unknown after eight fixes. |

Net result: code that worked by brute force — around five redundant rebuild triggers, two magic timing constants, ~150 lines of regression-diary comments, a shipped debug overlay, and a dead duplicate file. Every step of the protocol below is the negation of one row of this table.

<!-- chunk: rebug.protocol | tags: regressions,protocol,root-cause,testing -->

## The seven steps

**1 · Stop. Do not write fix N+1 yet.** The instinct after a regression is to patch the newly-found path. One more patch on an un-isolated root cause just moves the leak.

**2 · Enumerate the failure modes — are there actually two?** List every distinct *cause* that produces this symptom, each with its precise mechanism. A failed fetch and a never-issued fetch both render grey; they are different bugs. If you find two, split the symptom-level issue into one issue per cause — the tracker should model the causes, not the pixels.

**3 · Find the source, not the trigger.** A trigger is a situation that exposes the bug — "tab-flip", "app-resume". The source is the one defect all triggers share. The tell that you are trigger-patching: each fix guards a new situation with a new flag. Fix the source once and every trigger stops mattering.

**4 · Write the reproduction test at the level the bug lives.** Every map fix added a unit test for its own knob; none tested the integration path the bug lived in. The bug was a widget-lifecycle race, so the honest test had to pump the real widget through the real lifecycle transition. Write that test and make it the regression lock — a future "delete the defenses" change must fail CI, not a code review.

> **[RULE]**

> **5 · Never delete another fix's defenses without proving they are dead.** Proof means: the reproduction test from step 4 passes *with the defensive code removed*. #843 deleted defenses on the assumption its cause was the whole story; it was not, and the deletion alone caused a release-visible regression. Default to keeping defenses.

**6 · Never ship diagnostics as product.** If you cannot reproduce and need field evidence, the instrumentation goes behind a debug flag or into a debug build — never into production UI with translated strings across every locale. A shipped debug overlay is a confession that step 3 was skipped. (The line, precisely: a consent-gated *local* error log the user can export is legitimate permanent infrastructure — see [page 05](05-traceability.html); a user-facing overlay is not. The test is whether it changes product UI.)

**7 · Clean up the patch-pile in the same effort.** Once the source is fixed, delete the now-redundant triggers, the magic timing constants, the regression-diary comments, the superseded files. A root-cause fix that leaves the scaffolding is half done — the next maintainer cannot tell live code from dead. If the cleanup touches more than a handful of files or multiple subsystems, it is an Epic with the structural fix, the scaffolding removal and the regression test as separate children ([page 23](23-github-craft.html)).

> **[CHECK]**

> The protocol succeeded when three things are true: the reproduction test is red on the pre-fix commit and green after; the fix count for this symptom stops growing; and a grep for the symptom's guard flags and timing constants comes back empty. If any defensive scaffolding survived, either it is load-bearing (then the source is not fully fixed) or it is dead (then step 7 is not done).

<!-- chunk: rebug.detectors | tags: regressions,detectors,state-machines -->

## Detector blind spots and circular gates

Two failure classes survive even a correct root-cause fix, both observed in a Bluetooth reconnect saga and both general:

- **A counter only sees the failure shape it was built for.** A wedge detector counting consecutive *failed* connect ladders is blind to success-then-instant-drop *flapping* — the connect completes, the session dies in seconds, and the success resets the backoff, so the loop never converges and the detector never fires. When adding any storm or stand-down detector, enumerate the other terminal shapes — hard failure, silent success, short-lived success, timeout — and give each its own latch or an explicit "covered by X" note. Corollary: a success signal must never blindly reset escalation state; only a success that *proves itself* (a session lifetime over a threshold, an explicit user action) may.
- **Never let a gate validate a value the system itself derived.** A receipt-OCR gate "verified" litres × price = total — on a total it had computed from those same two mis-assigned numbers. Tautological confidence 1.0 on garbage. Confidence must count independently-read inputs only; derived fields are flagged and never raise it.

Related hand-off rule from the same saga: **a state machine's "ready" state is not proof its held resource is alive.** After an external teardown, the supervisor still held the corpse in `ready`. Any seam that hands a resource across layers checks the resource's own liveness, never just the holder's state.

> **[RULE]**

> **When a user's debug export reproduces the bug, copy it verbatim into `test/fixtures/` as the red-on-master test.** A real field artifact beats any synthetic reproduction — it encodes the rotation, the OCR mangling, the timing pattern you would never invent. Synthesising "something like it" re-introduces exactly the assumptions the bug lives in.

<!-- chunk: rebug.fingerprint | tags: regressions,diagnosis,timing -->

## Cycle-time fingerprinting

When a failure repeats on a steady period, **the period names the driver**: measure what single step in the system takes exactly that long. A field reconnect loop ran at ~4.7 s — precisely the duration of one connect dial — which proved the sequence was dial → adopt → *instant* drop (the failure took ~0 s), not a timeout, not a backoff, not a watchdog. One number eliminated three hypotheses before any code was read.

The inverse reading matters too: **a run of success traces at machine cadence is itself the anomaly**. Twenty successful connects in a hundred seconds means success is not sticking — the question becomes "who consumes the success?", not "why does it fail?". Either way the log's *rhythm* is evidence before its contents are.

<!-- chunk: rebug.notraces | tags: regressions,forensics,crashes,exitinfo -->

## Crashes with no traces

When a recurring crash leaves nothing in the app's own error log, the absence of traces *is* the diagnosis: the failure lives in a layer your handlers cannot see — native code, an ANR, an OOM kill, an injected wrapper — or the evidence dies with the process because it only ever lived in memory. The move is a **forensics-first pass**: ship instrumentation that harvests OS-level exit records (Android's `ApplicationExitInfo`) and persists the in-memory diagnostics to disk — and only then hypothesise.

> **[TRAP]**

> **Symptom: "recording crashes, nothing in the log" — for months.** One source project's saga resolved three days after shipping an exit-info harvest: the culprit was a store-injected integrity wrapper that no dev build even contained — unfindable by any amount of reading your own code. Corollary: **an environment-conditional crash points at the environment delta.** Only-on-store-build, only-on-one-OEM, only-after-store-update — list what that channel adds or changes (re-signing wrappers, split installs, vendor patches) before auditing your own code.

This instrumentation is not the step-6 anti-pattern: a local, consent-gated error log the user can export changes no product UI and is legitimate permanent infrastructure. The forbidden thing remains the user-facing overlay shipped because diagnosis stalled.

<!-- chunk: rebug.antipatterns | tags: regressions,anti-patterns,summary -->

## Anti-patterns

| Anti-pattern | Which step it violates |
| --- | --- |
| Patching the trigger you just found | Step 3 — that is fix N+1; find the source first |
| Assuming one symptom = one cause | Step 2 — the most expensive sagas are two causes wearing one symptom |
| Deleting defenses on a hunch | Step 5 — prove they are dead with the reproduction test, or keep them |
| Shipping a debug overlay as a feature | Step 6 — instrumentation is not a deliverable |
| Fixing the source but leaving the patch-pile | Step 7 — half a cleanup is still a patch-pile |
| Unit-testing each fix's own knob | Step 4 — the reproduction must live at the level the bug lives |

#### Sources for this page

- The nine-issue map grey-tiles chain in one source project, read end to end: the two-cause split, the deleted-defenses regression, the trigger patches, the shipped overlay, and the eventual Epic that removed the scaffolding.
- The same project's Bluetooth reconnect saga: the flapping-blind wedge detector, the success-resets-backoff loop, the 4.7-second cycle-time diagnosis, and the ready-state-versus-live-resource hand-off rule.
- Its receipt-OCR circular-confidence incident and the verbatim-fixture rule that followed.
- Its "recording crashes, nothing in the log" resolution via an `ApplicationExitInfo` harvest, and the store-injected-wrapper finding.

This page originated as a maintained agent skill in the projects' shared tooling; it is promoted here because the protocol is human process, not agent process. All incidents are observed; the protocol's step ordering is the recommendation distilled from them.
