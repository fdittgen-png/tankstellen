**20 · Ship**

# Testers & Google Groups

> Tester management is the part of distribution that looks trivial and produces the most confused support conversations. Both stores have a mechanism that silently does nothing when misused, and both have an obvious-looking approach that does not scale past about ten people.

**Chunk prefix** test-mgmt **Updated** 2026-08-01 **Depends on** 19 Go-live

#### On this page

1. [Play testing tracks](#tracks)
1. [Google Groups as the tester list](#groups)
1. [The opt-in link, and why it fails](#optin)
1. [TestFlight: internal versus external](#testflight)
1. [Invitation mechanics that fail silently](#invitations)
1. [Public links](#publiclink)
1. [Automating tester management](#automation)
1. [Getting usable feedback](#feedback)
1. [Off-store channels](#offstore)

<!-- chunk: test-mgmt.tracks | tags: play,tracks,testing -->

## Play testing tracks

| Track | Audience | Review | Use for |
| --- | --- | --- | --- |
| **Internal** | Up to 100 named testers | None — available in minutes | Proving the pipeline; your own devices |
| **Closed (alpha)** | Named lists or Google Groups; can be several tracks | Light | A trusted tester cohort |
| **Open (beta)** | Anyone with the opt-in link, optionally capped | Yes | Real-device diversity at scale |
| **Production** | Everyone | Yes | Release, staged |

> **[RULE]**

> **Keep one track continuously fresh and promote from that one.** If a daily build feeds open testing while the internal track is updated rarely, a promotion defaulting to internal ships a stale, lower-versioned build. Make the source track an explicit parameter of your promotion workflow rather than a default nobody re-reads — one project changed exactly this default after being bitten.

> **[TRAP]**

> **Symptom: a user reports a bug you fixed weeks ago, and swears they are on the latest version.** They almost certainly are — of the *testing* track. A user who once opted into open testing keeps receiving that channel's builds after you ship to production, and the store gives them no obvious signal that they are on a different channel. Two countermeasures: tag beta builds visibly in-app (an about-screen suffix is enough), and document on your download page how to leave the testing programme.

<!-- chunk: test-mgmt.groups | tags: google-groups,play,tester-management -->

## Google Groups as the tester list

For any closed track with more than a handful of testers, use a **Google Group** as the tester list. You then manage membership in Groups rather than in the Play Console, which changes tester management from a release-engineering task into an ordinary administrative one.

|   | Email list in the console | Google Group |
| --- | --- | --- |
| Adding a tester | Edit the list in Play Console, save, wait for propagation | Add them to the group — no console access needed |
| Who can do it | Someone with console access | Any group manager |
| Self-service joining | No | Yes, if the group allows requests |
| Audit trail | Weak | Group membership history |
| Scales to | Tens, painfully | Thousands |
| Reuse across tracks/apps | Copy-paste | One group, referenced anywhere |

### Setting it up

1. Create a group at `groups.google.com` — for example `myapp-testers@googlegroups.com`. A free Google Group is sufficient; a Workspace group works identically.
1. Set who may join: open, request-and-approve, or invitation-only. *Request-and-approve* is usually right — it gives self-service without losing control.
1. Play Console → **Test and release → Testing → Closed testing** → your track → **Testers** → choose the Google Groups option and enter the group's **email address**.
1. Share the **opt-in link** shown on that page with the group.

> **[RULE]**

> **The account a tester uses to join the group must be the same Google account signed in on their device.** This is the single most common failure. Someone joins with a work address and installs on a phone signed in with a personal one; the store shows "item not found" and nothing indicates why. Say this explicitly in the invitation email — one sentence prevents most of the support load.

> **[TRAP]**

> **Symptom: a tester was added but still cannot see the app, hours later.** Check, in this order: **(1)** membership is *active*, not pending — a request-to-join group leaves people pending until approved; **(2)** the device account matches the group membership; **(3)** they have actually followed the opt-in link and accepted, which is a separate step from group membership; **(4)** propagation, which can take a few hours after a change; **(5)** the country — a track restricted by country excludes testers elsewhere with no explanation.

A practical convention: keep *two* groups — a small internal one for people who get everything immediately, and a larger external one for the closed track. Managing the boundary in Groups is easier than maintaining two console lists.

<!-- chunk: test-mgmt.optin | tags: play,opt-in,onboarding -->

## The opt-in link, and why it fails

Being on the tester list is necessary and not sufficient — each tester must also follow the opt-in URL and accept.

```text
https://play.google.com/apps/testing/<your.package.name>
```

| Failure | Cause | What to tell the tester |
| --- | --- | --- |
| "Not an authorised tester" | Not on the list, or the wrong account | Confirm which address they joined with and which is on the device |
| Opted in, store shows the production version | Store app cache | Force-stop the store app, clear its cache, retry after some minutes |
| "Item not found" on the listing | The app has not yet been published to *any* track visible to them | Confirm the build has actually rolled out, not just been uploaded |
| Opted in on the web, no update on the device | The device account differs from the browser account | Open the link in a browser signed in as the device account |
| Was working, now gone | The track was superseded, or they were removed from the group | Check group membership and whether the track still has a live release |

> **[CHECK]**

> Test the whole path yourself from a device that has never had the app, using an account that is not yours: join the group, follow the opt-in link, install from the store. Every step of that has failed for someone, and doing it once tells you which of your instructions are ambiguous.

<!-- chunk: test-mgmt.testflight | tags: testflight,apple,groups -->

## TestFlight: internal versus external

Two kinds of tester with genuinely different mechanics, and picking the wrong one costs a review cycle.

|   | Internal | External |
| --- | --- | --- |
| Limit | 100 testers | 10 000 testers |
| Prerequisite | **Must be an App Store Connect user** on your team | Just an email address — no Apple account needed |
| Review | None | **Beta App Review on the first build**; later builds go straight through |
| Availability | Minutes after processing | After review clears |
| Public link | No | Yes, with a tester cap |
| Build expiry | 90 days | 90 days |
| Use for | Your own devices, close collaborators | Everyone else |

> **[RULE]**

> **Internal testers must be App Store Connect *users* first — being "added as a tester" is a two-step operation.** You invite them as a user (scoped to this app only, with no provisioning rights), they accept the invitation, and only then can they be assigned to an internal group. Automation that tries to assign before acceptance appears to succeed and does nothing. Scope the invitation narrowly: visible to this app only, no provisioning permission.

> **[TRAP]**

> **Symptom: the first external build sits waiting on a form nobody filled.** Beta App Review needs the review contact block, the localised beta descriptions and — for anything using background execution or hardware — a demo video. Push all of it *ahead* of the build with a no-build lane, so the first external submission does not stall on data entry. See [page 14](14-ios.html#review).

<!-- chunk: test-mgmt.invitations | tags: api,testflight,automation,defensive -->

## Invitation mechanics that fail silently

The tester APIs have several behaviours that make naive automation report success while doing nothing. Each of the following was added to one project's tester lane after a real failure.

| Behaviour | Symptom | Defence |
| --- | --- | --- |
| **App-scoped lookup returns nothing for an existing tester** | A tester who exists on the account but is not yet indexed against this app looks absent, so the code tries to create them and hits a conflict | Look the tester up **account-scoped**, not app-scoped |
| **The bulk endpoint returns success with per-tester errors inside** | A 200 response containing a failure for one address; nothing raises | Separate create-new and add-existing paths; parse the per-item results |
| **An existing member's invitation cannot simply be re-sent** | "Resend" appears to work and no email arrives | Remove and re-add (external), or delete and recreate the pending invitation (internal) |
| **An app-manager-scoped key cannot manage users** | An authorisation error that looks transient and is permanent | Warn and continue — this is a configuration limitation, not a failure. Say so in the log. |
| **Assignment reports success before it is visible** | The tester is not in the group despite a successful call | **Re-fetch and verify** before claiming success |

> **[RULE]**

> **Verify by re-fetching, never by trusting the mutation's return.** This is the general lesson: for any outward-facing API that sends a real email to a real person, the only trustworthy confirmation is reading the state back. A lane that says "added 3 testers" without re-fetching is reporting its own intent.

> **[RULE]**

> **Tester-management workflows are dispatch-only. Never scheduled, never automatic on merge.** Adding a tester sends a real invitation email. It is an outward-facing action with a human recipient and belongs behind a deliberate trigger — the same reasoning as listing-metadata publication.

<!-- chunk: test-mgmt.publiclink | tags: public-link,recruitment,testflight -->

## Public links

Both stores can hand you a URL that lets anyone join, with different properties.

|   | Play open-testing opt-in link | TestFlight public link |
| --- | --- | --- |
| Cap | Optional tester cap on the track | Required cap, default around 100 |
| Approval | None — anyone with the link joins | None |
| Review | The open track is reviewed | The group's first build is reviewed |
| Revocation | Close the track | Disable the link |
| Anonymity | You see aggregate numbers | You see tester emails |

> **[RULE]**

> **Set a cap you can actually support, and remember a public link cannot be un-shared.** Once the URL is in a forum post it is public permanently — the only lever afterwards is disabling it, which cuts off everyone. Start with a low cap and raise it; the reverse is not available.

Practical detail: create the external group with access to all builds enabled, so every subsequent build reaches the group without per-build assignment. Otherwise you will be assigning builds by hand forever, which is exactly the toil the group was meant to remove.

<!-- chunk: test-mgmt.automation | tags: automation,workflow,cli -->

## Automating tester management

```yaml
name: TestFlight testers
on:
  workflow_dispatch:            # dispatch-ONLY — this sends real email
    inputs:
      email:      { description: 'Address, or comma-separated list', required: true }
      groups:     { description: 'Target groups (blank = every external group)' }
      first_name: { description: 'Optional' }
      last_name:  { description: 'Optional' }
      resend:     { description: 'Remove and re-add to force a new invitation',
                    type: boolean, default: false }
jobs:
  add:
    # API-only: no build, no signing, no Xcode. Linux is fine and cheap.
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: ruby/setup-ruby@v1
        with: { bundler-cache: true }
      - run: bundle exec fastlane ios manage_testers
        env:
          TESTER_EMAIL: ${{ inputs.email }}
          TESTER_GROUPS: ${{ inputs.groups }}
          APP_STORE_CONNECT_API_KEY_BASE64: ${{ secrets.APP_STORE_CONNECT_API_KEY_BASE64 }}
          APP_STORE_CONNECT_API_KEY_ID:     ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
          APP_STORE_CONNECT_API_ISSUER_ID:  ${{ secrets.APP_STORE_CONNECT_API_ISSUER_ID }}
```

| Design point | Why |
| --- | --- |
| Runs on Linux | It is API calls. A macOS runner here is pure waste. |
| Idempotent | Re-adding an existing tester is a no-op, not a failure |
| Blank groups means all external groups | The common case is "give this person everything" |
| An explicit resend mode | Because a plain resend does not work — see [above](#invitations) |
| Warn-and-continue on a permission limitation | An app-manager key cannot manage users; that is configuration, not failure |

The other store needs no equivalent automation if you use a Google Group — that *is* the automation. Membership changes propagate without touching the console, which is the whole argument for the approach.

<!-- chunk: test-mgmt.feedback | tags: feedback,support,process -->

## Getting usable feedback

Testers will report bugs in whatever channel is easiest. Make the useful channel the easy one.

- **Put the version and build number on an about screen**, selectable so it can be copied. Then require it in the bug template. This single field resolves the largest category of unactionable report.
- **Ship a "report a problem" affordance** that pre-fills device model, OS version, app version and a redacted trace excerpt, and opens your issue tracker. See [page 05](05-traceability.html#reporting) — it is consent-gated by construction, because the user sees and sends it themselves.
- **Tag beta builds visibly.** A suffix on the version string prevents an entire genre of confused report.
- **Tell testers what changed.** Per-build release notes reach TestFlight testers directly; on the other store they appear in the listing. A build with no notes gets tested at random.
- **Ask specific questions.** "Does the trip recording keep running when you lock the screen?" produces a usable answer; "let me know how it goes" does not.

> **[WHY]**

> Because it is a data-collection surface you then have to declare, secure and maintain — and it duplicates an issue tracker you already run. Composing a pre-filled issue and handing it to the user costs nothing, keeps the report public and searchable, and lets you state truthfully that the app uploads nothing on its own.

<!-- chunk: test-mgmt.offstore | tags: sideload,fdroid,validation -->

## Off-store channels

For anything hardware-dependent, the store channels are the slowest way to validate. Two faster paths:

| Channel | Latency | Use for |
| --- | --- | --- |
| **Direct-install artifact from CI** | Minutes | Validating a device-layer fix today. Debug-signed on purpose: fine for sideloading, and structurally blocked from store upload. |
| **Your own libre repository** | Hours | Real users, real updates, no review — and no store policy constraining what the build may contain. |

> **[RULE]**

> **Use the off-store path to validate anything blocked on store paperwork.** If a background feature is switched off pending a declaration, it can still be exercised today on a sideloaded build — one project's own documentation says exactly this, and points at its dev-artifact workflow for that purpose. Waiting for a review to test your own code is a self-inflicted delay.

Two things to document for anyone you send a direct-install artifact to: they will need to allow installation from that source, and a differently-signed build cannot upgrade a store install — they must uninstall first, which loses local data unless they export it.

#### Sources for this page

- One project's TestFlight tester lane and the specific defences it carries: account-scoped rather than app-scoped lookup, separate create-new and add-existing paths because the bulk endpoint returns per-item errors inside a success, the remove-and-re-add resend mode, the post-assignment verification re-fetch, and warn-and-continue when the key lacks user-management permission.
- The same project's external-group-with-public-link lane, its dispatch-only rule for outward-facing mutations, and its dev-artifact workflow used to validate features blocked on store paperwork.
- Its promotion-source-track default change, and the stale-testing-channel-build support pattern.

The Google Groups material is standard Play Console behaviour rather than an observation from either project — neither uses a Group today — and is included because it is the mechanism that makes closed-track tester management scale past a hand-maintained list.
