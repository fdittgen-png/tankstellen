// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/exchange_rate_provider.dart';
import '../../../core/domain/refuel_economics.dart';
import '../../../core/time/app_clock.dart';
import '../../../core/domain/refuel_profile_provider.dart';
import '../../../core/domain/search_result_item.dart';
import '../../../core/domain/travel_estimate.dart';
import '../../../core/utils/station_extensions.dart';
import 'refuel_candidate_builder.dart';
import 'refuel_travel_origin_provider.dart';
import 'search_filters_provider.dart';
import 'station_travel_estimates_provider.dart';

part 'refuel_decision_provider.g.dart';

/// The three answers for the current result set (#4090, epic #4087).
///
/// Keyed on the already-filtered-and-sorted list so the decision follows
/// what the user is actually looking at: hide a brand and the
/// recommendation changes with it, which is the only honest behaviour
/// when the header claims to name the best of what is on screen.
///
/// #4156 — `isOpen` and `updatedAt` reach the gates through the
/// country's `ProviderCapability`, not raw. A `bool?` read "unknown as
/// closed", which meant the conditional lead could never fire in the
/// eleven countries whose source publishes no hours at all. The
/// capability separates "this provider publishes none" (a gate that
/// stands down, with a caveat) from "this provider publishes them and
/// left this row blank" (a gate that still blocks).
///
/// EV rows are excluded. The economics is litres and L/100 km; a charger
/// has neither, and inventing a conversion to keep it in the ranking
/// would be exactly the fabricated authority `docs/specs/refuel-
/// economics.md` §3 forbids.
///
/// Distances are the crow-flies figures the result carries, so
/// [RefuelCandidate.isRoadDistance] stays false and the spec's 1.3
/// road factor applies — until #4359's road estimates land.
///
/// #4359 — once a search has published its origin
/// ([refuelTravelOriginProvider]), the result set is quoted as return
/// errands from that origin in ONE budgeted router request, in the
/// list's own order (so a station outside the radar's top eight is
/// quoted too). A current, road-verified quote replaces the crow-flies
/// figure; anything else — loading, failed, unreachable, stale, another
/// context — leaves the row explicitly approximate.
@riverpod
RefuelDecision refuelDecision(Ref ref, List<SearchResultItem> items) {
  final fuelType = ref.watch(selectedFuelTypeProvider);
  // #4361 — the vehicle side comes from fill-ups, the money side from
  // where the driver is. A mixed-currency list is then ranked in ONE
  // currency or not ranked on money at all; it is never sorted on bare
  // numbers whose units differ.
  final profile = ref.watch(refuelProfileProvider).withComparison(
        currency: ref.watch(comparisonCurrencyProvider),
        rates: ref.watch(exchangeRatesProvider),
      );
  // #4139 — the gates for the conditional lead (spec §3.1). Neither
  // enters the arithmetic; both decide whether Best Value is confident
  // enough to be stated as THE answer rather than one of three.
  final now = ref.watch(appClockProvider).now();
  final fuelItems = items.whereType<FuelStationResult>().toList();
  final origin = ref.watch(refuelTravelOriginProvider);
  final request = origin == null || fuelItems.isEmpty
      ? null
      : TravelQuoteRequest.budgeted(
          TravelContext(origin: origin, purpose: TravelPurpose.errandReturn),
          [
            for (final item in fuelItems)
              if (item.station.priceFor(fuelType) != null)
                (id: item.station.id, lat: item.station.lat,
                    lng: item.station.lng),
          ],
        );
  final estimates = request == null
      ? null
      : ref.watch(stationTravelEstimatesProvider(request));
  return RefuelEconomics.decide(
    [
      for (final item in fuelItems)
        buildRefuelCandidate(
          item.station,
          distKm: item.dist,
          fuelType: fuelType,
          now: now,
          road: request == null || estimates == null
              ? null
              : actionableTravelEstimate(
                  estimates, request, item.station.id, now),
        ),
    ],
    profile,
    now: now,
  );
}
