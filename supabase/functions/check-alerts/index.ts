// Edge Function: check-alerts
// Evaluates all active price alerts, fetches current prices, and sends
// ntfy notifications when thresholds are met. Intended to be called by
// pg_cron every 5-15 minutes.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { fetchPricesByCountry, type CountryCode, type StationPrices } from '../_shared/api-clients.ts';
import { sendPriceAlertNotification } from '../_shared/ntfy.ts';

// Minimum time between re-triggering the same alert (ms).
const COOLDOWN_MS = 60 * 60 * 1000; // 1 hour

Deno.serve(async (req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // 1. Fetch all active alerts that have an ntfy topic configured
    const { data: alerts, error: alertsError } = await supabase
      .from('price_alerts')
      .select('id, user_id, station_id, country_code, fuel_type, threshold_price, ntfy_topic, last_triggered_at, station_name')
      .eq('is_active', true)
      .not('ntfy_topic', 'is', null);

    if (alertsError) {
      console.error('Failed to fetch alerts:', alertsError);
      return new Response(JSON.stringify({ error: 'Failed to fetch alerts' }), { status: 500 });
    }

    if (!alerts || alerts.length === 0) {
      return new Response(JSON.stringify({ checked: 0, triggered: 0 }));
    }

    // 2. Group station IDs by country to batch API calls
    const stationsByCountry = new Map<CountryCode, Set<string>>();
    for (const alert of alerts) {
      const country = (alert.country_code ?? 'DE') as CountryCode;
      if (!stationsByCountry.has(country)) {
        stationsByCountry.set(country, new Set());
      }
      stationsByCountry.get(country)!.add(alert.station_id);
    }

    // 3. Fetch current prices per country
    const tankerkoenigKey = Deno.env.get('TANKERKOENIG_API_KEY');
    const allPrices = new Map<string, StationPrices>();

    for (const [country, stationIdSet] of stationsByCountry.entries()) {
      try {
        const prices = await fetchPricesByCountry(
          country,
          Array.from(stationIdSet),
          tankerkoenigKey,
        );
        for (const [id, p] of prices.entries()) {
          allPrices.set(id, p);
        }
      } catch (err) {
        console.error(`Failed to fetch prices for country ${country}:`, err);
      }
    }

    // 4. Evaluate each alert against current prices
    let triggered = 0;
    const now = Date.now();

    for (const alert of alerts) {
      // Respect cooldown: skip if triggered recently
      if (alert.last_triggered_at) {
        const lastTriggered = new Date(alert.last_triggered_at).getTime();
        if (now - lastTriggered < COOLDOWN_MS) continue;
      }

      const stationPrices = allPrices.get(alert.station_id);
      if (!stationPrices) continue;

      // Look up the price for the requested fuel type
      const currentPrice = getFuelPrice(stationPrices, alert.fuel_type);
      if (currentPrice === undefined) continue;

      // Trigger if current price is at or below the threshold
      if (currentPrice <= alert.threshold_price) {
        try {
          await sendPriceAlertNotification(
            alert.ntfy_topic,
            alert.station_name ?? alert.station_id,
            alert.fuel_type,
            currentPrice,
            alert.threshold_price,
          );

          // Update last_triggered_at
          await supabase
            .from('price_alerts')
            .update({ last_triggered_at: new Date().toISOString() })
            .eq('id', alert.id);

          triggered++;
        } catch (err) {
          console.error(`Failed to send notification for alert ${alert.id}:`, err);
        }
      }
    }

    return new Response(
      JSON.stringify({ checked: alerts.length, triggered }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('check-alerts unhandled error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500 },
    );
  }
});

/**
 * Extract a specific fuel type price from StationPrices.
 */
function getFuelPrice(prices: StationPrices, fuelType: string): number | undefined {
  const key = fuelType.toLowerCase();
  switch (key) {
    case 'e5':
      return prices.e5;
    case 'e10':
      return prices.e10;
    case 'diesel':
      return prices.diesel;
    case 'e98':
      return prices.e98;
    case 'sp95':
      return prices.sp95;
    case 'sp98':
      return prices.sp98;
    case 'gplc':
      return prices.gplc;
    case 'super':
      return prices.super;
    case 'superplus':
    case 'super_plus':
      return prices.superPlus;
    default:
      return undefined;
  }
}
