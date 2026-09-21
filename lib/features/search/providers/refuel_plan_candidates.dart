// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// Which stations a refuelling plan is ALLOWED to stop at (#4362, Epic
/// #4358).
///
/// The planner's correctness depends entirely on this list being the
/// right one, and the defect it fixes is a category error: the plan used
/// to be built from the same station list the ROUTE LIST renders, which
/// has already been through display and price filtering. A necessary
/// bridge stop that is expensive — the one the driver cannot skip — was
/// therefore capable of disappearing before feasibility was ever
/// considered, and the plan came back as a gap.
///
/// So the two kinds of filter are separated here, explicitly:
///
///  * **hard exclusions** — the station cannot be a stop for this driver
///    on this journey: a reference price that is not a place (#4348), a
///    station the driver has chosen to ignore, no price for the fuel the
///    vehicle takes, a price in a currency the plan cannot state
///    (#4361). Each is recorded with its reason, so a gap that follows
///    from one can be explained instead of looking like "no stations".
///  * **soft filters** — brand hiding, a price ceiling, the best-stops
///    view, the sort order. None of them reaches this file. They shape
///    what the driver READS; they may not shape what is feasible.
///
/// Pure functions over primitives: the provider watches, this decides.
library;

import 'package:meta/meta.dart';

import '../../../core/country/country_config.dart';
import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/money.dart';
import '../../../core/domain/refuel_plan.dart';
import '../../../core/domain/search_result_item.dart';
import '../../../core/domain/travel_estimate.dart';
import '../../../core/services/station_offer.dart';
import '../../../core/utils/route_projection.dart';
import '../../../core/utils/station_extensions.dart';
import '../../route_search/api.dart' show fuelForStation;

/// Why a station on this route cannot be a stop.
enum PlanCandidateExclusion {
  /// #4348 — a reference/aggregate price pinned at a stand-in point.
  referencePrice,

  /// The driver hid this station. A hard choice, respected even when it
  /// leaves a gap — and the gap is then explained, not silently filled.
  ignoredByUser,

  /// No price for the fuel this vehicle takes in this country.
  noPriceForFuel,

  /// #4361 — priced in a currency the plan cannot express in the
  /// driver's own at a stated, fresh rate.
  currencyNotComparable,
}

/// The allowed stops, what was excluded and why, and how complete the
/// evidence behind them is.
@immutable
class PlanCandidateSet {
  const PlanCandidateSet({
    required this.candidates,
    required this.travelStops,
    required this.exclusions,
    required this.coverageIncomplete,
    this.stationNames = const {},
  });

  static const empty = PlanCandidateSet(
    candidates: [],
    travelStops: [],
    exclusions: {},
    coverageIncomplete: false,
  );

  /// Station id to display name, so a plan can name its stops without a
  /// surface reaching back into the search result for them (#4363). A
  /// plan whose stops are ids is not an itinerary anyone can drive.
  final Map<String, String> stationNames;

  /// Allowed stops, in route order, on projection distances only — call
  /// [withRoadEstimates] once the router has answered.
  final List<PlanCandidate> candidates;

  /// The same stations for a travel quote, nearest-to-route first, which
  /// is the order the #4359 request budget spends itself in.
  final List<TravelStop> travelStops;

  final Map<String, PlanCandidateExclusion> exclusions;

  /// True when any allowed stop comes from a source that lists only part
  /// of its country (#4348). A gap over such a set is incomplete
  /// EVIDENCE, not proof that no usable station exists on the road.
  final bool coverageIncomplete;

  bool get excludedForCurrency => exclusions.values
      .contains(PlanCandidateExclusion.currencyNotComparable);

  /// Station ids excluded by a hard choice or a hard fact, in input
  /// order — what an explanation of a gap names.
  Iterable<String> excludedBy(PlanCandidateExclusion reason) => [
        for (final entry in exclusions.entries)
          if (entry.value == reason) entry.key,
      ];
}

/// Build the allowed stops. See the library doc for what may and may not
/// take a station out of this list.
PlanCandidateSet buildPlanCandidates({
  required List<SearchResultItem> stations,
  required Map<String, FuelType> profileFuelByCountry,
  required FuelType fuelType,
  required RouteProjection projection,
  required Set<String> ignoredStationIds,
  required String currency,
  required ExchangeRateSnapshot rates,
  required DateTime now,
}) {
  final candidates = <PlanCandidate>[];
  final positions = <String, double>{};
  final exclusions = <String, PlanCandidateExclusion>{};
  var coverageIncomplete = false;

  for (final item in stations) {
    if (item is! FuelStationResult) continue;
    final station = item.station;
    final offer = StationOffer.forStation(
        stationId: station.id, lat: station.lat, lng: station.lng);
    if (!offer.canRouteTo) {
      exclusions[station.id] = PlanCandidateExclusion.referencePrice;
      continue;
    }
    if (ignoredStationIds.contains(station.id)) {
      exclusions[station.id] = PlanCandidateExclusion.ignoredByUser;
      continue;
    }
    // #2631 — each station is priced by its own country's profile fuel on
    // a cross-border route, exactly as the list and the map do.
    final fuel = fuelForStation(station, profileFuelByCountry, fuelType);
    final price = station.priceFor(fuel);
    if (price == null || price <= 0) {
      exclusions[station.id] = PlanCandidateExclusion.noPriceForFuel;
      continue;
    }

    // #4361 — normalise BEFORE planning. A price that cannot be stated in
    // the plan's currency is excluded with a reason, never converted at
    // an assumed rate and never compared as a bare number.
    final code = offer.countryCode == null
        ? null
        : Countries.byCode(offer.countryCode!)?.currency;
    final native = code == null ? null : Money(price, code);
    double normalised = price;
    if (native != null && code != currency) {
      final converted = rates.convert(native, currency, now).converted;
      if (converted == null) {
        exclusions[station.id] = PlanCandidateExclusion.currencyNotComparable;
        continue;
      }
      normalised = converted.amount;
    }

    final at = projection.project(station.lat, station.lng);
    positions[station.id] = at.offRouteKm;
    if (!offer.coverageComplete) coverageIncomplete = true;
    candidates.add(PlanCandidate(
      stationId: station.id,
      alongRouteKm: at.alongKm,
      pricePerLitre: normalised,
      nativePrice: native,
      countryCode: offer.countryCode,
      detourKm: at.offRouteKm,
    ));
  }

  final byId = {
    for (final item in stations)
      if (item is FuelStationResult) item.station.id: item.station,
  };
  final quoted = [...candidates]..sort((a, b) =>
      positions[a.stationId]!.compareTo(positions[b.stationId]!));
  return PlanCandidateSet(
    candidates: candidates,
    travelStops: [
      for (final c in quoted)
        (
          id: c.stationId,
          lat: byId[c.stationId]!.lat,
          lng: byId[c.stationId]!.lng
        ),
    ],
    exclusions: exclusions,
    coverageIncomplete: coverageIncomplete,
    stationNames: {
      for (final c in candidates) c.stationId: byId[c.stationId]!.name,
    },
  );
}

/// Replace each candidate's projection detour with the routed exit/rejoin
/// cost where [roadFor] has a current, actionable quote (#4359).
///
/// A station without one keeps the projection — the crow-flies gap to the
/// nearest sampled vertex — and the plan states its detour time as
/// approximate rather than passing it off as routed.
List<PlanCandidate> withRoadEstimates(
  List<PlanCandidate> candidates,
  StationTravelEstimate? Function(String stationId) roadFor,
) =>
    [
      for (final c in candidates)
        if (roadFor(c.stationId) case final road?)
          PlanCandidate(
            stationId: c.stationId,
            alongRouteKm: c.alongRouteKm,
            pricePerLitre: c.pricePerLitre,
            nativePrice: c.nativePrice,
            countryCode: c.countryCode,
            detourKm: c.detourKm,
            roadExtraKm: road.extraKm,
            roadExtraMinutes: road.extraDrivingMinutes,
            incrementalCharge: c.incrementalCharge,
          )
        else
          c,
    ];
