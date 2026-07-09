# OBD2 link rewrite — field-validation checklist (Epic #3527, task 7 / #3534)

One real drive with the vLinker FS proves (or falsifies) the rewrite. Take
this checklist along; everything observable lives in the app itself — the
trip-detail charts, the connection status dot, and the diagnostic exports
(Parameters → OBD2 diagnostics → export: connect traces + breadcrumbs).

## Before the drive

- [ ] Build from the epic branch/master with #3528–#3533 merged.
- [ ] Clear old diagnostics (reset button) so the export tells only this
      drive's story.
- [ ] Vehicle profile has the adapter pinned (`obd2AdapterMac` set).

## During the drive

1. **Cold start** — plug the adapter, ignition on, start a recording.
   - Expect: one dial, live data within ~10 s. The breadcrumb export later
     shows `OBD2 link ready — first connect`.
2. **Induced drop** (the 2026-07-08 flatline scenario) — mid-trip, pull the
   adapter for ~20 s, then re-seat it.
   - Expect on screen: charts pause (or degrade to GPS-only when GPS is on),
     the dot pulses amber — and **charts RESUME on their own** within a few
     seconds of re-seating. No permanent flatline, ever.
   - Expect in the export: `OBD2 link drop → OBD2 dial failed (×N, growing
     backoff) → OBD2 link ready — recovered after N dial(s)` — the full
     detect→dial→recovered chain, timestamps strictly increasing.
3. **Garbage/ladder check** (optional, hard to induce) — any `ELM recovery —
   ATWS`/`ATPC` breadcrumbs mean the classify-before-you-kill ladder fired
   and the session survived without a socket recycle.
4. **Engine off** — park, ignition off, leave the app running ~3 min.
   - Expect: at most ONE dial after the adapter sleeps, then
     `OBD2 link parked — engine off`. The loop must NOT keep dialing a
     sleeping car (battery).
5. **Wake** — ignition back on, drive off (or reopen the app).
   - Expect: the link comes back without any manual reconnect tap.

## Red flags in the export (any one = file a bug against #3527)

- **Identical-timestamp dials** — two dial attempts in the same instant means
  a second reconnect authority survived the deletion wave (the #3386 war
  signature: 0–1 ms back-to-back traces alternating firstConnect/liveReconnect).
- **Dead-end reconnecting** — a `reconnecting` state with no later dial,
  ready, or parked breadcrumb: the loop stranded (the exact 2026-07-08 bug;
  structurally impossible now, so seeing it means a regression).
- **Dial storm** — dials more often than the backoff schedule allows
  (0.5→1→2→4→8…30 s cap + ≤12.5% jitter).
- **PID flatline with a green dot** — charts flat while the link claims
  ready: staleness watchdog (15 s) should have recycled the session; check
  for a missing `session:stale` drop breadcrumb.

## After the drive

- [ ] Trip-detail charts show a visible GAP for the induced drop, with data
      on both sides (the trip must not have finalised early).
- [ ] Attach both exports to the epic (#3527) with a one-line verdict per
      checklist item. Green across the board closes #3425's protocol run
      for the rewrite and unblocks the epic's close.
