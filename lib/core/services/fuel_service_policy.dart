// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// How a country's upstream fuel-price source delivers data.
///
/// This is the discriminator the [StationServiceChain] branches on (#2264):
///
///  - [polledApi] — a live HTTP endpoint queried per-search (lat/lng/radius),
///    rate-limited by [FuelServicePolicy.minInterval] and cached per search
///    key with [FuelServicePolicy.searchResultTtl]. DE Tankerkönig, AT
///    e-control, MX CRE, PT DGEG, UK CMA all behave this way: each search is
///    an upstream request.
///
///  - [bulkFile] — a whole-country dataset downloaded as one file/feed and
///    filtered locally. ES MITECO (~12k stations), IT MIMIT, AR Secretaría de
///    Energía, DK aggregate, etc. For these the per-search-key cache is
///    pointless: every search hits the same in-memory/persisted dataset, so
///    the chain answers "nearby" by local-filtering rather than re-hitting the
///    network or storing one Hive entry per (lat,lng,radius,fuel) tuple. The
///    dataset itself is governed by [FuelServicePolicy.datasetTtlSoft] /
///    [FuelServicePolicy.datasetTtlHard].
enum SourceModel {
  /// Live endpoint queried per search; per-key TTL cache applies.
  polledApi,

  /// Whole-country dataset downloaded once and filtered locally.
  bulkFile,
}

/// Typed, per-country data-source policy — the **single source of truth** for
/// the cache + rate-limiter knobs the service layer reads (#2264, child of
/// Epic #2249).
///
/// Before this type, the chain hard-coded one TTL for every country and the
/// rate limit lived in each Dio factory call. Folding both into one config
/// row per [CountryServiceEntry] means:
///
///  - the chain reads [model] to decide bulk-vs-polled behaviour,
///  - the per-key cache reads [searchResultTtl] for polled sources,
///  - the persisted-dataset read-through reads [datasetTtlSoft] (serve from
///    disk + refresh in the background past this age) and [datasetTtlHard]
///    (force a blocking re-download past this age),
///  - the rate limiter reads [minInterval],
///
/// and adding a country becomes a config row rather than scattered edits.
///
/// [attribution] / [license] are **data**, not yet rendered — the
/// attribution UI is a later batch. They live here as plain const strings so
/// the policy row is the one place the legal text is recorded.
class FuelServicePolicy {
  /// How this source delivers data — the chain's bulk-vs-polled discriminator.
  final SourceModel model;

  /// Minimum spacing between two upstream requests for this source — the
  /// token-bucket / rate-limit interval. For [SourceModel.bulkFile] sources
  /// this throttles how often the *whole dataset* may be re-downloaded; for
  /// [SourceModel.polledApi] it throttles per-search requests.
  final Duration minInterval;

  /// Soft dataset TTL ([SourceModel.bulkFile]): past this age the persisted
  /// dataset is still served (offline-friendly), but the next search triggers
  /// a background refresh. Ignored for [SourceModel.polledApi] sources.
  final Duration datasetTtlSoft;

  /// Hard dataset TTL ([SourceModel.bulkFile]): past this age the dataset is
  /// considered too stale to serve without a blocking re-download. Always
  /// `>= datasetTtlSoft`. Ignored for [SourceModel.polledApi] sources.
  final Duration datasetTtlHard;

  /// Per-search-key cache TTL ([SourceModel.polledApi]): how long a
  /// `search:<country>:<lat>:<lng>:<radius>:<fuel>` Hive entry stays fresh.
  /// Ignored for [SourceModel.bulkFile] sources (they local-filter instead).
  final Duration searchResultTtl;

  /// Human-readable attribution string for the upstream data provider.
  ///
  /// DATA, not a rendered UI string — the attribution UI ships in a later
  /// batch. Brand/proper-noun + provider names only; safe as a const literal.
  // i18n-ignore: data, rendered in a later batch
  final String attribution;

  /// SPDX-style or named licence under which the upstream data is published.
  ///
  /// DATA, not a rendered UI string — see [attribution].
  // i18n-ignore: data, rendered in a later batch
  final String license;

  const FuelServicePolicy({
    required this.model,
    required this.minInterval,
    required this.datasetTtlSoft,
    required this.datasetTtlHard,
    required this.searchResultTtl,
    required this.attribution,
    required this.license,
  });

  /// `true` when this source downloads a whole-country dataset and filters
  /// it locally (the chain answers nearby without a network round-trip).
  bool get isBulkFile => model == SourceModel.bulkFile;

  /// `true` when this source is a live endpoint queried per search.
  bool get isPolledApi => model == SourceModel.polledApi;
}
