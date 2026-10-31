<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Ready, Done and issue closure

This is the canonical authoring contract for #4483, implementing the
[owner's exit policy](https://github.com/fdittgen-png/tankstellen/issues/4339#issuecomment-5909680886).
[#4339](https://github.com/fdittgen-png/tankstellen/issues/4339) remains the
execution index. Existing approved checkpoints do not need another epic or
approval round for equivalent engineering.

## Intake, then Ready

A reporter supplies current versus expected behavior, reproduction if known,
version/platform ("unknown" is acceptable), and optional **redacted** evidence.
Screenshots, private identifiers, diagnosis and test plans are not required to
report a bug. Security reports use [the private channel](../../SECURITY.md).
Feature intake may propose an improvement to an existing journey or a new one.

The implementer then refreshes the base and active PRs, reads the issue plus
later owner corrections, and records one concise effective brief:

- User outcome, current/expected behavior and minimal proving scenario;
  type/priority, business risk, source revision and ownership of shared paths.
- Observed evidence versus hypotheses; existing paths versus proposed files.
  Missing current proof means **unverified**, not automatically unimplemented.
- Bounded producer **and real consumer**, non-goals, necessary producer
  checkpoint (or none), and separate release/device/operator evidence gates.
  A coordination link or shared-file lock is not a whole-issue prerequisite.
- Acceptance → fixture/preconditions → actual entry point → expected value,
  state or side effect → test path/name → runnable command → required evidence.
- Keep/adapt/replace/already implemented: proposed → chosen approach, reasons,
  meaningful alternatives/trade-offs, preserved invariants and named proof.
- Explicit STOP condition and the evidence that remains outside code delivery.

An API/connector-created issue needs the same brief: web forms do not validate
API bodies. Long source research can go in a linked specification or details
block; do not omit security or compatibility acceptance to meet a word quota.

## Done and STOP

Done means the specified producer/consumer, success/refusal/recovery paths,
applicable migration/configuration/help/locales and required candidate checks
are complete. Reuse adequate tests; add distinct failure cases according to
risk, not a test quota or a new suite merely to restate results. Pure prose or
SQL does not require every application test layer. Required omitted tests stay
NOT RUN/BLOCKED with a reason.

**STOP when this bounded checkpoint is Done.** No speculative platform,
framework, provider or repeated polishing. Fix directly caused regressions and
concrete security/data-integrity/acceptance failures; triage unrelated findings
separately. Review iterations must name a failed requirement or missing critical
proof. Equivalent engineering needs no extra approval loop; changes to access,
privacy, product/retention policy or paid/production actions retain their own
authorization requirements.

After two attempts with the same failure signature, record command, original
exit, source SHA and broken assumption; change approach before another bounded
attempt. Changing a commit hash does not reset this failure history. Reconcile
shared ownership and ancestry at actual integration boundaries; unrelated merges
do not require constant rebasing. Regenerate derived files rather than merging
them by hand. [Current-candidate review and checks](../ci/independent-review.md)
still apply.

Report base/final SHA, PR, production entry point, acceptance-to-test evidence,
commands/original exits/artifacts, decisions, compatibility/rollback and limits
once, reusing the same integrated packet. PASS, FAIL, NOT RUN, BLOCKED and
DEFERRED are different outcomes. An optimization rejected on measured contention
is DEFERRED; an already-implemented or retired contract needs source/proof.

Use `Refs #N` for partial delivery. Use `Closes #N` only when **all** issue
acceptance, including required external evidence, is satisfied; verify the merge
on the default branch before reporting closure. `implemented-in-PR`,
`verified-at-SHA`, `evidence-pending` and `released-in` are separate states.
Missing external evidence stops code churn and keeps its qualification open.
Parents consume named leaf evidence rather than creating another implementation.

## Finite examples

| Work | Proving boundary and STOP | Honest remaining state |
|---|---|---|
| Ordinary code fix | Reproduce denied location in the actual refresh consumer; preserve previous results, actionable error, and success control. Stop after applicable checks. | Verified at candidate SHA; release not implied. |
| Unit/UX change | Exercise the real action through loading/error/empty states and the relevant accessibility constraints; reuse existing lower-layer fixtures. | No arbitrary test quota or unrelated redesign. |
| Consumption corpus | Replay named anonymized full-tank/source-class fixtures with exact expected outputs; keep partial observations distinct. | Missing measured corpus is BLOCKED; simulation does not certify physical accuracy. |
| BLE/Classic/iPhone | Code and controlled lifecycle tests complete; name required adapter/device/OS/build matrix and the person supplying evidence. | Physical qualification NOT RUN until actual hardware observations exist. |
| Store/operator delivery | Record source/build, actual distribution state and tester installability or operator verification. | Upload/first-frame/PID socket success does not prove installability, useful UI or hardware continuity. |
| Duplicate database index | Prove constraint/FK/query equivalence on the actual local schema and compare plans before removal. | Metadata-only checks do not prove RLS; unavailable local backend means BLOCKED. |
| Paged API | Fake server cap below requested page size; actual consumer receives every page/tombstone and refuses incomplete responses. | A short page alone need not mean completion. |
| Retired hosted task | Source removed plus actual scheduler ownership/retirement evidence. | A still-active hosted job prevents claiming retirement. |

### API-created implementation brief example

```markdown
Outcome: denied-location refresh explains recovery and retains the last result.
Current/expected: generic failure → typed location message; success unchanged.
Type/priority/risk: bug / P1 / loss of search usability, no storage migration.
Source: base 6b45030152641a6205243e2537bcc63246056978;
  existing lib/features/search/presentation/screens/search_screen.dart _refreshAll.
Owner/scope: refresh error consumer and its existing location exception contract.
Prerequisite: existing typed location error; no device/store gate for this code.
Non-goals: permission onboarding redesign, geocoder or map changes.
Decision: adapt existing localizer instead of introducing another error system.
Proposed proof: denied + success → real refresh → retained position/message;
  test/features/search/presentation/screens/search_permission_regression_test.dart.
Command: flutter test --no-pub test/features/search/presentation/screens/search_permission_regression_test.dart
Exit: STOP after these paths, compatible localization and candidate checks pass.
Status: ready/unverified; command NOT RUN in this synthetic authoring example.
  Refs until whole acceptance; never claim released or physical-device verified.
```

## Portable adoption and source reconciliation

For another project, link this method from its existing contributor/agent
entry points, substitute its actual producer/consumer and verification commands,
and keep one local authority. It assumes no particular database, hardware,
language, container tool or CI provider. Do not copy Sparkilo's live backlog or
create a shared runtime package, new bot or heading-enforcement workflow.

The companion [Deskilo #1860 checkpoint A](https://github.com/fdittgen-png/deskilo/issues/1860#issuecomment-5952157639)
already merged its Ready/Done/Refs guidance in PR #2092. This adopts the same
meaning without waiting for a cross-repository merge. Tankstellen has no tracked
development/epic skill or evolution playbook; local skills are not portable repo
policy. This guide is its version-controlled portable method, reached through
AGENT_RULES; older local epic/closure advice must be reconciled with it. A future
adoption may link its existing project-evolution playbook to its local authority.
