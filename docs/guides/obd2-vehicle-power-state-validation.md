# On-device validation — vehicle power state (Epic #3855)

Drive this once on a build that carries the #3855 bundle. It is the
epic-close gate. Export the error log + breadcrumbs afterwards
(Settings → Diagnostics) and check the tells below.

## The drive

1. **Sit in the car, engine OFF, key out.** Open the app, go to Trips,
   tap Start.
   - expected: the recording **starts** (no "start the engine" error);
     the pill reads *Waiting for the engine — recording on GPS*; the
     status dot is grey; **no Reset button** anywhere.
   - breadcrumbs: `OBD2 start: bus silent — starting GPS-first` and
     `OBD2 recording: engine off at start — GPS-first`; **zero** `OBD2
     dial` / `OBD2 link drop` lines while parked; no `protocol
     establishment` line yet.
2. **Wait ~1 min.** Then start the engine.
   - expected: within ~15 s the pill disappears, live engine data
     appears (rpm, consumption). No user action.
   - breadcrumbs: `OBD2 recording: engine transition — attaching`
     with `engineRunning via voltage …V` (or `via rpm`), then exactly
     one `protocol establishment (reconnect-resume)` and its
     `answered` verdict.
3. **Drive ≥ 10 min normally.** Any drop must recover within ~5–20 s as
   before (#3775 checklist).
4. **Park. Switch the engine off, leave the recording running, stay
   in the car.**
   - expected within ~20 s: pill *Waiting for the engine — recording on
     GPS*, **no** "reconnecting" pill, **no** Reset button.
   - after 3 min stationary: *Engine off for 3 min — stop recording?*
     with Stop / Keep. Tap **Keep** — the prompt must not return.
   - breadcrumbs: `OBD2 recording: silent bus — engine off (asleep via
     voltage 12.xV) — waiting, not recovering`; if the adapter sleeps and
     the socket drops: `OBD2 link drop … car asleep …, parking without a
     dial`. **Zero** dials in this phase.
5. **Restart the engine** (fuel-stop shape).
   - expected: engine data returns by itself within ~15 s; at most **one**
     dial if the adapter had slept (`OBD2 engine running — waking
     reconnect` → `OBD2 link ready`).
6. **Switch off, tap Stop.** Open the trip.
   - expected: the list entry is **green** (OBD2 healthy), not red; the
     detail note reads *Engine off for the first 1:xx and the last y:yy* —
     **never** *"connection dropped"*; consumption and distance are
     plausible; the summary card shows the OBD2 badge.
7. **Reset while asleep (negative test).** With the engine off and a
   recording running, open the kebab → Reset connection.
   - expected: snackbar *Engine is off — start it to reconnect*; **no**
     dial in the breadcrumbs.

## Pass criteria

- No error at either boundary; the driver never had to retry.
- Zero `OBD2 dial` lines while the car was asleep; at most one reset /
  one dial per engine transition.
- Session journal (trip export): `linkEngineOff: trip: waiting for the
  engine` → `degradedGpsOnly: engineOff` → `leftDegraded: engine started`,
  and `ended: user` (or `engineOffParked` for an auto-record trip).
- Samples carry `bv` roughly every 10 s; the values read ~12.x V with
  the engine off and ≥ 13.2 V with it running.

## If something fails

Attach the error-log export to #3855 with the step number. The
breadcrumb chain above is designed so the failing step names itself.
