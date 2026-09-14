// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// What each country's upstream actually supports (#4156, Epic #4155).
///
/// One [ProviderCapability] per registered country, referenced by that
/// country's [CountryServiceEntry]. The entry's field is **required**, so
/// a new country cannot be added without declaring one — the compiler is
/// the test that "a country was added without a capability" can never
/// pass silently.
///
/// ## How these values were established
///
/// Each row was read off the country's own adapter, not off the
/// provider's marketing:
///
///  * [ProviderCapability.openingHours] is true only where the adapter
///    produces a structured `WeeklyOpeningHours` or an explicit
///    open/closed flag we can reason over. SI publishes hours as free
///    text and is therefore **false** — displayable, not evaluable.
///  * [ProviderCapability.priceTimestamp] is true only where the adapter
///    sets `Station.updatedAt` from a stamp the row itself carried.
///  * [ProviderCapability.stationIdentity] is false where the id is
///    synthesised from the record's content.
///  * [ProviderCapability.expectedFreshness] is the cadence the provider
///    documents, NOT our `FuelServicePolicy` TTLs — those say how often
///    we are willing to ask, which is a different question and usually a
///    more conservative number.
///
/// Aspirational values are the failure mode this file exists to prevent.
/// Where a source is structurally incomplete it says so
/// ([ProviderCoverage.partial]); where it is dead it says that too
/// ([ProviderCoverage.none]).
library;

import 'provider_capability.dart';

/// DE Tankerkönig — the reference case: a real 5-minute feed with stable
/// station UUIDs and a structured opening-hours schedule.
///
/// No per-price timestamp: the API stamps nothing per price, so a
/// freshness gate built on it would be measuring our own polling.
const kDeCapability = ProviderCapability(
  stationIdentity: true,
  price: true,
  openingHours: true,
  expectedFreshness: Duration(minutes: 5),
  coverage: ProviderCoverage.national,
);

/// FR Prix Carburants — the richest source the app has: stable `id_pdv`,
/// a structured schedule, the `services` list behind the amenities
/// filter, and a per-station `maj` stamp. The *flux instantané*
/// republishes roughly every 10 minutes.
const kFrCapability = ProviderCapability(
  stationIdentity: true,
  price: true,
  openingHours: true,
  amenities: true,
  priceTimestamp: true,
  expectedFreshness: Duration(minutes: 10),
  coverage: ProviderCoverage.national,
);

/// AT e-control — hourly Spritpreisrechner refresh, structured hours,
/// no per-price stamp.
const kAtCapability = ProviderCapability(
  stationIdentity: true,
  price: true,
  openingHours: true,
  expectedFreshness: Duration(hours: 1),
  coverage: ProviderCoverage.national,
);

/// ES MITECO — national Geoportal dataset with stable IDEESS ids and a
/// weekly schedule. The stamp is on the DATASET, never on a price, so
/// [ProviderCapability.priceTimestamp] is false.
const kEsCapability = ProviderCapability(
  stationIdentity: true,
  price: true,
  openingHours: true,
  expectedFreshness: Duration(hours: 24),
  coverage: ProviderCoverage.national,
);

/// PT DGEG — daily publication, structured hours, per-row stamp.
const kPtCapability = ProviderCapability(
  stationIdentity: true,
  price: true,
  openingHours: true,
  priceTimestamp: true,
  expectedFreshness: Duration(hours: 24),
  coverage: ProviderCoverage.national,
);

/// GB Fuel Finder — the statutory scheme publishes twice daily. Retailer
/// feeds carry a `site_id`; none carries hours, and the amenities the
/// feed schema allows are not parsed, so the app must not offer that
/// filter here.
const kUkCapability = ProviderCapability(
  stationIdentity: true,
  price: true,
  expectedFreshness: Duration(hours: 12),
  coverage: ProviderCoverage.national,
);

/// IT MIMIT osservaprezzi — one CSV a day at 08:00, registry ids, a
/// per-price stamp, no hours.
const kItCapability = ProviderCapability(
  stationIdentity: true,
  price: true,
  priceTimestamp: true,
  expectedFreshness: Duration(hours: 24),
  coverage: ProviderCoverage.national,
);

/// DK — an aggregate of three BRAND feeds (OK, Shell, Q8/F24), roughly
/// 800 of the country's stations.
///
/// [ProviderCoverage.partial] is the honest value and it matters: a
/// cheapest-nearby answer in Denmark speaks only for three chains, and a
/// surface that presents it as "the cheapest around you" is overstating
/// what we know.
const kDkCapability = ProviderCapability(
  stationIdentity: true,
  price: true,
  priceTimestamp: true,
  expectedFreshness: Duration(hours: 12),
  coverage: ProviderCoverage.partial,
);

/// LU — a single regulated national price set by ministerial arrêté.
///
/// There are no stations in this feed at all: the app stands in five
/// city centroids so a radius search finds something, which is why
/// [ProviderCapability.coordinates] is **false**. The price itself is
/// exactly right everywhere in the country, which is why coverage is
/// still national. Those two facts are not in tension — they are
/// different questions, and a single "quality" number could not have
/// expressed both.
const kLuCapability = ProviderCapability(
  stationIdentity: true,
  coordinates: false,
  price: true,
  priceTimestamp: true,
  expectedFreshness: Duration(hours: 24),
  coverage: ProviderCoverage.national,
);

/// SI goriva.si — daily, stable ids. Hours arrive as a free-text line
/// (`openingHoursText`) that we render and cannot evaluate, so
/// [ProviderCapability.openingHours] is false.
const kSiCapability = ProviderCapability(
  stationIdentity: true,
  price: true,
  expectedFreshness: Duration(hours: 24),
  coverage: ProviderCoverage.national,
);

/// MX CRE — permit ids are stable; the feed publishes no open/closed
/// signal at all (#3198) and no per-price stamp.
const kMxCapability = ProviderCapability(
  stationIdentity: true,
  price: true,
  expectedFreshness: Duration(hours: 24),
  coverage: ProviderCoverage.national,
);

/// CL CNE Bencina en Línea — daily, stable ids, and a real schedule.
const kClCapability = ProviderCapability(
  stationIdentity: true,
  price: true,
  openingHours: true,
  expectedFreshness: Duration(hours: 24),
  coverage: ProviderCoverage.national,
);

/// AR Secretaría de Energía — the bulk CSV has no station key, so the
/// adapter synthesises one by hashing `empresa + direccion`.
///
/// [ProviderCapability.stationIdentity] is therefore **false**: an
/// upstream address correction silently becomes a different station, and
/// any favorite or price alert pointing at the old id stops matching.
const kArCapability = ProviderCapability(
  stationIdentity: false,
  price: true,
  priceTimestamp: true,
  expectedFreshness: Duration(hours: 24),
  coverage: ProviderCoverage.national,
);

/// AU NSW FuelCheck — **dead** (#804).
///
/// The `FuelCheckApp/v2` namespace was retired and the replacement
/// requires OAuth2 credentials the app does not carry, so
/// `AustraliaStationService.searchStations` throws on every call. The
/// capability says exactly that rather than letting a consumer assume
/// prices are one request away.
const kAuCapability = ProviderCapability(
  stationIdentity: false,
  coordinates: false,
  price: false,
  expectedFreshness: Duration(hours: 24),
  coverage: ProviderCoverage.none,
);

/// KR OPINET (KNOC) — near-real-time national prices with stable
/// `uniId`s. No hours, no per-price stamp.
const kKrCapability = ProviderCapability(
  stationIdentity: true,
  price: true,
  expectedFreshness: Duration(hours: 1),
  coverage: ProviderCoverage.national,
);

/// GR Paratiritirio Timon via the community `fuelpricesgr` mirror —
/// **prefecture-level**, not station-level (#576, #3539).
///
/// The finest granularity Greece publishes is the νομός, so the app
/// stands in one synthetic station per prefecture:
/// [ProviderCapability.coordinates] false, coverage
/// [ProviderCoverage.partial]. It also runs on a mirror we do not
/// control, which #3194 showed can vanish without notice —
/// [ProviderCapability.freshnessViolatedBy] is how that becomes
/// detectable instead of mysterious.
const kGrCapability = ProviderCapability(
  stationIdentity: true,
  coordinates: false,
  price: true,
  priceTimestamp: true,
  expectedFreshness: Duration(hours: 24),
  coverage: ProviderCoverage.partial,
);

/// RO Monitorul Prețurilor — 15-minute upstream updates, stable ids, a
/// per-row stamp. After DE and FR, the freshest source the app has.
const kRoCapability = ProviderCapability(
  stationIdentity: true,
  price: true,
  priceTimestamp: true,
  expectedFreshness: Duration(minutes: 15),
  coverage: ProviderCoverage.national,
);
