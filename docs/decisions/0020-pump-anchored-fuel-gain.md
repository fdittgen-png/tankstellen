<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0020: The pump is the truth — a learned fuel gain anchors OBD2 consumption on full-tank fills

**Status:** Accepted
**Date:** 2026-08-30
**Issue:** #3887 (Epic #3886)
**Related:** #815 (η_v learner, superseded), #3645 (fill-anchored consumption), #3616 (tank report), #1423 (broken-MAP belief), #3888 (E85 trims)

## Context

OBD2 fuel consumption on a car without a fuel-rate PID is an estimate:
air mass from MAP/RPM/IAT (or MAF) divided by an assumed AFR, times an
assumed volumetric efficiency, times the ECU's fuel trims. Every one of
those inputs can be off. The only physically true figure the app ever
gets is the refuel: between two FULL fills the litres pumped are what
the car burned, and the odometer delta is how far it drove.

The #815 learner tried to close the loop through η_v, but it compared
Σ recorded litres against the WHOLE tank's litres — with no correction
for how much of the tank was actually recorded and no full-tank gating.
At 81 % recording coverage it concluded the recordings ran 19 % *under*
the pump while they ran 37 % *over*; the two mechanisms fought and the
gap never closed. It also only touched the speed-density branch (a MAF
car got nothing) and was clamped to a physical η_v range that cannot
express a 40 % correction.

## Decision

1. **One knob, learned from the pump.** `VehicleProfile.pumpGain`
   multiplies every ESTIMATED fuel-rate branch (speed-density and MAF)
   in the live snapshot chain and the pull-mode reader. ECU-reported
   fuel (PID 5E / 9D) is never scaled. η_v goes back to its catalog /
   manual value and is no longer mutated.
2. **Full-to-full windows, compared per km.** `PumpGainLearner` runs
   when a full fill closes a tank window (the same windows the tank
   report uses): `target = pumpLPer100Km / rawRecordedLPer100Km` over
   the recordings linked to the window. Per-km comparison makes
   coverage cancel; coverage below 60 % or under 40 recorded km is
   refused, as is a target more than 3× outside the [0.5, 2.0] bounds.
3. **Trips stamp the gain they carried.** `TripSummary.pumpGainApplied`
   lets the learner divide the stored litres back to the raw estimator
   output, so consecutive windows converge instead of compounding.
4. **Sample-dependent blend.** The first window sets the gain outright,
   the second weighs 0.5, later ones 0.4. The tank report's calibration
   line becomes the *residual* after the gain and should trend to 0.
5. **Ethanol fuels skip the trim step** (#3888): dividing by the E85 AFR
   already contains the enrichment the ECU expresses as +25 % LTFT.

## Consequences

- The recorded L/100 km converges on the pump within one or two full
  tanks, for MAF and speed-density cars alike; the broken-MAP belief
  keeps its plausibility input (`proposedEta = η_v × target`).
- Historic trips are not rewritten; their stored figures stay what the
  driver saw, and the tank report shows the gap for those windows.
- The field case (6.4 L/100 km pumped, 10.5 recorded, 81 % coverage)
  yields gain 0.61 on the first window.

## Alternatives Considered

- **Fix the η_v learner's coverage maths.** Rejected: η_v is physical
  and bounded, cannot reach a MAF car, and the AFR/trim errors it would
  absorb are not volumetric-efficiency errors.
- **Rewrite stored trips to the new gain.** Rejected: the report must
  keep showing what was recorded; the per-trip stamp gives the learner
  the raw figure without touching history.
