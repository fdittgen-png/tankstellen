// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../domain/fuel_type.dart';
import '../../domain/station.dart';
import '../mixins/station_service_helpers.dart';
import '../../utils/geo_utils.dart' as geo;
import '../../utils/station_extensions.dart';

/// The single distance-ranking authority shared by every radar surface (#3267).
///
/// The on-search radar ([radar_search_provider]), the trip-screen single
/// nearest lookup ([nearest_station_radar_provider]) and the swipe page-set
/// ([radar_candidate_list_provider]) all need the SAME four steps:
///
///   1. **Dedup by id** — when a wide corridor slice is merged with a direct
///      in-radius fetch (#2806/#2965), the in-radius row must win (it carries
///      the freshest per-fuel price). The merge passes corridor rows first and
///      in-radius rows last, so "last write wins" is the contract.
///   2. **Fuel-filter** — drop forecourts that don't sell the selected fuel so
///      the surface never shows a `--` price (#2926/#2583).
///   3. **Live distance stamp** — recompute `Station.dist` (km) from the
///      CURRENT GPS fix, not the value frozen at corridor-fetch time, so the
///      distance caption + closeness bar move as the driver approaches
///      (#2808/#3092/#3267).
///   4. **Distance sort** — nearest first.
///
/// Pulling the copy-pasted body of those three providers into one helper is the
/// "one framework for both" the radar unification (#3267) asks for: change the
/// ranking once and every surface — search list, PiP tile, swipe card — moves
/// together, and the live re-stamp on each GPS fix is identical everywhere.
class RadarRanking {
  const RadarRanking._();

  /// Dedup [stations] by id (last wins), fuel-filter for [fuel], re-stamp each
  /// row's live distance (km) from ([lat], [lng]) and return them distance-
  /// sorted (nearest first).
  ///
  /// [requirePrice] picks the fuel-filter:
  ///
  ///  - `false` (the on-search radar) applies the SHARED hard-fuel filter
  ///    [StationServiceHelpers.filterByFuel] — identical to the regular search,
  ///    so the radar list is a consistent superset of it. `FuelType.all` and
  ///    the unpriced fuels (electric/hydrogen) keep every station.
  ///  - `true` (the trip nearest / swipe page-set) keeps ONLY stations that
  ///    carry a usable (`> 0`) price for [fuel] — the driver must be able to
  ///    price-compare the target, so a `--` row never becomes the locked
  ///    station or a swipe page (#2583). The trip surfaces always resolve a
  ///    concrete priced fuel, where this coincides with the shared filter; the
  ///    flag only diverges for `all`/EV, which those surfaces never pass.
  static List<Station> rank(
    Iterable<Station> stations, {
    required double lat,
    required double lng,
    required FuelType fuel,
    bool requirePrice = false,
  }) {
    // 1. Dedup by id — last write wins (the in-radius merge row beats the
    // corridor row it follows).
    final byId = <String, Station>{};
    for (final s in stations) {
      byId[s.id] = s;
    }

    // 2. Fuel-filter.
    final Iterable<Station> filtered = requirePrice
        ? byId.values.where((s) {
            final price = s.priceFor(fuel);
            return price != null && price > 0;
          })
        : StationServiceHelpers.filterByFuel(
            byId.values.toList(growable: false),
            fuel,
          );

    // 3. Live distance stamp + 4. distance sort.
    return [
      for (final s in filtered)
        s.copyWith(dist: geo.distanceMeters(lat, lng, s.lat, s.lng) / 1000.0),
    ]..sort((a, b) => a.dist.compareTo(b.dist));
  }

  /// The single nearest station of [rank] with `requirePrice: true`, or `null`
  /// when nothing in [stations] is priced for [fuel]. The trip-screen nearest
  /// lookup ([nearest_station_radar_provider]) surfaces exactly this.
  static Station? nearestPriced(
    Iterable<Station> stations, {
    required double lat,
    required double lng,
    required FuelType fuel,
  }) {
    final ranked = rank(
      stations,
      lat: lat,
      lng: lng,
      fuel: fuel,
      requirePrice: true,
    );
    return ranked.isEmpty ? null : ranked.first;
  }
}
