<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0017: Trip recording is bounded-memory — live ring, WAL as the source of truth, incremental aggregates, downsampled rendering

**Status:** Accepted
**Date:** 2026-08-29
**Issue:** #3878
**Related:** #3758 (append-only sample WAL), #3613 (lazy trip decode), #3741 (zero-copy buffer views)

## Context

A recording captures one `TripSample` (30 fields, ~400 B in memory) per
second for as long as the drive lasts. Before this decision the whole
capture list lived in memory until stop (cap 120 000 = 33 h), the GPS-only
pipeline had no cap at all, the harsh-event counts were recomputed by
scanning the event list eight times a second, the stop path walked the
full list three to four times (gear coaching, fuel back-fill, coverage
twice, the sync payload re-decoded from the row just written), and the
post-save hook decoded **every** stored trip of the vehicle with its
samples and copied them into an isolate to recompute aggregates — the
single largest peak, right at the moment the user taps Stop. The detail
screen drew every GPS point and every sample in every chart.

#3758 had already moved persistence to an append-only NDJSON WAL, but the
WAL was fed from the in-memory list by index, so the list could not be
trimmed.

## Decision

1. **Online aggregation + a bounded live window.** Every summary
   statistic is folded in O(1) per sample (the recorder already did;
   harsh counts now too). In memory the capture buffer is a **ring of the
   last 15 min** (`TripSampleBuffer.kLiveWindow` = 900). It releases a
   sample only once the WAL has it on disk (the flush hands the unwritten
   tail to the WAL by absolute index and then calls `releaseWritten`);
   a broken WAL keeps the old full list, so nothing is ever lost.
2. **The WAL is the source of truth at stop.** `stop()` flushes the tail
   and reads the whole trip back from the file in one isolate hop
   (`readAllCapturedSamples`), then runs the remaining whole-trip passes
   once (gear coaching over the returned list, fuel back-fill, coverage
   computed once in `toJson`). The GPS-only pipeline does the same
   (`GpsOnlyTripWal.readAll`), and stamps the per-fix fuel estimate
   *before* the sample reaches the WAL.
3. **Incremental vehicle aggregates.** The post-save hook receives the
   saved entry and folds it in (`VehicleAggregateUpdater.foldInTrip`);
   the full recompute is reserved for the below-threshold / no-priors
   cases and the admin action. The sync payload reuses the entry in hand.
4. **Rendering downsamples; storage does not.** Charts draw at most
   1 500 points chosen by LTTB (Largest-Triangle-Three-Buckets, the
   standard for time series — keeps peaks and troughs); the map polyline
   is simplified with Douglas–Peucker at 4 m above 2 000 fixes. Every
   sample is still persisted and exported.
5. **Caps everywhere a list could still grow**: the GPS-only ring, the
   road-grade window by count, the harsh events as counters.

## Consequences

- Steady-state RSS of a recording no longer grows with trip duration
  (~15 min of samples in memory regardless of a 3 h drive); the stop-time
  peak is one sample list instead of three to four plus a decode of the
  vehicle's whole history.
- The on-disk trip format is unchanged (one JSON row per trip with every
  sample); exports, sync and recovery keep working as before.
- `capturedSamples` on the controller now means *the live window*; code
  that needs the whole trip asks the host (`readAllCapturedSamples` /
  `collectAllSamples`).
- The next step — not taken here — is a columnar, delta-encoded trip
  detail format in 5-minute chunks so the detail screen and TankSync can
  stream a trip instead of decoding one string.

## Alternatives Considered

- **Keep the full list but raise the compute threshold.** Rejected: the
  list itself is the memory, and the OS kills on RSS, not on CPU.
- **Downsample what is stored** (keep 1 sample / 5 s). Rejected: the
  detail charts, GPX export and the driving-score lessons need the 1 Hz
  truth; rendering is where the reduction belongs.
- **Compute everything in the isolate and never materialise samples on
  the UI isolate.** Deferred: it needs the trip-entry builder to move
  behind the isolate boundary (a larger refactor); the ring + WAL read
  already removes the duration-proportional growth.
