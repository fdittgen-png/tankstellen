# Vehicle abstraction

A guide for contributors who want to know how Tankstellen models a
vehicle, what subsystems read which fields, and where the
"is this Peugeot-only?" question gets answered.

> The framing "only Peugeot 107 supported" is misleading.

The architecture supports any vehicle: every engine parameter the
fuel-rate, calibration, and OBD-II layers consume is parameterised on
either `VehicleProfile` (per-instance, user-owned) or
`ReferenceVehicle` (shared catalog). Only **two** fallback constants
are 107-tuned, and they only fire when both `VehicleProfile` AND the
`ReferenceVehicle` catalog are empty — i.e. the user has neither
filled in the engine spec nor matched a catalog row. Everything else
is data-driven.

This guide walks through:

1. The myth vs reality — what is and isn't hardcoded.
2. `VehicleProfile` fields — the per-vehicle abstraction.
3. `ReferenceVehicle` catalog — the shared abstraction.
4. The fuel-rate fallback chain — per-PID dispatch.
5. The two hardcoded fallback constants — the only "Peugeot
   fingerprints" left.
6. Adaptive VE learning (#815) — how the per-vehicle calibration
   self-improves.
7. Adding a new vehicle — cookbook.
8. Future work pointers.

---

## Section 1 — The myth vs reality

The framing "Tankstellen only supports the Peugeot 107" is misleading.
Here is what the codebase actually looks like:

| Subsystem                    | Per-vehicle parameter source                                   | Hardcoded?            |
| ---------------------------- | -------------------------------------------------------------- | --------------------- |
| Direct fuel rate (PID 0x5E)  | none — ECU returns L/h directly                                | no                    |
| MAF + stoichiometry          | `preferredFuelType` selects AFR + density (petrol vs diesel)   | constants per fuel    |
| Speed-density math           | `engineDisplacementCc`, `volumetricEfficiency`                 | no                    |
| Odometer PID                 | `referenceVehicleId` → `odometerPidStrategy` (PSA/VAG/BMW/...) | no                    |
| Tire / gear inference        | `tireCircumferenceMeters`, `gearCentroids`                     | sensible defaults     |
| Calibration aggregates       | per-profile Welford accumulators                               | no                    |
| Adaptive VE learning (#815)  | per-profile EWMA                                               | no                    |
| Fallback when nothing known  | `kDefaultEngineDisplacementCc=1000`, `kDefaultVe=0.85`         | **yes** (these two)   |

Those two fallback constants live in
`lib/features/consumption/data/obd2/fuel_rate_estimator.dart:39`
and `:45`. They were originally tuned for the Peugeot 107 / Toyota
Aygo / Citroën C1 (1KR-FE 1.0 L NA petrol) — the engines that
motivated the speed-density branch when the developer's own car
turned out to lack PIDs 0x5E and 0x10 alike. They only fire when
**both** of these are true:

- The active `VehicleProfile` carries `null` for `engineDisplacementCc`
  / no override for `volumetricEfficiency`, AND
- No `ReferenceVehicle` catalog row matched the profile's
  `make` / `model` / `year` (so `referenceVehicle?.displacementCc` is
  also `null`).

Everything else parameterises off the per-vehicle profile or the
catalog. This guide tells you exactly what those two layers look like
and how to extend them.

---

## Section 2 — `VehicleProfile` fields

Source: `lib/features/vehicle/domain/entities/vehicle_profile.dart:108`.

`VehicleProfile` is a Freezed value class persisted in Hive. Every
user-owned vehicle is one instance; the trip recorder, fuel-rate
estimator, OBD-II service, and calibration learner all read from this
object via the `vehicleProfileRepositoryProvider`.

Fields are grouped here by purpose. For each, "Read by" lists the
subsystem that consumes it.

### Identity

| Field   | Type                  | Default               | Purpose                                                      | Read by                        |
| ------- | --------------------- | --------------------- | ------------------------------------------------------------ | ------------------------------ |
| `id`    | `String`              | required              | Stable Hive key for the profile.                             | every consumer                 |
| `name`  | `String`              | required              | User-visible label ("My 208").                               | UI                             |
| `type`  | `VehicleType`         | `combustion`          | One of `combustion`, `hybrid`, `ev`. Drives section gating.  | UI, fuel-rate, EV gating       |
| `make`  | `String?`             | `null`                | Marketing brand, e.g. `"Peugeot"`. Used for catalog match.   | catalog matcher                |
| `model` | `String?`             | `null`                | Model name, e.g. `"208"`. Used for catalog match.            | catalog matcher                |
| `year`  | `int?`                | `null`                | Model year, used to disambiguate catalog generations.        | catalog matcher                |
| `vin`   | `String?`             | `null`                | Vehicle Identification Number. Optional; pre-fills via VIN decoder. | VIN decoder + UI         |

### EV-specific

| Field                  | Type                   | Default            | Purpose                                                      | Read by                        |
| ---------------------- | ---------------------- | ------------------ | ------------------------------------------------------------ | ------------------------------ |
| `batteryKwh`           | `double?`              | `null`             | Battery pack energy capacity.                                | EV consumption + range         |
| `maxChargingKw`        | `double?`              | `null`             | Peak DC charging power.                                      | charging filter                |
| `supportedConnectors`  | `Set<ConnectorType>`   | `{}`               | Which plug types fit (Type 2, CCS, CHAdeMO, ...).            | charging-station filter        |
| `chargingPreferences`  | `ChargingPreferences`  | defaults           | min/max SoC + preferred networks.                            | charging UI                    |

### Combustion-specific

| Field                | Type     | Default | Purpose                                                | Read by                        |
| -------------------- | -------- | ------- | ------------------------------------------------------ | ------------------------------ |
| `tankCapacityL`      | `double?` | `null` | Tank volume in litres. Used by range estimation.       | range UI, fill-up math         |
| `preferredFuelType`  | `String?` | `null` | Free-text fuel key (`"petrol"`, `"diesel"`, ...).      | AFR + density selector (#800)  |

`preferredFuelType` is intentionally a string, not an enum, because it
is populated from several sources (manual onboarding, VIN decoder,
home-widget mirror) and the dispatcher only needs `.contains("diesel")`
to switch AFR / density constants — see `isDieselProfile` in
`fuel_rate_estimator.dart:60`.

### Engine parameters (speed-density math, #812)

| Field                          | Type      | Default  | Purpose                                                                                                    | Read by                       |
| ------------------------------ | --------- | -------- | ---------------------------------------------------------------------------------------------------------- | ----------------------------- |
| `engineDisplacementCc`         | `int?`    | `null`   | Total swept volume in cc. Drives speed-density air-mass calculation. Null → catalog → 1000 cc fallback.    | speed-density estimator       |
| `engineCylinders`              | `int?`    | `null`   | Reserved for firing-event-based estimation + engine-stress indicators. No default — null is honest.        | future features               |
| `volumetricEfficiency`         | `double`  | `0.85`   | Fraction of theoretical air mass actually inducted. 0.60–0.95 typical. **Adaptive — see Section 6.**       | speed-density estimator       |
| `volumetricEfficiencySamples`  | `int`     | `0`      | EWMA sample counter. Bumped each successful tankful reconciliation. Used for UX ("calibrated from 3 fillups"). | UI debug surface           |
| `curbWeightKg`                 | `int?`    | `null`   | Mass in kg. Used by future rolling-resistance estimator. Null → 1500 kg default downstream.                | future estimator (#812)       |

Note: `volumetricEfficiency` defaults to `0.85` directly on the entity
(non-nullable), so the precedence chain in the OBD-II service treats
"user has a profile" as "user has a VE", and the catalog VE wins only
when `vehicle == null`. See `obd2_service.dart:494`.

### OBD-II adapter pairing (#784, #1004)

| Field                  | Type      | Default | Purpose                                                                                  | Read by                       |
| ---------------------- | --------- | ------- | ---------------------------------------------------------------------------------------- | ----------------------------- |
| `obd2AdapterMac`       | `String?` | `null`  | MAC of the currently connected adapter. Persisted across launches.                       | reconnect path (#784)         |
| `obd2AdapterName`      | `String?` | `null`  | UI label of the adapter (e.g. `"vLinker FS"`).                                           | UI                            |
| `pairedAdapterMac`     | `String?` | `null`  | MAC of the adapter that *belongs* to this vehicle. Watched by the BLE auto-connect listener. Distinct from `obd2AdapterMac`. | auto-record listener (#1004)  |
| `autoRecord`           | `bool`    | `false` | Master toggle for hands-free recording. Off by default — user must opt in.               | auto-record service           |
| `movementStartThresholdKmh` | `double` | `5.0` | Speed (OBD2 0x0D OR GPS, whichever fires first) above which auto-record fires `startTrip`. | auto-record service       |
| `disconnectSaveDelaySec` | `int`   | `60`    | Debounce before BT disconnect triggers `stopAndSave`. Tunnels / lifts shouldn't terminate trips. | auto-record service     |
| `backgroundLocationConsent` | `bool` | `false` | Stored answer to "may we record GPS while screen is off?" Without it, auto-flow runs BT-only. | auto-record + GPS gates  |

### Calibration / driving metrics

| Field                         | Type                          | Default                  | Purpose                                                                                | Read by                        |
| ----------------------------- | ----------------------------- | ------------------------ | -------------------------------------------------------------------------------------- | ------------------------------ |
| `calibrationMode`             | `VehicleCalibrationMode`      | `rule`                   | `rule` (winner-take-all #779) vs `fuzzy` (proportional membership #894).               | baseline calibration           |
| `tireCircumferenceMeters`     | `double`                      | `1.95` (195/65R15)       | Driven-wheel circumference. Drives gear-RPM / wheel-RPM ratio for clusterer.           | gear inference (#1263)         |
| `gearCentroids`               | `List<double>?`               | `null`                   | Persisted k-means centroids from previous trip. Cold-start when null.                  | gear inference (#1263)         |
| `tripLengthAggregates`        | `TripLengthBreakdown?`        | `null`                   | Short / medium / long bucket Welford stats from rolling aggregator (#1193).            | vehicle-detail UI              |
| `speedConsumptionAggregates`  | `SpeedConsumptionHistogram?`  | `null`                   | Per-speed-band L/100 km histogram.                                                     | vehicle-detail UI              |
| `aggregatesUpdatedAt`         | `DateTime?`                   | `null`                   | Wall-clock time of the last aggregator pass.                                           | vehicle-detail UI              |
| `aggregatesTripCount`         | `int?`                        | `null`                   | # trips folded into the current pass. Section gates below a min-trips threshold.       | vehicle-detail UI              |

### Catalog reference (#950 phase 4)

| Field                  | Type      | Default | Purpose                                                                              | Read by                        |
| ---------------------- | --------- | ------- | ------------------------------------------------------------------------------------ | ------------------------------ |
| `referenceVehicleId`   | `String?` | `null`  | Slug of the matched catalog row, e.g. `"peugeot-208-ii-2019"`. Resolves to a `ReferenceVehicle` via the catalog provider. | OBD-II service, fuel-rate   |

The slug format is `<make>-<model>-<generation>` lowercased with
non-alphanumeric runs collapsed to single dashes — see
`VehicleProfileCatalogMatcher.slugFor` at
`lib/features/vehicle/data/vehicle_profile_catalog_matcher.dart:93`.

---

## Section 3 — `ReferenceVehicle` catalog

Source: `lib/features/vehicle/domain/entities/reference_vehicle.dart`.

The catalog is a JSON-asset-backed list of make/model/generation
records. It carries the engine-parameter defaults the OBD-II layer
needs so the user does not have to discover them by hand. **The
catalog IS the abstraction** — it is sparsely populated today, but
designed to scale to arbitrary cars.

### Catalog model

| Field                  | Type    | Default            | Purpose                                                                |
| ---------------------- | ------- | ------------------ | ---------------------------------------------------------------------- |
| `make`                 | string  | required           | Manufacturer brand, e.g. `"Peugeot"`.                                  |
| `model`                | string  | required           | Model name as marketed in Europe, e.g. `"208"`.                        |
| `generation`           | string  | required           | Free-form generation label, e.g. `"II (2019-)"`.                       |
| `yearStart`            | int     | required           | First model year.                                                      |
| `yearEnd`              | int?    | `null`             | Last model year, or `null` for still-in-production.                    |
| `displacementCc`       | int     | required           | Engine displacement in cc.                                             |
| `fuelType`             | string  | required           | One of `"petrol"`, `"diesel"`, `"hybrid"`, `"electric"`.               |
| `transmission`         | string  | required           | One of `"manual"`, `"automatic"`.                                      |
| `volumetricEfficiency` | double  | `0.85`             | Typical VE for this engine. Override per generation if known.          |
| `odometerPidStrategy`  | string  | `"stdA6"`          | Which PID strategy unlocks the odometer for this make.                 |
| `notes`                | string? | `null`             | Free-form (e.g. "PHEV variant uses different VE").                     |

`fuelType` and `transmission` are stored as strings (not enums) so
adding a new variant is a JSON-only change.

### Odometer PID strategies

| Strategy   | Applies to                                           | Mechanism                              |
| ---------- | ---------------------------------------------------- | -------------------------------------- |
| `stdA6`    | Standards-compliant cars (rare in practice)          | OBD-II Service 01 PID A6               |
| `psaUds`   | PSA family — Peugeot, Citroën, DS, Opel post-2017, Vauxhall | UDS-over-CAN custom PID         |
| `bmwCan`   | BMW                                                  | Raw-CAN broadcast frame                |
| `vwUds`    | VAG group — VW, Skoda, Seat, Audi                    | UDS PID                                |
| `unknown`  | No working strategy known                            | Consumer falls back to trip integration |

### Where the catalog lives

- **JSON asset:** `assets/reference_vehicles/vehicles.json` — source
  of truth.
- **Asset declaration:** `pubspec.yaml` under `flutter: assets:`.
- **Entity:**
  `lib/features/vehicle/domain/entities/reference_vehicle.dart`.
- **Provider:**
  `lib/features/vehicle/data/reference_vehicle_catalog_provider.dart` —
  loads JSON once at startup (`keepAlive: true`), exposes a
  make/model/year lookup helper.
- **Matcher:**
  `lib/features/vehicle/data/vehicle_profile_catalog_matcher.dart` —
  tiered lookup (exact → make+model → make-only) so partial profiles
  still resolve to *something* useful.
- **Migrator:**
  `lib/features/vehicle/data/vehicle_profile_migrator.dart` — runs on
  first launch after install / upgrade, fills in `referenceVehicleId`
  on existing profiles.

### How a `referenceVehicleId` resolves into catalog data

1. The user's `VehicleProfile.referenceVehicleId` is a slug
   like `"peugeot-208-ii-2019"`.
2. The OBD-II service watches `referenceVehicleCatalogProvider`
   (a `Future<List<ReferenceVehicle>>`).
3. It linearly scans the list for the catalog entry whose
   `slugFor(entry)` matches the profile's slug.
4. The matched `ReferenceVehicle` is passed to
   `readFuelRateLPerHour` (and similar consumers) alongside the
   `VehicleProfile`. Per-instance values still win — see Section 4.

If no slug is set yet (pre-#950 profiles, or a user who hasn't gone
through onboarding), the migrator runs `bestMatch` from the catalog
matcher and persists whatever best-effort tier hits. If even the
make-only tier misses, `referenceVehicleId` stays null and the
fuel-rate path falls back to the constants in Section 5.

### Catalog snapshot today

The bundled catalog at `assets/reference_vehicles/vehicles.json`
ships ~30 entries spanning Peugeot, Renault, Citroën, Volkswagen,
Toyota, Ford, BMW, Audi, and a handful of EVs. See
`docs/guides/vehicle-catalog.md` for the JSON-schema reference and
how to add an entry; this section just establishes that the file IS
the abstraction layer and is meant to grow.

---

## Section 4 — The fuel-rate fallback chain

Source: `lib/features/consumption/data/obd2/obd2_service.dart:480`
(`readFuelRateLPerHour`).

The fuel-rate estimator dispatches on **PID capability discovered at
runtime** (#811), not on vehicle make. Three steps, in order of
preference:

```
                       readFuelRateLPerHour()
                                |
                    +-----------+-----------+
                    | precedence resolution |
                    | engineDisplacementCc  |
                    | volumetricEfficiency  |
                    | isDiesel / AFR / rho  |
                    +-----------+-----------+
                                |
                                v
                    +-----------+-----------+
                    | isPidSupported(0x5E)? |
                    +-----+-------------+---+
                       Y  |             |  N
                          v             |
              direct ECU L/h            |
              (post-trim)               |
                          |             v
                          |    +--------+--------+
                          |    | isPidSupported  |
                          |    |     (0x10)?     |
                          |    +---+--------+----+
                          |     Y  |        |  N
                          |        v        |
                          |  MAF + AFR/rho  |
                          |  fuel-trim corr |
                          |        |        v
                          |        |  +-----+-----+
                          |        |  | speed-density |
                          |        |  | (0x0B + 0x0F  |
                          |        |  |  + 0x0C +     |
                          |        |  |  displacement |
                          |        |  |  + VE)        |
                          |        |  +-----+---------+
                          |        |        |
                          v        v        v
                       L/h      L/h      L/h | null
```

### Precedence resolution (lines 491-507)

Before any PID is queried, the service resolves the engine parameters
by walking the precedence chain:

```dart
final engineDisplacementCc = vehicle?.engineDisplacementCc
    ?? referenceVehicle?.displacementCc
    ?? estimator.kDefaultEngineDisplacementCc;     // 1000 cc

final volumetricEfficiency = vehicle?.volumetricEfficiency
    ?? referenceVehicle?.volumetricEfficiency
    ?? estimator.kDefaultVolumetricEfficiency;     // 0.85

final isDiesel = vehicle != null
    ? estimator.isDieselProfile(vehicle)
    : referenceVehicle?.fuelType.toLowerCase() == 'diesel';
```

User-set values on `VehicleProfile` win, then the catalog row, then
the fallback constants. (Note: `volumetricEfficiency` is non-nullable
on `VehicleProfile`, so when a profile exists, the catalog VE never
gets to vote — the profile's adaptive value is authoritative.)

### Step 1 — PID 0x5E (direct fuel rate)

When `isPidSupported(0x5E)` returns true, the service issues
`Elm327Protocol.engineFuelRateCommand` and parses L/h directly. This
is the cleanest path: the ECU has already applied fuel trim, so no
correction is needed.

### Step 2 — PID 0x10 (MAF + stoichiometry)

When 0x5E is unsupported but 0x10 (Mass Air Flow) is, the service
reads MAF in g/s and computes:

```
L/h = MAF × 3600 / (AFR × density)
```

then multiplies by the fuel-trim correction `(1 + (STFT + LTFT)/100)`
because the stoichiometric math doesn't account for the ECU's
mixture trim. AFR (14.7 petrol / 14.5 diesel) and density (740 g/L
petrol / 832 g/L diesel) are stoichiometric constants, not vehicle
parameters.

### Step 3 — Speed-density (PIDs 0x0B + 0x0F + 0x0C)

When neither 0x5E nor 0x10 is available, the service reads
**M**anifold **A**bsolute **P**ressure (0x0B), **I**ntake **A**ir
**T**emperature (0x0F), and **R**PM (0x0C), then applies the ideal
gas law with the vehicle's displacement and volumetric efficiency:

```
air_g_per_s = (MAP_Pa × disp_m³ × (RPM/120) × VE) / (R × IAT_K)
L/h         = air_g_per_s × 3600 / (AFR × density)
```

Then applies fuel-trim correction. If any of the three PIDs is
known-unsupported, the step bails and the service returns null —
there's no partial answer worth shipping. See
`fuel_rate_estimator.dart:97` (`estimateFuelRateLPerHourFromMap`).

---

## Section 5 — The two hardcoded fallback constants

Source: `lib/features/consumption/data/obd2/fuel_rate_estimator.dart`.

These are the only two vehicle-specific hardcodes left in the
fuel-rate path:

```dart
// fuel_rate_estimator.dart:39
const int kDefaultEngineDisplacementCc = 1000;

// fuel_rate_estimator.dart:45
const double kDefaultVolumetricEfficiency = 0.85;
```

| Constant                          | Value | Fires only when                                                                       | Origin                                       |
| --------------------------------- | ----- | ------------------------------------------------------------------------------------- | -------------------------------------------- |
| `kDefaultEngineDisplacementCc`    | 1000  | `vehicle?.engineDisplacementCc == null` AND `referenceVehicle?.displacementCc == null` | Peugeot 107 / Aygo / C1 (1KR-FE 1.0L NA)     |
| `kDefaultVolumetricEfficiency`    | 0.85  | `vehicle == null` AND `referenceVehicle?.volumetricEfficiency == null`                 | Sensible NA-petrol-at-cruise midpoint        |

These are the "Peugeot 107 fingerprints" — the only place in the
codebase where a vehicle-specific assumption is baked in. Their reach
is **limited to fully-unconfigured vehicles**: a profile that knows
its displacement, OR a catalog match for the make/model/year, sidesteps
both constants entirely.

They exist as a safety net so that an OBD-II live read on a brand-new
profile (no make, no model, no VIN, never opened the edit screen)
returns *something* rather than null. Removing them isn't on the
roadmap — the right move is shrinking the population of vehicles that
have to rely on them, by growing the `ReferenceVehicle` catalog (#1372
phase 2) and making the catalog picker the primary onboarding path
(#1372 phase 3).

---

## Section 6 — Adaptive VE learning (#815)

Source: `lib/features/vehicle/data/ve_learner.dart`.

The static `volumetricEfficiency = 0.85` default is a starting guess.
Real VE drifts as the engine ages (carbon deposits, valve seat wear,
intake leaks) and varies by load (peaks near WOT, dips at part
throttle). Letting users live with a static guess wastes the
information already in the trip log: every tankful, the app holds two
numbers it can compare.

- **`integrated`** — sum of OBD-II fuel-rate integrations across the
  trips since the previous fill-up.
- **`pumped`** — the user-entered litres from the receipt.

If `integrated` over-predicts `pumped`, the speed-density branch is
running with too high a VE. The `VeLearner` runs an EWMA blend per
fill-up:

```
raw_new_ve = current_ve × (pumped / integrated)
new_stored = ewmaBlend × current_ve + (1 - ewmaBlend) × raw_new_ve
```

with `ewmaBlend = 0.7` (so a single odd tankful only nudges the
stored value by 30 % of the raw observation), clamped to
`[0.50, 1.00]`. The result is written back to
`VehicleProfile.volumetricEfficiency` and
`volumetricEfficiencySamples` is bumped.

Safety rails (any of these and the learner skips the tankful):

- combined trip distance < 50 km — too noisy.
- < 10 OBD-II samples — not enough data.
- `|integrated − pumped| / pumped > 0.40` — outlier; user probably
  missed a fill-up or typed the wrong litres.
- no trip found between the previous and current fill-up.

The same calibration pattern is used by the fuel-consumption baseline
in #779. Together they form the per-vehicle adaptation layer that
sits on top of the static catalog defaults.

---

## Section 7 — Adding a new vehicle (cookbook)

Three options, in increasing order of "effort but worth it":

### Option A — User configures every field manually (works today)

The `Edit Vehicle` screen at
`lib/features/vehicle/presentation/screens/edit_vehicle_screen.dart`
already exposes every field in `VehicleProfile`. A user who knows
their displacement and rough VE can fill them in and the speed-density
branch will use those values immediately.

This is the path that works for any vehicle today — the abstraction
already supports it. The downside is discoverability: most users
won't know what "volumetric efficiency" means, never mind a value to
type in.

### Option B — Add a `ReferenceVehicle` catalog entry (recommended)

For any popular EU car, add a row to
`assets/reference_vehicles/vehicles.json` and the catalog matcher
will pick it up. See `docs/guides/vehicle-catalog.md` for the JSON
schema and the validation tests.

Sourcing values:

| Field                  | Where to get it                                                              |
| ---------------------- | ---------------------------------------------------------------------------- |
| `displacementCc`       | Manufacturer spec sheet / Wikipedia engine code page.                        |
| `fuelType`             | Manufacturer spec sheet.                                                     |
| `transmission`         | Manufacturer spec sheet (for the most common variant).                       |
| `volumetricEfficiency` | Default `0.85` is fine; override only if community OBD2 forums published a measured value (typical NA petrol 0.80-0.92, turbo 0.90-1.05). |
| `odometerPidStrategy`  | OBD-II forums (e.g. `pidsync.io`, `obd2forums.com`), or test against the existing `psaUds`/`bmwCan`/`vwUds` strategies and pick what works. |

Run `flutter test` after adding — the catalog parse + duplicate-slug
tests will catch malformed entries.

### Option C — Extend a manufacturer's `odometerPidStrategy` (one-off OBD quirks)

If a brand uses a custom PID that doesn't fit the existing strategies
(`stdA6` / `psaUds` / `bmwCan` / `vwUds` / `unknown`), add a new
strategy enum + handler:

1. Add the new key (e.g. `"renaultCan"`) to the docstring in
   `lib/features/vehicle/domain/entities/reference_vehicle.dart:55`.
2. Add the dispatch branch in the OBD-II odometer reader (search
   `odometerPidStrategy` in `lib/features/consumption/data/obd2/`
   for the dispatch site).
3. Update `assets/reference_vehicles/vehicles.json` rows that should
   use the new strategy.
4. Write a unit test for the new handler — the existing strategies
   each have one, mirror the pattern.

---

## Section 8 — Future work

This guide is phase 1 of #1372 — the documentation phase. Two more
phases are planned:

- **Phase 2 — Catalog expansion.** Add 20-50 popular European cars
  to `assets/reference_vehicles/vehicles.json`. Cover PSA, Renault,
  VW, Toyota, Ford at minimum.
- **Phase 3 — Onboarding picker.** Wire a `ReferenceVehicle` picker
  into the new-vehicle wizard so the catalog is the primary path,
  manual entry the fallback. Pre-fill `VehicleProfile` fields from
  the catalog row.

See #1372 for the full epic plan and acceptance criteria.

Related references:

- `docs/guides/vehicle-catalog.md` — JSON-schema reference for the
  catalog asset.
- `docs/guides/obd2-adapters.md` — adapter pairing + protocol notes.
- `docs/guides/auto-record.md` — the hands-free trip recording flow
  that consumes `pairedAdapterMac` + `autoRecord`.
- `docs/guides/driving-insights.md` — how the per-vehicle aggregates
  surface in the UI.
