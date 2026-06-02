// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/location/user_position_provider.dart';
import '../../../core/utils/geo_utils.dart' as geo;
import '../../../core/utils/station_extensions.dart';
import '../../approach/providers/fuel_station_radar_provider.dart';
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
/// A one-shot, cache-first radar fetch around the user's persisted position
/// ([userPositionProvider], NOT the trip-only shared GPS stream), surfaced in
/// the search results list like a regular search. It reuses the #2661 radar
/// data layer ([fuelStationRadarProvider]) — the tier-1 corridor location
/// cache (1 h) + tier-3 JIT price cache (5 min) — so a repeat run nearby costs
/// zero network.
///
/// Deliberately distinct from the trip-gated `nearestStationRadarProvider` /
/// approach detector: those only fire while a trip records (gated on
/// `ApproachPolling`). This provider runs on demand from the search screen, with
/// no geofence polling and no second `ApproachDetector` / `PipController`.
@riverpod
class RadarSearch extends _$RadarSearch {
  @override
  RadarSearchState build() => RadarSearchState.idle;

  /// Run the radar around the user's persisted position. No-op (leaves the
  /// radar inactive) when no position is known yet — the user must search /
  /// locate at least once so we have somewhere to scan around.
  Future<void> runRadar() async {
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

      // Stamp each station's distance (km) from the user, distance-sort, then
      // drop rows with no usable price for the selected fuel — the radar
      // surfaces priced stations only, like the regular search list.
      final priced = <Station>[];
      for (final s in raw) {
        final distKm =
            geo.distanceMeters(pos.lat, pos.lng, s.lat, s.lng) / 1000.0;
        final withDist = s.copyWith(dist: distKm);
        final price = withDist.priceFor(fuel);
        if (price == null || price <= 0) continue;
        priced.add(withDist);
      }
      priced.sort((a, b) => a.dist.compareTo(b.dist));

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
