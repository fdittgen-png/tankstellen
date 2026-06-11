# Changelog

All notable changes to this project will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/).

Discipline (#3177): keep an `[Unreleased]` section at the top; every
user-visible change lands there with its PR. Cutting a release means
renaming `[Unreleased]` to `[X.Y.Z] - date (Build N)` — the Play deploy
workflow refuses to ship a version that has no entry here. Release and
beta builds are tagged `vX.Y.Z+BUILD` by the workflows at dispatch, so an
About-screen build number always maps back to a commit.

## [Unreleased]

### Added

- Weekly endpoint-canary CI that live-probes every country service's
  endpoint and tracks outages in a single issue, so a silent endpoint
  death is caught in days instead of months.

### Fixed

- South Korea: searches that the live OPINET API can never satisfy now
  surface a clear, classified error instead of a silently empty map
  (the full coordinate fix is tracked separately).

## [6.0.0] - 2026-06-07 (Build 5133)

First public production release.

### Added

- Engine-power-aware driving/eco scoring — low-power cars are scored proportionally for hard acceleration, with a per-vehicle power field (auto-filled from the catalogue, overridable).
- Route/itinerary map now shows the fuel stations along your trip with the route line.

### Fixed

- OBD2 reliability overhaul: reliable multi-adapter connection (BLE + Classic), automatic reconnection when the link drops, transport-aware connect (Classic adapters no longer waste time on a doomed BLE attempt), and robust `0100` protocol detection so live data (RPM/speed/fuel) actually flows.
- Driving analysis: no more phantom hard-brake/acceleration penalties from GPS noise; combustion-health magnitude corrected; trip distance no longer over-counted on GPS-only trips.

### Changed

- Unified, faster station-map rendering across all map views.

## [5.0.0] - 2026-05-03 (Build 5132)

First public open-testing release on Google Play (backfilled from the
commit log per #3177 — the 5.0.0 line ran builds 5000-5132 between
2026-04-15 and 2026-05-03; per-sideload build numbers below 5132 were
dev-device builds and are not individually listed).

### Added

- Hands-free trip logbook: automatic OBD2 trip recording (auto start/stop
  via a native Android bridge), OBD2 speed source, stale-trip recovery,
  and per-vehicle adapter pairing (incl. vLinker FS Bluetooth Classic).
- Driving insights: composite driving score, throttle/RPM histogram,
  engine-load sparkline, cold-start surcharge, gear-inference coaching,
  monthly insights, and real-time eco-coaching haptics.
- Consumption tracker upgrades: tank-level indicator, fuel cost on trip
  detail, trip-vs-pump reconciliation with correction fill-ups,
  full-tank toggle, and PNG trip sharing.
- Unified refuel search: fuel stations and EV charging in one result list
  with filter chips.
- Price alerts deep-link straight to the cheapest station; predictive
  price-drop widget nudges.
- Eco-routing (OSRM) with savings preview and cross-border search banner.
- Vehicle catalogue integration: auto-read VIN over OBD2, reference-
  catalog vehicle profiles, per-vehicle aggregates.
- Achievements and badges with a profile opt-out toggle.
- Full backup: XML-in-ZIP export with a published schema.
- Predictive maintenance hints from OBD2 trend analysis.
- Loyalty pilot: per-card discount overlay for fuel-club brands.
- Daily open-testing release pipeline (18:00 Paris).

### Fixed

- OBD2 silent-failure detection (adapter-not-responding feedback) and
  background-isolate error reporting with foreground replay.
