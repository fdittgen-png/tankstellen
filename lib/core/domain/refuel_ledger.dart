// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The one ledger every refuelling itinerary is booked against (#4361,
/// Epic #4358).
///
/// Split from `refuel_itinerary.dart` the way `refuel_planner.dart` is
/// split from `refuel_plan.dart`: what an itinerary IS and how one is
/// evaluated are different concerns, and the types are consumed by
/// surfaces that never run the arithmetic.
///
/// Read the library doc of `refuel_itinerary.dart` first — it states the
/// leg structure and the four questions answered here.
library;

import 'money.dart';
import 'refuel_itinerary.dart';

/// Evaluate one itinerary. See the library doc for the leg structure.
ItineraryOutcome evaluateItinerary(ItineraryInput input) {
  if (!input.isWellFormed) return _invalid(input);

  final blockers = <ItineraryBlocker>{};
  final ledger = <ItineraryStopLedger>[];
  final nativeByCurrency = <String, double>{};
  final nativeOrder = <String>[];
  var convertible = true;
  var convertedCash = 0.0;
  var position = 0.0;
  var litres = input.startLitres;
  var consumed = 0.0;
  var extraKm = 0.0;
  var extraMinutes = 0.0;
  var approximate = false;

  for (final stop in input.stops) {
    final half = input.litresFor(stop.extraKm / 2);
    final along = input.litresFor(stop.alongRouteKm - position);
    final arrival = litres - along - half;
    consumed += along + half;
    if (arrival < input.reserveLitres - kLitreEpsilon) {
      blockers.add(ItineraryBlocker.belowReserve);
    }
    final departure = arrival + stop.litresToBuy;
    if (departure > input.capacityL + kLitreEpsilon) {
      blockers.add(ItineraryBlocker.exceedsCapacity);
    }
    final cash = stop.pumpCash;
    final converted = input.rates
        .convert(cash, input.comparisonCurrency, input.now)
        .converted;
    if (converted == null) {
      convertible = false;
    } else {
      convertedCash += converted.amount;
    }
    nativeByCurrency.update(cash.currencyCode, (v) => v + cash.amount,
        ifAbsent: () {
      nativeOrder.add(cash.currencyCode);
      return cash.amount;
    });
    ledger.add(ItineraryStopLedger(
      stop: stop,
      arrivalLitres: arrival,
      departureLitres: departure,
      pumpCash: cash,
      pumpCashConverted: converted,
    ));

    consumed += half;
    litres = departure - half;
    position = stop.alongRouteKm;
    extraKm += stop.extraKm;
    final routed = stop.extraMinutes;
    if (routed == null) {
      approximate = true;
      // Timed at the route's own average speed — an approximation, and
      // flagged as one rather than passed off as routed.
      extraMinutes += input.routeKm <= 0
          ? 0
          : stop.extraKm * (input.drivingMinutes / input.routeKm);
    } else {
      extraMinutes += routed;
    }
    extraMinutes += stop.stopOverheadMinutes;
  }

  final lastLeg = input.litresFor(input.routeKm - position);
  consumed += lastLeg;
  final end = litres - lastLeg;
  if (end < input.reserveLitres - kLitreEpsilon) {
    blockers.add(
        end < -kLitreEpsilon ? ItineraryBlocker.doesNotReachDestination
            : ItineraryBlocker.belowReserve);
  }
  if (input.limits.exceededByKm(extraKm)) {
    blockers.add(ItineraryBlocker.exceedsExtraDistanceLimit);
  }
  if (input.limits.exceededByMinutes(extraMinutes)) {
    blockers.add(ItineraryBlocker.exceedsExtraTimeLimit);
  }

  var chargeTotal = 0.0;
  for (final charge in [
    ...input.sharedCharges,
    for (final s in input.stops) ?s.incrementalCharge,
  ]) {
    final converted =
        input.rates.convert(charge, input.comparisonCurrency, input.now)
            .converted;
    if (converted == null) {
      convertible = false;
    } else {
      chargeTotal += converted.amount;
    }
  }
  if (!convertible) blockers.add(ItineraryBlocker.currencyNotComparable);

  final pump =
      convertible ? Money(convertedCash, input.comparisonCurrency) : null;
  final charges =
      convertible ? Money(chargeTotal, input.comparisonCurrency) : null;
  return ItineraryOutcome(
    blockers: blockers,
    stops: ledger,
    consumedLitres: consumed,
    endLitres: end,
    extraKm: extraKm,
    extraMinutes: extraMinutes,
    totalMinutes: input.drivingMinutes + extraMinutes,
    extraTimeIsApproximate: approximate,
    nativePumpCash: [
      for (final code in nativeOrder) Money(nativeByCurrency[code]!, code),
    ],
    charges: charges,
    pumpCash: pump,
    total: pump == null || charges == null ? null : pump + charges,
  );
}

ItineraryOutcome _invalid(ItineraryInput input) => const ItineraryOutcome(
      blockers: {ItineraryBlocker.invalidInput},
      stops: [],
      consumedLitres: 0,
      endLitres: 0,
      extraKm: 0,
      extraMinutes: 0,
      totalMinutes: 0,
      extraTimeIsApproximate: false,
      nativePumpCash: [],
      charges: null,
    );
