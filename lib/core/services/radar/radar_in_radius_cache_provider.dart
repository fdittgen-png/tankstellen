// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../country/country_provider.dart';
import '../../domain/fuel_type.dart';
import '../../domain/search_params.dart';
import '../../domain/station.dart';
import '../country_service_registry.dart';
import 'radar_in_radius_cache.dart';
import '../service_providers.dart';

part 'radar_in_radius_cache_provider.g.dart';

/// The shared, movement+time-gated in-radius merge cache (#3254) used by the
/// radar surfaces that re-evaluate on every GPS fix — the swipe page-set
/// ([radarCandidateList]) and the live on-search radar.
///
/// keepAlive so the gate's last-fetch position/time survives the per-fix
/// rebuilds of those providers; the country's `minInterval` is read live so a
/// country switch picks up the new published cadence. The fetch is fuel-
/// agnostic (`FuelType.all`) — the chain returns every fuel's price per row, so
/// one cached merge serves any selected fuel and a fuel change never forces a
/// re-fetch; [RadarRanking] applies the per-fuel filter downstream.
@Riverpod(keepAlive: true)
RadarInRadiusCache radarInRadiusCache(Ref ref) {
  final svc = ref.read(stationServiceProvider);
  return RadarInRadiusCache(
    fetch: (lat, lng, radiusKm) async {
      try {
        final result = await svc.searchStations(
          SearchParams(
            lat: lat,
            lng: lng,
            radiusKm: radiusKm,
            fuelType: FuelType.all,
            sortBy: SortBy.distance,
          ),
        );
        return result.data;
      } on Object {
        return const <Station>[];
      }
    },
    minInterval: () {
      final code = ref.read(activeCountryProvider).code;
      return CountryServiceRegistry.policyFor(code)?.minInterval ??
          const Duration(seconds: 60);
    },
  );
}
