// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/location/user_position_provider.dart';
import '../../../core/services/service_providers.dart';
import '../../../core/utils/geo_utils.dart' as geo;
import '../../../core/utils/station_extensions.dart';
import '../../approach/providers/fuel_station_radar_provider.dart';
import '../data/models/search_params.dart';
import '../domain/entities/fuel_type.dart';
import '../domain/entities/station.dart';
import 'search_filters_provider.dart';

part 'radar_search_provider.g.dart';

/// State of the on-search Fuel Station Radar (#2659 / #2674).
///
/// Holds whether the radar is the active result source ([active]) plus the
/// `AsyncValue` of the distance-sorted, priced station list it produced.
class RadarSearchState {
  const RadarSearchState({
    required this.active,
    required this.stations,
  });

  /// `true` once a radar run has resolved and the results list should render
  /// the radar stations instead of the regular `searchStateProvider` results.
  final bool active;

  /// The radar's distance-sorted, priced station list (loading/data/error).
  final AsyncValue<List<Station>> stations;

  static const RadarSearchState idle = RadarSearchState(
    active: false,
    stations: AsyncData<List<Station>>(<Station>[]),
  );

  RadarSearchState copyWith({
    bool? active,
    AsyncValue<List<Station>>? stations,
  }) =>
      RadarSearchState(
        active: active ?? this.active,
        stations: stations ?? this.stations,
      );
}

/// The on-search Fuel Station Radar (#2659).
///
/// A one-shot radar fetch around the user's CURRENT position
/// ([userPositionProvider], refreshed from live GPS on each run — #2806 — NOT
/// the trip-only shared GPS stream), surfaced in the search results list like
/// a regular search. It reuses the #2661 radar data layer
/// ([fuelStationRadarProvider]) — the tier-1 corridor location cache (1 h) +
/// tier-3 JIT price cache (5 min) — for the wide net, and merges a direct
/// in-radius fetch so the result is always a superset of the regular search
/// (#2806).
///
/// Deliberately distinct from the trip-gated `nearestStationRadarProvider` /
/// approach detector: those only fire while a trip records (gated on
/// `ApproachPolling`). This provider runs on demand from the search screen, with
/// no geofence polling and no second `ApproachDetector` / `PipController`.
@riverpod
class RadarSearch extends _$RadarSearch {
  @override
  RadarSearchState build() => RadarSearchState.idle;

  /// Run the radar around the user's CURRENT position. No-op (leaves the radar
  /// inactive) when no position is known yet — the user must search / locate at
  /// least once so we have somewhere to scan around.
  Future<void> runRadar() async {
    // #2806 — refresh the live GPS fix first, exactly as the regular search
    // does (search_provider_orchestration.dart). The radar used to reuse the
    // PERSISTED [userPositionProvider] with no refresh, so after any movement
    // it scanned a location minutes behind the user — surfacing a far-away
    // band and dropping the nearby stations the in-radius search shows.
    // Best-effort: keep the persisted position if the fix is denied / times
    // out, so an offline / permission-less run still scans the last spot.
    try {
      await ref.read(userPositionProvider.notifier).updateFromGps();
    } on Object {
      // Fall back to whatever position was already persisted.
    }

    final pos = ref.read(userPositionProvider);
    if (pos == null) {
      state = RadarSearchState.idle;
      return;
    }

    final radiusKm = ref.read(searchRadiusProvider);
    final fuel = ref.read(selectedFuelTypeProvider);

    state = state.copyWith(
      active: true,
      stations: const AsyncLoading<List<Station>>(),
    );

    try {
      final radar = ref.read(fuelStationRadarProvider);
      final raw = await radar.fetchStations(
        pos.lat,
        pos.lng,
        radiusKm,
        fuel.apiValue,
      );

      // #2806 — the wide corridor is fetched with a hard row cap (60 km /
      // limit 50, un-distance-ordered), so in a dense area its returned slice
      // can MISS the closest forecourts, leaving the radar excluding stations
      // the regular search shows. Merge a direct in-radius fetch so the radar
      // is always a SUPERSET of the in-radius search around the same position
      // (the user's stated expectation). Best-effort: corridor-only if the
      // in-radius fetch fails.
      final nearby = await _inRadiusStations(pos, radiusKm, fuel);

      // Dedup by id (the in-radius row wins — it carries the freshest per-fuel
      // price), stamp each station's distance (km) from the user, drop rows
      // with no usable price for the selected fuel, then distance-sort — the
      // radar surfaces priced stations only, like the regular search list.
      final byId = <String, Station>{};
      for (final s in [...raw, ...nearby]) {
        final distKm =
            geo.distanceMeters(pos.lat, pos.lng, s.lat, s.lng) / 1000.0;
        final withDist = s.copyWith(dist: distKm);
        final price = withDist.priceFor(fuel);
        if (price == null || price <= 0) continue;
        byId[withDist.id] = withDist;
      }
      final priced = byId.values.toList()
        ..sort((a, b) => a.dist.compareTo(b.dist));

      state = state.copyWith(
        active: true,
        stations: AsyncData<List<Station>>(priced),
      );
    } catch (e, st) {
      state = state.copyWith(
        active: true,
        stations: AsyncError<List<Station>>(e, st),
      );
    }
  }

  /// A direct in-radius station fetch around [pos], mirroring the regular
  /// search, so [runRadar] can guarantee the radar list is a superset of it
  /// (#2806). Returns `[]` on any failure so the radar degrades to its cached
  /// corridor rather than erroring.
  Future<List<Station>> _inRadiusStations(
    UserPositionData pos,
    double radiusKm,
    FuelType fuel,
  ) async {
    try {
      final result = await ref.read(stationServiceProvider).searchStations(
            SearchParams(
              lat: pos.lat,
              lng: pos.lng,
              radiusKm: radiusKm,
              fuelType: fuel,
              sortBy: SortBy.distance,
            ),
          );
      return result.data;
    } on Object {
      return const <Station>[];
    }
  }

  /// Dismiss the radar result and hand the results list back to the regular
  /// `searchStateProvider`.
  void dismiss() {
    state = RadarSearchState.idle;
  }
}

/// The nearest priced radar station, or null. Feeds the small-window PiP tile
/// (#2677) the same way `nearestStationRadarProvider` feeds the trip PiP.
@riverpod
Station? radarSearchNearest(Ref ref) {
  final radar = ref.watch(radarSearchProvider);
  if (!radar.active) return null;
  final list = radar.stations.value;
  if (list == null || list.isEmpty) return null;
  return list.first;
}
