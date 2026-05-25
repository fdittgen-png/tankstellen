<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0010: GPS driving-style calibration matrix

**Status:** Accepted
**Date:** 2026-05-25
**Issue:** #2056
**Parent Epic:** #2055

## Context

In Medium-profile mode (`obd2Optional` flag OFF), trajets are
recorded from GPS samples only. `TripSummary.fuelLitersConsumed` and
`avgLPer100Km` stay null because there's no fuel-rate signal — the
recording UI shows "—" for both, which reads as a broken feature.

We need a per-vehicle calibration that maps GPS-derivable
driving-style features (idle / accel / cruise / brake / high-speed
seconds) to an estimated L/100 km, and self-refines after every
fill-up so it converges toward the user's real-world consumption.

This is the **second** calibration matrix on `VehicleProfile`. The
existing OBD2 matrix (volumetric efficiency, fuel-rate trim, A/B/C
confidence tier from #2027) stays untouched and is used whenever
`obd2CoverageRatio ≥ 0.95` (full-coverage OBD2 trip). The GPS matrix
is used for `gpsOnly` (coverage = 0) and `hybrid` (0 < coverage < 0.95).

## Decision

### Feature set — lean 4-coefficient model (cold-start)

The matrix is a linear function

```
L/100 km = baseline
         + idle_cost      × (idle_seconds      / total_seconds)
         + high_speed_penalty × (high_speed_seconds / total_seconds)
         + accel_event_cost   × (accel_events       / distance_km)
```

with these four coefficients tracked per vehicle:

| Coefficient | Unit | Default (cold start) | Bounds |
|---|---|---|---|
| `baseline` | L/100 km | `vehicle.consumptionWltp` if set, else population median (6.5) | [3.0, 15.0] |
| `idleCost` | L/100 km per share-of-idle | 1.2 | [0.0, 5.0] |
| `highSpeedPenalty` | L/100 km per share-of-≥110-km/h | 2.0 | [0.0, 6.0] |
| `accelEventCost` | L/100 km per accel-event-per-km | 0.5 | [0.0, 3.0] |

GPS-derivable features that **don't** feed the lean model but ARE
captured (so the future 7-coef expansion is data-ready):

- `brakeEvents` — for regen / coasting proxy.
- `gradeClimbMeters`, `gradeDescentMeters` — from altitude delta.
- `cornerLoadIntegral` — heading-rate × speed²; reserved.

### Expand-on-demand to 7 coefficients

The matrix expands from 4 → 7 (adds `brakeEventCost`,
`gradeClimbCost`, `cornerLoadCost`) when **both** conditions are met
after a fill-up:

1. Maturity tier is still `cold` (see below).
2. Residual variance over the last 5 fill-ups > 1.5 (L/100 km)².

The expanded coefficients seed from population medians; the
re-fitting loop on subsequent fill-ups absorbs them.

### Cold-start seeding

- `baseline` = `vehicle.consumptionWltp` if non-null and in
  `[3.0, 15.0]`, else 6.5.
- Other coefficients = population medians listed above.
- Matrix starts in `cold` maturity until at least 3 fill-ups have
  contributed reconciliation samples.

### Update rule — closed-form least-squares (lean 4-coef path)

After each fill-up `f` that closes a window of GPS-only trajets
since the previous fill-up, the reconciler:

1. Sums per-trajet features → `Σidle/total`, `Σhigh/total`,
   `Σaccel/distance`, and `total_km`, `total_litres` (ground truth).
2. Builds the design row `[1, idle_share, high_share, accel_rate]`
   per trajet, target = trajet's share of `total_litres`.
3. Solves `Σ wᵢ ( yᵢ - xᵢᵀ β )² → min β` via the normal-equations
   form (4×4 matrix invert — tractable in pure Dart without a
   linear-algebra dep). Weight `wᵢ` = trajet distance ratio.
4. Clamps the resulting coefficients to the per-field bounds above.
5. Writes back via `VehicleProfile.copyWith(gpsCalibration: …)`.

The fit is **incremental** — each fill-up window adds N trajets to
the running design matrix; older trajets weight-decay by 0.9 per
window (capped at the most recent 10 fill-ups' worth).

### Maturity tier rules

Mirrors the A/B/C OBD2 tier from #2027.

| Tier | Predicate |
|---|---|
| `cold` (C, ±10 %) | Fewer than 3 fill-up reconciliations applied |
| `warming` (B, ±5 %) | 3–7 fill-ups AND residual variance ≤ 1.5 |
| `converged` (A, ±2 %) | ≥ 8 fill-ups AND residual variance ≤ 0.5 |

Residual variance = `mean( (predicted - actual)² )` over the last
5 fill-ups in L/100 km units.

### Hive schema

New type adapter `GpsCalibrationMatrixAdapter` registered as
typeId 47 (next free, see `lib/core/storage/hive_boxes.dart`).
Fields:

```dart
class GpsCalibrationMatrix {
  final double baseline;
  final double idleCost;
  final double highSpeedPenalty;
  final double accelEventCost;
  // Reserved for the 7-coef expansion (null until expanded):
  final double? brakeEventCost;
  final double? gradeClimbCost;
  final double? cornerLoadCost;
  // Reconciliation bookkeeping:
  final int fillUpReconciliationCount;
  final double residualVariance;
  final DateTime? lastReconciledAt;
}
```

Legacy `VehicleProfile` instances (created before #E lands) load
with `gpsCalibration: null`. The runtime uses `null` as a sentinel
for "needs cold-start init" and seeds on first use.

### Always-both recording contract (cross-references #2065)

The recording controller runs both pipelines in parallel during
every trajet, regardless of `obd2Optional`. At trip end:

1. Compute `obd2CoverageRatio = obd2SampleSeconds / totalSeconds`.
2. Pick the matrix:
   - `obd2CoverageRatio ≥ 0.95` → OBD2 matrix (existing #2027 path).
   - Else (0 ≤ ratio < 0.95) → GPS matrix.
3. `TripKind` = `gpsPlusObd2` if ratio ≥ 0.95, else `gpsOnly`.
   Hybrid trips classify as `gpsOnly` for matrix routing but
   preserve OBD2 segment data for the detail screen.

Threshold rationale: a 5 % gap allows for brief dropouts (BLE
hiccup, parked-car restart) without flipping the routing.

## Consequences

### Positive

- GPS-only users see real `Carburant utilisé` + `Moyenne` numbers
  post-trip instead of dashes.
- Self-calibrating: matrix improves with each fill-up.
- Maturity badge tells the user how much to trust the figure.
- Adaptive complexity (4 → 7 coef) keeps cold-start simple but
  refuses to leave accuracy on the table for picky cars.

### Negative

- New Hive type → migration risk for users with corrupted boxes.
  Mitigated by the null-sentinel cold-start path: an unparseable
  matrix just re-initialises from WLTP.
- Linear model is wrong on EVs (regen, kWh) — explicitly out of
  scope; EVs continue to use the existing EV path.
- Fill-up reconciliation requires *some* GPS trajets between
  fill-ups. Users who switch to OBD2 mid-tank fall back to the
  OBD2 matrix without GPS update — fine, intended.

## Alternatives Considered

- **Single matrix for OBD2 + GPS.** Rejected: OBD2 has direct
  fuel-rate ground truth; GPS doesn't. Merging conflates the
  certainty levels.
- **Per-trip coefficient (no per-vehicle persist).** Rejected:
  defeats the convergence story; users want stable predictions.
- **Bayesian / Kalman update rule.** Rejected for v1: closed-form
  LSQ is simpler to reason about and debug; the residual-variance
  maturity tier already captures uncertainty.
- **Hard-coded WLTP factor (multiplier).** Rejected: ignores
  driving style entirely; the whole point of the matrix is to
  surface style impact.

## Reshapes downstream

This ADR fixes the schema + algorithm contract for:

- #E `feat(vehicle): GpsCalibrationMatrix field + Hive migration`
- #F `feat(consumption): GPS-matrix fuel estimator + post-trip
  L/100 km imputation`
- #G `feat(consumption): refine GPS calibration matrix after each
  fill-up`
- #H `feat(consumption): GPS matrix maturity badge`
- #I `test(consumption): integration coverage`
