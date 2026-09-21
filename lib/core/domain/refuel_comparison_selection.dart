// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

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

/// Whether the results list is in picking mode (#4396).
///
/// The comparison's own controls are cheap to show once a comparison
/// exists — every row already grows the toggle. The *first* pick was the
/// hole: with an empty comparison the list offered nothing but a long
/// press, which no glyph, label or tooltip advertised, so the feature was
/// invisible to anyone who had not read the issue.
///
/// This flag is the visible door. It is turned on from the results
/// overflow menu — the same place #3926 moved three unlabelled icon
/// buttons into labelled entries — and while it is on, every row carries
/// the explicit toggle exactly as it does once a station is picked. It is
/// only an affordance switch: it holds no station, and turning it off
/// leaves the comparison exactly as the driver built it.
///
/// It lives beside the selection rather than in the search feature for
/// the same reason the selection does: the row is drawn by
/// `station_card_price_column.dart` and the switch is thrown in
/// `results_action_menu.dart`, and neither may import the other's layer.
class RefuelComparisonPicking extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final refuelComparisonPickingProvider =
    NotifierProvider<RefuelComparisonPicking, bool>(
        RefuelComparisonPicking.new);
