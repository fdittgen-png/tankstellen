// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/cache/cache_manager.dart';
import '../../../core/services/bulk_migration_flags.dart';
import '../../../core/services/station_service.dart';
import 'uk_cma_bulk_station_service.dart';
import 'uk_fuel_finder_auth.dart';
import 'uk_fuel_finder_feed.dart';
import 'uk_station_service.dart';
import 'uk_statutory_fallback_station_service.dart';

/// Builds the GB raw [StationService] (#3190) — the single seam
/// `buildRawCountryService` calls, so the feature owns its own composition
/// (one core→feature import instead of five; the #3132 boundary ratchet).
///
/// Selection:
///
///  1. **Statutory Fuel Finder primary** — [apiKey] holds registered OAuth2
///     credentials packed as `client_id:client_secret` (the shared
///     per-country Settings key slot; see
///     [UkFuelFinderAuth.fromPackedCredentials] for the free registration
///     steps): the statutory bulk path ([UkCmaBulkStationService] with a
///     [UkFuelFinderFeed]) answers searches, with the legacy retailer
///     fan-out demoted to the in-service fallback
///     ([UkStatutoryFallbackStationService]).
///  2. **Keyless** — the pre-#3190 behaviour, unchanged: the legacy
///     per-search retailer fan-out ([UkStationService]), or the
///     unauthenticated bulk path when `BulkMigrationFlags.ukCmaBulk` is
///     flagged on (#2277 staged rollout).
StationService buildGbStationService({
  required String? apiKey,
  required CacheStrategy cache,
}) {
  final auth = UkFuelFinderAuth.fromPackedCredentials(apiKey);
  if (auth != null) {
    return UkStatutoryFallbackStationService(
      primary: UkCmaBulkStationService(
        cache: cache,
        feed: UkFuelFinderFeed(auth: auth),
      ),
      fallback: UkStationService(),
    );
  }
  return BulkMigrationFlags.ukCmaBulk
      ? UkCmaBulkStationService(cache: cache)
      : UkStationService();
}
