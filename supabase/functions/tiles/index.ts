// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Edge Function: tiles
// OSM raster-tile caching proxy (Epic #2394 Layer 2, #2397).
//
// Why: the app used to fetch OSM tiles directly with a per-release
// User-Agent in the `flutter_map` namespace and no shared cache — both
// patterns OSM's tile-usage policy enforces against, and the direct path
// is what kept regressing into grey tiles on a slow/rate-limited round
// trip. This function puts a stable, policy-compliant identity and a
// 7-day cache in front of OSM:
//
//   - One STABLE server-side User-Agent ([OSM_TILE_USER_AGENT], mirrored
//     from `AppConstants.tileProxyOsmUserAgent`) with a contact URL, so we
//     look like a single well-behaved client.
//   - A Supabase Storage bucket ([CACHE_BUCKET]) keyed `{z}/{x}/{y}.png`
//     as the durable cache; on a hit we stream the stored bytes straight
//     back. Stacked on top, every response carries a 7-day
//     `Cache-Control` so the Supabase CDN + downstream caches also keep
//     the tile for a week — direct OSM load stays near zero.
//   - z/x/y bounds validation so the proxy can NOT be abused as an open
//     relay (out-of-range / non-integer → 400, OSM never touched).
//   - Graceful upstream handling: an OSM 4xx/5xx or a timeout is passed
//     through with its own status and is NEVER cached — a transient OSM
//     blip cannot 500-storm us or get pinned in the bucket.
//
// Route: GET /tiles/{z}/{x}/{y}.png   (the `.png` suffix is optional)
//
// Deploy is MANUAL and must happen BEFORE the app flip (#2396) reaches
// users — see README.md. This file is code-only; it is intentionally not
// added to supabase/deploy.sh's automatic list.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

/// Stable OSM-facing identity. Mirrors `AppConstants.tileProxyOsmUserAgent`
/// in lib/core/constants/app_constants.dart — keep the two in lockstep.
const OSM_TILE_USER_AGENT =
  'de.tankstellen.tile-proxy/1.0 (+https://github.com/fdittgen-png/tankstellen)';

/// Project repo, sent as `Referer` per the OSM tile-usage policy so an
/// operator can trace traffic back to us.
const REFERER = 'https://github.com/fdittgen-png/tankstellen';

/// Upstream OSM raster tile server.
const OSM_TILE_BASE = 'https://tile.openstreetmap.org';

/// Storage bucket holding cached PNG tiles, keyed `{z}/{x}/{y}.png`.
/// Created by the 20260530000001_osm_tiles_bucket.sql migration.
const CACHE_BUCKET = 'osm-tiles';

/// 7 days in seconds — the OSM policy's caching expectation. Sent on every
/// success so the Supabase CDN and downstream caches hold the tile.
const CACHE_MAX_AGE_SECONDS = 604800;

/// OSM raster tiles top out at zoom 19. Anything above has no real data.
const MAX_ZOOM = 19;

/// Abort an upstream fetch that stalls, so a hung OSM connection cannot
/// pin the function open.
const UPSTREAM_TIMEOUT_MS = 10000;

/// Headers attached to every successful PNG response. 7-day shared cache
/// (`Cache-Control` for browsers/clients, `CDN-Cache-Control` for the
/// Supabase edge). The cache directive is deliberately always
/// `public, max-age=...` and never a no-store / revalidate-every-time one.
function pngHeaders(extra: Record<string, string> = {}): HeadersInit {
  return {
    'Content-Type': 'image/png',
    'Cache-Control': `public, max-age=${CACHE_MAX_AGE_SECONDS}, immutable`,
    'CDN-Cache-Control': `public, max-age=${CACHE_MAX_AGE_SECONDS}`,
    'Access-Control-Allow-Origin': '*',
    ...extra,
  };
}

/// Parse + validate the `{z}/{x}/{y}` triplet. Returns the integer tuple
/// when every value is an in-range integer, else null (→ caller 400s).
///
/// Bounds: z in [0, MAX_ZOOM]; x,y in [0, 2^z − 1]. Rejecting out-of-range
/// coordinates is what keeps this from being an open relay.
export function parseTileCoords(
  zRaw: string,
  xRaw: string,
  yRaw: string,
): { z: number; x: number; y: number } | null {
  // Strict integer match — reject "1.0", "01", "+1", "0x1", "" etc. before
  // Number() coerces something surprising.
  const intRe = /^(0|[1-9][0-9]*)$/;
  if (!intRe.test(zRaw) || !intRe.test(xRaw) || !intRe.test(yRaw)) return null;

  const z = Number(zRaw);
  const x = Number(xRaw);
  const y = Number(yRaw);

  if (!Number.isInteger(z) || z < 0 || z > MAX_ZOOM) return null;

  const max = 2 ** z; // exclusive upper bound for x/y at this zoom
  if (!Number.isInteger(x) || x < 0 || x >= max) return null;
  if (!Number.isInteger(y) || y < 0 || y >= max) return null;

  return { z, x, y };
}

/// Pull the `{z}/{x}/{y}` path segments out of a request URL, tolerating
/// the `/functions/v1/tiles` prefix Supabase routes under and an optional
/// trailing `.png`. Returns the three raw strings or null.
export function extractZxy(
  pathname: string,
): { z: string; x: string; y: string } | null {
  // Drop any trailing ".png" then split on "/".
  const cleaned = pathname.replace(/\.png$/i, '');
  const parts = cleaned.split('/').filter((s) => s.length > 0);
  // The last three non-empty segments are z/x/y regardless of how many
  // routing prefixes ("functions", "v1", "tiles") precede them.
  if (parts.length < 3) return null;
  const [z, x, y] = parts.slice(-3);
  return { z, x, y };
}

function jsonError(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'GET' && req.method !== 'HEAD') {
    return jsonError('Method not allowed', 405);
  }

  const url = new URL(req.url);

  const raw = extractZxy(url.pathname);
  if (raw === null) {
    return jsonError('Expected /tiles/{z}/{x}/{y}.png', 400);
  }

  const coords = parseTileCoords(raw.z, raw.x, raw.y);
  if (coords === null) {
    // Out-of-range or non-integer — refuse before touching OSM so the
    // proxy cannot be used as an open relay.
    return jsonError('Tile coordinates out of range', 400);
  }

  const { z, x, y } = coords;
  const objectKey = `${z}/${x}/${y}.png`;

  // ---- Storage cache lookup -------------------------------------------
  // Service-role client so we can read/write the private cache bucket.
  // Missing env is a deploy misconfig, not a per-tile error — but we still
  // degrade to an OSM-direct fetch rather than 500 the whole basemap.
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const supabase = supabaseUrl && serviceKey
    ? createClient(supabaseUrl, serviceKey)
    : null;

  if (supabase) {
    const { data: cached, error: cacheErr } = await supabase.storage
      .from(CACHE_BUCKET)
      .download(objectKey);
    if (!cacheErr && cached) {
      const bytes = new Uint8Array(await cached.arrayBuffer());
      return new Response(bytes, {
        status: 200,
        headers: pngHeaders({ 'X-Tile-Cache': 'HIT' }),
      });
    }
  }

  // ---- Upstream fetch on miss -----------------------------------------
  let upstream: Response;
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), UPSTREAM_TIMEOUT_MS);
    try {
      upstream = await fetch(`${OSM_TILE_BASE}/${z}/${x}/${y}.png`, {
        headers: {
          // Stable, policy-compliant identity — NOT per-release.
          'User-Agent': OSM_TILE_USER_AGENT,
          'Referer': REFERER,
          'Accept': 'image/png,image/*;q=0.8',
        },
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timer);
    }
  } catch (_err) {
    // Timeout / network error reaching OSM. Surface as 504; do NOT cache.
    return jsonError('Upstream tile fetch failed', 504);
  }

  if (!upstream.ok) {
    // Propagate OSM's status as-is (404 for a missing tile, 429 when
    // rate-limited, 5xx on their side). Errors are NEVER cached, and the
    // success path always sends a positive max-age cache directive.
    return jsonError(
      `Upstream returned ${upstream.status}`,
      upstream.status,
    );
  }

  const bytes = new Uint8Array(await upstream.arrayBuffer());

  // ---- Populate the cache (best-effort) -------------------------------
  // A write failure must not fail the user's tile — log and serve anyway.
  if (supabase) {
    const { error: uploadErr } = await supabase.storage
      .from(CACHE_BUCKET)
      .upload(objectKey, bytes, {
        contentType: 'image/png',
        cacheControl: String(CACHE_MAX_AGE_SECONDS),
        upsert: true,
      });
    if (uploadErr) {
      console.error(`tiles: cache write failed for ${objectKey}:`, uploadErr);
    }
  }

  return new Response(bytes, {
    status: 200,
    headers: pngHeaders({ 'X-Tile-Cache': 'MISS' }),
  });
});
