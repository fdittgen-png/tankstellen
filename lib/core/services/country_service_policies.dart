// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'bulk_migration_flags.dart';
import 'fuel_service_policy.dart';

// ---------------------------------------------------------------------------
// Per-service data-source policies (#2264)
// ---------------------------------------------------------------------------
// Seeded from the Epic #2249 per-service audit. Each `CountryServiceEntry`
// (`country_service_data.dart`) references exactly one of these; they are the
// single source of truth for the cache TTLs + rate-limit interval the chain
// and Dio layer read. Values are deliberately conservative — for bulk files
// the soft TTL is roughly the upstream publish cadence and the hard TTL is a
// multiple of it (offline grace), for polled APIs `searchResultTtl` matches
// how fast prices move and `minInterval` matches the published / inferred
// rate limit.
//
// #3232 — extracted from `country_service_registry.dart` alongside the entry
// rows. The entry-referenced policies are public (`k…Policy`); the staged
// legacy/bulk variants stay private to this file.

/// DE Tankerkönig — polled API, ~1 request/min published policy, prices on a
/// 5-minute cadence. (#2264)
const kDePolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(seconds: 60),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(minutes: 5),
  attribution: 'Tankerkönig',
  license: 'CC BY 4.0',
  sourceUrl: 'https://creativecommons.tankerkoenig.de/',
);

/// AT e-control — polled API; the Spritpreisrechner refreshes hourly, so a
/// 1–2 h search TTL and a gentle 1 h min-interval keep us inside policy.
const kAtPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 2),
  attribution: 'E-Control (Spritpreisrechner)',
  license: 'CC BY 3.0 AT',
  sourceUrl: 'https://www.spritpreisrechner.at/',
);

/// MX CRE — polled-then-merged feed that updates several times daily; cache
/// the merged result 4 h and don't re-pull more often than that.
const kMxPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 4),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 4),
  attribution: 'Comisión Reguladora de Energía (CRE)',
  license: 'Libre Uso MX',
  sourceUrl: 'https://datos.gob.mx/busca/dataset/ubicacion-de-gasolineras-y-precios-comerciales-de-gasolina-y-diesel',
);

/// PT DGEG — polled API; the portal publishes daily, so a 12 h search TTL and
/// a 1 h min-interval are comfortable.
const kPtPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 12),
  attribution: 'DGEG (preçoscombustíveis)',
  license: 'Open data (DGEG)',
  sourceUrl: 'https://precoscombustiveis.dgeg.gov.pt/',
);

/// UK CMA Fuel Finder — LEGACY polled fan-out across retailer feeds published
/// daily under the CMA scheme; cache each search 6 h. Default until the bulk
/// migration (#2277) is validated on-device.
const _ukPolicyLegacy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(minutes: 30),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 6),
  attribution: 'CMA Fuel Finder (retailer feeds)',
  license: 'Open Government Licence v3.0',
  sourceUrl: 'https://www.gov.uk/guidance/access-fuel-price-data',
);

/// UK CMA Fuel Finder — BULK consolidated twice-daily file (#2277): one
/// whole-country download per ~12 h publication cadence, persisted and
/// local-filtered. Soft TTL ≈ the publish cadence, hard TTL an offline-grace
/// multiple. Selected only when `BulkMigrationFlags.ukCmaBulk` is `true`.
const _ukPolicyBulk = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration(hours: 12),
  datasetTtlHard: Duration(hours: 48),
  searchResultTtl: Duration.zero,
  attribution: 'CMA Fuel Finder (consolidated)',
  license: 'Open Government Licence v3.0',
  sourceUrl: 'https://www.gov.uk/guidance/access-fuel-price-data',
);

/// Staged-rollout selection (#2277): legacy by default, bulk when flagged.
const kUkPolicy =
    BulkMigrationFlags.ukCmaBulk ? _ukPolicyBulk : _ukPolicyLegacy;

/// LU — government-regulated uniform prices, polled; a daily refresh is ample
/// since the price changes only by ministerial arrêté.
const kLuPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 6),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 12),
  attribution: 'gouvernement.lu',
  license: 'CC0 1.0',
  sourceUrl: 'https://data.public.lu/fr/datasets/prix-des-carburants/',
);

/// SI goriva.si — polled API; daily-ish updates.
const kSiPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 6),
  attribution: 'goriva.si / Ministrstvo za gospodarstvo',
  license: 'Open data (gov.si)',
  sourceUrl: 'https://goriva.si/',
);

/// KR OPINET — polled API; near-real-time prices, 5-minute search TTL.
const kKrPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(seconds: 60),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(minutes: 30),
  attribution: 'OPINET (KNOC)',
  license: 'KOGL Type 1',
  sourceUrl: 'https://www.opinet.co.kr/',
);

/// CL CNE Bencina en Línea — polled API; daily-ish updates.
const kClPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 6),
  attribution: 'CNE (Comisión Nacional de Energía)',
  license: 'Datos Abiertos CL',
  sourceUrl: 'https://www.cne.cl/',
);

/// GR Paratiritirio Timon — polled API (community FastAPI wrapper); prefecture
/// observatory updates roughly daily.
const kGrPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 6),
  attribution: 'Παρατηρητήριο Τιμών Υγρών Καυσίμων',
  license: 'Open data (data.gov.gr)',
  sourceUrl: 'https://paratiritirio.mindev.gov.gr/',
);

/// RO Monitorul Prețurilor — polled API; 15-minute upstream updates.
const kRoPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(minutes: 15),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(minutes: 30),
  attribution: 'Consiliul Concurenței (Monitorul Prețurilor)',
  license: 'Open data (RO)',
  sourceUrl: 'https://www.monitorulpreturilor.info/',
);

/// AU FuelCheck — stub (#804); throws on every search. Policy still recorded
/// so the row exists once an endpoint lands; polled when it does.
const kAuPolicy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(seconds: 60),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(minutes: 30),
  attribution: 'NSW Government FuelCheck',
  license: 'CC BY 4.0',
  sourceUrl: 'https://www.fuelcheck.nsw.gov.au/',
);

/// ES MITECO — bulk national dataset (~12k stations) downloaded per province
/// and filtered locally; published daily.
const kEsPolicy = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(minutes: 30),
  datasetTtlSoft: Duration(hours: 6),
  datasetTtlHard: Duration(hours: 24),
  searchResultTtl: Duration.zero,
  attribution: 'Geoportal Gasolineras (MITECO)',
  license: 'Open data (MITECO)',
  sourceUrl: 'https://geoportalgasolineras.es/',
);

/// IT MIMIT (osservaprezzi) — bulk CSV dataset published daily at 08:00.
const kItPolicy = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(minutes: 30),
  datasetTtlSoft: Duration(hours: 6),
  datasetTtlHard: Duration(hours: 24),
  searchResultTtl: Duration.zero,
  attribution: 'MIMIT (osservaprezzi)',
  license: 'IODL 2.0',
  sourceUrl: 'https://carburanti.mise.gov.it/ospzSearch/',
);

/// AR Secretaría de Energía — bulk CSV dataset (Resolución 314/2016); a few
/// updates per day, large file.
const kArPolicy = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(hours: 1),
  datasetTtlSoft: Duration(hours: 6),
  datasetTtlHard: Duration(hours: 24),
  searchResultTtl: Duration.zero,
  attribution: 'Secretaría de Energía (datos.energia.gob.ar)',
  license: 'Open data (AR)',
  sourceUrl: 'https://datos.energia.gob.ar/dataset/precios-en-surtidor',
);

/// DK — bulk national aggregate across OK / Shell / Q8 feeds, filtered
/// locally; refreshed a few times daily.
const kDkPolicy = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(minutes: 15),
  datasetTtlSoft: Duration(hours: 2),
  datasetTtlHard: Duration(hours: 12),
  searchResultTtl: Duration.zero,
  attribution: 'OK / Shell / Q8 (DK)',
  license: 'Provider terms',
  sourceUrl: 'https://www.ok.dk/privat/produkter/benzinkort/aktuelle-braendstofpriser',
);

/// FR Prix Carburants — LEGACY polled/OSM-enriched per-search query against
/// data.economie.gouv.fr. Default until the bulk migration (#2277) is
/// validated on-device.
const _frPolicyLegacy = FuelServicePolicy(
  model: SourceModel.polledApi,
  minInterval: Duration(minutes: 30),
  datasetTtlSoft: Duration.zero,
  datasetTtlHard: Duration.zero,
  searchResultTtl: Duration(hours: 6),
  attribution: 'Prix Carburants (data.economie.gouv.fr)',
  license: 'Licence Ouverte 2.0',
  sourceUrl: 'https://www.prix-carburants.gouv.fr/',
);

/// FR Prix Carburants — BULK *flux instantané* ZIP (#2277): one whole-country
/// download per ~10 min cadence, persisted and local-filtered (never poll
/// per-station). Soft TTL ≈ the 10-min flux cadence, hard TTL an offline-grace
/// multiple. Selected only when `BulkMigrationFlags.frFluxBulk` is `true`.
const _frPolicyBulk = FuelServicePolicy(
  model: SourceModel.bulkFile,
  minInterval: Duration(minutes: 10),
  datasetTtlSoft: Duration(minutes: 10),
  datasetTtlHard: Duration(hours: 6),
  searchResultTtl: Duration.zero,
  attribution: 'Prix Carburants (flux instantané)',
  license: 'Licence Ouverte 2.0',
  sourceUrl: 'https://www.prix-carburants.gouv.fr/',
);

/// Staged-rollout selection (#2277): legacy by default, bulk when flagged.
const kFrPolicy =
    BulkMigrationFlags.frFluxBulk ? _frPolicyBulk : _frPolicyLegacy;
