<!-- Copyright (c) 2026 Florian DITTGEN; SPDX-License-Identifier: AGPL-3.0-or-later -->

# Record useful evidence for a mixture or consumption concern

Enable **Settings → Driving → Troubleshooting → Full diagnostic recording**
before starting the next OBD trip. Keep the car's displacement, fuel type and
vehicle profile accurate. Ordinary driving plus a short stationary warm-idle
period gives different operating conditions; note any symptoms and their times
after stopping. Do not clear fault codes or reset adaptations before collecting
the evidence: that removes useful history and freeze-frame context.

Export the trip's driving analysis after saving it. Schema 7 includes numeric
`obd2Features.healthSignals` and the exact session's `vehicleHealth` diagnostic
evidence, when its local raw recording remains available. The diagnostic file
can also be downloaded from Troubleshooting. The app retains the newest 20
recordings and limits each trace to 50 MiB; export relevant recordings promptly.
Older trips without a file link are explicitly marked unavailable rather than
being matched to a different trip by time proximity.

## What to inspect together

- Bank 1 STFT and LTFT, both separately and combined, including warm-idle and
  warm-moving summaries. A correction is ECU feedback, not a diagnosis of a
  vacuum leak, pump or sensor. Sampling coverage is not time spent lean.
- Fuel-system status: closed loop, warm-up open loop, load/deceleration open
  loop, or feedback fault. Interpret trim data in this operating context.
- Narrowband O2 voltages and optional sensor trims, separately from measured
  wideband equivalence ratio and the commanded ratio. Oxygen-sensor presence
  bitmaps identify the sensor layout. No wideband reading does not mean a car
  with narrowband oxygen sensors has no mixture feedback.
- MAP, MAF, intake temperature, coolant, ignition advance, pressure where
  supported, voltage, load and RPM. Raw traces preserve the time series;
  exported means, ranges, extreme timestamps and gaps help locate events.
- Stored, pending and permanent DTCs, warning-light/readiness bytes,
  freeze-frame replies and code changes. An empty *successful* scan differs
  from an unanswered scan. Pending codes can appear and disappear during a trip.
- Fuel provenance and estimator context: direct fuel-flow PIDs versus MAF or
  speed-density estimates, volumetric efficiency and applied pump gain. An
  estimated trip consumption is not an independent measured fuel-use test;
  compare it with reliable full-tank fill-up records over multiple trips.

Full diagnostic mode explicitly requests fuel trims, petrol fuel pressure,
MAP, MAF, intake temperature and ignition advance, in addition to its oxygen,
electrical, fuel-system, emissions and fault-code plan. Already subscribed
commands are not duplicated. Unsupported requests are dropped after repeated
NO DATA; diagnostic traffic yields to speed/RPM on a slow adapter. Target rates
are not a guarantee of actual sampling or enough bandwidth to evaluate rapid
oxygen switching or misfire. Ignition advance alone does not measure knock
retard or prove a knock-sensor fault. Manufacturer-specific modules and Mode 06
misfire test results require a supported, validated vehicle-specific reader;
this feature does not claim those capabilities.

## Why the November 1 Peugeot 107 export needed this change

The supplied schema-6 example had 20.7% stored STFT/LTFT coverage, not zero.
The mixture lesson used actual stored trim readings. Their numeric summaries
were absent from the export, making the lesson difficult to verify externally.
Its fuel provenance was speed-density (estimated), although the older
`obd2Features.fuelSource` incorrectly said measured merely because a fuel-rate
value was present. Schema 7 corrects that classification, distinguishes mixed
and unknown legacy provenance, and exports the supporting measurements.

Nothing can reconstruct missing sensor values from the old summary alone.
Neither 8.97 estimated L/100 km nor a positive trim correction establishes a
failed pump, throttle body, knock sensor, or unsafe lean combustion.

Protocol references: [OBD Solutions service modes](https://www.obdsol.com/knowledgebase/obd-software-development/obd-services-modes/)
and [CSS Electronics J1979 PID reference](https://www.csselectronics.com/pages/obd2-pid-table-on-board-diagnostics-j1979).
The requests here are read-only; no code-clearing or actuator commands are added.
