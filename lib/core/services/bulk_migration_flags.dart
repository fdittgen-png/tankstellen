// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Staged-rollout toggles for the whole-country bulk-file source migrations
/// (#2277, child of Epic #2249).
///
/// Two countries are moving off a per-search network path onto a single
/// whole-country bulk download that is persisted and local-filtered:
///
///  - **GB** — from the per-search fan-out across ~14 CMA retailer feeds
///    ([UkStationService]) to one consolidated CMA / Fuel Finder file
///    downloaded per ~12 h publication cadence ([UkCmaBulkStationService]).
///  - **FR** — from polling `data.economie.gouv.fr` per search
///    ([PrixCarburantsStationService]) to the whole-country *flux instantané*
///    ZIP downloaded per ~10 min cadence ([PrixCarburantsFluxStationService]).
///
/// Because each rewrite changes a whole-country data path it ships **behind a
/// flag that defaults to the LEGACY path**. The bulk path is opt-in / staged:
/// the legacy per-search path stays the production default until each country
/// is validated on-device, and remains intact as the fallback (flip the flag
/// back to `false` to return to it with no other change).
///
/// This is deliberately a per-source **compile-time const config toggle**, not
/// a `Feature` enum value: it gates data-source plumbing, never a user-visible
/// capability, so it needs no `FeatureManifest` / feature-management / ARB
/// cascade. The [CountryServiceRegistry] reads these flags to choose, per
/// country, between the legacy ([SourceModel.polledApi]) policy + factory and
/// the bulk ([SourceModel.bulkFile]) policy + factory.
///
/// ## How to flip a flag (staged rollout)
///
/// Set the relevant field below to `true` and rebuild. To roll a country back,
/// set it to `false` again — the legacy service + policy are untouched, so the
/// fallback is one edit away with no migration. The two flags are independent:
/// UK and FR can be promoted separately.
class BulkMigrationFlags {
  const BulkMigrationFlags._();

  /// `true` routes GB through the consolidated CMA bulk file
  /// ([UkCmaBulkStationService] + the bulk policy); `false` (default) keeps
  /// the legacy per-search retailer fan-out ([UkStationService]).
  static const bool ukCmaBulk = false;

  /// `true` routes FR through the *flux instantané* bulk ZIP
  /// ([PrixCarburantsFluxStationService] + the bulk policy); `false` (default)
  /// keeps the legacy per-search `data.economie.gouv.fr` polling
  /// ([PrixCarburantsStationService]).
  static const bool frFluxBulk = false;
}
