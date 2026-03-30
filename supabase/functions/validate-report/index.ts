// Edge Function: validate-report
// Validates community-submitted price reports by comparing against official
// prices and enforcing rate limits. Intended to be called via a database
// webhook when a new row is inserted into the price_reports table.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { fetchPricesByCountry, type CountryCode } from '../_shared/api-clients.ts';

// A reported price deviating more than this percentage from the official
// price is considered invalid.
const MAX_DEVIATION_PERCENT = 50;

// Maximum reports per station per reporter per day.
const MAX_REPORTS_PER_DAY = 3;

Deno.serve(async (req: Request) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Parse the incoming payload (from database webhook or direct invocation)
    const body = await req.json();
    const report = body.record ?? body;

    const {
      id: reportId,
      station_id: stationId,
      country_code: countryCode,
      fuel_type: fuelType,
      reported_price: reportedPrice,
      reporter_id: reporterId,
    } = report;

    if (!reportId || !stationId || !fuelType || reportedPrice === undefined || !reporterId) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields in report' }),
        { status: 400 },
      );
    }

    const country = (countryCode ?? 'DE') as CountryCode;

    // 1. Rate limit check: max N reports per station per reporter per day
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const { count: reportsToday, error: countError } = await supabase
      .from('price_reports')
      .select('id', { count: 'exact', head: true })
      .eq('station_id', stationId)
      .eq('reporter_id', reporterId)
      .gte('created_at', todayStart.toISOString());

    if (countError) {
      console.error('Failed to count reports:', countError);
    }

    if ((reportsToday ?? 0) > MAX_REPORTS_PER_DAY) {
      // Rate limited: mark as not validated with a reason
      await supabase
        .from('price_reports')
        .update({
          is_validated: false,
          validation_reason: `Rate limit exceeded: max ${MAX_REPORTS_PER_DAY} reports per station per day`,
        })
        .eq('id', reportId);

      return new Response(
        JSON.stringify({ validated: false, reason: 'rate_limited' }),
        { headers: { 'Content-Type': 'application/json' } },
      );
    }

    // 2. Fetch the official price for comparison
    const tankerkoenigKey = Deno.env.get('TANKERKOENIG_API_KEY');
    let officialPrice: number | undefined;

    try {
      const prices = await fetchPricesByCountry(country, [stationId], tankerkoenigKey);
      const stationPrices = prices.get(stationId);

      if (stationPrices) {
        officialPrice = getPrice(stationPrices, fuelType);
      }
    } catch (err) {
      console.error(`Failed to fetch official price for station ${stationId}:`, err);
    }

    // 3. Validate by comparing against the official price
    let isValidated: boolean;
    let validationReason: string;

    if (officialPrice === undefined) {
      // Cannot validate — no official price available; accept provisionally
      isValidated = true;
      validationReason = 'No official price available for comparison; accepted provisionally';
    } else {
      const deviation = Math.abs(reportedPrice - officialPrice) / officialPrice * 100;

      if (deviation > MAX_DEVIATION_PERCENT) {
        isValidated = false;
        validationReason = `Reported price ${reportedPrice.toFixed(3)} deviates ${deviation.toFixed(1)}% from official price ${officialPrice.toFixed(3)}`;
      } else {
        isValidated = true;
        validationReason = `Within ${deviation.toFixed(1)}% of official price ${officialPrice.toFixed(3)}`;
      }
    }

    // 4. Update the report with validation result
    const { error: updateError } = await supabase
      .from('price_reports')
      .update({
        is_validated: isValidated,
        validation_reason: validationReason,
        validated_at: new Date().toISOString(),
      })
      .eq('id', reportId);

    if (updateError) {
      console.error('Failed to update report validation:', updateError);
      return new Response(
        JSON.stringify({ error: 'Failed to update report' }),
        { status: 500 },
      );
    }

    return new Response(
      JSON.stringify({
        validated: isValidated,
        reason: validationReason,
        officialPrice: officialPrice ?? null,
      }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('validate-report unhandled error:', err);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500 },
    );
  }
});

/**
 * Extract a specific fuel type price from a StationPrices-like object.
 */
function getPrice(prices: Record<string, unknown>, fuelType: string): number | undefined {
  const key = fuelType.toLowerCase();
  const mapping: Record<string, string> = {
    e5: 'e5',
    e10: 'e10',
    diesel: 'diesel',
    e98: 'e98',
    sp95: 'sp95',
    sp98: 'sp98',
    gplc: 'gplc',
    super: 'super',
    superplus: 'superPlus',
    super_plus: 'superPlus',
  };

  const propName = mapping[key];
  if (!propName) return undefined;

  const val = prices[propName];
  return typeof val === 'number' ? val : undefined;
}
