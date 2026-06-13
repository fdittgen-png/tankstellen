// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../country/country_bounding_box.dart';
import '../domain/fuel_type.dart';
import 'country_service_entry.dart';
import 'country_service_policies.dart';
import 'service_result.dart';

/// #3232 — the country data rows extracted out of `country_service_registry.dart`.
///
/// Holds the ordered [kCountryServiceEntries] list and the [kDefaultFuelTypes]
/// fallback — the pure data the registry's behaviour (lookups + service
/// builders) reads. The per-service [FuelServicePolicy] consts each row
/// references live in `country_service_policies.dart`. The registry exposes
/// `CountryServiceRegistry.entries` as an alias of [kCountryServiceEntries], so
/// no call site changed. Adding a country still means appending exactly one
/// [CountryServiceEntry] here (and one `k…Policy` const next door).

/// Default ordered fuel-type list returned for any country not present in
/// the registry. Mirrors the historical `default:` branch of the old
/// `fuelTypesForCountry` switch — the minimal set every petrol/diesel
/// station can be assumed to carry, plus EV and the "all" wildcard.
const List<FuelType> kDefaultFuelTypes = [
  FuelType.e5,
  FuelType.e10,
  FuelType.diesel,
  FuelType.electric,
  FuelType.all,
];

/// All registered country service entries.
///
/// Ordering note: the list is ordered for the bounding-box lookup
/// algorithm (see `CountryServiceRegistry.entryByLatLng`). Small
/// / island / coastal countries come first so their tight boxes are
/// not shadowed by larger neighbours whose generous boxes incidentally
/// overlap them — e.g. `PT`'s tight Iberian box sits entirely inside
/// `ES`'s generous box, so `PT` must be tested first. Cross-currency
/// border cases (#516) drove the ordering decisions:
///
/// - `PT` first → its tight box is entirely inside `ES`'s.
/// - `GB` early → island, no continental overlap.
/// - `DK` before `DE` → Copenhagen's lat sits inside DE's box.
/// - `LU` before `FR` / `DE` → Luxembourg-Ville at (49.6, 6.1) sits
///   inside both.
/// - `SI` before `AT` / `IT` → Ljubljana sits inside both.
/// - `CL` before `AR` → Santiago sits inside AR's generous box.
/// - Continental EU countries last so stations outside every tighter
///   box still get attributed to something European.
const List<CountryServiceEntry> kCountryServiceEntries = [
  // ── Tight-box / island first (avoid shadowing) ─────────────────────
  CountryServiceEntry(
    countryCode: 'PT',
    errorSource: ServiceSource.portugalApi,
    boundingBox: CountryBoundingBox(
      minLat: 32.0, maxLat: 42.5, minLng: -32.0, maxLng: -6.0,
    ),
    availableFuelTypes: [
      FuelType.e5, FuelType.e98, FuelType.diesel,
      FuelType.lpg, FuelType.electric, FuelType.all,
    ],
    policy: kPtPolicy,
  ),
  CountryServiceEntry(
    countryCode: 'GB',
    errorSource: ServiceSource.ukApi,
    boundingBox: CountryBoundingBox(
      minLat: 49.5, maxLat: 61.0, minLng: -9.0, maxLng: 2.0,
    ),
    // GB (#2180): UkStationService parses the CMA feed into e5
    // (E5/unleaded), e10 (E10), e98 (super_unleaded), diesel
    // (B7/diesel). _defaultFuelTypes omitted e98, so super-unleaded
    // stations could not be searched — promote to the explicit set.
    availableFuelTypes: [
      FuelType.e5, FuelType.e10, FuelType.e98, FuelType.diesel,
      FuelType.electric, FuelType.all,
    ],
    policy: kUkPolicy,
  ),
  CountryServiceEntry(
    countryCode: 'DK',
    errorSource: ServiceSource.denmarkApi,
    boundingBox: CountryBoundingBox(
      minLat: 54.0, maxLat: 58.0, minLng: 7.5, maxLng: 15.5,
    ),
    // DK (#3198): the single 95-octane grade is e5 only (no published
    // E10); the #3187 exact-grade mapping emits Oktan 100 / V-Power →
    // e98 and V-Power Diesel → dieselPremium.
    availableFuelTypes: [
      FuelType.e5, FuelType.e98, FuelType.diesel,
      FuelType.dieselPremium, FuelType.electric, FuelType.all,
    ],
    policy: kDkPolicy,
  ),
  CountryServiceEntry(
    countryCode: 'LU',
    errorSource: ServiceSource.luxembourgApi,
    // Tight box — LU is ~82 km north-south, ~57 km east-west; modest
    // margin so BE/FR/DE neighbours don't bleed into LU matches.
    boundingBox: CountryBoundingBox(
      minLat: 49.4, maxLat: 50.25, minLng: 5.7, maxLng: 6.55,
    ),
    // Luxembourg regulated prices (#574): Sans Plomb 95 (E5/E10),
    // Sans Plomb 98, Diesel, LPG.
    availableFuelTypes: [
      FuelType.e5, FuelType.e10, FuelType.e98, FuelType.diesel,
      FuelType.lpg, FuelType.electric, FuelType.all,
    ],
    policy: kLuPolicy,
  ),
  CountryServiceEntry(
    countryCode: 'SI',
    errorSource: ServiceSource.sloveniaApi,
    // Tight box — Slovenia surrounded by IT / AT / HR; over-generous
    // margin would shadow them. See #575.
    boundingBox: CountryBoundingBox(
      minLat: 45.3, maxLat: 47.0, minLng: 13.3, maxLng: 16.7,
    ),
    // Slovenia (#575/#3198): NMB-95 → e5 (single 95-octane grade — the
    // old e5→e10 mirror is gone, goriva.si publishes no E10),
    // NMB-100/98 → e98, Dizel → diesel, Dizel Premium → dieselPremium,
    // avtoplin-lpg → lpg, cng → cng.
    availableFuelTypes: [
      FuelType.e5, FuelType.e98, FuelType.diesel,
      FuelType.dieselPremium, FuelType.lpg, FuelType.cng,
      FuelType.electric, FuelType.all,
    ],
    policy: kSiPolicy,
  ),
  // ── Continental EU (test order matters for shadow neighbours) ─────
  CountryServiceEntry(
    countryCode: 'AT',
    errorSource: ServiceSource.eControlApi,
    boundingBox: CountryBoundingBox(
      minLat: 46.0, maxLat: 49.5, minLng: 9.0, maxLng: 17.5,
    ),
    // AT (#3198): E-Control publishes exactly one petrol grade (SUP);
    // the default set advertised an E10 the feed never carries.
    availableFuelTypes: [
      FuelType.e5, FuelType.diesel, FuelType.electric, FuelType.all,
    ],
    policy: kAtPolicy,
  ),
  CountryServiceEntry(
    countryCode: 'FR',
    errorSource: ServiceSource.prixCarburantsApi,
    // France (mainland), excludes overseas territories.
    boundingBox: CountryBoundingBox(
      minLat: 41.0, maxLat: 51.5, minLng: -5.5, maxLng: 10.0,
    ),
    // FR: Prix Carburants — SP95-E10 first (most common), then
    // SP95 / SP98, Gazole, E85 (Bioéthanol), GPL.
    availableFuelTypes: [
      FuelType.e10, FuelType.e5, FuelType.e98, FuelType.diesel,
      FuelType.e85, FuelType.lpg, FuelType.electric, FuelType.all,
    ],
    policy: kFrPolicy,
  ),
  CountryServiceEntry(
    countryCode: 'IT',
    errorSource: ServiceSource.miseApi,
    boundingBox: CountryBoundingBox(
      minLat: 35.0, maxLat: 47.5, minLng: 6.0, maxLng: 19.0,
    ),
    // IT: MIMIT (osservaprezzi) — Benzina, Gasolio, GPL, Metano (CNG).
    availableFuelTypes: [
      FuelType.e5, FuelType.diesel, FuelType.lpg, FuelType.cng,
      FuelType.electric, FuelType.all,
    ],
    policy: kItPolicy,
  ),
  CountryServiceEntry(
    countryCode: 'ES',
    errorSource: ServiceSource.mitecoApi,
    // Spain (mainland + Balearic + Canary).
    boundingBox: CountryBoundingBox(
      minLat: 27.0, maxLat: 44.0, minLng: -19.0, maxLng: 5.0,
    ),
    // ES: Geoportal Gasolineras — 95/98, Diésel A/A+, GLP.
    availableFuelTypes: [
      FuelType.e5, FuelType.e10, FuelType.e98, FuelType.diesel,
      FuelType.dieselPremium, FuelType.lpg, FuelType.electric,
      FuelType.all,
    ],
    policy: kEsPolicy,
  ),
  CountryServiceEntry(
    countryCode: 'DE',
    errorSource: ServiceSource.tankerkoenigApi,
    requiresApiKey: true,
    boundingBox: CountryBoundingBox(
      minLat: 47.0, maxLat: 55.5, minLng: 5.5, maxLng: 15.5,
    ),
    // DE: Tankerkönig publishes E5, E10, Diesel.
    availableFuelTypes: kDefaultFuelTypes,
    policy: kDePolicy,
  ),
  // ── Non-EU countries (no overlap concerns) ─────────────────────────
  CountryServiceEntry(
    countryCode: 'MX',
    errorSource: ServiceSource.mexicoApi,
    boundingBox: CountryBoundingBox(
      minLat: 14.0, maxLat: 33.0, minLng: -119.0, maxLng: -86.0,
    ),
    // MX (#2704): CRE sells Regular (Magna, e5), Premium (91–92, e98) and
    // Diesel in MXN — premium maps to the high-octane e98 slot, NOT the
    // European e10 ethanol blend. The picker must offer what the parser
    // surfaces.
    availableFuelTypes: [
      FuelType.e5, FuelType.e98, FuelType.diesel,
      FuelType.electric, FuelType.all,
    ],
    policy: kMxPolicy,
  ),
  // CL before AR: Chile's narrow strip sits inside AR's generous
  // longitude range along the cordillera (#596).
  CountryServiceEntry(
    countryCode: 'CL',
    errorSource: ServiceSource.chileApi,
    requiresApiKey: true,
    boundingBox: CountryBoundingBox(
      minLat: -56.5, maxLat: -17.0, minLng: -77.0, maxLng: -66.0,
    ),
    // CL (#596): Gasolina 93/95 (e5), Gasolina 97 (e98), Diésel, LPG.
    availableFuelTypes: [
      FuelType.e5, FuelType.e98, FuelType.diesel,
      FuelType.lpg, FuelType.electric, FuelType.all,
    ],
    policy: kClPolicy,
  ),
  CountryServiceEntry(
    countryCode: 'AR',
    errorSource: ServiceSource.argentinaApi,
    boundingBox: CountryBoundingBox(
      minLat: -56.0, maxLat: -21.0, minLng: -74.0, maxLng: -53.0,
    ),
    // AR (#2180/#3198): ArgentinaStationService emits Nafta súper → e5
    // (no e10 — the feed publishes no E10 grade), Nafta premium → e98,
    // Gas oil → diesel, Gas oil premium → dieselPremium, GNC → cng.
    availableFuelTypes: [
      FuelType.e5, FuelType.e98, FuelType.diesel,
      FuelType.dieselPremium, FuelType.cng, FuelType.electric,
      FuelType.all,
    ],
    policy: kArPolicy,
  ),
  CountryServiceEntry(
    countryCode: 'AU',
    errorSource: ServiceSource.australiaApi,
    boundingBox: CountryBoundingBox(
      minLat: -44.0, maxLat: -9.5, minLng: 112.5, maxLng: 154.0,
    ),
    // AU (#2180): NSW FuelCheck publishes U91 → e5, U95 → e10, U98 →
    // e98, Diesel → diesel, LPG → lpg. AustraliaStationService is a
    // documented stub pending a working endpoint (#804), so there is no
    // live emission to converge on; this mirrors the config's
    // FuelCheck grade set instead of the unrelated _defaultFuelTypes
    // fallback, keeping the picker and selector in agreement.
    availableFuelTypes: [
      FuelType.e5, FuelType.e10, FuelType.e98, FuelType.diesel,
      FuelType.lpg, FuelType.electric, FuelType.all,
    ],
    policy: kAuPolicy,
  ),
  CountryServiceEntry(
    countryCode: 'KR',
    errorSource: ServiceSource.openinetApi,
    requiresApiKey: true,
    // South Korea mainland + Jeju. No overlap with any other
    // registered country. See #597.
    boundingBox: CountryBoundingBox(
      minLat: 33.0, maxLat: 39.0, minLng: 124.0, maxLng: 131.0,
    ),
    // KR (#597): Gasoline (e5), Premium Gasoline (e98), Diesel, LPG.
    availableFuelTypes: [
      FuelType.e5, FuelType.e98, FuelType.diesel,
      FuelType.lpg, FuelType.electric, FuelType.all,
    ],
    policy: kKrPolicy,
  ),
  CountryServiceEntry(
    countryCode: 'GR',
    errorSource: ServiceSource.greeceApi,
    // Eastern edge deliberately pulled in from the geographic limit
    // (~29.6) so Istanbul (41.01, 28.98) is NOT falsely attributed
    // to GR. Kastellorizo is the only Greek territory lost. See #576.
    boundingBox: CountryBoundingBox(
      minLat: 34.5, maxLat: 41.8, minLng: 19.0, maxLng: 28.5,
    ),
    // GR (#576): Αμόλυβδη 95 (e5), Αμόλυβδη 100 (e98), Diesel, LPG.
    availableFuelTypes: [
      FuelType.e5, FuelType.e98, FuelType.diesel,
      FuelType.lpg, FuelType.electric, FuelType.all,
    ],
    policy: kGrPolicy,
  ),
  CountryServiceEntry(
    countryCode: 'RO',
    errorSource: ServiceSource.romaniaApi,
    // No neighbour conflicts — HU, BG, UA, RS, MD are not in the
    // registry. See #577.
    boundingBox: CountryBoundingBox(
      minLat: 43.5, maxLat: 48.5, minLng: 20.0, maxLng: 29.8,
    ),
    // RO (#577): Benzină Standard (e5), Benzină Premium (e98),
    // Motorină Standard (diesel), Motorină Premium (diesel premium),
    // GPL (lpg).
    availableFuelTypes: [
      FuelType.e5, FuelType.e98, FuelType.diesel,
      FuelType.dieselPremium, FuelType.lpg, FuelType.electric,
      FuelType.all,
    ],
    policy: kRoPolicy,
  ),
];
