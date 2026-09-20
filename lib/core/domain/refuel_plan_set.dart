// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The set of answers a journey has, and how they are labelled (#4146,
/// #4362, Epic #4358).
///
/// Split from `refuel_plan.dart` when #4362 added the third objective and
/// that file reached the 400-line cap. A real seam: "what ONE plan is" and
/// "which plans a journey has, and what each of them is the minimum of"
/// are different concerns, and the card consumes only this half.
///
/// Re-exported by `refuel_plan.dart`, so every existing caller keeps one
/// import.
library;

import 'package:meta/meta.dart';

import 'money.dart';
import 'refuel_plan.dart';

/// What a journey may be optimised FOR (#4362).
///
/// Three objectives, never a blended score. A weight between money,
/// minutes and kilometres is a value judgement the driver makes, and an
/// opaque number that made it for them could not be explained in one
/// sentence — which is the test `docs/specs/refuel-economics.md` §5 sets.
/// Lowest pump price stays a station FACT, not a journey objective: it
/// says nothing about the drive to get there.
///
/// Cost per kilometre is not a fourth objective either. On the shared
/// baseline distance it orders plans exactly as the totals do, so it is a
/// unit conversion of [lowestCost].
enum RefuelObjective {
  /// Minimum comparable total money, at the documented valuation and the
  /// known charges (#4360, #4361).
  lowestCost,

  /// Minimum expected total time: route, access and rejoin driving plus
  /// each stop's explicit overhead estimate.
  shortestTime,

  /// Minimum actual extra ROAD kilometres over the baseline journey.
  leastExtraDistance,
}

/// The plans a long trip has (#4146, #4362).
///
/// One per objective, for the same reason `refuel_economics.dart` ranks
/// three ways: the question genuinely has several answers and the app
/// does not get to pick for the driver. Any of them may be null when it
/// cannot be computed honestly, and two objectives that land on the same
/// itinerary are ONE result carrying both labels ([objectivesFor]).
@immutable
class RefuelPlanSet {
  const RefuelPlanSet({
    this.cheapest,
    this.fastest,
    this.leastDetour,
    this.gap,
    this.searchWasBounded = false,
    this.reserveLitres = kDefaultReserveLitres,
    this.valuationPricePerLitre,
    this.currencyCode,
  });

  /// Minimum total money.
  final RefuelPlan? cheapest;

  /// Minimum total time. Not "fewest stops": one long detour can lose to
  /// two quick ones, and a shorter drive that takes longer does not win.
  final RefuelPlan? fastest;

  /// Minimum extra road kilometres.
  final RefuelPlan? leastDetour;

  /// True when the candidate search hit its documented work limit, so
  /// these are the best itineraries FOUND rather than provably the best
  /// that exist (#4362). The surface says so; it never claims complete
  /// coverage from a bounded search.
  final bool searchWasBounded;

  /// Set when the route cannot be driven at all; then every plan is null.
  final RefuelPlanGap? gap;

  bool get isFeasible => gap == null;

  /// The reserve both plans are compared at — the common target terminal
  /// fuel state (#4360 rule 3).
  final double reserveLitres;

  /// The ONE price every plan's leftover fuel is valued at: the lowest
  /// pump price among this route's candidates. Documented, common, and
  /// conservative — surplus fuel is credited at the least it could have
  /// been bought for on this journey, never at what a plan happened to
  /// pay. Null when there were no candidates.
  final double? valuationPricePerLitre;

  /// The currency [valuationPricePerLitre] and every plan total are in
  /// (#4361).
  final String? currencyCode;

  /// [plan]'s pump cash with its fuel above the reserve at the destination
  /// valued back at [valuationPricePerLitre] — the figure two plans with
  /// different terminal inventories CAN be compared on (#4360 fixture
  /// B: €4 ending at 5 L and €80 ending at 43 L are both €4 here).
  ///
  /// Null without a valuation basis: then only equal end states compare.
  double? comparableCost(RefuelPlan plan) {
    final basis = valuationPricePerLitre;
    if (basis == null) return null;
    return plan.fuelCost - (plan.endLitres - reserveLitres) * basis;
  }

  /// [comparableCost] with its currency attached (#4361).
  Money? comparableMoney(RefuelPlan plan) {
    final code = currencyCode;
    final value = comparableCost(plan);
    return code == null || value == null ? null : Money(value, code);
  }

  /// The objectives [plan] is the answer to — so a surface shows one
  /// result with two labels instead of the same itinerary three times.
  ///
  /// Identity, not equality: the planner returns the SAME instance for
  /// objectives that agree, which is what makes the collapse exact
  /// rather than a comparison of floating-point totals.
  Set<RefuelObjective> objectivesFor(RefuelPlan plan) => {
        if (identical(cheapest, plan)) RefuelObjective.lowestCost,
        if (identical(fastest, plan)) RefuelObjective.shortestTime,
        if (identical(leastDetour, plan)) RefuelObjective.leastExtraDistance,
      };

  /// What [plan] costs in money, minutes and kilometres against
  /// [reference] — the explanation an alternative objective owes the
  /// driver (#4363).
  ///
  /// Positive means MORE than the reference. Money is null when the two
  /// plans are not in one currency or one of them has no total, which is
  /// the #4361 case where a combined figure is withheld; minutes and
  /// kilometres are always available, because neither needs a rate.
  RefuelPlanTradeOff tradeOff(RefuelPlan plan, RefuelPlan reference) {
    final a = plan.totalMoney, b = reference.totalMoney;
    return RefuelPlanTradeOff(
      cost: a == null || b == null ? null : a - b,
      minutes: plan.totalMinutes - reference.totalMinutes,
      km: plan.detourKm - reference.detourKm,
    );
  }

  /// The distinct plans worth presenting, each once, cost first.
  List<RefuelPlan> get distinctPlans {
    final out = <RefuelPlan>[];
    for (final plan in [cheapest, fastest, leastDetour]) {
      if (plan != null && !out.any((p) => identical(p, plan))) out.add(plan);
    }
    return out;
  }
}

/// What one plan costs against another, per objective (#4363).
///
/// Never a single number: "€3 more, 14 minutes quicker, 8 km further" is
/// a trade the driver can make. A weighted total of the three would be
/// the opaque score `docs/specs/refuel-economics.md` §5 refuses.
@immutable
class RefuelPlanTradeOff {
  const RefuelPlanTradeOff({
    required this.cost,
    required this.minutes,
    required this.km,
  });

  /// Positive: this plan costs MORE. Null when no comparable total
  /// exists (#4361) — the minutes and kilometres still do.
  final Money? cost;

  /// Positive: this plan takes LONGER.
  final double minutes;

  /// Positive: this plan drives FURTHER off the route.
  final double km;

  /// Whether anything at all differs — an identical alternative is a
  /// label on the same result, never a second row.
  bool get isMaterial =>
      (cost != null && cost!.amount.abs() > 0.005) ||
      minutes.abs() > 0.5 ||
      km.abs() > 0.05;
}
