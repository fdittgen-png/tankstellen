<!-- Copyright (c) 2026 Florian DITTGEN; SPDX-License-Identifier: AGPL-3.0-or-later -->

# Record useful evidence for a mixture or consumption concern

Enable **Settings → Driving → Troubleshooting → Full diagnostic recording**
before starting the next OBD trip. Keep the car's displacement, fuel type and
vehicle profile accurate. Ordinary driving plus a short stationary warm-idle
period gives different operating conditions; note any symptoms and their times
after stopping. Do not clear fault codes or reset adaptations before collecting
the evidence: that removes useful history and freeze-frame context.

Export the trip's driving analysis after saving it. Schema 8 includes numeric
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
  wideband lambda and commanded lambda. Oxygen-sensor presence
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
value was present. Schema 8 corrects that classification, distinguishes mixed
and unknown legacy provenance, and exports the supporting measurements.

Nothing can reconstruct missing sensor values from the old summary alone.
Neither 8.97 estimated L/100 km nor a positive trim correction establishes a
failed pump, throttle body, knock sensor, or unsafe lean combustion.

Protocol references: [OBD Solutions service modes](https://www.obdsol.com/knowledgebase/obd-software-development/obd-services-modes/)
and [CSS Electronics J1979 PID reference](https://www.csselectronics.com/pages/obd2-pid-table-on-board-diagnostics-j1979).
The requests here are read-only; no code-clearing or actuator commands are added.


## Explainability and source-aware scoring (schema 8)

- `vehicleHealth.sensorTimeline` keeps decoded request timestamps and values
  without resampling. It exports the first 20,000 decoded rows with an explicit
  omitted-row count; statistics still use the whole retained recording. Use the
  raw NDJSON for a complete high-volume series within its recorded file limits.
- `mixtureLessonEvidence` names the actual rule: the displayed trim magnitude
  is mean absolute LTFT of compensating warm-running paired samples, with
  direction from signed STFT+LTFT. Warm coolant alone does not prove closed loop.
- `score.calculation` exports every actual contribution, the exact sum,
  clamp/rounding and reconstruction check. It is a heuristic score, not a
  diagnosis or a calibrated per-engine assessment.
- Speed-density/MAF/unknown fuel cannot establish injector cutoff. Coasting
  becomes unavailable without direct fuel-flow evidence; the model does not
  invent zero fuel during deceleration. No fuel-cut credit is not a penalty.
- J1979 commanded and wideband ratios are raw lambda (<1 rich, >1 lean).
  Historical `lm` / `mq`, Phi-named aliases and plots retain their raw meaning;
  only the two live air-to-fuel paths convert once to true phi for the existing
  mathematical API. Effective AFR is stoichiometric AFR times lambda (within
  the existing clamp bands). This fixes the formerly reversed fuel adjustment
  without rewriting historical samples or changing direct fuel-flow readings.
  See the manufacturer [UltraGauge manual](https://ultra-gauge.com/ultragauge/support/Ultra_Gauge_EM_Plus_v1.4_2_17_22.pdf),
  printed pages 23 and 25, for measured/commanded lambda and AFR conversion.
- Kinematic RPA/PKE/VAPOS and speed-derived coasting are exported for OBD trips
  too. Their definitions and units are included; they are distinct from measured
  injector cutoff. Typed pattern totals export events, seconds and eligible
  exposure separately (model version 2 for direct-fuel-only coast eligibility).
- IMU compact fields carry units and omission semantics. Omitted diagnostic
  stretch records are not missing sensor samples or confirmed manoeuvre counts.
- Climbing and traffic restarts are contextual information, not driver blame.
  Inferred low gear means a possibly unnecessary short gear, not demonstrated
  high-gear low-RPM lugging. The uniform high-RPM heuristic is identified as such.
- Fuel integration remains interval litres divided by total distance. There is
  no coefficient retuning or empirical calibration based on an inferred verdict.

## Robotized gearbox: capture the refusal itself

For the owner-reported 2006 Peugeot 107 2-Tronic concern, neither a driving
score nor engine RPM establishes actuator force, an engaged gear or a failed
2-to-1 shift. Standard OBD engine/emissions and supply-voltage evidence does
not replace a manufacturer-specific gearbox/TCU scan. ABS, airbags and body
modules are not assessed by this recording either; exports state this scope.

Ask the garage to compare requested versus actual gear, clutch and selector
positions, supply voltage under load, actuator current and adaptation state
with the supported vehicle-specific tool. Correlate a failed 2-to-1 attempt
with a successful attempt, stationary N-to-1, cold/warm and E/M modes, retaining
the exact symptom time, speed, displayed gear, warning indicators and DTC
context. A position reading alone does not prove effective clutch release.
No actuator test, code clearing or relearning command is performed by this app.
The owner-reported E10 label does not establish measured ethanol percentage.
