<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0016: The vehicle's power state is a first-class input

**Status:** Accepted
**Date:** 2026-08-29
**Issue:** #3863
**Parent Epic:** #3855
**Amends:** the engine-off handling of the #3527 link rewrite and the
#3775 ownership fix, which treated a silent bus as a link condition. The
12 #3527 consensus rules, the single-owner invariant and the no-dead-end
loop are unchanged.

## Context

After #3527 / #3775 / #3699 the OBD2 link was reliable **when the engine
was on from the beginning to the end** of a recording (user report,
2026-08-29). Engine off at the start and/or the end still produced
errors, because the app treated the car's electrical state as noise: an
engine that is off was indistinguishable, in most of the pipeline, from
a link that is broken — and every "broken link" path then did exactly
the wrong thing for a parked car.

Verified on master `9cbd64386`:

| boundary | what happened |
|---|---|
| start, engine off | the start gate re-probed `0100`, redialed, then **refused to start** with "start the engine and try again"; every retry re-sent `0100` into a silent bus — the K-line livelock trigger (#3575); the supervisor parked and the key alone never woke it |
| engine off before Stop | 50 null parses → `silentFailure` ("dead ECU") → GPS-degraded → the **reconnect scanner dialed an adapter about to sleep**, feeding the #3603 stand-down with failures that were never failures; the pill offered **Reset**, the one useless action |
| afterwards | coverage was computed over all samples, so a parked tail read *"Engine data stopped 80 % into the trip (connection dropped)"* and painted the trip **red** in the list (#3835) |

And one unused sensor: the ElmSession keepalive already sent `ATRV`
every ~4 s idle and discarded the reply. Battery voltage — ~12.4 V at
rest, ≥ 13.2 V with the alternator — tells engine state *without
touching the vehicle bus*: it works while the ECU is silent, mid
protocol-search, and through the UNABLE-TO-CONNECT livelock, every case
where the bus itself is uninformative.

## Decision

### 1. One model: `VehiclePowerState`

```
unknown         no fresh evidence — every consumer behaves exactly as before
asleep          ECU silent / adapter asleep (ignition off)
ecuAwake        bus answers, rpm == 0 (ignition on, engine off; stop-start pauses)
engineRunning   rpm > 0 OR alternator voltage (EV/hybrid READY maps here)
```

Fused in `Obd2VehiclePower` (`lib/features/obd2/domain/vehicle_power_state.dart`)
from per-source stamps with freshness windows. Evidence ladder, highest wins:

1. **rpm PID** — authoritative (`> 0` running, `== 0` awake). Window 20 s.
2. **`ATRV` voltage** — alternator ≥ 13.2 V on, < 12.8 V off (hysteresis).
   Window 30 s. Parsed from the keepalive reply (`ElmSession.onVoltage`) and
   from an explicit `Obd2Service.readBatteryVoltageV()` the recording loop
   issues every 10 s. Stamped onto samples as `bv`.
3. **Bus probe** — `answered` = awake; `silent` = asleep **only** when the
   voltage agrees. Silent + alternator = the livelock with the engine
   running (#3780), never a parked car.
4. **BT-ACL engine-start hint** (#3699) — `engineStartExpected`, not a state.
5. **GPS motion** — moving with no engine evidence = a tow (#3599),
   `movingWithoutEngine`, never "connect harder".

### 2. Policy — act on the engine, not on the link

| phase | behaviour |
|---|---|
| start, engine off | **start anyway**, GPS-first, pill *Waiting for the engine*; the link is held on its keepalive; **no `0100` while `asleep`**; the emit loop's voltage watch sees the alternator (or the ACL hint / first rpm) and runs the whole deferred start — quiet-window protocol, identity reads, polling |
| engine off mid-recording | `TripDropReason.engineOff` when the silent window coincides with `asleep` evidence (voltage < 12.9 V): **no scanner, no stand-down accounting, no fallback marker**; recording continues on GPS; link kept on the voltage watch; re-attach on the engine transition without a dial |
| link unhealthy, engine **running** | the **only** retry-with-reset case: one bounded protocol recovery, keep the link (never park mid-drive) |
| link unhealthy, engine **off** | zero dials: a drop while `asleep` parks `engineOff` directly; the engine transition (rpm / voltage / ACL / movement / resume) wakes the loop |
| parked, still recording | engine off + stationary ≥ 3 min: manual trips ask *Stop / Keep*; auto-record trips finalise themselves |

### 3. One UX vocabulary

*Connected · Ignition on · Waiting for the engine · Engine off · Reconnecting.*
The **Reset** action is shown only while the engine runs; with the car
asleep its place reads *Start the engine to reconnect*, and tapping the
kebab reset says so instead of dialing.

### 4. Data honesty — the engine-running envelope

`Obd2EngineCoverage` classifies **inside** the first..last engine-running
sample; the head and tail outside it are reported as durations
(*"Engine off for the first 1:40 and the last 3:55"*), and the history
row persists the in-envelope count (`esc`) with the envelope size (`evc`)
so the list badge and the detail agree. A drop is a gap *inside* the
envelope — nothing else. The #3599 transport rule is unchanged.

## Consequences

- With `unknown` evidence every path is byte-for-byte the pre-#3855
  behaviour: the reliability floor is the current one.
- The voltage watch costs one AT reply per 10 s during recording and
  nothing on the bus.
- Trips recorded before #3861 keep their whole-trip classification (no
  `evc` on the row); nothing is re-judged retroactively.
- Out of scope: background (FGS) recording (#3417), dongle-specific sleep
  timings, EV consumption models.

## Alternatives Considered

- **Keep refusing to start with the engine off** (the #3009 gate) and
  improve the error copy. Rejected: the driver's stated workflow is to
  start the recording before turning the key; a refusal plus retry loop
  re-sends `0100` into a silent bus (#3575) and still loses the drive.
- **Voltage only, no fused model.** Rejected: `ATRV` is unavailable on a
  dead socket and ambiguous on EVs / while charging; rpm, the bus probe,
  the ACL hint and GPS motion each cover a case voltage cannot, and one
  arbiter keeps the consumers from disagreeing.
- **Treat a silent bus mid-trip as a regular drop with a longer scanner
  backoff.** Rejected: every dial against a sleeping adapter fed the
  #3603 stand-down with a false failure, and the pill still offered the
  one useless action (Reset).
- **Auto-stop every trip after N minutes parked.** Rejected for manual
  trips (a fuel stop or a ferry queue is not the end of the drive); kept
  for auto-record trips, which started on their own and end on their own.

## Validation

`docs/guides/obd2-vehicle-power-state-validation.md` — the on-device drive
that closes the epic.
