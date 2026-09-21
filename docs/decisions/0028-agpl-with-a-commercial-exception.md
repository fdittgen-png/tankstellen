<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: AGPL-3.0-or-later
-->

# ADR 0028: AGPL-3.0 with a commercial exception, and the name as a mark

**Status:** Accepted
**Date:** 2026-09-20
**Supersedes:** [ADR 0007](0007-mit-license-choice.md)

## Context

The owner wants commercial businesses — fleet operators above all — to
pay for what associations, collectives and individuals get for free, and
wants Sparkilo to stay in F-Droid's main repository. The sibling project
DesKilo made the same decision on the same day; its
[ADR 0031](https://github.com/fdittgen-png/deskilo/blob/main/docs/decisions/0031-agpl-with-a-commercial-exception.md)
is the model.

Those two wishes look incompatible and are not.

**A licence that forbids commercial use is not free software.** It fails
OSD #6 ("No Discrimination Against Fields of Endeavor") and FSF freedom
0. `fdroid lint` validates a recipe's `License:` field against the free
list, so the listing would close. The PolyForm Noncommercial, Commons
Clause and BUSL family are all source-available, none are FOSS, and none
are admitted to F-Droid.

**The fleet feature's users ARE commercial operators.** Haulage firms,
service fleets and company-car pools are nearly all for-profit. A
non-commercial clause would not exclude a distant corporation; it would
exclude the actual adopters, and it would make a volunteer association
that charges a mileage contribution ask a lawyer whether it qualifies.
"Non-commercial" is the hardest word in licensing to define, and it
would have to be defined against our own users.

**Nothing published can be recalled.** Every release to date — every
store build, every F-Droid build, the whole history — is MIT, which
grants use, modification and closed redistribution with no conditions at
all. Anyone may fork the last MIT commit and carry on for ever. New
terms bind only code written after them, and the value of the change
grows with distance from that commit. Stating this here is part of the
decision; discovering it later would not be.

**ADR 0007 chose MIT deliberately**, for "maximum adoption", and
accepted "no protection against proprietary forks" as the trade-off. It
named that exact risk and took it. This reverses that choice knowingly,
because the goal has changed from "impose nothing" to "a company either
shares its changes or pays".

## Decision

1. **AGPL-3.0-or-later is the licence of the whole repository.** A
   commercial operator may still run Sparkilo — but if it modifies the
   app or the server functions and offers them to its drivers over a
   network, §13 obliges it to publish those changes. That is the whole
   lever: **publish, or buy an exception.**

   A first draft scoped this to the fleet subtree alone. That was
   rejected on reflection: AGPL is viral across a combined work, so the
   shipped binary would have been AGPL either way, and the only thing
   subtree-scoping bought was a per-file "which licence is this?"
   question for every contributor and reviewer, in exchange for nothing.

2. **A commercial licence**
   ([`COMMERCIAL-LICENCE.md`](../../COMMERCIAL-LICENCE.md)) sells exactly
   that exception, for one legal entity. Associations, collectives,
   public bodies, schools and individuals never need it, and neither
   does a company that runs Sparkilo as it ships or publishes its
   changes.

3. **Two additional permissions under AGPL §7**, both in
   [`LICENSE-EXCEPTIONS.md`](../../LICENSE-EXCEPTIONS.md), both possible
   only because the owner is sole copyright holder:

   - **App stores.** GPL-family terms conflict with Apple's device-count
     restrictions — this is what removed VLC from the App Store in 2011
     — and Sparkilo ships TestFlight and App Store builds. Without this
     clause the iOS leg dies, so it is a condition of the change, not an
     afterthought.
   - **Named proprietary libraries.** The Play flavour links
     `com.google.android.gms`, `com.google.mlkit` and
     `com.google.android.play`, which arrive through
     `geolocator_android`, `google_mlkit_text_recognition` and
     `in_app_review`. AGPL plus non-free linked libraries is the classic
     incompatibility; without this permission the Play artifact cannot
     be distributed. DesKilo needed no equivalent — this one is
     Sparkilo's alone. The components are named individually on purpose:
     a blanket "any proprietary library" clause would give away the
     thing §13 protects.

4. **The name is a mark.** "Sparkilo" and its logo are asserted as
   trademarks ([`TRADEMARK.md`](../../TRADEMARK.md)), so a fork must
   rename. This is the cheapest protection of the set — it costs no
   licence complexity, it keeps the F-Droid submission alive, and it is
   often what people actually mean when they say "limit commercial use".

## Consequences

- **The dependency rule of ADR 0007 reverses.** It said "GPL-licensed
  dependencies are prohibited" to protect an MIT outbound licence. The
  constraint is now AGPL-compatibility *outbound*, which MIT, BSD and
  Apache-2.0 all satisfy — so the existing tree already complies. What
  changes is that it becomes a standing release gate rather than a
  one-off check.

- **F-Droid: the two recipes say different things, and both are correct.**
  This ADR first claimed the recipe was a release blocker pending an audit
  that did not yet exist. That was wrong, and the correction is recorded
  rather than quietly edited away: the audit **already existed**.

  `scripts/audit_no_gms.sh` resolves `fdroidReleaseRuntimeClasspath` — the
  release graph, not debug — then audits the release APK's dex for class
  definitions and, in strict mode on a release-named artifact, for dangling
  references at F-Droid's own `check-apk` bar. `fdroid.yml` runs all three
  layers on **every pull request**. The belief that it checked only the
  debug graph came from a note that #3473/#3480 had since made obsolete.

  This very relicense proved it. The `build-fdroid` job on the PR that
  merged ADR 0028 reported:

  ```
  INFO [strict]: 0 dangling GMS/ML Kit/Play-Core/Sentry type reference(s)
  OK [strict]: zero GMS/ML Kit/Play-Core/Sentry definitions AND references
  ==> AUDIT PASSED: fdroid flavor ships no GMS/ML Kit/Play-Core/Sentry
  ```

  So the libre flavour needs no §7 permission and never did. What remains is
  a bookkeeping rule, enforced by
  `test/features/fdroid/fdroid_recipe_licence_matches_pin_test.dart`:

  * `fdroid/metadata/…` — the **self-hosted** repo ships a prebuilt APK
    built from current master, and the next `v*` tag builds from an AGPL
    master. It says **AGPL-3.0-or-later**.
  * `metadata/…` — the source of the official **fdroiddata** recipe. Its
    `Builds:` entries pin `506fcf502` (v6.0.5, 2026-08-10), which is MIT.
    The field describes *that commit*, so **MIT is the correct value**, and
    changing it today would misstate the build F-Droid actually produces.
    It becomes AGPL in the same commit that moves the pin — the test fails
    until it does.

  The rule generalises: a claim in an F-Droid recipe is a claim about the
  pinned commit, never about HEAD.

- **Play and TestFlight are unaffected**, given clause 3.

- **Contributions must be AGPL**, or the dual licence cannot be offered:
  a contributor's copyright is not the maintainer's to sell.
  [`CONTRIBUTING.md`](../../CONTRIBUTING.md) says so and asks for a DCO
  sign-off.

- **The sweep is machine-checked.** 4420 SPDX headers changed in one
  commit, and `test/lint/spdx_headers_test.dart` asserts both that every
  source file declares a licence and that it declares this one. A sweep
  at this scale is exactly the kind that finishes 99 % of the way and is
  believed to have finished; DesKilo's missed ten files and stayed wrong
  for two weeks because nothing checked.

## Alternatives Considered

- **Scoping the AGPL to the fleet subtree.** See clause 1.
- **A non-commercial licence.** See Context. It would have removed
  Sparkilo from F-Droid and excluded the feature's own users.
- **Saying "companies pay".** The terms say what they say: the trigger
  is modifying *and* network-serving *and* withholding the source. A
  haulage company that runs Sparkilo as it ships and manages its whole
  fleet with it owes nothing and never will. Writing anything stronger
  into the repository would have been a claim the licence does not
  support.
