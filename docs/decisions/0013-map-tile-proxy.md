<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# ADR 0013: Map tile source = Supabase OSM caching proxy; camera = `initialCameraFit`; markers = `bestDisplayPrice`

**Status:** Accepted
**Date:** 2026-05-30
**Issue:** #2395
**Parent Epic:** #2394

## Context

The grey-basemap + `--`-marker bug survived **four** band-aid fixes (#2044,
#2096/#2097, #2122/#2123, #2177/#2221) over two months and kept regressing.
Per the recurring-bug protocol we stopped patching the reset/abort machinery
and reimplemented the map's tile path, camera lifecycle, and marker price
resolution from root cause. The Epic was split into two shippable layers so
the app could land first with zero new infrastructure:

- **Layer 1 (#2409, merged):** deleted the parallel inline `TileLayer` and the
  12-second `_coldStartResetWindow`; routed the basemap through the single
  hardened `SparkiloTileLayer(key: ValueKey('main-tiles'))`; switched the
  camera to `MapOptions.initialCameraFit` + one guarded `didUpdateWidget`
  re-fit + `keepAlive: true`; made the OSM User-Agent stable + version-free
  (`de.tankstellen.app`); added the `bestDisplayPrice` resolver so a station
  with any price never renders `--`. Layer 1 still serves tiles **OSM-direct**.
- **Layer 2 (this ADR + #2396/#2397/#2403):** moves the tile fetch behind a
  Supabase `tiles` caching proxy and flips the app's default tile URL to it.

This ADR fixes the Layer-2 reimplementation contract so every following PR has
a fixed target.

## Decision

### Tile source — Supabase `tiles` edge-function caching proxy

The app's default basemap tiles are served by a Supabase edge function that
proxies `https://tile.openstreetmap.org` with:

- a **stable, server-side OSM-facing User-Agent**,
  `de.tankstellen.tile-proxy/1.0 (+https://github.com/fdittgen-png/tankstellen)`
  (`AppConstants.tileProxyOsmUserAgent`), carrying a contact URL per the OSM
  tile-usage policy;
- a **7-day edge cache** — every response carries
  `Cache-Control: public, max-age=604800` (604 800 s) plus a matching
  `CDN-Cache-Control`, so the Supabase CDN and downstream caches keep tiles for
  a week and direct OSM load stays minimal (the policy's caching requirement);
- **z/x/y bounds validation** (`z ∈ 0..19`, `x`/`y ∈ 0..2^z−1`) so the proxy
  cannot be used as an open relay — out-of-range or non-integer coordinates
  return `400` without ever touching OSM;
- **graceful upstream error handling** — an OSM `404`/`4xx`/`5xx` or a timeout
  is propagated as-is (errors are *not* cached, never `no-cache`), so a
  transient OSM blip does not 500-storm or get pinned in the cache.

App tile URL template (`AppConstants.tileProxyUrl`):

```
https://klelxnkzrxlpzuddhpfg.supabase.co/functions/v1/tiles/{z}/{x}/{y}.png
```

OSM-direct (`AppConstants.osmTileUrl`,
`https://tile.openstreetmap.org/{z}/{x}/{y}.png`) is retained as a documented
fallback: `SparkiloTileLayer` degrades to it when `tileProxyUrl` is empty/unset,
so a misconfigured build still renders a map instead of grey. The on-device
`BuiltInMapCachingProvider` is left default-on (its own 7-day TTL stacks on top
of the edge cache).

### Identity — stable, version-free User-Agents

- **Client → proxy/OSM:** `de.tankstellen.app` (`AppConstants.osmUserAgent`),
  the bare package id with **no `/version` suffix** — a per-release UA looks
  like many distinct clients to OSM's abuse heuristics. The versioned
  `AppConstants.userAgent` is retained for the data-API HTTP clients, where
  per-release identification helps upstream debugging.
- **Proxy → OSM:** `AppConstants.tileProxyOsmUserAgent` (see above), mirrored
  into the edge function.

### Camera — `initialCameraFit`

First paint uses `MapOptions.initialCameraFit` (frames the search circle during
layout, no post-frame race); result changes use a single guarded
`didUpdateWidget` re-fit (mounted + `_mapReady` via `onMapReady` +
value-distinct centre). All reset-stream / cold-start-window machinery is
deleted (Layer 1) and `keepAlive: true` keeps the map alive across tab visits.

### Markers — `bestDisplayPrice`

Markers resolve their price via `bestDisplayPrice(station, selected)`: the
selected fuel where present, else the first non-null price in the order
E10 → E5 → Diesel → Diesel Premium → E85 → LPG → CNG, reporting which fuel
produced it so a fallback can be labelled. `--` is rendered **only** when the
station has no usable price for any fuel. The fuel chip re-triggers
`repeatLastSearch()` so the new fuel's prices are actually fetched.

### Tests (locked by #2403)

- a single-allowlist consistency lint: only `SparkiloTileLayer` may construct a
  raw `TileLayer`, and the map screen must use `SparkiloTileLayer`;
- a proxy URL + cache-header contract test (Dart side: the layer's default URL
  is the proxy template and the OSM UA carries no `digit.digit` version; Deno
  side: the function returns `Cache-Control: max-age=604800` with the stable
  OSM-facing UA);
- a never-blank-marker test: `bestDisplayPrice` returns a real price whenever
  any fuel price exists, `--` only when all are null.

## Consequences

### Positive

- Direct OSM tile load drops to near-zero behind the edge cache → policy
  compliant and resilient to OSM rate-limiting / 429s.
- The stable UA + caching proxy removes the two structural causes OSM was
  enforcing against (versioned UA in the `flutter_map` namespace + uncached
  per-client fetches).
- The app degrades to OSM-direct if the proxy constant is ever cleared, so a
  misconfigured build is never blank.

### Negative / risks

- **Deploy ordering is load-bearing:** the app flip (#2396) must not reach
  users before the `tiles` function is live, or every tile 404s. Mitigated by
  *not* arming auto-merge — the maintainer deploys the function, then merges.
- Adds a Supabase egress + Storage-cache cost. Sized to stay within free tier
  (~500K invocations/mo, ~1 GB ≈ 100K cached tiles); the 7-day edge cache keeps
  invocations low.

### Cost

Supabase only (the Epic's single allowed cost). No PMTiles self-host (exceeds
free tier — out of scope).

## Alternatives Considered

- **Keep OSM-direct (Layer 1 end-state).** Rejected as the *final* state: the
  versioned-UA + uncached-per-client pattern is exactly what OSM enforces
  against; a caching proxy with a stable UA is the policy-clean path.
- **Self-hosted PMTiles / vector basemap.** Rejected: exceeds the Supabase
  free tier and adds a basemap-styling project far beyond this Epic.
- **Third-party tile CDN (MapTiler/Stadia free tier).** Rejected: adds an
  external account + key rotation; the existing Supabase project already covers
  it at no new vendor.

## Reshapes downstream

This ADR fixes the contract for:

- #2396 — flip `SparkiloTileLayer`'s default tile URL to `tileProxyUrl`
  (fallback to `osmTileUrl`); pin the real project subdomain.
- #2397 — `supabase/functions/tiles/index.ts` caching proxy (code only;
  maintainer deploys).
- #2403 — the regression suite at the seams (contract + lint + never-blank).
- #2402 — moving the `© OpenStreetMap contributors` attribution label to ARB
  across all locales (separate issue, out of this PR's scope).
