// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Edge Function: aggregate-wait-times
//
// Pairs "arrived"/"left" pings by session_id, computes a rolling
// median wait per (station, hour) window, and upserts into
// public.wait_time_aggregates. Sparse buckets (< 5 samples) are not
// written, so the client sees nothing instead of a noisy hint.
//
// Privacy:
//   - Aggregates carry no user_id. The function reads pings via the
//     service-role key, computes per-session wait seconds, then groups
//     by (station_id, hour) — user identity is dropped before any row
//     is written to the aggregates table.
//   - After aggregation, pings older than the retention window are
//     deleted. The retention horizon is intentionally short (7 days
//     by default) because once a ping has rolled into an aggregate
//     bucket, the raw row is no longer needed.
//
// Scheduling:
//   pg_cron triggers this every 30 minutes via
//   supabase/migrations/20260506000002_wait_time_aggregator_schedule.sql.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// How far back to recompute aggregates each invocation.
const AGGREGATION_WINDOW_HOURS = 24;

// Minimum samples per bucket before a row is written. Mirrors the
// client-side sparse-data fallback in #1119.
const MIN_SAMPLE_COUNT = 5;

// Maximum plausible wait time. Sessions where "left" is more than this
// far from "arrived" are dropped — almost certainly a forgotten "left"
// ping rather than a real 4-hour pump session.
const MAX_WAIT_SECONDS = 60 * 60; // 1 hour

// How long raw pings are retained before deletion.
const PING_RETENTION_DAYS = 7;

interface PingRow {
  session_id: string;
  station_id: string;
  country_code: string;
  event_type: 'arrived' | 'left';
  recorded_at: string;
}

interface SessionPair {
  station_id: string;
  country_code: string;
  arrived_at: number;
  left_at: number;
}

Deno.serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const windowStart = new Date(
      Date.now() - AGGREGATION_WINDOW_HOURS * 60 * 60 * 1000,
    ).toISOString();

    // 1. Pull every ping in the recompute window. The aggregator runs
    // service-role so RLS does not apply; we still scope by recorded_at
    // to keep the working set bounded.
    const { data: pings, error: pingsError } = await supabase
      .from('wait_time_pings')
      .select('session_id, station_id, country_code, event_type, recorded_at')
      .gte('recorded_at', windowStart);

    if (pingsError) {
      console.error('Failed to fetch pings:', pingsError);
      return new Response(JSON.stringify({ error: 'fetch_failed' }), {
        status: 500,
      });
    }

    const sessions = pairSessions((pings ?? []) as PingRow[]);
    const buckets = bucketByStationHour(sessions);

    // 2. Upsert one row per (station, hour) bucket that meets the
    // sample-count floor. Sparse buckets are silently dropped.
    let written = 0;
    const computedAt = new Date().toISOString();
    const rows = Array.from(buckets.values())
      .filter((b) => b.waits.length >= MIN_SAMPLE_COUNT)
      .map((b) => ({
        station_id: b.station_id,
        hour_bucket: b.hour_bucket,
        country_code: b.country_code,
        median_wait_seconds: median(b.waits),
        sample_count: b.waits.length,
        computed_at: computedAt,
      }));

    if (rows.length > 0) {
      const { error: upsertError } = await supabase
        .from('wait_time_aggregates')
        .upsert(rows, { onConflict: 'station_id,hour_bucket' });

      if (upsertError) {
        console.error('Failed to upsert aggregates:', upsertError);
        return new Response(JSON.stringify({ error: 'upsert_failed' }), {
          status: 500,
        });
      }
      written = rows.length;
    }

    // 3. Trim raw pings older than the retention horizon. Once a ping
    // has rolled into a bucket the raw row carries no further value
    // and keeping it around just widens the privacy surface.
    const trimBefore = new Date(
      Date.now() - PING_RETENTION_DAYS * 24 * 60 * 60 * 1000,
    ).toISOString();

    const { error: trimError } = await supabase
      .from('wait_time_pings')
      .delete()
      .lt('recorded_at', trimBefore);

    if (trimError) {
      console.error('Failed to trim old pings:', trimError);
    }

    return new Response(
      JSON.stringify({
        sessions_paired: sessions.length,
        buckets_written: written,
        sparse_buckets_dropped: buckets.size - written,
      }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('aggregate-wait-times unhandled error:', err);
    return new Response(JSON.stringify({ error: 'internal' }), {
      status: 500,
    });
  }
});

/**
 * Pair each session_id's "arrived" with its matching "left" ping.
 * Sessions without both events, or with implausibly long waits, are
 * dropped — they would skew the median.
 */
export function pairSessions(pings: PingRow[]): SessionPair[] {
  const bySession = new Map<string, { arrived?: PingRow; left?: PingRow }>();

  for (const p of pings) {
    const slot = bySession.get(p.session_id) ?? {};
    if (p.event_type === 'arrived') {
      slot.arrived = p;
    } else if (p.event_type === 'left') {
      slot.left = p;
    }
    bySession.set(p.session_id, slot);
  }

  const out: SessionPair[] = [];
  for (const { arrived, left } of bySession.values()) {
    if (!arrived || !left) continue;
    const arrivedMs = Date.parse(arrived.recorded_at);
    const leftMs = Date.parse(left.recorded_at);
    if (!Number.isFinite(arrivedMs) || !Number.isFinite(leftMs)) continue;
    const waitSeconds = Math.round((leftMs - arrivedMs) / 1000);
    if (waitSeconds <= 0 || waitSeconds > MAX_WAIT_SECONDS) continue;

    out.push({
      station_id: arrived.station_id,
      country_code: arrived.country_code,
      arrived_at: arrivedMs,
      left_at: leftMs,
    });
  }
  return out;
}

interface Bucket {
  station_id: string;
  country_code: string;
  hour_bucket: string;
  waits: number[];
}

/**
 * Group sessions into (station_id, hour-of-arrival) buckets. The hour
 * bucket key is the ISO timestamp of the start of the arrival hour
 * (UTC) — matches the storage shape of wait_time_aggregates.hour_bucket.
 */
export function bucketByStationHour(sessions: SessionPair[]): Map<string, Bucket> {
  const buckets = new Map<string, Bucket>();

  for (const s of sessions) {
    const arrived = new Date(s.arrived_at);
    arrived.setUTCMinutes(0, 0, 0);
    const hour = arrived.toISOString();
    const key = `${s.station_id}|${hour}`;
    let bucket = buckets.get(key);
    if (!bucket) {
      bucket = {
        station_id: s.station_id,
        country_code: s.country_code,
        hour_bucket: hour,
        waits: [],
      };
      buckets.set(key, bucket);
    }
    bucket.waits.push(Math.round((s.left_at - s.arrived_at) / 1000));
  }
  return buckets;
}

/**
 * Median of a non-empty list of integers. For even-sized lists,
 * returns the rounded mean of the two middle values.
 */
export function median(values: number[]): number {
  const sorted = [...values].sort((a, b) => a - b);
  const n = sorted.length;
  const mid = Math.floor(n / 2);
  if (n % 2 === 1) return sorted[mid];
  return Math.round((sorted[mid - 1] + sorted[mid]) / 2);
}
