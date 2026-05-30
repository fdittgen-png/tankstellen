<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0012: GPS-only live consumption estimator

**Status:** Accepted
**Date:** 2026-05-30
**Issue:** #2386
**Parent Epic:** #2385

## Context

When a trajet records from GPS only (no OBD2 dongle, or a dropout), the
post-trip GPS calibration matrix (ADR 0010, #2056) can impute a whole-trip
**average** L/100 km after the trip ends — but it cannot produce a *live*
figure while the user is driving. The recording screen, the PiP overlay,
and the live banner therefore show a blank consumption read-out for the
entire GPS-only trip, which reads as a missing feature next to the rich
OBD2 live read-out.

Epic #2385 sets out to surface a **live** GPS-only consumption estimate.
The post-trip matrix is the wrong tool for this: it is a per-vehicle linear
fit over *aggregate* driving-style features (idle / accel / high-speed
shares) and is only meaningful once the whole trajet's feature totals
exist. We need a model that consumes one GPS sample per ~1 Hz tick and
emits an instantaneous figure that converges over the trip.

Two families of live model were on the table:

1. A **physics road-load model** — derive tractive power from speed +
   acceleration + vehicle mass/drag/rolling-resistance, convert to fuel via
   fuel-energy + driveline efficiency, anchored to OBD2 ground truth with a
   single per-vehicle scale factor.
2. A **fuzzy / driving-style classifier** — bucket the live signal into
   eco/normal/aggressive style bands and map each band to a consumption
   multiplier off the WLTP baseline.

The forces at play: GPS gives us speed (and noisy altitude) but no engine
signal; the figure must be live and per-tick; it must degrade gracefully
with no calibration data; and it must be able to *learn* from the OBD2
ground truth we already collect on dongle trips (the #2388 `physicsScale`).

## Decision

**GPS-only live consumption is a calibrated physics road-load model
anchored to the vehicle baseline, calibrated from OBD2 ground truth via a
single per-vehicle `physicsScale`. Fuzzy / driving-style classification is
at most an optional modifier layered on top — it is NOT the primary
model.**

### The primary model — physics road-load

Implemented as the pure-domain `GpsLiveFuelEstimator` (#2387). For each
~1 Hz tick the tractive force at the wheels is

```
F = Crr·m·g                    (rolling resistance)
  + ½·ρ·Cd·A·v²                (aerodynamic drag, ρ = 1.225 kg/m³)
  + m·a                        (inertia — a is the low-passed accel)
  + m·g·grade                  (only when grade is confident)
```

Power `P = max(0, F·v)` (no negative-power credit — coasting/braking burns
idle fuel, it does not put fuel back in the tank). Fuel mass-flow combines
tractive burn with a constant idle draw, and the instantaneous figure is

```
L/100 km = ṁ / v · 1e5 · physicsScale
```

valid only while moving (`v > 0.5 m/s`); at a standstill the figure is
undefined (null) and only idle litres accumulate.

### Anchoring & calibration — OBD2 is the ground truth

- A single per-vehicle `GpsCalibrationMatrix.physicsScale` (#2388,
  default 1.0) multiplies the raw physics output. This is the *one* knob
  the OBD2-anchored calibration tunes: when a vehicle has been driven with
  a dongle, the measured fuel-rate ground truth fits `physicsScale` so the
  physics output matches reality, then that scale carries over to the
  vehicle's GPS-only trips.
- The body-load defaults (mass / Cd / frontal area / Crr) and the fuel-
  energy / driveline params come from a vehicle-class table keyed on curb
  weight + fuel type, so the model produces a plausible figure even with
  **zero** calibration history (`physicsScale` 1.0).

### Fuzzy / driving-style is at most a modifier — not the model

A driving-style classifier could, later, nudge the figure (e.g. a small
multiplier for sustained aggressive throttle that the pure road-load model
under-counts). If it is ever added it sits *downstream* of the physics
output as an optional correction, never as the source figure. The physics
model — anchored to OBD2 — stays the primary, auditable basis. This keeps
the model explainable (every term is a physical quantity), keeps the
calibration story single-knob, and avoids a black-box style classifier
becoming load-bearing for a number we surface to users.

### Robustness

- Acceleration is the finite difference of speed run through a **3-sample
  moving-average low-pass** — mandatory to stop GPS speed jitter from
  injecting phantom inertial spikes.
- The grade term is gated off unless the grade is confident; raw GPS
  altitude is too noisy to feed blindly.
- Both the instant and running-average figures are clamped to the same
  `[0.5, 30.0]` L/100 km plausibility band the post-trip estimator uses.

### Surfacing (deferred)

The live estimate is emitted into the recording pipeline now (#2389, the
nullable `TripLiveReading.gpsEstimatedLPer100Km`) but its **display** is
deferred. When surfaced, the figure carries a leading `~` to mark it as an
estimate (not a measurement) plus a maturity / confidence signal — the
display + confidence work lands in #2391 and #2393; the PiP wiring in
#2390. On OBD2 trips the real measured value remains the source of truth
and the estimate field stays null.

## Consequences

### Positive

- GPS-only users get a live consumption read-out that was previously blank,
  matching the OBD2 live experience.
- The model is explainable end-to-end: every term is a physical quantity,
  and calibration is a single human-readable scale factor.
- One calibration knob (`physicsScale`) means OBD2 ground truth transfers
  cleanly to GPS-only trips with no separate live-model fit.
- Works with zero calibration history via the class-default table, then
  improves as `physicsScale` converges.

### Negative

- A road-load model needs reasonable mass / Cd / frontal-area defaults; the
  curb-weight class table is a coarse approximation for unusual bodies
  (vans, heavily-loaded vehicles). The `physicsScale` anchor absorbs the
  systematic part of this error once OBD2 data exists.
- The model is combustion-oriented (fuel-energy + idle draw); EVs are out
  of scope here and keep their own path, consistent with ADR 0010.
- Without OBD2 history the figure is an un-anchored physics estimate — hence
  the `~` prefix and confidence signal (#2391/#2393) so users read it as an
  estimate, not a measurement.

## Alternatives Considered

- **Fuzzy / driving-style classifier as the primary model.** Rejected as
  the primary: a style-band → multiplier mapping is a black box that is
  hard to anchor to OBD2 ground truth and hard to explain, and it discards
  the directly-usable physical signal (speed, accel, mass). It survives
  only as an optional downstream modifier.
- **Reuse the post-trip GPS calibration matrix (ADR 0010) live.** Rejected:
  the matrix is a fit over *aggregate* whole-trajet feature shares; it has
  no meaningful per-tick output and cannot converge live within a single
  trip.
- **Per-tick least-squares / Kalman fit of the road-load coefficients.**
  Rejected for v1: GPS gives no independent fuel signal mid-trip to fit
  against, so there is nothing to regress on live. The single-scale OBD2
  anchor is simpler and is the only signal we actually have ground truth
  for. Revisit if richer live signals appear.
- **Hard-coded WLTP × speed-bucket lookup.** Rejected: ignores load,
  acceleration, mass and grade entirely — the whole point of a live figure
  is that it responds to how the car is being driven right now.
