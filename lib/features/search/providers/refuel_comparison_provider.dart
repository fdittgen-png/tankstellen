// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The ONE shared comparison of the stations the driver picked (#4363,
/// Epic #4358).
///
/// The selection (`refuelComparisonSelectionProvider`, core) is what the
/// driver chose; this is what it costs, recomputed from scratch whenever
/// anything it depends on moves — the vehicle's consumption, the quantity,
/// the fuel, the currency and rates, the tank, the route, where the
/// driver is — while the selection itself is left exactly as it was. The
/// list, the detail screen and the map all read this same result, so an
/// edited quantity invalidates every total at once and no surface can
/// show a figure another has already superseded.
///
/// Every entry goes through the same reduction the nearby decision uses
/// (`buildRefuelCandidate`) and the same calculator (#4360's trip
/// ledger, `RefuelEconomics.tripCost`), so a station cannot cost one
/// thing here and another in the header. Money is decided in one
/// currency or withheld (#4361); a reference price stays a visible price
/// with no drive (#4348).
///
/// ## A late answer for a previous selection cannot land here
///
/// Road quotes are keyed on the request — context AND stop list. Changing
/// the selection is a new request, so a router answer for the old one
/// resolves into a provider nothing watches any more; and even a hit on
/// the same key is only used while `isCurrentFor` holds. The card-level
/// test in `refuel_comparison_card_test.dart` pins this behaviour.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/data_value.dart';
import '../../../core/domain/exchange_rate_provider.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/money.dart';
import '../../../core/domain/refuel_comparison_selection.dart';
import '../../../core/domain/refuel_economics.dart';
import '../../../core/domain/refuel_profile_provider.dart';
import '../../../core/domain/refuel_quantity_provider.dart';
import '../../../core/domain/refuel_trip_cost.dart';
import '../../../core/domain/search_result_item.dart';
import '../../../core/domain/station.dart';
import '../../../core/domain/tank_state_provider.dart';
import '../../../core/domain/travel_estimate.dart';
import '../../../core/services/station_offer.dart';
import '../../../core/time/app_clock.dart';
import '../../route_search/api.dart';
import 'refuel_candidate_builder.dart';
import 'refuel_travel_origin_provider.dart';
import 'search_provider.dart';
import 'station_travel_estimates_provider.dart';

/// Where a row's kilometres come from.
enum RefuelComparisonTravel {
  /// Both legs routed, current for this context.
  road,

  /// Crow-flies with the documented road factor — explicitly approximate.
  approximate,

  /// A road quote is on its way; the row shows the approximate figure
  /// meanwhile and says so.
  pending,
}

/// One station in the comparison.
@immutable
class RefuelComparisonEntry {
  const RefuelComparisonEntry({
    required this.station,
    required this.offer,
    required this.fuel,
    required this.candidate,
    required this.outcome,
    required this.travel,
    this.cash,
    this.nativeCash,
    this.extraVsBaseline,
    this.isBaseline = false,
  });

  final Station station;
  final StationOffer offer;

  /// The grade this station is priced for.
  final FuelType fuel;

  final RefuelCandidate candidate;
  final RefuelTripOutcome outcome;
  final RefuelComparisonTravel travel;

  /// Pump cash in the comparison currency, or null when the trip could
  /// not be costed or its currency could not be converted (#4361).
  final Money? cash;

  /// The same cash as the station's country quotes it.
  final Money? nativeCash;

  /// What this station costs OVER the baseline for the same net refill —
  /// never negative, because the baseline is the minimum. Null when
  /// either side has no comparable cash.
  final Money? extraVsBaseline;

  final bool isBaseline;

  String get stationId => station.id;
  RefuelTripCost? get cost => outcome.cost;
  RefuelTripBlocker? get blocker => outcome.blocker;

  /// True when the native amount is in another currency than the
  /// comparison's, so a surface shows both.
  bool nativeDiffersFrom(String currency) =>
      nativeCash != null && nativeCash!.currencyCode != currency;
}

/// The shared result.
@immutable
class RefuelComparison {
  const RefuelComparison({
    required this.entries,
    required this.currency,
    required this.quantityLitres,
    required this.quantityIsChosen,
    required this.consumption,
    required this.originKnown,
    required this.moneyWithheld,
    this.isJourneyStop = false,
  });

  static const empty = RefuelComparison(
    entries: [],
    currency: '',
    quantityLitres: 0,
    quantityIsChosen: false,
    consumption: DataValue.unknown(reason: DataUnknownReason.notMeasuredYet),
    originKnown: false,
    moneyWithheld: false,
  );

  /// In selection order — the order the driver built it in.
  final List<RefuelComparisonEntry> entries;
  final String currency;

  /// The NET refill every row is priced for (#4360).
  final double quantityLitres;

  /// True when the driver set the quantity; false when it is their
  /// measured median or the default.
  final bool quantityIsChosen;

  final DataValue<double> consumption;

  /// False when no search has published where the driver is, so every
  /// distance is crow-flies.
  final bool originKnown;

  /// True when at least one priced physical station could not be
  /// expressed in [currency] — the cheapest is then withheld (#4361).
  final bool moneyWithheld;

  /// True when the rows are stops on the active route (their distance is
  /// the detour), false for errands from where the driver is.
  final bool isJourneyStop;

  bool get isEmpty => entries.isEmpty;

  RefuelComparisonEntry? get baseline =>
      entries.where((e) => e.isBaseline).firstOrNull;

  /// #4348 — a pick drawn from a partial source speaks for the stations
  /// listed, not the country.
  bool get coverageIncomplete => entries.any(
      (e) => e.offer.canHoldStationRanking && !e.offer.coverageComplete);
}

final refuelComparisonProvider = Provider<RefuelComparison>((ref) {
  final picked = ref.watch(refuelComparisonSelectionProvider);
  if (picked.isEmpty) return RefuelComparison.empty;

  final fuelType = ref.watch(selectedFuelTypeProvider);
  final currency = ref.watch(comparisonCurrencyProvider);
  final rates = ref.watch(exchangeRatesProvider);
  final profile = ref.watch(refuelProfileProvider);
  final chosen = ref.watch(refuelQuantityProvider);
  final tank = ref.watch(tankStateProvider);
  final now = ref.watch(appClockProvider).now();
  final litres = chosen ?? profile.litresIntended;

  // The live result's copy of a station beats the snapshot taken when it
  // was picked: a refreshed price is the price. A station the list no
  // longer shows keeps its snapshot — it is still the station the driver
  // chose.
  final live = <String, FuelStationResult>{
    for (final item in ref.watch(searchStateProvider).value?.data ??
        const <SearchResultItem>[])
      if (item is FuelStationResult) item.station.id: item,
  };
  final route = ref.watch(routeSearchStateProvider).value;
  final stations = [
    for (final s in picked) live[s.id]?.station ?? s,
  ];

  // One context for every row, so the rows are comparable at all: a stop
  // on the active journey when there is one, else an errand from where
  // the driver is, else nothing to route from.
  final context = _context(route, ref.watch(refuelTravelOriginProvider));
  final request = context == null
      ? null
      : TravelQuoteRequest.budgeted(context, [
          for (final s in stations) (id: s.id, lat: s.lat, lng: s.lng),
        ]);
  final estimates =
      request == null ? null : ref.watch(stationTravelEstimatesProvider(request));

  final drafts = <RefuelComparisonEntry>[];
  var withheld = false;
  for (final station in stations) {
    final fuel = fuelForStation(
        station, route?.profileFuelByCountry ?? const {}, fuelType);
    final road = request == null || estimates == null
        ? null
        : actionableTravelEstimate(estimates, request, station.id, now);
    final candidate = buildRefuelCandidate(
      station,
      distKm: live[station.id]?.dist ?? station.dist,
      fuelType: fuel,
      now: now,
      road: road,
    );
    final outcome = RefuelEconomics.tripCost(_tripInput(
      candidate, profile, litres, tank,
      // A stop on a journey costs its detour, not the whole itinerary
      // (#4359): the extra over the baseline drive, split across the two
      // legs the router reports as a pair.
      journeyStop: context?.purpose == TravelPurpose.stopOnJourney,
    ));
    final code = candidate.currencyCode;
    final cost = outcome.cost;
    Money? native, cash;
    if (cost != null) {
      native = Money(cost.cashAtPump, code ?? currency);
      cash = rates.convert(native, currency, now).converted;
      if (cash == null && candidate.isPhysicalStation) withheld = true;
    }
    drafts.add(RefuelComparisonEntry(
      station: station,
      offer: StationOffer.forStation(
          stationId: station.id, lat: station.lat, lng: station.lng),
      fuel: fuel,
      candidate: candidate,
      outcome: outcome,
      travel: road != null
          ? RefuelComparisonTravel.road
          : (estimates?.isLoading ?? false)
              ? RefuelComparisonTravel.pending
              : RefuelComparisonTravel.approximate,
      cash: cash,
      nativeCash: native,
    ));
  }

  // The baseline is the cheapest comparable physical station for this
  // net refill — named, so every "more than" has a subject. Ties break on
  // id so the header does not reshuffle between rebuilds.
  //
  // #4361 — a row that could not be expressed in [currency] withholds
  // the winner for the WHOLE card: naming the cheapest among the rows
  // that happened to convert would be a claim about a set the driver did
  // not choose. The native quotes stay, side by side.
  RefuelComparisonEntry? baseline;
  for (final e in withheld ? const <RefuelComparisonEntry>[] : drafts) {
    final v = e.cash;
    if (v == null || !e.candidate.isPhysicalStation) continue;
    if (baseline == null ||
        v.amount < baseline.cash!.amount ||
        (v.amount == baseline.cash!.amount &&
            e.stationId.compareTo(baseline.stationId) < 0)) {
      baseline = e;
    }
  }

  return RefuelComparison(
    entries: [
      for (final e in drafts)
        RefuelComparisonEntry(
          station: e.station,
          offer: e.offer,
          fuel: e.fuel,
          candidate: e.candidate,
          outcome: e.outcome,
          travel: e.travel,
          cash: e.cash,
          nativeCash: e.nativeCash,
          isBaseline: identical(e, baseline),
          extraVsBaseline: baseline == null || e.cash == null
              ? null
              : e.cash! - baseline.cash!,
        ),
    ],
    currency: currency,
    quantityLitres: litres,
    quantityIsChosen: chosen != null,
    consumption: profile.consumption,
    originKnown: context != null,
    moneyWithheld: withheld,
    isJourneyStop: context?.purpose == TravelPurpose.stopOnJourney,
  );
});

TravelContext? _context(RouteSearchResult? route, TravelPoint? origin) {
  final geometry = route?.route.geometry;
  if (geometry != null && geometry.isNotEmpty) {
    return TravelContext(
      origin: TravelPoint(geometry.first.latitude, geometry.first.longitude),
      destination: TravelPoint(geometry.last.latitude, geometry.last.longitude),
      purpose: TravelPurpose.stopOnJourney,
      routeRevision: Object.hash(geometry.length, route!.route.distanceKm),
    );
  }
  if (origin != null) {
    return TravelContext(origin: origin, purpose: TravelPurpose.errandReturn);
  }
  return null;
}

RefuelTripInput _tripInput(
  RefuelCandidate c,
  RefuelProfile profile,
  double litres,
  TankState tank, {
  required bool journeyStop,
}) {
  final road = c.roadTravel;
  final double outbound, back;
  if (road != null && road.isActionable) {
    if (journeyStop) {
      final extra = road.extraKm ?? 0;
      outbound = extra / 2;
      back = extra / 2;
    } else {
      outbound = road.toStation.distanceKm ?? 0;
      back = road.fromStation.distanceKm ?? 0;
    }
  } else {
    // The approximate errand: there and back, crow-flies corrected by
    // the documented road factor (#4089).
    final oneWay =
        c.oneWayKm * (c.isRoadDistance ? 1 : profile.roadFactor);
    outbound = oneWay;
    back = oneWay;
  }
  return RefuelTripInput(
    outboundKm: outbound,
    returnKm: back,
    pricePerLitre: c.pricePerLitre,
    consumptionLPer100km: profile.consumptionLPer100km,
    quantity: RefuelPurchaseQuantity.netIncrease(litres),
    isPhysicalStation: c.isPhysicalStation,
    travelIsRoad: road != null && road.isActionable,
    consumptionIsEstimated: profile.consumptionIsEstimated,
    startLitres: tank.currentL,
    capacityL: tank.capacityL,
  );
}
