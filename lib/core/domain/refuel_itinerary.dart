// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// One fully specified refuelling itinerary, evaluated (#4361, Epic
/// #4358, work packages C and D).
///
/// A plan is not "a set of stations"; it is an ORDER of stops with a
/// quantity at each. This library evaluates exactly one such itinerary
/// and answers four questions the caller may not answer for itself:
///
///  * is it feasible — reserve respected on every leg, capacity never
///    exceeded, destination actually reached;
///  * what does it cost — pump cash in each native currency, converted
///    into one comparison currency only when a stated, fresh rate exists
///    (#4361), plus charges that are known (an unknown toll is not zero);
///  * how long does it take and how far does it go beyond the baseline
///    journey, against the driver's own extra-km / extra-minute limits;
///  * what is left in the tank at the end — because two itineraries that
///    end differently are not comparable on cash alone (#4360 rule 3).
///
/// It decides nothing. `refuel_planner.dart` (#4362) enumerates candidate
/// itineraries and picks the minimum of each objective; this file is the
/// single ledger both it and the cross-border comparison (#4361) book
/// against, so the two can never account for fuel differently.
///
/// ## The leg structure of a stop
///
/// ```
/// … along the route to the exit → ACCESS leg → forecourt
/// forecourt → REJOIN leg → back on the route → …
/// ```
///
/// [ItineraryStop.extraKm] is the routed extra of the whole exit-and-
/// rejoin (#4359) and is split evenly between the two legs: the router
/// reports the pair, not the split, and pretending to know it would be
/// invented precision. The reserve is checked at ARRIVAL — after the
/// access leg, before any fuel is bought — which is the moment a driver
/// can actually run dry.
///
/// Pure Dart: no Flutter, no station type, no provider.
library;

import 'package:meta/meta.dart';

import 'money.dart';

/// Floating-point slack for a litre comparison. A tenth of a millilitre:
/// far below anything a pump or a tank sensor resolves, far above the
/// accumulated error of a few dozen multiplications.
const double kLitreEpsilon = 1e-9;

/// The driver's own ceiling on what a refuelling detour may cost them.
///
/// Both limits are opt-in; a null limit is "no stated limit", never zero.
/// They are applied to the EXTRA over the baseline journey, so a long
/// trip does not fail a limit meant for the detour.
@immutable
class TravelLimits {
  const TravelLimits({this.maxExtraKm, this.maxExtraMinutes});

  static const none = TravelLimits();

  final double? maxExtraKm;
  final double? maxExtraMinutes;

  bool exceededByKm(double extraKm) =>
      maxExtraKm != null && extraKm > maxExtraKm! + 1e-9;

  bool exceededByMinutes(double extraMinutes) =>
      maxExtraMinutes != null && extraMinutes > maxExtraMinutes! + 1e-9;
}

/// One stop, with the quantity to buy there.
@immutable
class ItineraryStop {
  const ItineraryStop({
    required this.stopId,
    required this.alongRouteKm,
    required this.pricePerLitre,
    required this.litresToBuy,
    this.countryCode,
    this.extraKm = 0,
    this.extraMinutes,
    this.stopOverheadMinutes = 0,
    this.incrementalCharge,
  });

  final String stopId;

  /// Position along the baseline route. 0 is the origin — a compatible
  /// station at the origin is a valid stop, not a phantom.
  final double alongRouteKm;

  /// The pump price in the SELLING station's own currency (#4361).
  final Money pricePerLitre;

  final double litresToBuy;

  /// The selling country, so a crossing can be made visible and a
  /// coverage or setup caveat attributed to the right place.
  final String? countryCode;

  /// Routed access + rejoin kilometres over the baseline (#4359).
  final double extraKm;

  /// Routed extra DRIVING minutes, stop overhead excluded. Null when the
  /// router did not answer — the itinerary then reports its time as
  /// partly approximate rather than inventing one.
  final double? extraMinutes;

  /// Pulling off, queueing, paying, rejoining — an estimate, carried
  /// apart from routed duration so it can never read as a measured queue.
  final double stopOverheadMinutes;

  /// A charge incurred ONLY by stopping here: a forecourt access toll, a
  /// transaction fee. Charges shared by every itinerary belong in
  /// [ItineraryInput.sharedCharges] and are counted once on each side.
  final Money? incrementalCharge;

  Money get pumpCash => pricePerLitre * litresToBuy;

  /// The same stop with a different quantity — how a stop SITE (where
  /// one could stop) becomes a stop (where one does, and for how much).
  ItineraryStop withLitres(double litres) => ItineraryStop(
        stopId: stopId,
        alongRouteKm: alongRouteKm,
        pricePerLitre: pricePerLitre,
        litresToBuy: litres,
        countryCode: countryCode,
        extraKm: extraKm,
        extraMinutes: extraMinutes,
        stopOverheadMinutes: stopOverheadMinutes,
        incrementalCharge: incrementalCharge,
      );
}

/// Everything the ledger needs, and nothing it can guess.
@immutable
class ItineraryInput {
  const ItineraryInput({
    required this.routeKm,
    required this.consumptionLPer100km,
    required this.startLitres,
    required this.capacityL,
    required this.comparisonCurrency,
    required this.now,
    this.stops = const [],
    this.drivingMinutes = 0,
    this.reserveLitres = 0,
    this.rates = const ExchangeRateSnapshot.empty(),
    this.sharedCharges = const [],
    this.limits = TravelLimits.none,
  });

  /// The baseline journey both a stopping and a non-stopping itinerary
  /// drive. Zero is invalid: there is no journey to plan.
  final double routeKm;
  final double drivingMinutes;
  final double consumptionLPer100km;
  final double startLitres;
  final double capacityL;
  final double reserveLitres;

  /// In route order. The evaluator does not reorder them — an itinerary
  /// whose stops are out of order is invalid input, not a puzzle.
  final List<ItineraryStop> stops;

  /// The one currency every total is expressed in.
  final String comparisonCurrency;

  final ExchangeRateSnapshot rates;
  final DateTime now;

  /// Charges every itinerary under comparison incurs (the border toll
  /// both routes pay). Counted once here, so it cannot change a
  /// DIFFERENCE while still being present in each total.
  final List<Money> sharedCharges;

  final TravelLimits limits;

  bool get isWellFormed {
    if (![routeKm, drivingMinutes, consumptionLPer100km, startLitres,
          capacityL, reserveLitres].every((v) => v.isFinite)) {
      return false;
    }
    if (routeKm <= 0 || consumptionLPer100km <= 0 || capacityL <= 0) {
      return false;
    }
    if (startLitres < 0 || reserveLitres < 0 || reserveLitres >= capacityL) {
      return false;
    }
    if (startLitres > capacityL + kLitreEpsilon) return false;
    var previous = double.negativeInfinity;
    for (final s in stops) {
      if (!s.alongRouteKm.isFinite ||
          s.alongRouteKm < 0 ||
          s.alongRouteKm > routeKm + 1e-9) {
        return false;
      }
      if (s.alongRouteKm < previous) return false;
      previous = s.alongRouteKm;
      if (!s.litresToBuy.isFinite || s.litresToBuy < 0) return false;
      if (!s.pricePerLitre.isFinite || s.pricePerLitre.amount <= 0) {
        return false;
      }
      if (!s.extraKm.isFinite || s.extraKm < 0) return false;
      final minutes = s.extraMinutes;
      if (minutes != null && (!minutes.isFinite || minutes < 0)) return false;
      if (!s.stopOverheadMinutes.isFinite || s.stopOverheadMinutes < 0) {
        return false;
      }
    }
    return true;
  }

  double litresFor(double km) => km * consumptionLPer100km / 100;
}

/// Why an itinerary is not usable as stated.
enum ItineraryBlocker {
  /// A non-finite or negative figure, or stops out of route order.
  invalidInput,

  /// The tank would drop below the reserve before some stop, or before
  /// the destination.
  belowReserve,

  /// A purchase would overflow the tank.
  exceedsCapacity,

  /// The fuel bought does not reach the destination at all.
  doesNotReachDestination,

  /// Past the driver's stated extra-distance limit.
  exceedsExtraDistanceLimit,

  /// Past the driver's stated extra-time limit.
  exceedsExtraTimeLimit,

  /// A native amount could not be expressed in the comparison currency,
  /// so there is no combined total to show (#4361). The native amounts
  /// remain, and the surface shows them side by side.
  currencyNotComparable,
}

/// The tank around one stop — the numbers that prove the plan.
@immutable
class ItineraryStopLedger {
  const ItineraryStopLedger({
    required this.stop,
    required this.arrivalLitres,
    required this.departureLitres,
    required this.pumpCash,
    required this.pumpCashConverted,
  });

  final ItineraryStop stop;

  /// After the along-route drive AND the access leg, before buying.
  final double arrivalLitres;

  final double departureLitres;
  final Money pumpCash;

  /// The same cash in the comparison currency, or null when no fresh
  /// stated rate related the two (#4361) — never a 1:1 stand-in.
  final Money? pumpCashConverted;
}

/// A costed itinerary, with every refusal named.
@immutable
class ItineraryOutcome {
  const ItineraryOutcome({
    required this.blockers,
    required this.stops,
    required this.consumedLitres,
    required this.endLitres,
    required this.extraKm,
    required this.extraMinutes,
    required this.totalMinutes,
    required this.extraTimeIsApproximate,
    required this.nativePumpCash,
    required this.charges,
    this.pumpCash,
    this.total,
  });

  final Set<ItineraryBlocker> blockers;
  final List<ItineraryStopLedger> stops;

  /// Fuel burned over the route and every access/rejoin leg.
  final double consumedLitres;

  /// Tank at the destination — the terminal state two itineraries must
  /// share (or have valued) before their cash is comparable.
  final double endLitres;

  /// Kilometres beyond the baseline route.
  final double extraKm;

  /// Minutes beyond the baseline drive: routed detour minutes plus each
  /// stop's overhead estimate.
  final double extraMinutes;

  final double totalMinutes;

  /// True when at least one stop had no routed duration, so
  /// [extraMinutes] rests on an estimate for that stop.
  final bool extraTimeIsApproximate;

  /// Pump cash per currency, in route order of first appearance — what a
  /// mixed-currency itinerary shows when it cannot show one total.
  final List<Money> nativePumpCash;

  /// Known charges in the comparison currency, or null when a charge
  /// could not be converted. Unknown charges are simply absent — never
  /// counted as zero.
  final Money? charges;

  /// Pump cash in the comparison currency. Null when any leg could not
  /// be converted.
  final Money? pumpCash;

  /// [pumpCash] + [charges]. Null whenever either is.
  final Money? total;

  bool get isFeasible => blockers.isEmpty;

  /// Litres actually bought — zero for a journey that needs no stop,
  /// which is a first-class answer and not a failure.
  double get litresBought =>
      stops.fold<double>(0, (sum, s) => sum + s.stop.litresToBuy);
}
