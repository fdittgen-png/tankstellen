<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0019: Settings information architecture — a two-level topic tree with one home per parameter

**Status:** Accepted

**Date:** 2026-08-30

**Issue:** #3884 (Epic #3881)

## Context

The Settings root (`ProfileScreen`) had grown by accretion into a flat
list of eight labelled groups whose blocks were all `_FoldableSection`s,
collapsed by default. The 2026-08-30 inventory found:

- **Up to four nesting levels before a control**: Settings → "Features &
  usage" → "Consumption" foldable → "Coaching while driving" → "Voice
  Announcements" → three sliders. Nothing at the root told the user what
  was inside a foldable, so discovery was trial and error.
- **Duplicate homes** for the same parameter: "Delete all" in Storage &
  cache *and* in the Privacy Dashboard; the show-fuel / show-EV switches
  in Feature management *and* in the profile edit sheet; the trip-sync
  consent in TankSync while its four sibling consents sat in Privacy.
  Two homes means two places to drift and two places to explain.
- **Orphans**: the radar auto-pin switch was reachable only from a help
  sheet opened by long-pressing the radar pin; backup/restore only from
  the Consumption overflow menu; three persisted `UserProfile`
  parameters (`routeSearchCriterion`, `routeSearchTopNPerSamplePoint`,
  `hybridFuelChoice`) had no UI at all.
- **Scope was invisible**: the widget colour/variant persist per profile
  but were labelled "applies to all widgets"; nothing distinguished
  per-profile, per-vehicle and app-wide settings.
- **Preset foot-gun**: the use-mode bundles are exhaustive, so applying
  Basic/Medium/Full silently switched OFF five default-on features
  (`fuelCalculator`, `carbonDashboard`, `paymentQrScan`,
  `communityPriceReports`, `addFillUpOcrReceipt`).
- Four feature labels fell back to English manifest strings and the
  Location section carried two hard-coded English strings — both
  violations of HARD RULE #1 hidden behind the foldables.

## Decision

1. **Two levels, no foldables at the root.** The root is a scannable
   list of twelve *topic tiles* — icon, title, one-line subtitle naming
   what is inside — plus a search field that filters tiles by title,
   subtitle and a per-topic keyword list. Each tile pushes a dedicated
   screen (`/settings/<topic>`, registered in `profile_routes.dart`)
   whose body hosts the **existing** section widgets expanded under
   plain `SectionHeader`s. The widgets were moved and re-hosted, not
   rewritten. Topic order is frequency-of-use first:
   Profiles & region · Vehicles & OBD2 · Driving & consumption ·
   Prices & alerts · Units & display · Features & use mode · Data
   sources & location · Sync & account (gated on `Feature.tankSync`) ·
   Privacy & data · Backup & restore · Advanced & developer (gated on the
   PAT/debug flag) · About.
2. **One home per parameter.** Every persisted parameter has exactly one
   editable surface; every other mention is a cross-link (`ListTile` with
   a chevron), never a second control. Concretely: Storage & cache loses
   its "Delete all" (the Privacy Dashboard owns erasure; a one-line hint
   + link remains); the profile sheet loses the show-fuel/show-EV
   switches (a link to Features & use mode remains); the trip-sync
   consent returns to Privacy & data next to the Cloud Sync master it
   depends on (TankSync keeps a cross-link); the voice-announcement
   sliders move from the driving section to Prices & alerts; the radar
   auto-pin switch and the active profile's radar card get a proper
   screen under Driving & consumption; backup/restore get their own
   topic screen and the export flow is extracted into a shared
   `BackupExportFlow` that both the overflow menu and the screen call.
3. **Scope is labelled.** A `ScopeBadge` ("This profile" / "All
   profiles" / "This vehicle") appears on tiles and section headers
   whose scope is not global. Global rows carry no badge, so the badge
   stays a signal.
4. **Presets keep default-on features on.** The five default-on
   features are added to the bundles where they apply (Basic: the three
   prerequisite-free price tools; Medium and Full: those plus the carbon
   dashboard and receipt OCR, which need fill-up data).
5. **The three orphan `UserProfile` parameters get controls** in the
   profile edit sheet: a segmented cheapest / nearest-to-route criterion
   and a 3–20 candidates slider in the Route planning card, and a
   hybrid-fuel dropdown in the Vehicle card shown only when the default
   vehicle is multi-fuel.
6. **Read-only rows are honest about it.** Units & display shows the
   distance unit derived from the active profile's country as a
   display-only row ("From the active profile's country"); no unit
   conversion is built here (#3883 adds the consumption-unit row).

## Consequences

- Every parameter is at most two taps from the root; the deepest path
  (voice-announcement sliders) drops from five levels to two.
- Thirteen new routes (`RoutePaths.settings*`) and thirteen small screen
  files (each well under the 400-line cap) replace one 395-line root.
- The `profile → driving` and `profile → widget` cross-feature edges hit
  zero (the new screens import the `api.dart` barrels), breaking two
  bidirectional cycles in the feature-boundary ratchet; `profile →
  feature_management` drops from 52 to 47. `search/api.dart` gains one
  export (`radar_pin_provider`) so the radar screen can host the auto-pin
  switch without reaching into the search feature's internals.
- Existing tests that pumped `ProfileScreen` to reach a section now pump
  the topic screen that hosts it (Feature management → Features & use
  mode, Theme tile → Units & display, voice sliders → their own tile
  test). A per-screen widget test pins that each topic hosts its
  sections expanded (no `ExpansionTile`), the root renders every topic
  tile, and the search filter works.
- Applying a preset no longer disables the calculator, scan-to-pay,
  community reports, the carbon dashboard or receipt OCR; the pinned
  "byte-for-byte" preset test was updated deliberately.
- Seven ARB keys that only the removed duplicates referenced were deleted
  (the no-unused-keys ratchet enforces this); `widgetDefaultsApplyToAllHint`
  was replaced by `widgetDefaultsThisProfileHint`.
- Follow-ups: #3883 inserts the "Live consumption readout" tile in the
  marked slot at the top of Driving & consumption and the
  consumption-unit row under Units & display; the wiki settings pages
  (7 languages) need the new tree.

## Alternatives Considered

- **Keep the flat root, expand the foldables by default.** Fixes depth
  but not scannability: 30+ controls on one scroll with no map of what
  is where; search would still have nothing to filter.
- **One giant searchable list of every control (à la iOS Settings
  search).** Requires each control to be extractable from its section
  widget; the sections are self-contained `ConsumerWidget`s that own
  their providers, so this means rewriting every section. Filtering
  *tiles* by keywords gets most of the benefit for a fraction of the
  surface.
- **Three levels (Settings → group → topic → screen).** The eight
  existing groups map poorly onto what users look for ("where is the
  radar pin?"); twelve flat topics with honest subtitles are scannable
  without an intermediate level.
- **Keep both homes for the show-fuel/EV switches "for convenience".**
  Rejected: the two surfaces already disagreed once (#1373 phase 3c
  migrated the source of truth to the central flags); a link is as
  convenient and cannot drift.
- **Make presets additive instead of exhaustive.** Would fix the
  default-on foot-gun without touching the bundles, but breaks
  `detectProfileFromFlags` (exact-match detection is what lets the
  Settings selector show which preset is active) and the idempotent
  re-apply contract. Adding the five features to the bundles is the
  minimal, explicit fix.
