# Reference Vehicle Catalog

The reference vehicle catalog ships a curated list of popular EU
passenger cars with pre-tuned engine quirks. The OBD-II layer reads
this catalog (phase 2, see #950) so users don't have to discover
volumetric efficiency or odometer PID strategy by hand.

## Where the data lives

- **JSON asset:** `assets/reference_vehicles/vehicles.json` — the
  source of truth. Edit this file to add or update entries.
- **Entity:** `lib/features/vehicle/domain/entities/reference_vehicle.dart`
  — `freezed` data class, immutable.
- **Provider:**
  `lib/features/vehicle/data/reference_vehicle_catalog_provider.dart` —
  loads the JSON once at app startup (`keepAlive: true`) and exposes
  a make/model/year lookup helper.

## JSON schema

Each catalog entry is an object with these fields:

| Field                  | Type    | Required | Notes                                                                  |
| ---------------------- | ------- | -------- | ---------------------------------------------------------------------- |
| `make`                 | string  | yes      | Manufacturer brand, e.g. `"Peugeot"`.                                  |
| `model`                | string  | yes      | Model name as marketed in Europe, e.g. `"208"`.                        |
| `generation`           | string  | yes      | Free-form generation label, e.g. `"II (2019-)"`.                       |
| `yearStart`            | integer | yes      | First model year for this generation.                                  |
| `yearEnd`              | integer | no       | Last model year, or `null` if still in production.                     |
| `displacementCc`       | integer | yes      | Engine displacement in cubic centimetres.                              |
| `fuelType`             | string  | yes      | One of `"petrol"`, `"diesel"`, `"hybrid"`, `"electric"`.               |
| `transmission`         | string  | yes      | One of `"manual"`, `"automatic"`.                                      |
| `volumetricEfficiency` | number  | no       | Defaults to `0.85`. Typical range 0.80-0.92 for naturally-aspirated.   |
| `odometerPidStrategy`  | string  | no       | Defaults to `"stdA6"`. See [Strategy values](#odometerpidstrategy-values). |
| `notes`                | string  | no       | Free-form notes (e.g. PHEV variants, platform sharing).                |

Lookup is case-insensitive on `make` + `model`, and inclusive on the
production-year window (so `yearStart <= year <= yearEnd`).

## `odometerPidStrategy` values

| Value      | Meaning                                                                           |
| ---------- | --------------------------------------------------------------------------------- |
| `stdA6`    | Generic OBD-II Service 01 PID A6. Standards-compliant default.                    |
| `psaUds`   | PSA family (Peugeot, Citroen, DS, post-2017 Opel, Vauxhall) UDS-over-CAN PID.     |
| `bmwCan`   | BMW raw-CAN broadcast frame.                                                      |
| `vwUds`    | VAG group (VW, Skoda, Seat, Audi) UDS PID.                                        |
| `unknown`  | No working strategy known. The OBD-II consumer falls back to trip integration.    |

When in doubt, leave the field unset (defaults to `stdA6`) — the
generic strategy works on most modern cars.

## Adding a new entry

1. Find the closest matching existing entry (same brand or platform)
   and copy it as a template — most fields will be similar.
2. Look up the generation window on the manufacturer's spec sheet or
   Wikipedia.
3. For `volumetricEfficiency`: default `0.85` for naturally-aspirated
   petrol, `0.88` for modern turbo-diesels, `0.87-0.88` for hybrids,
   `0.83` for older/smaller engines (1.0L and below). Leave it default
   unless you have a measured value.
4. For `odometerPidStrategy`: pick by manufacturer. If the brand isn't
   covered by the strategy table above, leave as `stdA6` and add a
   note like `"odometer PID untested"`.
5. Run `flutter test
   test/features/vehicle/data/reference_vehicle_catalog_provider_test.dart`
   to confirm the new entry parses cleanly and the catalog still has
   ≥30 entries.

## Phasing

This catalog ships in phases:

- **Phase 1 (this PR):** data + provider only. No consumer changes.
- **Phase 2 (#950 follow-up):** rewrite `obd2_service.dart` to consume
  the catalog instead of hardcoded Peugeot fallbacks.
- **Phase 3:** documentation polish (this file plus the OBD-II quirk
  rationale).
- **Phase 4:** migrate existing user `VehicleProfile` entries — let
  users pick a catalog entry to autofill their profile.

Changes to the JSON asset are safe to ship in any phase: the consumer
reads the catalog by make/model/year, not by index.
