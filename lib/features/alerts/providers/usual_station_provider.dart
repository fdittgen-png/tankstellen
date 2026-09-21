// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../fill_ups/api.dart';
import '../data/usual_station_store.dart';
import '../domain/usual_station_candidate.dart';

part 'usual_station_provider.g.dart';

/// The confirmed usual station (#4154) — null until the user sets one.
@riverpod
class UsualStationSetting extends _$UsualStationSetting {
  static const UsualStationStore _store = UsualStationStore();

  @override
  UsualStation? build() => _store.read();

  /// Confirm [candidate] as the usual station.
  Future<void> confirm(UsualStationCandidate candidate) async {
    await set(
        stationId: candidate.stationId, stationName: candidate.stationName);
  }

  /// Set the usual station directly — the path a station screen uses,
  /// where the user named the station themselves.
  Future<void> set({required String stationId, String? stationName}) async {
    final station =
        UsualStation(stationId: stationId, stationName: stationName);
    await _store.write(station);
    state = station;
  }

  Future<void> clear() async {
    await _store.clear();
    state = null;
  }
}

/// What the fill-up history suggests, or null when it is too thin (#4154).
///
/// Offered, never applied: [UsualStationSetting] only changes on an
/// explicit confirm. A wrong "usual" makes every finding about it wrong,
/// and the ranking cannot tell a habit from a fortnight of holiday
/// driving — so the user is the one who decides.
///
/// The `fill_ups` dependency goes through that feature's `api.dart`
/// barrel, which `feature_boundary_test` exempts from its per-pair
/// count; reaching into `providers/` directly would be the violation.
@riverpod
UsualStationCandidate? usualStationSuggestion(Ref ref) {
  final fills = ref.watch(fillUpListProvider);
  return usualStationCandidate([
    for (final f in fills)
      (stationId: f.stationId, stationName: f.stationName),
  ]);
}
