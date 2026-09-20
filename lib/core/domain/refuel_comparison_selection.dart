// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The stations a driver has picked to compare (#4363, Epic #4358).
///
/// Picking is one act with three doors — a list row, a station's detail
/// screen, a pin on the map — and every door must land on the SAME
/// selection, or the driver assembles a comparison in one place and finds
/// it empty in another. So the selection lives here in core, beside
/// `refuel_quantity_provider.dart` and for the same reason: the search
/// list, the station detail feature and the map feature all read and
/// write it, and none of them may import the others.
///
/// It is deliberately only a selection. It holds no cost, no ranking and
/// no travel quote: those are recomputed from it by the comparison
/// provider whenever the vehicle, the quantity, the route or the
/// constraints change — while THIS stays exactly as the driver left it.
/// A comparison that forgot its stations because the tank estimate moved
/// would be worse than none.
///
/// Each entry is the [Station] as it was when picked, so a station that
/// has since scrolled out of the result set (or was picked from a detail
/// screen the list never showed) still compares. The comparison provider
/// prefers the live result's copy when one is on screen, so a refreshed
/// price wins over the snapshot.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'station.dart';

/// The most a comparison may hold. Enough to weigh a handful of
/// alternatives; few enough that the travel quote stays one request.
const int kRefuelComparisonMaxStations = 6;

class RefuelComparisonSelection extends Notifier<List<Station>> {
  @override
  List<Station> build() => const [];

  bool contains(String stationId) => state.any((s) => s.id == stationId);

  /// Add [station], or remove it if it is already selected. Returns
  /// whether it is selected afterwards. A pick past the cap is refused
  /// (returns false) rather than silently dropping the oldest.
  bool toggle(Station station) {
    if (contains(station.id)) {
      remove(station.id);
      return false;
    }
    if (state.length >= kRefuelComparisonMaxStations) return false;
    state = [...state, station];
    return true;
  }

  void remove(String stationId) =>
      state = [for (final s in state) if (s.id != stationId) s];

  void clear() => state = const [];
}

final refuelComparisonSelectionProvider =
    NotifierProvider<RefuelComparisonSelection, List<Station>>(
        RefuelComparisonSelection.new);
