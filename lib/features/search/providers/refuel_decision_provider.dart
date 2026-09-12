// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/refuel_economics.dart';
import '../../../core/domain/refuel_profile_provider.dart';
import '../../../core/domain/search_result_item.dart';
import '../../../core/utils/station_extensions.dart';
import 'search_filters_provider.dart';

part 'refuel_decision_provider.g.dart';

/// The three answers for the current result set (#4090, epic #4087).
///
/// Keyed on the already-filtered-and-sorted list so the decision follows
/// what the user is actually looking at: hide a brand and the
/// recommendation changes with it, which is the only honest behaviour
/// when the header claims to name the best of what is on screen.
///
/// EV rows are excluded. The economics is litres and L/100 km; a charger
/// has neither, and inventing a conversion to keep it in the ranking
/// would be exactly the fabricated authority `docs/specs/refuel-
/// economics.md` §3 forbids.
///
/// Distances are the crow-flies figures the result carries, so
/// [RefuelCandidate.isRoadDistance] stays false and the spec's 1.3
/// road factor applies. When #3633-style road distances are available
/// for a row, passing them here with the flag set is the only change
/// needed — the arithmetic below does not move.
@riverpod
RefuelDecision refuelDecision(Ref ref, List<SearchResultItem> items) {
  final fuelType = ref.watch(selectedFuelTypeProvider);
  final profile = ref.watch(refuelProfileProvider);
  return RefuelEconomics.decide(
    [
      for (final item in items.whereType<FuelStationResult>())
        RefuelCandidate(
          stationId: item.station.id,
          oneWayKm: item.dist,
          pricePerLitre: item.station.priceFor(fuelType),
        ),
    ],
    profile,
  );
}
