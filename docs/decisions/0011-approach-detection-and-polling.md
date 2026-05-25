<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0011: Approach-detection + speed-aware polling scheduler

**Status:** Accepted
**Date:** 2026-05-25
**Issue:** #2066
**Parent Epic:** #2065

## Context

The in-trip PiP overlay redesign (#2068) leads with a huge L/100 km
figure. When the driver approaches a fuel station, the overlay grows
and flips to a huge **price** figure for the user's fuel type.

We need a reusable service that, given the driver's live GPS stream,
emits **approach events** (entered radius / left radius / station
target changed) for the currently-relevant fuel station.

This ADR fixes:

- The bbox query shape that feeds the existing
  `StationServiceChain` (no new persistent subscription).
- The speed-adaptive polling formula + its bounds.
- The state-machine of the detector.
- Where the service lives so it can be re-used outside the
  trip-recording flow (future).

## Decision

### Architecture — standalone `ApproachDetector` service

Lives at `lib/core/services/approach_detector.dart`. **NOT** in the
`consumption` feature dir, because:

1. It will be reused (future) by the route-planning ETA panel +
   the favourites quick-glance overlay.
2. It depends only on GPS + the search chain — no consumption
   domain entities.

API:

```dart
class ApproachDetector {
  ApproachDetector({
    required Ref ref,
    required Stream<Position> gpsStream,
    required ApproachDetectorConfig config,
  });

  /// Emits the current approach state. Compact value object — the
  /// overlay watches this directly via `riverpod_annotation`.
  Stream<ApproachState> get state;

  Future<void> dispose();
}

class ApproachDetectorConfig {
  /// Geo-fence radius in metres. From `profile.approachRadiusKm × 1000`.
  final int radiusMeters;
  /// `nearest` locks onto the first station the driver crosses the
  /// radius for; `cheapestInRadius` re-evaluates every poll.
  final ApproachPriceMode priceMode;
  /// Floor for the poll cadence. From `profile.approachMinPollSeconds`.
  /// Clamped to [1, 10] s by the profile UI; runtime double-checks.
  final int minPollSeconds;
  /// Ceiling for the poll cadence — never longer than this even at
  /// 0 m/s. Hard-coded to 30 s.
  static const int maxPollSeconds = 30;
}

sealed class ApproachState {}
class ApproachIdle extends ApproachState {} // no GPS or out of range
class ApproachPolling extends ApproachState {
  final Position gps;
  final Duration nextPollIn;
}
class ApproachInRadius extends ApproachState {
  final Station station;
  final double distanceMeters;
}
class ApproachLeaving extends ApproachState { // grace period after exit
  final Station lastStation;
}
```

### Polling formula

```
pollInterval = clamp(
  0.2 × radiusMeters / speedMps,
  minPollSeconds,
  maxPollSeconds,
)
```

The `0.2 ×` factor ensures we refresh while the driver traverses
20 % of the radius — so they get the price update with at least 4×
margin before reaching the station.

Worked examples (radius = 1 000 m, minPoll = 5 s):

| Speed | Raw | Clamped |
|---|---|---|
| 130 km/h ≈ 36 m/s | 5.5 s | 5.5 s |
| 90 km/h ≈ 25 m/s | 8.0 s | 8.0 s |
| 50 km/h ≈ 14 m/s | 14.4 s | 14.4 s |
| 30 km/h ≈ 8 m/s | 24 s | 24 s |
| 10 km/h ≈ 3 m/s | 67 s | **30 s** (ceiling) |
| 0 m/s | ∞ | **30 s** (ceiling) |

At highway speed the detector polls every ~5–8 s, never tighter
than the profile floor. Idle / urban crawl plateaus at 30 s. Quota
ceiling: ~120 polls/hour at sustained highway speed (< 2/min).

Speed source: average of the last 3 GPS samples (smooths out the
0-m/s read at a red light).

### Bbox query shape

Re-uses `ref.read(searchChainProvider.notifier).search(...)` with a
synthetic `SearchCriteria` built per-poll:

- `lat`/`lng` = current GPS position.
- `radiusKm` = `config.radiusMeters / 1000.0`.
- `fuelType` = vehicle's fuel if set, else profile's preferred
  (see #2065 Epic).
- `country` = current GPS-derived country.

The search chain's existing cache layer (5-min TTL) absorbs
stationary polling.

### State machine

```
   ┌────────┐  no gps         ┌────────┐
   │ Idle   │ ──────────────► │ Idle   │
   └────────┘                 └────────┘
       │ gps available
       ▼
   ┌─────────┐  no station in radius  ┌─────────┐
   │ Polling │ ───────────────────────│ Polling │
   └─────────┘                        └─────────┘
       │ station in radius                ▲
       ▼                                  │ no station for > graceSeconds
   ┌────────────┐  station leaves   ┌──────────┐
   │ InRadius   │ ─────────────────▶│ Leaving  │
   └────────────┘                   └──────────┘
       │ user passes target             │ station re-enters within grace
       │ (distance > radius)            ▼
       └─────────────────────────► (back to InRadius if same id)
```

**Grace period** for `Leaving → Polling`: 5 seconds. Prevents UI
flicker when the GPS sample stutters across the radius boundary.

### Price-mode handling

- `nearest`: on first `InRadius` entry, lock `station.id`. Stay in
  `InRadius` with this station until distance > radius, even if a
  cheaper station enters the bbox.
- `cheapestInRadius`: every poll, re-evaluate `station` = `min by
  (priceForVehicleFuel ?? double.infinity)` across all stations
  inside the radius. The UI sees the `Station` change as a state
  transition.

### Offline behaviour

If the search chain returns `ServiceChainExhaustedException`, the
detector stays in `Polling` (last-known-good `station` if any) and
emits a `lastError` field on `ApproachState`. The overlay (#D)
falls back to the non-approach big-L/100-km mode silently.

### Reusability

`ApproachDetector` takes its GPS stream as a constructor param. The
trip-recording controller passes `Geolocator.getPositionStream()`;
future callers (route-planning, favourites) pass whatever stream
they own. No coupling to recording state.

### What this ADR does NOT decide

- The overlay UI itself — that's #2068 (default L/100 km) and #D
  (approach big-price flip). This ADR only delivers data.
- Hybrid OBD2 + GPS sample fusion — separate concern (Epic #2055).
- Caching layer — re-uses the existing search-chain cache.

## Consequences

### Positive

- Single source of truth for the "am I near a fuel station?" signal.
- Speed-adaptive polling — high accuracy at highway speed, low
  battery / quota cost at rest.
- Standalone service → future route-planning + favourites can
  subscribe without recreating logic.
- Falls back gracefully on offline.

### Negative

- Adds a per-trip background subscription (extra GPS listener +
  search-chain polls). Battery cost characterised at ~120
  polls/hour worst case — measured ~0.4 % battery/hour in
  back-of-envelope calc, will be re-measured in #D's acceptance.
- The 5-second grace on `Leaving` adds a UI lag when the driver
  intentionally passes a station without stopping. Worth it to
  avoid flicker.

## Alternatives Considered

- **Pre-fetch wide bbox at trip start.** Rejected: blind to far
  travel beyond the pre-fetched extent; complicates the offline
  story.
- **Persistent subscription via WebSocket / push.** Rejected: no
  upstream supports it (Prix-Carburants, Tankerkönig, etc. are all
  pull-only).
- **Fixed 10s polling.** Rejected: wastes quota at idle, too slow
  on highway. Speed-adaptive nails both.
- **Geo-fence via OS-level APIs.** Rejected: requires registering
  every station as a fence, which doesn't scale (millions of
  stations) and would need re-registration whenever GPS drifts.

## Reshapes downstream

This ADR fixes the contract for:

- #D `feat(consumption): PiP grows + flips to huge price when
  within approach radius` — consumes `ApproachState.InRadius`.
- #E `feat(core): standalone ApproachDetector service` — implements
  this contract.
- #F `test(consumption): integration coverage for the approach
  state machine + overlay transitions`.
