<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Add an external TestFlight tester

Enroll an external iOS tester into the app's TestFlight beta group(s) so they
receive **all current and future** builds for that group — without logging
into App Store Connect by hand.

## How to run

GitHub → **Actions** → **iOS TestFlight Testers** → **Run workflow**
(`workflow_dispatch`). Or from the CLI:

```bash
# Add the default tester (florian.dittgen@trelleborg.com) to ALL external groups
gh workflow run ios-testers.yml

# Add a specific tester, optionally to specific group(s)
gh workflow run ios-testers.yml \
  -f email="someone@example.com" \
  -f groups="External Testers" \
  -f first_name="Some" \
  -f last_name="One"
```

### Inputs

| Input        | Required | Default                          | Meaning                                                                 |
| ------------ | -------- | -------------------------------- | ----------------------------------------------------------------------- |
| `email`      | yes      | `florian.dittgen@trelleborg.com` | Tester email. An invite email is sent to this address.                  |
| `groups`     | no       | _(empty)_                        | Comma-separated group names. **Empty → add to every external group.**   |
| `first_name` | no       | _(empty)_                        | Tester first name.                                                      |
| `last_name`  | no       | _(empty)_                        | Tester last name.                                                       |

When `groups` is omitted the workflow enumerates the app's external beta
groups and adds the tester to **each** of them, so "all current and future
tests" is covered regardless of how the group is named. The run log prints the
discovered group names (internal and external) so you can see exactly which
group the tester landed in.

## Prerequisites

- The app (`de.tankstellen.tankstellen`) must already have a **TestFlight
  build** and **at least one external beta group** in App Store Connect.
  Create the group under App Store Connect → TestFlight first; the workflow
  adds testers to existing groups, it does not create them. If no external
  group exists (and no matching `groups` name is passed) the lane fails with a
  clear message.
- The App Store Connect API key secrets must be configured (they already are
  for the TestFlight build workflow): `APP_STORE_CONNECT_API_KEY_BASE64`,
  `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`.

## What happens

- The tester receives a TestFlight **invite email**. They accept it, install
  TestFlight, and from then on get every build distributed to that group.
- The operation is **idempotent**: re-running it for an already-enrolled
  tester is a no-op, not an error.

## Why `workflow_dispatch` only

This is an outward-facing, live App Store Connect mutation that emails a real
person. It must never run automatically, so the workflow has no `push` /
`schedule` triggers — the maintainer (or the orchestrator) dispatches it by
hand. Under the hood it reuses the same App Store Connect API key and decode
step as `ios-testflight.yml`, and the `manage_testers` lane in
`ios/fastlane/Fastfile`.

---

# Diagnosing delivery: what App Store Connect actually thinks

`pilot` printing

```
Successfully distributed build to External testers 🚀
```

means the build was **assigned to the group and submitted**. It is *not*
evidence that a tester can install it. That distinction cost seven weeks in
[#3814](https://github.com/fdittgen-png/tankstellen/issues/3814): ~50 builds
uploaded "successfully" while the `extern` group's tester was still offered a
build from seven weeks earlier.

The `testflight_status` lane exists to answer the question the log line only
appears to answer. It is **read-only**: it submits nothing, assigns nothing and
expires nothing.

## How to run it

GitHub → **Actions** → **iOS TestFlight Status** → **Run workflow**. Or:

```bash
# The last 15 builds, newest first
gh workflow run ios-testflight-status.yml

# A shorter window, plus a named tester's group membership and 90-day usage
gh workflow run ios-testflight-status.yml \
  -f limit=30 \
  -f tester="someone@example.com"
```

| Input    | Required | Default | Meaning                                                    |
| -------- | -------- | ------- | ---------------------------------------------------------- |
| `limit`  | no       | `15`    | How many recent builds to report, newest first.            |
| `tester` | no       | _(empty)_ | Look one tester up: groups, invite type, 90-day usage.   |

It runs on `ubuntu-latest` (API only — no macOS runner), reuses the same
`APP_STORE_CONNECT_API_KEY_BASE64` / `_KEY_ID` / `_ISSUER_ID` secrets and the
same decode step as `ios-testers.yml`, and the report is mirrored into the
**job summary** so a dispatch is readable without opening the log.

To run it on a workstation, point `ASC_API_KEY_FILEPATH` at a local `.p8` as
described in [`ios-codesigning.md`](ios-codesigning.md), then:

```bash
cd ios && bundle exec fastlane testflight_status limit:15
```

## What each state means

A build carries three independent state machines. The one that governs
external testers is `externalBuildState`.

**`processingState`** — Apple's ingestion of the binary.

| Value        | Meaning                                                     |
| ------------ | ----------------------------------------------------------- |
| `PROCESSING` | Still being processed; nothing can be distributed yet.      |
| `VALID`      | Processed successfully. Necessary, nowhere near sufficient. |
| `FAILED` / `INVALID` | The binary was rejected before review ever started. |

**`expired`** — TestFlight builds live 90 days. An expired build is
uninstallable regardless of every other state, and an approved build that
expires before testers update strands them on whatever came before it.

**`internalBuildState`** — internal groups (App Store Connect users). They
need no review, so this reaches `IN_BETA_TESTING` on its own. It says nothing
about external testers, and reading it as if it did is one way to mistake a
broken pipeline for a healthy one.

**`externalBuildState`** — the external gate, and the field that matters:

| Value                      | Can an external tester install it? |
| -------------------------- | ---------------------------------- |
| `PROCESSING`               | No — still ingesting.              |
| `READY_FOR_BETA_SUBMISSION`| **No.** Processed, but *never submitted for review*. This is the silent-stranding state: the upload log is green and nothing else ever happens. |
| `WAITING_FOR_BETA_REVIEW`  | No — queued behind Apple.          |
| `IN_BETA_REVIEW`           | No — under review.                 |
| `BETA_REJECTED`            | No — rejected; see the review submission's rejection reason. |
| `MISSING_EXPORT_COMPLIANCE` / `IN_EXPORT_COMPLIANCE_REVIEW` | No — blocked on the encryption declaration. |
| `BETA_APPROVED`            | **Yes**, provided the rest of the chain below holds. |
| `EXPIRED`                  | No — past 90 days.                 |

**`betaReviewState`** (`WAITING_FOR_REVIEW` / `IN_REVIEW` / `REJECTED` /
`APPROVED`) is the review submission's own state. A build with **no review
submission at all** prints `—`, which is not "pending": it means nothing was
ever submitted. Only the *first* build of a version normally goes through a
full review; subsequent builds of the same version are usually auto-approved.

**Beta groups** — the list of groups the build is attached to. An external
build that is approved but attached to no external group reaches nobody.

## The combination that means "a tester can actually install this"

All five, together — any one missing and the build ships to no one:

1. `processingState = VALID`
2. `expired = false`
3. `externalBuildState = BETA_APPROVED`
4. the external group (`extern`) is listed among the build's **beta groups**
5. the tester is a **member of that group** and has **accepted** their invite

Anything short of all five is a build that uploaded successfully and delivers
nothing. `testflight_assert_delivery` asserts exactly 1–4 (plus a freshness
window) on every release-train run, so a new stranding fails the run instead of
hiding behind a green log for seven weeks.

## What the API does *not* tell you

Worth knowing before spending a CI round-trip guessing at it:

- **There is no per-tester delivery signal.** App Store Connect exposes no
  "which testers can see build X" beyond group attachment.
- **A tester's invite `state` is not exposed** on the `betaTesters` resource —
  requesting `fields[betaTesters]=state` returns nothing. Only `email`,
  `inviteType` and the names come back.
- The usable proxy is **per-tester usage** (`metrics/betaTesterUsages`, 90-day
  window), which `testflight_status` prints. `sessionCount = 0` means that
  identity has never run a build from the group — the observable form of
  "enrolled but installing nothing".
- `has_access_to_all_builds` is absent on external groups by design: it
  characterises internal groups, which receive every build automatically.
  External groups take builds explicitly.

When every server-side link measures healthy and a device still shows an old
build, the remaining evidence is device-side. The group's **public link**
(printed by the lane when enabled) re-joins whichever Apple ID is signed in on
the phone, needs no email, and removes nothing — so it is both the safest
mitigation and the cleanest discriminator between a stale device enrolment and
something the API is not exposing.
