// Shared API clients for fetching fuel prices from government/open data sources.
// Each country has its own fetch function that returns a Map<stationId, StationPrices>.

export interface StationPrices {
  e5?: number;
  e10?: number;
  diesel?: number;
  e98?: number;
  sp95?: number;
  sp98?: number;
  gplc?: number;
  super?: number;
  superPlus?: number;
  updatedAt?: string;
}

// ---------------------------------------------------------------------------
// Tankerkoenig (Germany) — requires user-provided API key
// Docs: https://creativecommons.tankerkoenig.de/
// ---------------------------------------------------------------------------

export async function fetchTankerkoenigPrices(
  stationIds: string[],
  apiKey: string,
): Promise<Map<string, StationPrices>> {
  const result = new Map<string, StationPrices>();

  if (stationIds.length === 0) return result;

  // The prices endpoint accepts up to 10 IDs at once.
  const batchSize = 10;
  for (let i = 0; i < stationIds.length; i += batchSize) {
    const batch = stationIds.slice(i, i + batchSize);
    const url = `https://creativecommons.tankerkoenig.de/json/prices.php?ids=${batch.join(',')}&apikey=${apiKey}`;

    const response = await fetch(url);
    if (!response.ok) {
      console.error(`Tankerkoenig API error: ${response.status} ${response.statusText}`);
      continue;
    }

    const data = await response.json();
    if (!data.ok) {
      console.error(`Tankerkoenig API returned error: ${data.message}`);
      continue;
    }

    for (const [id, info] of Object.entries(data.prices ?? {})) {
      const p = info as Record<string, unknown>;
      if (p.status !== 'open') continue;
      result.set(id, {
        e5: typeof p.e5 === 'number' ? p.e5 : undefined,
        e10: typeof p.e10 === 'number' ? p.e10 : undefined,
        diesel: typeof p.diesel === 'number' ? p.diesel : undefined,
        updatedAt: new Date().toISOString(),
      });
    }
  }

  return result;
}

// ---------------------------------------------------------------------------
// Prix-Carburants (France) — no API key required (government open data)
// Docs: https://www.prix-carburants.gouv.fr/
// ---------------------------------------------------------------------------

export async function fetchPrixCarburantsPrices(
  stationIds: string[],
): Promise<Map<string, StationPrices>> {
  const result = new Map<string, StationPrices>();

  if (stationIds.length === 0) return result;

  // The instantane endpoint returns all stations; we filter locally.
  // In production, caching this response for a few minutes is advisable.
  const url = 'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/prix-des-carburants-en-france-flux-instantane-v2/records';

  // Query in batches of station IDs to avoid overly long URLs.
  const batchSize = 20;
  for (let i = 0; i < stationIds.length; i += batchSize) {
    const batch = stationIds.slice(i, i + batchSize);
    const whereClause = batch.map((id) => `id="${id}"`).join(' OR ');
    const params = new URLSearchParams({
      where: whereClause,
      limit: String(batchSize),
      select: 'id,prix',
    });

    try {
      const response = await fetch(`${url}?${params.toString()}`);
      if (!response.ok) {
        console.error(`Prix-Carburants API error: ${response.status}`);
        continue;
      }

      const data = await response.json();
      for (const record of data.results ?? []) {
        const prices: StationPrices = { updatedAt: new Date().toISOString() };
        const prixList = record.prix ?? [];

        for (const entry of prixList) {
          const nom = (entry['@nom'] ?? entry.nom ?? '').toLowerCase();
          const valeur = parseFloat(entry['@valeur'] ?? entry.valeur ?? '');
          if (isNaN(valeur)) continue;

          // Convert from EUR/1000L to EUR/L
          const pricePerLitre = valeur / 1000;

          switch (nom) {
            case 'gazole':
              prices.diesel = pricePerLitre;
              break;
            case 'sp95':
              prices.sp95 = pricePerLitre;
              break;
            case 'sp98':
              prices.sp98 = pricePerLitre;
              break;
            case 'e10':
              prices.e10 = pricePerLitre;
              break;
            case 'e85':
              prices.e5 = pricePerLitre;
              break;
            case 'gplc':
              prices.gplc = pricePerLitre;
              break;
          }
        }

        result.set(record.id, prices);
      }
    } catch (err) {
      console.error(`Prix-Carburants fetch error: ${err}`);
    }
  }

  return result;
}

// ---------------------------------------------------------------------------
// E-Control (Austria) — no API key required (government open data)
// Docs: https://www.e-control.at/spritpreisrechner
// ---------------------------------------------------------------------------

export async function fetchEControlPrices(
  stationIds: string[],
): Promise<Map<string, StationPrices>> {
  const result = new Map<string, StationPrices>();

  if (stationIds.length === 0) return result;

  // E-Control provides a search-by-region API. For individual station lookups
  // we query the detail endpoint per station.
  const baseUrl = 'https://api.e-control.at/sprit/1.0/search/gas-stations/by-address';

  for (const stationId of stationIds) {
    try {
      const detailUrl = `https://api.e-control.at/sprit/1.0/search/gas-stations/${stationId}`;
      const response = await fetch(detailUrl, {
        headers: {
          'Accept': 'application/json',
        },
      });

      if (!response.ok) {
        console.error(`E-Control API error for station ${stationId}: ${response.status}`);
        continue;
      }

      const station = await response.json();
      const prices: StationPrices = { updatedAt: new Date().toISOString() };

      for (const price of station.prices ?? []) {
        const label = (price.fuelType ?? price.label ?? '').toLowerCase();
        const amount = parseFloat(price.amount ?? '');
        if (isNaN(amount)) continue;

        if (label.includes('diesel')) {
          prices.diesel = amount;
        } else if (label.includes('super 95') || label === 'sup') {
          prices.e5 = amount;
        } else if (label.includes('super plus') || label.includes('super 98')) {
          prices.superPlus = amount;
        }
      }

      result.set(stationId, prices);
    } catch (err) {
      console.error(`E-Control fetch error for station ${stationId}: ${err}`);
    }
  }

  return result;
}

// ---------------------------------------------------------------------------
// Dispatcher: fetch prices by country code
// ---------------------------------------------------------------------------

export type CountryCode = 'DE' | 'FR' | 'AT';

export async function fetchPricesByCountry(
  country: CountryCode,
  stationIds: string[],
  apiKey?: string,
): Promise<Map<string, StationPrices>> {
  switch (country) {
    case 'DE':
      if (!apiKey) throw new Error('Tankerkoenig API key required for DE stations');
      return fetchTankerkoenigPrices(stationIds, apiKey);
    case 'FR':
      return fetchPrixCarburantsPrices(stationIds);
    case 'AT':
      return fetchEControlPrices(stationIds);
    default:
      console.warn(`Unsupported country code: ${country}`);
      return new Map();
  }
}
