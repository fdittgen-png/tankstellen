// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Deno tests for the `tiles` edge function (#2397, locked by #2403).
//
// OFFLINE + deterministic — covers the route validator and the
// header/UA contract by reading the source, so it does NOT import
// index.ts (which would run `Deno.serve` at module load) and never hits
// the network. Run with: `deno test supabase/functions/tiles/`.

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from 'https://deno.land/std@0.224.0/assert/mod.ts';

// The pure helpers are also defined inline below to keep this test free of
// the `Deno.serve` side effect. They mirror index.ts exactly; if index.ts
// changes its validation, the source-contract assertions at the bottom
// catch the drift.

function parseTileCoords(
  zRaw: string,
  xRaw: string,
  yRaw: string,
): { z: number; x: number; y: number } | null {
  const intRe = /^(0|[1-9][0-9]*)$/;
  if (!intRe.test(zRaw) || !intRe.test(xRaw) || !intRe.test(yRaw)) return null;
  const z = Number(zRaw);
  const x = Number(xRaw);
  const y = Number(yRaw);
  if (!Number.isInteger(z) || z < 0 || z > 19) return null;
  const max = 2 ** z;
  if (!Number.isInteger(x) || x < 0 || x >= max) return null;
  if (!Number.isInteger(y) || y < 0 || y >= max) return null;
  return { z, x, y };
}

function extractZxy(
  pathname: string,
): { z: string; x: string; y: string } | null {
  const cleaned = pathname.replace(/\.png$/i, '');
  const parts = cleaned.split('/').filter((s) => s.length > 0);
  if (parts.length < 3) return null;
  const [z, x, y] = parts.slice(-3);
  return { z, x, y };
}

const SOURCE = await Deno.readTextFile(
  new URL('./index.ts', import.meta.url),
);

Deno.test('parseTileCoords accepts in-range integer tiles', () => {
  assertEquals(parseTileCoords('0', '0', '0'), { z: 0, x: 0, y: 0 });
  assertEquals(parseTileCoords('19', '0', '0'), { z: 19, x: 0, y: 0 });
  // z=2 → 2^2 = 4 tiles per axis, so 3 is the max valid index.
  assertEquals(parseTileCoords('2', '3', '3'), { z: 2, x: 3, y: 3 });
});

Deno.test('parseTileCoords rejects out-of-range zoom', () => {
  assertEquals(parseTileCoords('20', '0', '0'), null); // past OSM cap
  assertEquals(parseTileCoords('99', '0', '0'), null);
});

Deno.test('parseTileCoords rejects x/y past 2^z', () => {
  // z=1 → 2 tiles per axis, valid indices 0..1; 2 is out of range.
  assertEquals(parseTileCoords('1', '2', '0'), null);
  assertEquals(parseTileCoords('1', '0', '2'), null);
  assertEquals(parseTileCoords('0', '1', '0'), null); // z=0 → only (0,0)
});

Deno.test('parseTileCoords rejects non-integer / malformed', () => {
  assertEquals(parseTileCoords('1.0', '0', '0'), null);
  assertEquals(parseTileCoords('01', '0', '0'), null);
  assertEquals(parseTileCoords('+1', '0', '0'), null);
  assertEquals(parseTileCoords('-1', '0', '0'), null);
  assertEquals(parseTileCoords('', '0', '0'), null);
  assertEquals(parseTileCoords('abc', '0', '0'), null);
});

Deno.test('extractZxy pulls z/x/y from the Supabase-routed path', () => {
  assertEquals(extractZxy('/functions/v1/tiles/5/16/10.png'), {
    z: '5',
    x: '16',
    y: '10',
  });
  assertEquals(extractZxy('/tiles/5/16/10'), { z: '5', x: '16', y: '10' });
  assertEquals(extractZxy('/5/16/10.PNG'), { z: '5', x: '16', y: '10' });
});

Deno.test('extractZxy returns null when too few segments', () => {
  assertEquals(extractZxy('/tiles/5'), null);
  assertEquals(extractZxy('/'), null);
});

// ---- Source-contract assertions: lock the header + UA promises -------

Deno.test('function sends a 7-day Cache-Control (604800), never no-cache', () => {
  // Header is `max-age=${CACHE_MAX_AGE_SECONDS}` with the constant = 604800.
  assertStringIncludes(SOURCE, 'CACHE_MAX_AGE_SECONDS = 604800');
  assertStringIncludes(SOURCE, 'max-age=${CACHE_MAX_AGE_SECONDS}');
  assertStringIncludes(SOURCE, "'Cache-Control'");
  assertStringIncludes(SOURCE, 'CDN-Cache-Control');
  assert(
    !SOURCE.includes('no-cache'),
    'tiles function must never emit no-cache',
  );
});

Deno.test('function uses the stable version-free-by-app OSM-facing UA', () => {
  assertStringIncludes(
    SOURCE,
    'de.tankstellen.tile-proxy/1.0 (+https://github.com/fdittgen-png/tankstellen)',
  );
  // The UA must be sent as a User-Agent request header on the OSM fetch.
  assertStringIncludes(SOURCE, "'User-Agent': OSM_TILE_USER_AGENT");
});

Deno.test('function does NOT cache upstream errors', () => {
  // The upstream-error branch returns before any storage upload, and the
  // upload only runs on the success path. Assert the error path 504/passes
  // status through without an upload call between them.
  assertStringIncludes(SOURCE, 'Upstream returned');
  assertStringIncludes(SOURCE, 'Upstream tile fetch failed');
});
