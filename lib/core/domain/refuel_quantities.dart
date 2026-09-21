// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// How much to buy at each stop of a FIXED sequence (#4361/#4362, Epic
/// #4358).
///
/// Choosing WHERE to stop and choosing HOW MUCH to buy there are two
/// problems, and only the second has a closed form. For a fixed ordered
/// sequence of stops the minimum-cost purchase assignment is the classic
/// gas-station rule:
///
/// > At each stop, look ahead for the first strictly cheaper stop still
/// > reachable on a full tank. If there is one, buy just enough to arrive
/// > there at the reserve. Otherwise buy what the rest of the journey
/// > needs to finish at the agreed terminal level — capped by the tank.
///
/// ## Why it stops at the terminal level rather than filling up
///
/// Pure cost minimisation says "fill up whenever nothing cheaper is in
/// reach", and that IS cheaper per litre — but it ends the journey with a
/// different amount of fuel in the tank, and #4360 rule 3 is explicit
/// that two itineraries ending in different states are not comparable on
/// cash. Buying exactly what reaches [targetEndLitres] keeps every
/// alternative ending at the same place, which is what makes €25 and €30
/// a real difference rather than an artefact of how full each tank is.
///
/// The caller that genuinely wants the fill-up behaviour passes a higher
/// [targetEndLitres]; nothing here decides that for it.
///
/// Pure Dart.
library;

import 'dart:math' as math;

import 'refuel_itinerary.dart';

/// Assign a quantity to each site of [sites], in route order.
///
/// [sites] are stops whose `litresToBuy` is ignored; the returned stops
/// carry the computed quantities. The result is not validated here —
/// `evaluateItinerary` is what says whether it is feasible, and it must
/// stay the single judge of that.
List<ItineraryStop> assignPurchaseQuantities(
  ItineraryInput baseline,
  List<ItineraryStop> sites, {
  required double targetEndLitres,
}) {
  final out = <ItineraryStop>[];
  var position = 0.0;
  var litres = baseline.startLitres;

  for (var i = 0; i < sites.length; i++) {
    final site = sites[i];
    final half = baseline.litresFor(site.extraKm / 2);
    final arrival =
        litres - baseline.litresFor(site.alongRouteKm - position) - half;
    final usable = baseline.capacityL - baseline.reserveLitres - half;

    // The first strictly cheaper stop ahead that a full tank can reach
    // from this forecourt — its own access leg included.
    ItineraryStop? cheaperAhead;
    for (var j = i + 1; j < sites.length; j++) {
      final next = sites[j];
      final needed = half +
          baseline.litresFor(next.alongRouteKm - site.alongRouteKm) +
          baseline.litresFor(next.extraKm / 2);
      if (needed > usable + kLitreEpsilon) break;
      if (_isCheaper(baseline, next, site)) {
        cheaperAhead = next;
        break;
      }
    }

    final double needAtDeparture;
    if (cheaperAhead != null) {
      needAtDeparture = baseline.reserveLitres +
          half +
          baseline.litresFor(cheaperAhead.alongRouteKm - site.alongRouteKm) +
          baseline.litresFor(cheaperAhead.extraKm / 2);
    } else {
      needAtDeparture = targetEndLitres +
          half +
          baseline.litresFor(baseline.routeKm - site.alongRouteKm);
    }

    final buy = math.max(
      0.0,
      math.min(baseline.capacityL, needAtDeparture) - arrival,
    );
    out.add(site.withLitres(buy));
    litres = arrival + buy - half;
    position = site.alongRouteKm;
  }
  return out;
}

/// Strictly cheaper, in a currency comparison that is allowed to happen.
///
/// Both prices are taken to [ItineraryInput.comparisonCurrency] first, so
/// a DKK forecourt really can be the cheaper one behind a stated rate. If
/// either side cannot be converted the answer is "not cheaper" — the rule
/// then buys what the journey needs rather than gambling on an
/// unconverted number (#4361), and `evaluateItinerary` withholds the
/// combined money winner for the same reason.
bool _isCheaper(ItineraryInput input, ItineraryStop a, ItineraryStop b) {
  final left = input.rates
      .convert(a.pricePerLitre, input.comparisonCurrency, input.now)
      .converted;
  final right = input.rates
      .convert(b.pricePerLitre, input.comparisonCurrency, input.now)
      .converted;
  return left != null && right != null && left.amount < right.amount;
}
