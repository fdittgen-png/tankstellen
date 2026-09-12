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

import 'dart:math' as math;

import 'package:meta/meta.dart';

/// The default litres a refuel is assumed to buy when the user has no
/// fill-up history to measure (#4089).
///
/// A round European tankful. It only sets the SCALE of the detour
/// penalty — `Q` appears once, as a divisor — so being 10 L out moves
/// the effective price by cents, never the sign of a comparison. The
/// caller should prefer the user's own median fill-up; see
/// [RefuelProfile.litresIntended].
const double kDefaultRefuelLitres = 40;

/// Crow-flies → road distance correction (#4089).
///
/// Straight-line distance systematically understates driving, and an
/// understated detour is exactly the error that would talk a user into a
/// pointless one. 1.3 is the conventional detour index for European road
/// networks; it applies only when the caller has no real road distance
/// (`RefuelCandidate.isRoadDistance == false`).
const double kCrowFliesRoadFactor = 1.3;

/// There and back (the default) — the errand case, where the station is
/// not on the way to anywhere.
const double kRoundTripFactor = 2;

/// One way — the station is on a route the user is driving anyway, so
/// only the deviation counts. The route layer supplies the real
/// deviation as a road distance.
const double kEnRouteTripFactor = 1;

/// One station, reduced to what the economics needs.
@immutable
class RefuelCandidate {
  const RefuelCandidate({
    required this.stationId,
    required this.oneWayKm,
    this.pricePerLitre,
    this.isRoadDistance = false,
  });

  final String stationId;

  /// Distance to the station, one way. Crow-flies unless
  /// [isRoadDistance]; see [kCrowFliesRoadFactor].
  final double oneWayKm;

  /// Price of the SELECTED fuel, or null when this station does not
  /// publish one. A candidate without a price can still be the closest;
  /// it can never hold an economic ranking (spec §4.3).
  final double? pricePerLitre;

  /// True when [oneWayKm] is a real road distance, so no correction
  /// factor applies.
  final bool isRoadDistance;

  @override
  bool operator ==(Object other) =>
      other is RefuelCandidate &&
      other.stationId == stationId &&
      other.oneWayKm == oneWayKm &&
      other.pricePerLitre == pricePerLitre &&
      other.isRoadDistance == isRoadDistance;

  @override
  int get hashCode =>
      Object.hash(stationId, oneWayKm, pricePerLitre, isRoadDistance);
}

/// The vehicle and intent side of the calculation.
///
/// [consumptionLPer100km] is nullable ON PURPOSE: no consumption means
/// no Best Value ranking, and the UI says so rather than substituting a
/// number the user never gave (spec §4.1). [consumptionIsEstimated]
/// travels with it so an explanation built on a model reads as one.
@immutable
class RefuelProfile {
  const RefuelProfile({
    this.consumptionLPer100km,
    this.consumptionIsEstimated = false,
    this.litresIntended = kDefaultRefuelLitres,
    this.tripFactor = kRoundTripFactor,
    this.roadFactor = kCrowFliesRoadFactor,
  });

  /// Vehicle consumption in L/100 km — measured from fill-ups when the
  /// user has them, else a reference estimate, else null.
  final double? consumptionLPer100km;

  /// Whether [consumptionLPer100km] is modelled rather than measured.
  final bool consumptionIsEstimated;

  /// Litres this refuel is assumed to buy. The user's own median
  /// fill-up when known — the whole point of [kDefaultRefuelLitres]
  /// being a fallback and not a question.
  final double litresIntended;

  /// 2 there-and-back, 1 en route. See [kRoundTripFactor].
  final double tripFactor;

  /// Applied to crow-flies distances only. See [kCrowFliesRoadFactor].
  final double roadFactor;

  /// Whether an economic ranking can be computed at all.
  bool get canRankByValue =>
      (consumptionLPer100km ?? 0) > 0 && litresIntended > 0;
}

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

  /// `litresIntended × pricePerLitre`.
  final double purchaseCost;

  /// What the refuel costs in total.
  double get totalCost => purchaseCost + detourCost;
}

/// A station with its cost attached. [cost] is null when the station has
/// no price, or the profile has no consumption.
@immutable
class RefuelQuote {
  const RefuelQuote({required this.candidate, required this.cost});

  final RefuelCandidate candidate;
  final RefuelCost? cost;

  /// Cost per litre BOUGHT, detour included — the quantity Best Value
  /// ranks on. Null when [cost] is.
  double? get effectivePricePerLitre => cost == null
      ? null
      : cost!.totalCost / _litres;

  /// Kept so [effectivePricePerLitre] does not need the profile again.
  double get _litres =>
      cost!.purchaseCost / (candidate.pricePerLitre ?? 1);
}

/// Which question a station is the answer to.
enum RefuelRanking {
  /// Lowest price per litre — pure price, no arithmetic.
  cheapest,

  /// Least driving.
  closest,

  /// Lowest effective price per litre — price and detour together.
  bestValue,
}

/// The three answers, and nothing claiming to be THE answer.
///
/// The UI presents all three with their reasons; it never tells the user
/// one station is objectively best (spec §3). [bestValue] is null
/// exactly when the profile could not support the calculation, which the
/// UI must surface as a reason rather than hide.
@immutable
class RefuelDecision {
  const RefuelDecision({
    required this.profile,
    required this.quotes,
    this.cheapest,
    this.closest,
    this.bestValue,
  });

  final RefuelProfile profile;

  /// Every candidate, costed, in input order.
  final List<RefuelQuote> quotes;

  final RefuelQuote? cheapest;
  final RefuelQuote? closest;
  final RefuelQuote? bestValue;

  /// False when no Best Value could be computed — the UI states why
  /// instead of showing a recommendation it cannot justify.
  bool get valueRankingAvailable => bestValue != null;

  /// The rankings [stationId] holds, so the UI can collapse a station
  /// that is several answers at once into one row instead of repeating
  /// it three times.
  Set<RefuelRanking> rankingsFor(String stationId) => {
        if (cheapest?.candidate.stationId == stationId)
          RefuelRanking.cheapest,
        if (closest?.candidate.stationId == stationId) RefuelRanking.closest,
        if (bestValue?.candidate.stationId == stationId)
          RefuelRanking.bestValue,
      };

  /// The distinct stations worth presenting, best-value first, then
  /// cheapest, then closest — each appearing once.
  List<RefuelQuote> get distinctPicks {
    final seen = <String>{};
    return [
      for (final q in [bestValue, cheapest, closest])
        if (q != null && seen.add(q.candidate.stationId)) q,
    ];
  }

  /// What choosing [quote] over [reference] saves, in currency, at the
  /// profile's quantity. Negative means it costs more. Null when either
  /// side has no cost.
  double? savings(RefuelQuote quote, RefuelQuote reference) {
    final a = quote.cost, b = reference.cost;
    if (a == null || b == null) return null;
    return b.totalCost - a.totalCost;
  }

  /// Extra kilometres [quote] costs over [reference]. Never negative —
  /// a nearer pick simply has no extra driving to declare.
  double extraTravelKm(RefuelQuote quote, RefuelQuote reference) {
    final a = quote.cost?.travelKm, b = reference.cost?.travelKm;
    if (a == null || b == null) return 0;
    return math.max(0, a - b);
  }

  /// The quantity at which [quote] starts beating [reference] — the
  /// honest form of "only worth the detour if you buy at least this
  /// much".
  ///
  /// Null when the question does not arise: either side unpriced, no
  /// consumption, [quote] not actually cheaper per litre, or [quote]
  /// already winning at any quantity (it is cheaper AND no further).
  double? breakEvenLitres(RefuelQuote quote, RefuelQuote reference) {
    final pS = quote.candidate.pricePerLitre;
    final pK = reference.candidate.pricePerLitre;
    final cS = quote.cost, cK = reference.cost;
    final c = profile.consumptionLPer100km;
    if (pS == null || pK == null || cS == null || cK == null || c == null) {
      return null;
    }
    if (pK <= pS) return null; // not the cheaper one; nothing to justify
    final numerator = (c / 100) * (cS.travelKm * pS - cK.travelKm * pK);
    if (numerator <= 0) return null; // wins at any quantity
    return numerator / (pK - pS);
  }
}

/// The calculation. One entry point, no state.
abstract final class RefuelEconomics {
  /// Cost [candidate] under [profile]. Null when the station publishes
  /// no price for the selected fuel, or the profile cannot support the
  /// arithmetic (spec §4.1, §4.3).
  static RefuelCost? cost(RefuelCandidate candidate, RefuelProfile profile) {
    final price = candidate.pricePerLitre;
    final consumption = profile.consumptionLPer100km;
    if (price == null || price <= 0) return null;
    if (consumption == null || consumption <= 0) return null;
    if (profile.litresIntended <= 0) return null;

    final travelKm = candidate.oneWayKm *
        profile.tripFactor *
        (candidate.isRoadDistance ? 1 : profile.roadFactor);
    final detourLitres = travelKm * consumption / 100;
    return RefuelCost(
      travelKm: travelKm,
      detourLitres: detourLitres,
      detourCost: detourLitres * price,
      purchaseCost: profile.litresIntended * price,
    );
  }

  /// Rank [candidates] three ways under [profile].
  ///
  /// Ties break on the station id so the order is stable across rebuilds
  /// — a recommendation that reshuffles on every frame reads as noise.
  static RefuelDecision decide(
    Iterable<RefuelCandidate> candidates,
    RefuelProfile profile,
  ) {
    final quotes = [
      for (final c in candidates)
        RefuelQuote(candidate: c, cost: cost(c, profile)),
    ];

    RefuelQuote? best(
      double? Function(RefuelQuote) key,
    ) {
      RefuelQuote? winner;
      double? winning;
      for (final q in quotes) {
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

    return RefuelDecision(
      profile: profile,
      quotes: quotes,
      cheapest: best((q) => q.candidate.pricePerLitre),
      closest: best((q) => q.candidate.oneWayKm),
      bestValue:
          profile.canRankByValue ? best((q) => q.effectivePricePerLitre) : null,
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
