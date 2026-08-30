<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0018: Trip detail v2 — meta row + columnar 5-minute chunks, decoded off the UI isolate

**Status:** Accepted
**Date:** 2026-08-30
**Issue:** #3882 (Epic #3881)
**Related:** #3878 (ADR 0017, bounded-memory recording), #3741 (summaries-only list), #3613 (lazy decode), #3689 (worker isolates cannot open Hive boxes)

## Context

ADR 0017 bounded the memory of a *recording* but left the stored trip
as it was: one JSON string per trip carrying every 1 Hz sample as a map
of up to 34 keys. Opening the detail of a 40-minute trip therefore
decoded ~2 400 maps on the UI isolate (a visible stall), re-decoded them
on every history-list refresh (the per-id provider watched the whole
list), converted the samples into the domain shape five times in the
detail body, and ran ten `any()` scans just to decide which charts to
show. Readers that need two columns — the speed/consumption histogram,
the vehicle aggregates — paid for all 34.

## Decision

1. **A trip is stored as a meta row plus columnar chunks.** Under the
   trip id the box keeps everything `toJson()` emits *except* the samples
   and GPS diagnostics, stamped `v: 2` with the sample count (`sc`) and
   the set of sample columns that carry a value (`cols`). The samples live
   in sidecar rows `<id>::chunk::<n>` of at most 300 samples (5 min at
   1 Hz) as one array per column with delta-encoded timestamps; the GPS
   diagnostics in `<id>::gpsd`. The per-sample codec (`sampleToJson`)
   stays the single source of truth — a chunk is exactly its transpose,
   so decode ∘ encode yields the same maps (pinned by test).
2. **The layout is private to the repository.** `TripHistoryEntry.toJson`
   / `fromJson` — the export, TankSync `trip_details` and backup shapes —
   are untouched; `encodeTripRowsV2` / `decodeTripRowsV2` are the only
   translation and re-assemble the identical map.
3. **Reads are shaped to the reader.** The summary list decodes meta rows
   only; the detail screen decodes chunks on a background isolate
   (`loadByIdAsync` — the raw strings cross over, the entry comes back)
   behind a skeleton, and re-decodes only when the trip's own
   `(sampleCount, verdict, diagnostics)` identity changes; column readers
   (`loadColumns` / `loadSamplesWith`) decode only the arrays they ask
   for; chart visibility is an O(1) lookup in `cols`.
4. **Legacy rows migrate opportunistically and in the background.** A v1
   row still decodes; the first full read schedules its rewrite, and the
   repository provider runs a one-row-at-a-time sweep with a pause
   between rewrites (no timers once every row is v2). The deferred trip
   boxes are schema-stamped like the first-frame boxes.

## Consequences

- Opening a long trip no longer blocks the UI isolate; a list refresh
  caused by an unrelated save or delete no longer re-decodes the open
  trip; the detail body converts samples once.
- The speed/consumption histogram and the vehicle aggregate recompute
  read two columns instead of materialising every trip.
- The box holds more keys (≈ 1 + ⌈n/300⌉ + 1 per trip); `storedIds`,
  `delete` and the cap trim are sidecar-aware. A verdict rewrites the
  meta row only.
- The key-order of a re-assembled `toJson()` map can differ from the
  original; every consumer merges or re-encodes maps, so no contract
  depends on it.

## Alternatives Considered

- **A separate Hive box per trip or a binary (protobuf / CBOR) format.**
  Rejected: the JSON codec is the export and sync wire and is already
  tested end-to-end; the win comes from *not decoding what is not read*,
  which the columnar split gives without a second codec.
- **Keep one row and only move the decode to an isolate.** Rejected: it
  hides the stall but still decodes 34 columns for a two-column reader
  and still re-decodes on every list refresh.
