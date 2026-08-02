**19 · Ship**

# Go-live runbook

> Shipping to five channels is not five times the work of shipping to one, but it is five sets of paperwork with five different review latencies. The thing that decides whether a launch takes a week or two months is how early you start the steps no automation can do for you.

**Chunk prefix** live **Updated** 2026-08-01 **Depends on** 13–17 platform pages

#### On this page

1. [Start with what only a human can do](#humanonly)
1. [Irreplaceable material](#irreplaceable)
1. [T-minus checklist](#tminus)
1. [The launch sequence](#order)
1. [Staged rollout](#rollout)
1. [Rollback](#rollback)
1. [The first week](#firstweek)
1. [Steady-state cadence](#cadence)

<!-- chunk: live.humanonly | tags: go-live,manual-steps,planning -->

## Start with what only a human can do

Inventory these first, because each has a latency you cannot compress and several block everything downstream.

| Step | Channel | Latency | Blocks |
| --- | --- | --- | --- |
| Create the app record in the console | Both stores | Minutes | **The first upload.** One store binds a package on first upload; the other needs the record created first — no API for it. |
| Grant the publisher service account release permission | Play | Minutes | Every automated upload |
| Enable app-group capability on each App ID | Apple, portal only | Minutes | Widget/extension signing. **No API exists.** |
| Create the Developer ID certificate | Apple, account holder only | Minutes | macOS notarisation. No API — see [page 15](15-macos.html#accountholder). |
| Content rating questionnaire | Play | Minutes | Production listing |
| Data safety / privacy nutrition label | Both | An hour, if the inventory exists | Production listing |
| **Foreground-service declaration** | Play | **Days** — plus a video | Background features. Has a catch-22; see [page 13](13-android.html#fgs). |
| **Demo video for hardware features** | Apple, *every* submission | Hours to record | Review approval for background/Bluetooth features |
| Beta App Review (first external build) | Apple | **Days** | External testers |
| Catalog merge request | F-Droid | **Weeks** | Catalog listing only — self-hosting is not blocked |

> **[RULE]**

> **Start the video-gated and review-gated items on day one of the launch runway.** The foreground-service declaration and the Apple demo video are the two longest poles, and both are gated on a recording session rather than on code. Neither can be started at the end. Everything else — builds, uploads, listings — is automation that runs in minutes once the paperwork clears.

> **[WHY]**

> Both stores have the same problem with hardware-dependent features: a reviewer at a desk cannot exercise background recording or a Bluetooth link. Written descriptions do not clear it. A short recording on a physical device, showing every permission prompt, is the accepted evidence — and Apple's expectation is that it is refreshed for *every* submission, not once. Automate carrying the link (a repository secret appended to the review notes) so only the recording itself stays manual.

<!-- chunk: live.irreplaceable | tags: secrets,backup,risk -->

## Irreplaceable material

Some secrets can be rotated. These cannot. Back them up off-machine before launch, not after.

| Material | If lost |
| --- | --- |
| **The App Store Connect `.p8` key** | Downloadable exactly once. Apple will not re-issue it; you create a new key and update every consumer. |
| **The certificate-repository passphrase** | The encrypted repository is permanently unreadable. One project lost one and had to stand up an entirely separate certificate repository rather than re-encrypt one a sibling app depended on. |
| **The Android upload keystore and its passwords** | Recoverable via a store-side reset, but it is a support request with latency at the worst possible time. |
| **The self-hosted repository signing key** | Users' clients trust that key. Replacing it means every existing installation must be uninstalled and reinstalled. |
| **The Windows installer upgrade code** | Not secret, but permanent — see [page 16](16-windows.html#upgradecode). Commit it and never change it. |

> **[CHECK]**

> Run one restore drill before launch. On a machine that is not your development machine, fetch each backed-up secret and prove it works — decrypt the certificate repository, sign a throwaway artifact with the keystore, authenticate to the store API with the key. A backup you have never restored is a hypothesis.

<!-- chunk: live.tminus | tags: checklist,go-live -->

## T-minus checklist

### Product

- Every user-visible string is externalised; every locale is complete.
- The privacy screen, the privacy policy and both store declarations agree — one inventory, three artifacts ([page 09](09-confidentiality.html#inventory)).
- Export and delete-all work and are tested, including caches.
- Every feature behind a flag has a sensible per-channel default.
- Every permission is requested late, explained first, and the app remains usable if refused.
- No feature depends on a background guarantee the platform does not give ([page 21](21-background-and-pinning.html)).

### Engineering

- Full suite green on mainline; no tag-excluded test hiding a real failure.
- Clean codegen; zero drift.
- The **release artifact launches** on a real device or emulator — not just compiles ([page 13](13-android.html#r8)).
- Merged manifest declares only intended permissions.
- Startup within budget on a low-end device.
- A capturing-proxy session reviewed: nothing unexpected leaves the device.
- Crash and trace export produce something readable.
- Version numbers monotonic and mapped to commits by a tag.

### Store

- Listing text and screenshots in every launch locale.
- Feature graphic exactly to spec, correctly named (a wrong filename is silently ignored).
- Privacy-policy URL resolves — verify it, do not assume.
- Content rating, data safety, target audience, ads declaration all filed.
- Review contact block complete; never fabricate a phone number.
- Demo video recorded, hosted unlisted with no login wall, link set.
- Tester lists populated and the opt-in link tested from a device that is not yours.

> **[TRAP]**

> **Symptom: an upload succeeds and the listing does not change, or an image silently does not appear.** Store metadata tooling is unforgiving about filenames and dimensions and mostly fails quietly. Two specific ones worth pinning: the feature graphic must be camelCase and exactly 1024×500; and a metadata sync that deletes remote images not present locally will silently remove screenshots you forgot to include. Publish the full set every time, and check the live listing afterwards.

<!-- chunk: live.order | tags: sequence,launch,channels -->

## The launch sequence

Order matters, because each phase de-risks the next and the cheapest channels give you the fastest feedback.

| Phase | Do | Why here |
| --- | --- | --- |
| **1 · Sideload** | Build a directly-installable artifact; run the on-device checklist | No store, no review, no latency. Every hardware feature validated before anyone else sees it. |
| **2 · Self-hosted libre repo** | Publish the libre build to your own repository | An afternoon's work, real users, and it forces you to solve the dependency problem early ([page 17](17-fdroid.html)). |
| **3 · Internal testing** | Upload to the closed store track; a handful of testers | Proves signing, the upload pipeline and version codes end to end. |
| **4 · TestFlight internal** | Upload; internal testers only | Instant, no review. Proves the iOS signing chain, which is the most fragile one. |
| **5 · TestFlight external** | Submit to the external group | **First review gate.** Needs the demo video. Days of latency — start it as soon as phase 4 is green. |
| **6 · Open testing** | Public opt-in on the store | Real-device diversity at scale, still reversible. |
| **7 · Desktop** | Notarised DMG and signed MSI attached to a release | No review; ship whenever the artifacts are green. |
| **8 · Production, staged** | Promote at a small percentage | See below. |
| **9 · Catalog submission** | Open the merge request | Weeks of latency and blocks nothing. Do it in parallel with phase 6. |

> **[RULE]**

> **Never let phase 9 block phases 1–8.** A catalog review can take weeks and is entirely outside your control. Your own repository already serves the users who wanted a libre build. Submit and forget; respond to review comments as they arrive.

<!-- chunk: live.rollout | tags: rollout,release,risk -->

## Staged rollout

Promote in steps and give each step long enough for the signal to arrive.

| Stage | Hold for | Watch |
| --- | --- | --- |
| 1–5% | 24 h | Crash-free rate against the previous release; store reviews |
| 10% | 24 h | Same, plus any backend error-rate change |
| 25% | 48 h — spanning a weekend if the app has weekday/weekend usage differences | Same |
| 50% | 48 h | Same |
| 100% | — | Keep watching for a week |

> **[RULE]**

> **Promote from the track that is actually current.** If a daily build keeps the open-testing track fresh while the closed track is rarely updated, defaulting a promotion to the closed track silently ships a stale, lower-versioned build — and the store may reject the promotion for a non-increasing version code, which at least fails loudly. One project changed its promotion default specifically because of this. Make the source track an explicit, deliberate parameter.

> **[TRAP]**

> **Symptom: the build succeeds, the upload fails on an argument error.** Release notes containing embedded double quotes get argument-split when passed through a CI invocation. Because the build already succeeded, it reads as a mysterious late failure. Phrase release notes with single quotes or pass them via a file. Re-dispatching is safe — a fresh build number is minted.

Apple has no percentage rollout in the same form; the equivalent levers are phased release and holding a version in review until you are ready. Plan the two channels' timing separately rather than trying to synchronise them.

<!-- chunk: live.rollback | tags: rollback,incident,release -->

## Rollback

You cannot un-ship a version. What you can do is halt, supersede and communicate — decide which before you need it.

| Situation | Action |
| --- | --- |
| Bad build, staged rollout not complete | **Halt the rollout.** Immediate; users past the halt keep the bad build, but no new ones get it. |
| Bad build, fully rolled out | Ship a fix as a *higher* version. There is no downgrade — a version code must always increase. |
| Bad build on iOS | Remove from sale or expire the TestFlight build, then submit a fix. Review latency applies, so this is slower than the other store. |
| Bad build in your own repository | Rebuild the index with the previous artifact. This is the one channel where a true rollback is possible. |
| Bad data rather than bad code | Fix it server-side if you can. A remote fix beats a client release every time — which is an argument for a small remote configuration surface. |
| Bad desktop artifact | Delete the release asset and re-attach a corrected one. No install-base impact until someone downloads. |

> **[RULE]**

> **Write the halt procedure down before launch, with the exact console path.** During an incident nobody should be navigating a console for the first time. Two sentences and a URL in the release documentation is enough, and it is the difference between halting in two minutes and halting in twenty.

<!-- chunk: live.firstweek | tags: monitoring,launch,support -->

## The first week

| Watch | Where | Acting threshold |
| --- | --- | --- |
| Crash-free rate | Store vitals — no SDK needed | Any drop against the previous release |
| Store reviews | Both consoles | Read every one for the first week; they name the confusing part of your onboarding better than any analysis |
| Excessive-resource warnings | Android vitals | Wake locks, background CPU, ANRs — these get you delisted, not just downranked |
| Backend error rate | Your own logs | A launch is your first real load test |
| Third-party endpoints | The canary ([page 05](05-traceability.html#canary)) | Real usage finds rate limits synthetic probes do not |
| Issue tracker | Your repository | The template's version field is what makes reports actionable |

> **[TRAP]**

> **Symptom: a user insists a fixed bug is still present.** Check their version before anything else. Open-testing channels lag production, and a user who joined a testing programme keeps receiving that channel's builds. The fastest resolution is to sideload a build from current mainline and confirm against that. Put the version and build number somewhere a user can read out — an about screen — and require it in the bug template.

> **[CHECK]**

> On day one, install from each public channel yourself, on a device that has never had the app: the store listing, your own repository, and each desktop download. Not the artifact you built — the one the channel actually serves. This catches a wrong signature, a broken download link, a missing asset and a stale index, all of which are invisible from the publishing side.

<!-- chunk: live.cadence | tags: release,cadence,automation -->

## Steady-state cadence

After launch, most of this should run without you. A workable shape:

| Cadence | What | Trigger |
| --- | --- | --- |
| **Daily** | A build to the open-testing track, tagged back to its commit | Scheduled |
| **Daily** | A TestFlight build to the external group | Scheduled, staggered from the above |
| **Nightly** | The full suite including tag-excluded tests | Scheduled |
| **Weekly** | Dependency updates; endpoint canary | Scheduled |
| **Per release** | Changelog entry, tag, staged promotion, desktop artifacts | A version tag |
| **Per release** | A fresh demo video if hardware flows changed | Manual — the one genuinely unautomatable step |
| **Quarterly** | Restore drill; capturing-proxy session; known-gaps review | Manual |

> **[RULE]**

> **No release-process optimisation may introduce a step that needs a human.** The value of the pipeline is that a tag produces artifacts on every channel without supervision. A "quick manual check" added to the middle of it becomes the bottleneck for every future release, and it will be skipped under time pressure — which is worse than not having it. If a check matters, automate it or move it before the tag.

> **[WHY]**

> Three reasons. It proves the entire release pipeline still works — signing certificates expire, tokens are revoked, runner images change under you, and you want to discover that on a Tuesday rather than during a launch. It keeps the version-code sequence moving so there is never a gap to reason about. And it means "ship a fix" is an ordinary operation the pipeline performs nightly, not an exceptional one nobody has done in three months.

#### Sources for this page

- Both projects' release workflows and their go-live documentation: the staged-rollout percentages and hold times, the promotion-source-track default change, the daily build-and-tag cadence, and the changelog gate on tag-triggered releases.
- One project's owner-blocked-items list — the console steps with no API, the foreground-service declaration with its video requirement, and the catalog submission running in parallel — and its irreplaceable-material inventory.
- The other project's per-channel notes: the App Store Connect app record that must pre-exist, the account-holder-only certificate, and the honest-degradation naming of unsigned desktop artifacts.
- Post-mortems supplying the traps: the quoted release notes, the silently-ignored store graphic, the metadata sync that deletes remote images, and the stale testing-channel build.
