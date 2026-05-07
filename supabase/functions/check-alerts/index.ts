// Edge Function: check-alerts
// Evaluates all active price alerts, fetches current prices, and sends
// ntfy notifications when targets are met. Intended to be called by
// pg_cron every 5-15 minutes.
//
// Schema notes (#1476):
//   - The alerts table tracks alert config; ntfy delivery preferences
//     live on push_tokens keyed by user_id. We fetch them in two
//     queries and join client-side: alerts and push_tokens share a
//     user_id that points at users.id, but no direct FK exists between
//     the two, so PostgREST can't infer an embedded resource.
//   - alerts has no country_code column; we fall back to 'DE'. A future
//     migration to add country_code is tracked separately.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { fetchPricesByCountry, type CountryCode, type StationPrices } from '../_shared/api-clients.ts';
import { sendPriceAlertNotification } from '../_shared/ntfy.ts';

// Minimum time between re-triggering the same alert (ms).
const COOLDOWN_MS = 60 * 60 * 1000; // 1 hour

interface AlertRow {
  id: string;
  user_id: string;
  station_id: string;
  station_name: string | null;
  fuel_type: string;
  target_price: number;
  last_triggered_at: string | null;
}

interface PushTokenRow {
  user_id: string;
  ntfy_topic: string;
  enabled: boolean;
}

Deno.serve(async (_req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // 1a. Fetch active alerts.
    const { data: alertRows, error: alertsError } = await supabase
      .from('alerts')
      .select('id, user_id, station_id, station_name, fuel_type, target_price, last_triggered_at')
      .eq('is_active', true);

    if (alertsError) {
      console.error('Failed to fetch alerts:', alertsError);
      return new Response(JSON.stringify({ error: 'Failed to fetch alerts' }), { status: 500 });
    }

    const alerts: AlertRow[] = (alertRows ?? []) as AlertRow[];
    if (alerts.length === 0) {
      return new Response(JSON.stringify({ checked: 0, triggered: 0 }));
    }

    // 1b. Fetch ntfy topics for the alert owners.
    const userIds = Array.from(new Set(alerts.map((a) => a.user_id)));
    const { data: pushRows, error: pushError } = await supabase
      .from('push_tokens')
      .select('user_id, ntfy_topic, enabled')
      .in('user_id', userIds)
      .eq('enabled', true)
      .not('ntfy_topic', 'is', null);

    if (pushError) {
      console.error('Failed to fetch push tokens:', pushError);
      return new Response(JSON.stringify({ error: 'Failed to fetch push tokens' }), { status: 500 });
    }

    const ntfyByUser = new Map<string, string>();
    for (const row of (pushRows ?? []) as PushTokenRow[]) {
      if (row.ntfy_topic) ntfyByUser.set(row.user_id, row.ntfy_topic);
    }

    // Drop alerts whose owner has no enabled ntfy topic — nothing to deliver.
    const deliverable = alerts.filter((a) => ntfyByUser.has(a.user_id));
    if (deliverable.length === 0) {
      return new Response(JSON.stringify({ checked: alerts.length, triggered: 0 }));
    }

    // 2. Group station IDs by country to batch API calls. alerts has no
    // country_code column today; everything falls through to 'DE' until
    // the schema migration lands.
    const stationsByCountry = new Map<CountryCode, Set<string>>();
    for (const alert of deliverable) {
      const country: CountryCode = 'DE';
      if (!stationsByCountry.has(country)) {
        stationsByCountry.set(country, new Set());
      }
      stationsByCountry.get(country)!.add(alert.station_id);
    }

    // 3. Fetch current prices per country.
    const tankerkoenigKey = Deno.env.get('TANKERKOENIG_API_KEY');
    const allPrices = new Map<string, StationPrices>();

    for (const [country, stationIdSet] of stationsByCountry.entries()) {
      try {
        const prices = await fetchPricesByCountry(country, Array.from(stationIdSet), tankerkoenigKey);
        for (const [id, p] of prices.entries()) {
          allPrices.set(id, p);
        }
      } catch (err) {
        console.error(`Failed to fetch prices for country ${country}:`, err);
      }
    }

    // 4. Evaluate each alert against current prices.
    let triggered = 0;
    const now = Date.now();

    for (const alert of deliverable) {
      if (alert.last_triggered_at) {
        const lastTriggered = new Date(alert.last_triggered_at).getTime();
        if (now - lastTriggered < COOLDOWN_MS) continue;
      }

      const stationPrices = allPrices.get(alert.station_id);
      if (!stationPrices) continue;

      const currentPrice = getFuelPrice(stationPrices, alert.fuel_type);
      if (currentPrice === undefined) continue;

      if (currentPrice <= alert.target_price) {
        const ntfyTopic = ntfyByUser.get(alert.user_id);
        if (!ntfyTopic) continue;

        try {
          await sendPriceAlertNotification(
            ntfyTopic,
            alert.station_name ?? alert.station_id,
            alert.fuel_type,
            currentPrice,
            alert.target_price,
          );

          await supabase
            .from('alerts')
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
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500 });
  }
});

function getFuelPrice(prices: StationPrices, fuelType: string): number | undefined {
  const key = fuelType.toLowerCase();
  switch (key) {
    case 'e5': return prices.e5;
    case 'e10': return prices.e10;
    case 'diesel': return prices.diesel;
    case 'e98': return prices.e98;
    case 'sp95': return prices.sp95;
    case 'sp98': return prices.sp98;
    case 'gplc': return prices.gplc;
    case 'super': return prices.super;
    case 'superplus':
    case 'super_plus': return prices.superPlus;
    default: return undefined;
  }
}
