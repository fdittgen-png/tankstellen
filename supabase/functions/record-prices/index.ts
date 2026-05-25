// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Edge Function: record-prices
// Records price snapshots for all stations referenced by active alerts.
// Intended to be called by pg_cron hourly. Also cleans up snapshots
// older than 90 days.
//
// Schema notes (#1476):
//   - Reads station_ids from `alerts` (the canonical table; the prior
//     deploy referenced a non-existent `price_alerts`).
//   - alerts has no country_code; defaults to 'DE'. Tracked alongside
//     check-alerts for a future migration that adds it.
//   - price_snapshots is wide-table — one row per (station, recorded_at)
//     with one nullable column per fuel type. Map the StationPrices
//     fields that exist as columns; the rest are dropped (the schema
//     covers e5/e10/e98/diesel and the long-tail biofuel/lpg/cng prices
//     we don't currently fetch).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { fetchPricesByCountry, type CountryCode, type StationPrices } from '../_shared/api-clients.ts';

const RETENTION_DAYS = 90;

Deno.serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // 1. Get distinct station IDs from active alerts.
    const { data: activeAlerts, error: stationsError } = await supabase
      .from('alerts')
      .select('station_id')
      .eq('is_active', true);

    if (stationsError) {
      console.error('Failed to fetch active stations:', stationsError);
      return new Response(JSON.stringify({ error: 'Failed to fetch stations' }), { status: 500 });
    }

    if (!activeAlerts || activeAlerts.length === 0) {
      return new Response(JSON.stringify({ recorded: 0, cleaned: 0 }));
    }

    // Deduplicate stations. country_code isn't on alerts; default to DE
    // until the schema migration adds it.
    const country: CountryCode = 'DE';
    const stationIds = new Set<string>();
    for (const row of activeAlerts) {
      if (row.station_id) stationIds.add(row.station_id as string);
    }

    // 2. Fetch current prices for the country.
    const tankerkoenigKey = Deno.env.get('TANKERKOENIG_API_KEY');
    const allPrices = new Map<string, StationPrices>();

    try {
      const prices = await fetchPricesByCountry(
        country,
        Array.from(stationIds),
        tankerkoenigKey,
      );
      for (const [id, p] of prices.entries()) {
        allPrices.set(id, p);
      }
    } catch (err) {
      console.error(`Failed to fetch prices for country ${country}:`, err);
    }

    // 3. Insert one snapshot row per station — wide-table format.
    const now = new Date().toISOString();
    const snapshots: Array<Record<string, unknown>> = [];

    for (const [stationId, prices] of allPrices.entries()) {
      snapshots.push({
        station_id: stationId,
        country_code: country,
        recorded_at: now,
        e5: prices.e5 ?? null,
        e10: prices.e10 ?? null,
        e98: prices.e98 ?? null,
        diesel: prices.diesel ?? null,
      });
    }

    let recorded = 0;
    if (snapshots.length > 0) {
      const batchSize = 500;
      for (let i = 0; i < snapshots.length; i += batchSize) {
        const batch = snapshots.slice(i, i + batchSize);
        const { error: insertError } = await supabase
          .from('price_snapshots')
          .insert(batch);

        if (insertError) {
          console.error('Failed to insert price snapshots:', insertError);
        } else {
          recorded += batch.length;
        }
      }
    }

    // 4. Clean up old snapshots (older than RETENTION_DAYS)
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - RETENTION_DAYS);

    const { count: cleaned, error: cleanError } = await supabase
      .from('price_snapshots')
      .delete({ count: 'exact' })
      .lt('recorded_at', cutoff.toISOString());

    if (cleanError) {
      console.error('Failed to clean old snapshots:', cleanError);
    }

    return new Response(
      JSON.stringify({
        recorded,
        stations: allPrices.size,
        cleaned: cleaned ?? 0,
      }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('record-prices unhandled error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500 },
    );
  }
});
