// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The refuel decision model (#4089, Epic #4087).
///
/// Specified in `docs/specs/refuel-economics.md` BEFORE this code
/// existed, because a recommendation the user cannot trust is worse than
/// no recommendation. Read §4 of the spec — the trust rules — with this
/// file; each one is a test in `refuel_economics_test.dart`.
///
/// Pure Dart over primitives: no Flutter, no feature imports, no
/// station type. The caller reduces a station to a [RefuelCandidate] and
/// passes the vehicle side as numbers, which keeps this layer free to
/// evolve independently of the UI (layer 2 of the Epic's three) and
/// keeps every feature boundary intact.
///
/// ## What it replaces
///
/// `compareByPriceDistance` ranked by `price ÷ distance` — a quantity
/// with no economic meaning that is monotonically IMPROVED by driving
/// further, so at equal price it ranked the farther station first
/// (#4088). Effective price per litre is a real cost and is worsened by
/// distance, as it must be.
library;


import 'package:meta/meta.dart';

import 'money.dart';
import 'refuel_candidate.dart';
import 'refuel_profile.dart';
import 'refuel_decision.dart';
import 'refuel_trip_cost.dart';

// Re-exported so every existing caller keeps one import: the split
// (#4139) is an internal seam, not a change to this layer's contract.
export 'refuel_candidate.dart';
export 'refuel_decision.dart';
export 'refuel_profile.dart';
/// What a refuel at one station actually costs.
///
/// Every field is reproducible from [RefuelCandidate] + [RefuelProfile]
/// with the arithmetic in the spec — there is no score and no weight to
/// take on faith (spec §4.4).
@immutable
class RefuelCost {
  const RefuelCost({
    required this.travelKm,
    required this.detourLitres,
    required this.detourCost,
    required this.purchaseCost,
  });

  /// Total kilometres driven for this refuel: `tripFactor × oneWayKm ×
  /// roadFactor` (the factor omitted for a real road distance).
  final double travelKm;

  /// Fuel burned covering [travelKm].
  final double detourLitres;

  /// [detourLitres] priced at this station — you are replacing it here.
  final double detourCost;

  /// `litresIntended × pricePerLitre` — the price of the net refill.
  final double purchaseCost;

  /// CASH AT THE PUMP for a net refill of `litresIntended` (#4360).
  ///
  /// `(litresIntended + detourLitres) × price`: the pump delivers the
  /// refill plus what the trip burns, each litre paid once. Not "litres
  /// bought plus a travel charge" — and because every candidate is priced
  /// for the same net refill, every candidate ends in the same tank state
  /// and these totals compare directly.
  double get totalCost => purchaseCost + detourCost;
}

/// A station with its cost attached. [cost] is null when the station has
/// no price, or the profile has no consumption.
@immutable
class RefuelQuote {
  const RefuelQuote({required this.candidate, required this.cost});

  final RefuelCandidate candidate;
  final RefuelCost? cost;

  /// The litres the pump actually delivers for the net refill (#4360).
  /// Null when [cost] is.
  double? get litresToDispense =>
      cost == null ? null : _litres + cost!.detourLitres;

  /// Cash per NET litre gained, detour included — the quantity Best
  /// Value ranks on. Null when [cost] is.
  double? get effectivePricePerLitre => cost == null
      ? null
      : cost!.totalCost / _litres;

  /// Kept so [effectivePricePerLitre] does not need the profile again.
  double get _litres =>
      cost!.purchaseCost / (candidate.pricePerLitre ?? 1);
}

/// The calculation. One entry point, no state.
abstract final class RefuelEconomics {
  /// Cost [candidate] under [profile]. Null when the station publishes
  /// no price for the selected fuel, or the profile cannot support the
  /// arithmetic (spec §4.1, §4.3).
  static RefuelCost? cost(RefuelCandidate candidate, RefuelProfile profile) {
    final price = candidate.pricePerLitre;
    final consumption = profile.consumptionLPer100km;
    // #4348 — no drive to a reference point, so no detour to cost.
    if (!candidate.isPhysicalStation) return null;
    if (price == null || price <= 0) return null;
    if (consumption == null || consumption <= 0) return null;
    if (profile.litresIntended <= 0) return null;

    final travelKm = RefuelEconomics.travelKm(candidate, profile);
    final detourLitres = travelKm * consumption / 100;
    return RefuelCost(
      travelKm: travelKm,
      detourLitres: detourLitres,
      detourCost: detourLitres * price,
      purchaseCost: profile.litresIntended * price,
    );
  }

  /// Kilometres driven for this refuel (#4359).
  ///
  /// The routed itinerary when the candidate carries an actionable road
  /// estimate — both real legs, from the driver's own origin — else the
  /// approximate `tripFactor × oneWayKm × roadFactor`. The same figure
  /// costs the detour and ranks "closest", so the two can never disagree
  /// about which station is nearer.
  static double travelKm(RefuelCandidate candidate, RefuelProfile profile) {
    final road = candidate.roadTravel;
    final routed = road != null && road.isActionable
        ? road.itinerary.distanceKm
        : null;
    if (routed != null) return routed;
    return candidate.oneWayKm *
        profile.tripFactor *
        (candidate.isRoadDistance ? 1 : profile.roadFactor);
  }

  /// One refuelling TRIP with fuel conserved on its outbound and return
  /// legs, a purchase quantity whose meaning is kept, and cash counted
  /// once (#4360). The ledger lives in `refuel_trip_cost.dart`; this is
  /// the single calculator's entry point for it.
  static RefuelTripOutcome tripCost(RefuelTripInput input) =>
      computeRefuelTrip(input);

  /// Rank [candidates] three ways under [profile].
  ///
  /// Ties break on the station id so the order is stable across rebuilds
  /// — a recommendation that reshuffles on every frame reads as noise.
  ///
  /// #4361 — the two MONEY rankings are decided in one currency. When the
  /// candidates state several, each amount is converted at a stated,
  /// fresh rate from [RefuelProfile.rates]; a candidate whose amount
  /// cannot be converted keeps its native price on screen and is left out
  /// of the money rankings, which [RefuelDecision.moneyRankingWithheld]
  /// reports. "Closest" is unaffected — kilometres need no rate.
  ///
  /// [now] is what staleness is measured against. Without it no
  /// conversion is attempted at all, because an unverifiable rate is
  /// exactly the silent 1:1 this guard exists to prevent; a
  /// single-currency comparison never needs it.
  static RefuelDecision decide(
    Iterable<RefuelCandidate> candidates,
    RefuelProfile profile, {
    DateTime? now,
  }) {
    final quotes = [
      for (final c in candidates)
        RefuelQuote(candidate: c, cost: cost(c, profile)),
    ];
    final currencies = <String>{
      for (final q in quotes) ?q.candidate.currencyCode,
    };
    // Several currencies and no stated comparison currency is not a
    // comparison: there is no denomination to be cheapest IN.
    final unresolved = profile.comparisonCurrency == null &&
        currencies.length > 1;
    final target = profile.comparisonCurrency ??
        (currencies.length == 1 ? currencies.single : null);
    var withheld = false;

    /// [amount] in [target], or null when it may not be ranked there.
    double? inTarget(double? amount, String? code) {
      if (amount == null) return null;
      if (unresolved) return null;
      // Nothing states a currency, or this candidate states none: there
      // is no second denomination in play, so the amount is already in
      // the only one there is. Only a STATED foreign currency needs a
      // rate — that is the DKK-against-EUR defect, and an unresolvable
      // country is not it.
      if (target == null || code == null || code == target) return amount;
      if (now == null) return null;
      return profile.rates
          .convert(Money(amount, code), target, now)
          .converted
          ?.amount;
    }

    double? money(double? amount, RefuelCandidate c) {
      final value = inTarget(amount, c.currencyCode);
      if (value == null && amount != null && c.isPhysicalStation) {
        withheld = true;
      }
      return value;
    }

    RefuelQuote? best(
      double? Function(RefuelQuote) key,
    ) {
      RefuelQuote? winner;
      double? winning;
      for (final q in quotes) {
        // #4348 — a reference price never poses as the cheapest or
        // closest STATION.
        if (!q.candidate.isPhysicalStation) continue;
        final v = key(q);
        if (v == null) continue;
        if (winning == null ||
            v < winning ||
            (v == winning &&
                q.candidate.stationId
                        .compareTo(winner!.candidate.stationId) <
                    0)) {
          winner = q;
          winning = v;
        }
      }
      return winner;
    }

    final cheapest =
        best((q) => money(q.candidate.pricePerLitre, q.candidate));
    final bestValue = profile.canRankByValue
        ? best((q) => money(q.effectivePricePerLitre, q.candidate))
        : null;
    return RefuelDecision(
      profile: profile,
      quotes: quotes,
      cheapest: cheapest,
      closest: best((q) => travelKm(q.candidate, profile)),
      bestValue: bestValue,
      comparisonCurrency: target,
      moneyRankingWithheld: withheld,
    );
  }

  /// The median of [volumes] — the user's typical fill-up, and so the
  /// default [RefuelProfile.litresIntended] (spec §2).
  ///
  /// Median, not mean: one 8 L splash-and-dash or one jerrycan should
  /// not move the assumption. Null for an empty history, which is what
  /// makes [kDefaultRefuelLitres] a fallback rather than a question the
  /// user has to answer.
  static double? medianLitres(Iterable<double> volumes) {
    final sorted = volumes.where((v) => v > 0).toList()..sort();
    if (sorted.isEmpty) return null;
    final n = sorted.length;
    if (n.isOdd) return sorted[n ~/ 2];
    return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
  }
}
