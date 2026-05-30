-- #2397 — Storage cache bucket for the `tiles` OSM caching proxy.
--
-- Why: the `tiles` edge function (supabase/functions/tiles) proxies OSM
-- raster tiles and caches each PNG in this bucket keyed `{z}/{x}/{y}.png`.
-- On a cache hit it streams the stored bytes back instead of re-fetching
-- from OSM, keeping direct OSM load near zero (the OSM tile-usage policy's
-- caching requirement) and the function inside the Supabase free tier
-- (~1 GB ≈ 100K tiles).
--
-- Access model:
--   - PRIVATE bucket. Tiles are never served straight from Storage to the
--     browser; they only flow back THROUGH the edge function, which reads
--     and writes via the service_role key (service_role bypasses RLS).
--   - No anon / authenticated policies are added, so RLS denies all
--     client-side object access by default — exactly what we want.
--   - 256 KiB per-object cap: most OSM 256x256 PNGs are ~5-20 KB, but
--     dense urban/coastal tiles routinely hit 55-100 KB (a 50 KiB cap
--     silently rejected real tiles → every request was a cache MISS).
--     256 KiB covers the largest raster tiles with headroom while still
--     bounding a malformed upload.
--
-- RLS impact:
--   [x] Adds a private Storage bucket. No public read; no client policies.
--       service_role (the edge function) is the only accessor.
--
-- RLS confirmed: [x] private bucket, service-role-only access; no new
--   client-reachable surface.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'osm-tiles',
  'osm-tiles',
  false,
  262144,                 -- 256 KiB per tile (dense OSM tiles hit 55-100 KB)
  ARRAY['image/png']
)
ON CONFLICT (id) DO NOTHING;
