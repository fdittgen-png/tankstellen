// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../core/services/bulk_migration_flags.dart';
import '../../../core/services/country_service_dependencies.dart';
import '../../../core/services/impl/osm_brand_enricher.dart';
import '../../../core/services/station_service.dart';
import 'prix_carburants_flux_station_service.dart';
import 'prix_carburants_station_service.dart';

/// Builds the FR raw [StationService] — the `CountryServiceEntry.buildService`
/// factory (#3746), living feature-side so core never imports the two FR
/// service implementations directly (the #3132 boundary ratchet: one
/// core→feature import instead of two).
///
/// #2277 staged rollout — bulk *flux instantané* when flagged, else the
/// legacy per-search OSM-enriched service.
StationService buildFrStationService(CountryServiceDependencies deps) {
  if (BulkMigrationFlags.frFluxBulk) {
    return PrixCarburantsFluxStationService(cache: deps.cache);
  }
  return PrixCarburantsStationService(
    enricher: OsmBrandEnricher(deps.storage),
  );
}
