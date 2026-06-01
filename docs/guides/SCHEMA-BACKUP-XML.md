<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# Tankstellen Backup XML — Schema v1.0

This page describes the format produced by the Consumption screen's
**Export backup** action (download icon). The export bundles every
domain entity the app stores locally — vehicle profiles, fuel
fill-ups, OBD2 trip history (with per-tick samples), and EV charging
logs — into a single XML document, validated against the published
XSD schema, then zipped for share-sheet handoff.

> **Note for wiki sync** — when this PR merges, copy the contents of
> this file to a new wiki page `Schema-Backup-XML.md` in the
> `tankstellen.wiki` repo and link it from `Home.md` under a new
> "Data export" section.

## File layout

The share sheet hands you a single `.zip` file:

```
tankstellen_backup_<YYYYMMDDTHHMMSS>.zip
└── tankstellen_backup_<YYYYMMDDTHHMMSS>.xml
```

The timestamp is UTC. Both names share the same stamp so the inner
XML doesn't collide with sibling backups when you extract several at
once.

## Validating a backup

The schema lives at `assets/schemas/tankstellen_backup_v1.xsd` in the
app repo (and is also bundled inside the APK as a Flutter asset). To
validate an unzipped backup against the schema:

```bash
xmllint --noout \
        --schema assets/schemas/tankstellen_backup_v1.xsd \
        tankstellen_backup_20260430T220400.xml
```

A passing validation prints nothing (xmllint convention). A failing
validation prints a per-element diagnostic such as `element 'X':
This element is not expected.`

## Top-level structure

```xml
<TankstellenBackup version="1.0"
                   xmlns="https://tankstellen.app/backup/v1">
  <ExportedAt>2026-04-30T22:04:00.000Z</ExportedAt>
  <AppVersion>5.0.0</AppVersion>
  <Vehicles>
    <Vehicle>...</Vehicle>
  </Vehicles>
  <FillUps>
    <FillUp>...</FillUp>
  </FillUps>
  <Trips>
    <Trip>...</Trip>
  </Trips>
  <ChargingLogs>
    <ChargingLog>...</ChargingLog>
  </ChargingLogs>
</TankstellenBackup>
```

| Element        | Type     | Required | Notes                                                    |
| -------------- | -------- | -------- | -------------------------------------------------------- |
| `@version`     | string   | yes      | Schema version. Currently `"1.0"`.                       |
| `@xmlns`       | URI      | yes      | Always `https://tankstellen.app/backup/v1`.              |
| `ExportedAt`   | dateTime | yes      | ISO-8601 UTC instant the backup was generated.            |
| `AppVersion`   | string   | yes      | App version reported by `package_info_plus`.              |
| `Vehicles`     | element  | yes      | Container; `<Vehicle>` children may be absent.            |
| `FillUps`      | element  | yes      | Container; `<FillUp>` children may be absent.             |
| `Trips`        | element  | yes      | Container; `<Trip>` children may be absent.               |
| `ChargingLogs` | element  | yes      | Container; `<ChargingLog>` children may be absent.        |

## `<Vehicle>` element

| Element                       | Type      | Required | Notes                                                                |
| ----------------------------- | --------- | -------- | -------------------------------------------------------------------- |
| `Id`                          | string    | yes      | Stable per-vehicle id.                                               |
| `Name`                        | string    | yes      | Display name.                                                        |
| `EngineType`                  | enum      | yes      | `combustion` \| `hybrid` \| `ev`.                                    |
| `BatteryKwh`                  | decimal   | no       | EV battery capacity in kWh.                                          |
| `MaxChargingKw`               | decimal   | no       | Peak DC charging power.                                              |
| `SupportedConnectors`         | element   | no       | List of `<Connector>` enum values (`type2`, `ccs`, `chademo`, ...).  |
| `ChargingPreferences`         | element   | yes      | SoC bands + preferred network whitelist.                             |
| `TankCapacityL`               | decimal   | no       | Combustion fuel-tank capacity.                                       |
| `PreferredFuelType`           | string    | no       | `apiValue` of the user's default fuel.                               |
| `EngineDisplacementCc`        | int       | no       | Used by the speed-density fuel-rate fallback (#812).                 |
| `EngineCylinders`             | int       | no       | Reserved for future analytics.                                       |
| `VolumetricEfficiency`        | decimal   | yes      | Adaptive η_v (#815). Default 0.85.                                   |
| `VolumetricEfficiencySamples` | int       | yes      | EWMA sample count.                                                   |
| `CurbWeightKg`                | int       | no       | Vehicle curb weight (#812).                                          |
| `Obd2AdapterMac`              | string    | no       | Currently-connected OBD2 adapter MAC.                                |
| `Obd2AdapterName`             | string    | no       | Display label for that adapter.                                      |
| `PairedAdapterMac`            | string    | no       | Long-lived "this adapter belongs to this car" marker (#1004).        |
| `Vin`                         | string    | no       | Vehicle identification number.                                       |
| `CalibrationMode`             | enum      | yes      | `rule` \| `fuzzy` (#894).                                            |
| `AutoRecord`                  | boolean   | yes      | Auto-record toggle.                                                  |
| `MovementStartThresholdKmh`   | decimal   | yes      | Speed at which auto-record triggers `startTrip()`.                   |
| `DisconnectSaveDelaySec`      | int       | yes      | BT-disconnect debounce window.                                       |
| `BackgroundLocationConsent`   | boolean   | yes      | User consent for screen-off GPS.                                     |
| `Make`                        | string    | no       | Brand, e.g. `Peugeot`.                                               |
| `Model`                       | string    | no       | Model, e.g. `208`.                                                   |
| `Year`                        | int       | no       | Model year.                                                          |
| `ReferenceVehicleId`          | string    | no       | Catalog slug.                                                        |
| `AggregatesUpdatedAt`         | dateTime  | no       | Last per-vehicle aggregator pass.                                    |
| `AggregatesTripCount`         | int       | no       | Trips folded into the last aggregate.                                |
| `TireCircumferenceMeters`     | decimal   | yes      | Driven-wheel circumference for gear inference (#1263).               |
| `GearCentroids`               | element   | no       | Persisted gear-cluster centroids (sorted ascending).                 |

`<ChargingPreferences>` carries:

| Element             | Type | Required | Notes                                |
| ------------------- | ---- | -------- | ------------------------------------ |
| `MinSocPercent`     | int  | yes      | Soft floor for the SoC alert band.   |
| `MaxSocPercent`     | int  | yes      | Soft ceiling.                        |
| `PreferredNetworks` | list | no       | Whitelist of `<Network>` strings.    |

## `<FillUp>` element

| Element         | Type     | Required | Notes                                                   |
| --------------- | -------- | -------- | ------------------------------------------------------- |
| `Id`            | string   | yes      | Stable per-fill-up id.                                  |
| `VehicleId`     | string   | no       | Reference to the owning vehicle, if attributed.         |
| `Date`          | dateTime | yes      | ISO-8601 UTC.                                           |
| `FuelType`      | enum     | yes      | One of `e5` `e10` `e98` `diesel` `diesel_premium` `e85` `lpg` `cng` `hydrogen` `electric` `all`. |
| `Liters`        | decimal  | yes      |                                                         |
| `TotalCost`     | decimal  | yes      | Currency is implicit (EUR app-wide).                    |
| `OdometerKm`    | decimal  | yes      |                                                         |
| `StationId`     | string   | no       | API-side id when the fill-up came from a station tap.    |
| `StationName`   | string   | no       | Free-form display name.                                 |
| `Notes`         | string   | no       | User-entered note.                                      |
| `IsFullTank`    | boolean  | yes      | Whether this top-up filled to capacity (#1195).          |
| `LinkedTripIds` | list     | no       | OBD2 trip ids recorded since the previous fill-up (#888).|

## `<Trip>` element

| Element           | Type    | Required | Notes                                                     |
| ----------------- | ------- | -------- | --------------------------------------------------------- |
| `Id`              | string  | yes      | Stable per-trip id (typically the recording start ISO).   |
| `VehicleId`       | string  | no       | Owning vehicle, if known.                                 |
| `Automatic`       | boolean | yes      | Whether the trip was captured by the auto-record path.    |
| `AdapterMac`      | string  | no       | OBD2 adapter MAC (#1312).                                 |
| `AdapterName`     | string  | no       | Adapter display label.                                    |
| `AdapterFirmware` | string  | no       | ELM327 firmware string.                                   |
| `Summary`         | element | yes      | Aggregate metrics (see below).                            |
| `Samples`         | element | yes      | Container; per-tick `<Sample>` children may be absent.    |

`<Summary>` carries:

| Element                   | Type     | Required | Notes                                                                            |
| ------------------------- | -------- | -------- | -------------------------------------------------------------------------------- |
| `DistanceKm`              | decimal  | yes      |                                                                                  |
| `MaxRpm`                  | decimal  | yes      |                                                                                  |
| `HighRpmSeconds`          | decimal  | yes      | Time above the high-RPM threshold.                                               |
| `IdleSeconds`             | decimal  | yes      | Engine-on stationary time.                                                       |
| `HarshBrakes`             | int      | yes      |                                                                                  |
| `HarshAccelerations`      | int      | yes      |                                                                                  |
| `AvgLPer100Km`            | decimal  | no       | Null when no fuel-rate samples were recorded.                                    |
| `FuelLitersConsumed`      | decimal  | no       | Null when no fuel-rate samples were recorded.                                    |
| `StartedAt`               | dateTime | no       |                                                                                  |
| `EndedAt`                 | dateTime | no       |                                                                                  |
| `DistanceSource`          | enum     | yes      | `real` \| `virtual` (#800).                                                      |
| `ColdStartSurcharge`      | boolean  | yes      | Cold-start heuristic flag (#1262).                                               |
| `SecondsBelowOptimalGear` | decimal  | no       | Gear-inference coaching metric (#1263).                                          |

`<Sample>` carries:

| Element             | Type     | Required | Notes                                                            |
| ------------------- | -------- | -------- | ---------------------------------------------------------------- |
| `Timestamp`         | dateTime | yes      | ISO-8601 UTC.                                                    |
| `SpeedKmh`          | decimal  | yes      |                                                                  |
| `Rpm`               | decimal  | yes      |                                                                  |
| `FuelRateLPerHour`  | decimal  | no       | PID 0x5E. Absent on cars without the PID.                         |
| `ThrottlePercent`   | decimal  | no       | PID 0x11.                                                         |
| `EngineLoadPercent` | decimal  | no       | PID 0x04.                                                         |
| `CoolantTempC`      | decimal  | no       | PID 0x05.                                                         |

## `<ChargingLog>` element

| Element             | Type     | Required | Notes                                                  |
| ------------------- | -------- | -------- | ------------------------------------------------------ |
| `Id`                | string   | yes      | Stable per-session id.                                 |
| `VehicleId`         | string   | yes      | Required — every session belongs to a vehicle.         |
| `Date`              | dateTime | yes      |                                                        |
| `Kwh`               | decimal  | yes      | Energy delivered.                                      |
| `CostEur`           | decimal  | yes      | Total session cost.                                    |
| `ChargeTimeMin`     | int      | yes      | Plug-in duration in whole minutes.                     |
| `OdometerKm`        | int      | yes      | Odometer at session end.                               |
| `StationName`       | string   | no       | Free-form display label.                               |
| `ChargingStationId` | string   | no       | OCM station id when the log was opened from a station. |

## Schema source

The XSD lives in the repo at `assets/schemas/tankstellen_backup_v1.xsd`.
Schema version bumps require a fresh file (`tankstellen_backup_v2.xsd`)
so existing v1 archives stay readable; the writer encodes the version
it produced and a future importer dispatches on that value.

## Restoring a backup (#2571)

Restore is the mirror of export and is **now shipped**. The Consumption
screen's **Restore backup** action (the restore icon next to the
download/export one) drives the flow:

1. The user picks a `.zip` backup via the OS document picker
   (`file_selector` — no storage permission on Android, it uses the
   Storage Access Framework).
2. `BackupZipReader` decodes the zip and locates the inner `.xml` entry;
   `BackupXmlReader` parses it. The reader **dispatches on the root
   `version` attribute** — `1.x` parses via the v1 path, and a backup
   produced by a future major schema (`2.0`+) is rejected with a clear
   error rather than silently mis-read.
3. The user chooses **Merge** (default, safe — upsert by id, never
   deletes a local record the backup omits) or **Replace all** (wipes
   each store first, behind an explicit confirm). `FullBackupImporter`
   then writes the parsed entities into the same Hive boxes the writer
   read from.

Malformed, corrupt, or unsupported-version files surface a localized
error snackbar and never crash; live data is only ever touched after a
successful parse.

## Out of scope

- **Encryption** — backup is plaintext XML. If a privacy review later
  requires encryption, that's a separate issue with its own threat
  model.
- **Cloud auto-upload** — the share sheet is the destination picker;
  users route to Drive / OneDrive / mail themselves.
