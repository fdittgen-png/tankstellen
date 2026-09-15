// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/data_value.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/refuel_economics.dart';
import '../../../core/time/app_clock.dart';
import '../../../core/domain/refuel_profile_provider.dart';
import '../../../core/domain/search_result_item.dart';
import '../../../core/services/country_service_registry.dart';
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
/// road factor applies. When #3633-style road distances are available
/// for a row, passing them here with the flag set is the only change
/// needed — the arithmetic below does not move.
@riverpod
RefuelDecision refuelDecision(Ref ref, List<SearchResultItem> items) {
  final fuelType = ref.watch(selectedFuelTypeProvider);
  final profile = ref.watch(refuelProfileProvider);
  // #4139 — the gates for the conditional lead (spec §3.1). Neither
  // enters the arithmetic; both decide whether Best Value is confident
  // enough to be stated as THE answer rather than one of three.
  final now = ref.watch(appClockProvider).now();
  return RefuelEconomics.decide(
    [
      for (final item in items.whereType<FuelStationResult>())
        _candidate(item, fuelType, now),
    ],
    profile,
  );
}

RefuelCandidate _candidate(
  FuelStationResult item,
  FuelType fuelType,
  DateTime now,
) {
  // #4156 — the gates are only as good as the provider behind them, and
  // a cross-border result set mixes providers, so the capability is
  // resolved PER STATION: the id prefix first (#753's `de-`/`uk-`/…
  // scheme), then the bounding box for an id that carries none.
  //
  // Both lookups are static and storage-free on purpose. Reading the
  // active country instead would have pulled the profile box into a
  // provider whose whole job is arithmetic over a list it was handed —
  // and it is the wrong answer anyway for a station across the border.
  final code = CountryServiceRegistry.countryForStationId(item.station.id) ??
      CountryServiceRegistry.countryForLatLng(item.station.lat,
          item.station.lng);
  final capability =
      code == null ? null : CountryServiceRegistry.capabilityFor(code);
  final age = _priceAge(item.station.priceUpdatedAt, now);
  return RefuelCandidate(
    stationId: item.station.id,
    oneWayKm: item.dist,
    pricePerLitre: item.station.priceFor(fuelType),
    // An unregistered country gets the candidate's own defaults, which
    // block both gates. That is the honest answer: we do not know what
    // this source publishes, so we cannot stand a gate down over it.
    openState: capability?.openState(item.station.isOpen) ??
        const DataValue.unknown(
          reason: DataUnknownReason.notPublishedForThisItem,
        ),
    priceAge: capability?.priceAge(age) ??
        const DataValue.unknown(
          reason: DataUnknownReason.notPublishedForThisItem,
        ),
  );
}

/// How old the station's price is, or null when the provider published
/// no stamp — which lets [ProviderCapability] decide whether that is a
/// stand-down or a block, rather than deciding here.
///
/// #4189 — this read `Station.updatedAt`, which is a DISPLAY string
/// (`dd/MM HH:mm`). `DateTime.tryParse` returned null for it, so a
/// French, Danish or Portuguese price — from providers whose capability
/// declares `priceTimestamp: true` — became
/// `notPublishedForThisItem`, which the freshness gate treats as a
/// block. The confident pick was withheld in three of the best-data
/// countries for a reason that was not true.
Duration? _priceAge(DateTime? stamp, DateTime now) {
  if (stamp == null) return null;
  final age = now.difference(stamp);
  // A stamp in the future is a broken feed, not a fresh price.
  return age.isNegative ? null : age;
}
