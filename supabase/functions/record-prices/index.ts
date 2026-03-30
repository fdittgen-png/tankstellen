// Edge Function: record-prices
// Records price snapshots for all stations referenced by active alerts.
// Intended to be called by pg_cron every 15 minutes.
// Also cleans up snapshots older than 90 days.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { fetchPricesByCountry, type CountryCode, type StationPrices } from '../_shared/api-clients.ts';

const RETENTION_DAYS = 90;

Deno.serve(async (req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // 1. Get distinct station IDs from active alerts
    const { data: activeStations, error: stationsError } = await supabase
      .from('price_alerts')
      .select('station_id, country_code')
      .eq('is_active', true);

    if (stationsError) {
      console.error('Failed to fetch active stations:', stationsError);
      return new Response(JSON.stringify({ error: 'Failed to fetch stations' }), { status: 500 });
    }

    if (!activeStations || activeStations.length === 0) {
      return new Response(JSON.stringify({ recorded: 0, cleaned: 0 }));
    }

    // Deduplicate stations and group by country
    const stationsByCountry = new Map<CountryCode, Set<string>>();
    for (const row of activeStations) {
      const country = (row.country_code ?? 'DE') as CountryCode;
      if (!stationsByCountry.has(country)) {
        stationsByCountry.set(country, new Set());
      }
      stationsByCountry.get(country)!.add(row.station_id);
    }

    // 2. Fetch current prices per country
    const tankerkoenigKey = Deno.env.get('TANKERKOENIG_API_KEY');
    const allPrices = new Map<string, { prices: StationPrices; country: CountryCode }>();

    for (const [country, stationIdSet] of stationsByCountry.entries()) {
      try {
        const prices = await fetchPricesByCountry(
          country,
          Array.from(stationIdSet),
          tankerkoenigKey,
        );
        for (const [id, p] of prices.entries()) {
          allPrices.set(id, { prices: p, country });
        }
      } catch (err) {
        console.error(`Failed to fetch prices for country ${country}:`, err);
      }
    }

    // 3. Insert price snapshots
    const now = new Date().toISOString();
    const snapshots: Array<Record<string, unknown>> = [];

    for (const [stationId, { prices, country }] of allPrices.entries()) {
      // Create one row per fuel type that has a price
      const fuelEntries: Array<[string, number | undefined]> = [
        ['e5', prices.e5],
        ['e10', prices.e10],
        ['diesel', prices.diesel],
        ['e98', prices.e98],
        ['sp95', prices.sp95],
        ['sp98', prices.sp98],
        ['gplc', prices.gplc],
        ['super', prices.super],
        ['super_plus', prices.superPlus],
      ];

      for (const [fuelType, price] of fuelEntries) {
        if (price !== undefined) {
          snapshots.push({
            station_id: stationId,
            country_code: country,
            fuel_type: fuelType,
            price,
            recorded_at: now,
          });
        }
      }
    }

    let recorded = 0;
    if (snapshots.length > 0) {
      // Insert in batches of 500 to stay within payload limits
      const batchSize = 500;
      for (let i = 0; i < snapshots.length; i += batchSize) {
        const batch = snapshots.slice(i, i + batchSize);
        const { error: insertError, count } = await supabase
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
