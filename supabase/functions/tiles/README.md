<!--
  Copyright (c) 2026 Florian DITTGEN
  SPDX-License-Identifier: MIT
-->

# `tiles` — OSM raster-tile caching proxy

Epic #2394 Layer 2 (#2397). Proxies `https://tile.openstreetmap.org` with a
stable, policy-compliant identity and a 7-day cache so the app no longer
fetches OSM tiles directly. See `docs/decisions/0012-map-tile-proxy.md` for the
full decision.

## What it does

- **Route:** `GET /tiles/{z}/{x}/{y}.png` (the `.png` suffix is optional).
- **Validates** `z ∈ 0..19`, `x`/`y ∈ 0..2^z−1` and that all three are
  integers — out-of-range / non-integer → `400`, OSM is never touched (no open
  relay).
- **Caches** each PNG in the private `osm-tiles` Storage bucket keyed
  `{z}/{x}/{y}.png`. Cache hit → streams stored bytes back (`X-Tile-Cache:
  HIT`). Miss → fetches OSM, stores, returns (`X-Tile-Cache: MISS`).
- **OSM identity:** sends the stable server-side User-Agent
  `de.tankstellen.tile-proxy/1.0 (+https://github.com/fdittgen-png/tankstellen)`
  (mirrors `AppConstants.tileProxyOsmUserAgent`) plus a `Referer`.
- **Cache headers:** every success carries
  `Cache-Control: public, max-age=604800, immutable` (7 days) and a matching
  `CDN-Cache-Control`. Never `no-cache`.
- **Graceful upstream handling:** an OSM `4xx`/`5xx` is propagated with its own
  status; a timeout → `504`. Errors are **never** cached.

## Deploy (maintainer — manual)

This function is intentionally **not** in `supabase/deploy.sh`'s automatic list
and is **not** deployed by CI.

```sh
# Supabase CLI, linked to the project:
supabase functions deploy tiles --project-ref klelxnkzrxlpzuddhpfg

# Plus the Storage bucket (idempotent — safe to re-run):
supabase db push      # applies 20260530000001_osm_tiles_bucket.sql
```

The MCP equivalent is `deploy_edge_function` with `project_id =
klelxnkzrxlpzuddhpfg`, `name = tiles`.

The function reads `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` from the
default Supabase function environment (no extra secrets to set). If those are
absent it still serves tiles by falling straight through to OSM, just without
the Storage cache.

## ⚠️ Deploy BEFORE the app flip merges

The app flip (#2396) points `SparkiloTileLayer`'s default tile URL at
`https://klelxnkzrxlpzuddhpfg.supabase.co/functions/v1/tiles/{z}/{x}/{y}.png`.
If that PR merges and ships to users **before** this function is live, **every
basemap tile 404s** (grey map). Sequence:

1. Deploy this function (+ run `supabase db push` for the bucket).
2. Verify it returns a PNG, e.g.
   `curl -I https://klelxnkzrxlpzuddhpfg.supabase.co/functions/v1/tiles/0/0/0.png`
   → `200`, `Content-Type: image/png`, `Cache-Control: ... max-age=604800`.
3. Only then merge the app PR.

## Free-tier budget

7-day edge cache + the durable `osm-tiles` Storage cache keep invocations and
egress low: target < 500K invocations/mo, ~1 GB Storage (≈ 100K tiles).

## Tests

- Dart contract (`test/features/map/tile_proxy_contract_test.dart`): the app's
  default tile URL is this function's template and the OSM UA carries no
  version.
- Deno route-validator + header contract: `index.test.ts` (run with
  `deno test` — offline, no network).
