# Reference Vehicle Catalog

The reference vehicle catalog ships a curated list of popular EU
passenger cars with pre-tuned engine quirks. The OBD-II layer reads
this catalog (phase 2, see #950) so users don't have to discover
volumetric efficiency or odometer PID strategy by hand.

## Where the data lives

- **JSON asset:** `assets/reference_vehicles/vehicles.json` — the
  source of truth. Edit this file to add or update entries.
- **Asset declaration:** `pubspec.yaml` under `flutter: assets:` —
  must list `assets/reference_vehicles/vehicles.json` so `rootBundle`
  can resolve it at runtime and in tests.
- **Entity:** `lib/features/vehicle/domain/entities/reference_vehicle.dart`
  — `freezed` data class, immutable.
- **Provider:**
  `lib/features/vehicle/data/reference_vehicle_catalog_provider.dart` —
  loads the JSON once at app startup (`keepAlive: true`) and exposes
  a make/model/year lookup helper.
- **Consumer:** `lib/features/consumption/data/obd2/obd2_service.dart`
  — looks up the active `VehicleProfile` against the catalog and uses
  the matched entry's `volumetricEfficiency` and
  `odometerPidStrategy` to drive the OBD-II command pipeline.

## JSON schema

The asset is a top-level JSON array. Each catalog entry is an object
with these fields:

| Field                  | Type    | Required | Notes                                                                  |
| ---------------------- | ------- | -------- | ---------------------------------------------------------------------- |
| `make`                 | string  | yes      | Manufacturer brand, e.g. `"Peugeot"`. Title case.                      |
| `model`                | string  | yes      | Model name as marketed in Europe, e.g. `"208"`, `"Clio"`.              |
| `generation`           | string  | yes      | Free-form generation label, e.g. `"II (2019-)"` or `"V (2020-2024)"`.  |
| `yearStart`            | integer | yes      | First model year for this generation. Must be > 1900.                  |
| `yearEnd`              | integer | no       | Last model year, or `null` if still in production.                     |
| `displacementCc`       | integer | yes      | Engine displacement in cubic centimetres. Must be > 0.                 |
| `fuelType`             | string  | yes      | One of `"petrol"`, `"diesel"`, `"hybrid"`, `"electric"`.               |
| `transmission`         | string  | yes      | One of `"manual"`, `"automatic"`.                                      |
| `volumetricEfficiency` | number  | no       | Defaults to `0.85`. Sensible range 0.5 < VE ≤ 1.0; typical 0.80-0.92.  |
| `odometerPidStrategy`  | string  | no       | Defaults to `"stdA6"`. See [Strategy values](#odometerpidstrategy-values). |
| `notes`                | string  | no       | Free-form notes (e.g. PHEV variants, platform sharing).                |

The triple `(make, model, generation)` must be unique across the
catalog — duplicates are a hard error caught by the asset parse test.

Lookup is case-insensitive on `make` + `model`, and inclusive on the
production-year window (so `yearStart <= year <= yearEnd`).

### Example entry

```json
{
  "make": "Peugeot",
  "model": "208",
  "generation": "II (2019-)",
  "yearStart": 2019,
  "yearEnd": null,
  "displacementCc": 1199,
  "fuelType": "petrol",
  "transmission": "manual",
  "volumetricEfficiency": 0.85,
  "odometerPidStrategy": "psaUds",
  "notes": "PureTech 1.2 three-cylinder. Electric e-208 sibling shares body but uses electric fuelType."
}
```

## `odometerPidStrategy` values

The enum source of truth is the docstring on
`ReferenceVehicle.odometerPidStrategy` in
`lib/features/vehicle/domain/entities/reference_vehicle.dart`.

| Value      | Meaning                                                                           |
| ---------- | --------------------------------------------------------------------------------- |
| `stdA6`    | Generic OBD-II Service 01 PID A6. Standards-compliant default.                    |
| `psaUds`   | PSA family (Peugeot, Citroen, DS, post-2017 Opel, Vauxhall) UDS-over-CAN PID.     |
| `bmwCan`   | BMW raw-CAN broadcast frame.                                                      |
| `vwUds`    | VAG group (VW, Skoda, Seat, Audi) UDS PID.                                        |
| `unknown`  | No working strategy known. The OBD-II consumer falls back to trip integration.    |

When in doubt, leave the field unset (defaults to `stdA6`) — the
generic strategy works on most modern cars.

If you add a brand-new strategy value, you must:

1. Extend the docstring in `reference_vehicle.dart`.
2. Update the allowlist set in
   `test/features/vehicle/data/reference_vehicle_catalog_provider_test.dart`
   and
   `test/features/vehicle/data/reference_vehicle_catalog_asset_test.dart`.
3. Wire the new strategy into the OBD-II consumer
   (`obd2_service.dart`) — otherwise the catalog entry compiles but
   the consumer silently falls through to `stdA6`.

## Contributing a new vehicle

The catalog is ordered roughly by EU sales popularity so the lookup
hit rate is highest for the most common cars. Keep new entries
ordered with that in mind.

### Step-by-step

1. **Pick a candidate.** Use a recent EU new-car registrations
   ranking — ACEA's monthly press releases
   (<https://www.acea.auto/pc-registrations/>) and JATO Dynamics'
   monthly EU summaries are the canonical sources. The European
   Environment Agency's vehicle registration dataset
   (<https://www.eea.europa.eu/en/datahub/datahubitem-view/fa8b1229-3db6-495d-b18e-9c9b3267c02b>)
   is also publicly downloadable and breaks down by make/model.
   Prefer cars in the EU top 50 if the catalog doesn't already
   cover them.
2. **Find the closest existing entry** (same brand or platform) and
   copy it as a template — most fields will be similar.
3. **Look up the generation window** on the manufacturer's spec
   sheet, Wikipedia, or an automotive press archive. Use `null` for
   `yearEnd` when the generation is still in production.
4. **Pick `volumetricEfficiency`:**
   - `0.85` — naturally-aspirated petrol (default).
   - `0.88` — modern turbo-diesels.
   - `0.87`-`0.88` — hybrids on Atkinson-cycle engines.
   - `0.83` — older or smaller engines (≤ 1.0L).
   - Leave it unset (uses default `0.85`) when you don't have a
     measured value.
5. **Pick `odometerPidStrategy`** by manufacturer using the
   strategy table above. If the brand isn't covered, leave as the
   default `stdA6` and add a `"notes"` value like
   `"odometer PID untested"` so future contributors know the entry
   is provisional.
6. **Append to `assets/reference_vehicles/vehicles.json`** in the
   appropriate popularity slot (group by make where possible — the
   existing file groups Peugeot/Renault/VW/etc. together).
7. **Run the asset parse test** — this is the required test
   assertion for any catalog change:

   ```bash
   flutter test test/features/vehicle/data/reference_vehicle_catalog_asset_test.dart
   ```

   It validates that the asset still parses, has ≥ 30 entries, has
   no duplicate `(make, model, generation)` triples, and that every
   `odometerPidStrategy` is a known enum value.

8. **Run the provider test** as a smoke check on the riverpod
   provider:

   ```bash
   flutter test test/features/vehicle/data/reference_vehicle_catalog_provider_test.dart
   ```

9. **Open a PR** with the `area/api` and `type/enhancement` labels.
   No code changes outside the JSON file should be needed unless you
   added a new `odometerPidStrategy` value (see above).

### What NOT to add

- Niche or low-volume cars (anything outside the EU top ~100). The
  catalog is for hit-rate, not completeness — the obd2 layer falls
  back gracefully when no entry matches.
- Variant-specific entries (e.g. one row per trim level). Pick the
  most common engine for the generation; `notes` is the right place
  to mention sibling variants.
- Vehicles you cannot find a published `displacementCc` for —
  guessing breaks the consumption math downstream.

## Phasing

This catalog ships in phases (see #950):

- **Phase 1 (#1003):** entity + 31-vehicle catalog asset + provider.
- **Phase 2 (#1009):** `obd2_service` consumes the catalog.
- **Phase 3 (this PR):** JSON schema docs polish + asset parse test.
- **Phase 4 (planned):** migrate existing user `VehicleProfile`
  entries — let users pick a catalog entry to autofill their
  profile.

Changes to the JSON asset are safe to ship in any phase: the consumer
reads the catalog by make/model/year, not by index.
