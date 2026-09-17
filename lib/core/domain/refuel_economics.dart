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

import 'data_value.dart';
import 'refuel_decision.dart';

// Re-exported so every existing caller keeps one import: the split
// (#4139) is an internal seam, not a change to this layer's contract.
export 'refuel_decision.dart';

/// The default litres a refuel is assumed to buy when the user has no
/// fill-up history to measure (#4089).
///
/// A round European tankful.
///
/// ## What Q does, and what it does NOT do (corrected by #4158)
///
/// The effective price works out to `p + detourCost / Q`, and
/// `detourCost` does not depend on Q. So Q is the divisor that
/// **amortises the detour**: the more litres you buy, the less the drive
/// to get there costs per litre.
///
/// This docstring previously claimed Q "moves the effective price by
/// cents, never the sign of a comparison". **That is false**, and a
/// property test found the counterexample on its first run:
///
/// ```
/// a: €1.47/L at 0.7 km      b: €1.40/L at 7.7 km      6 L/100 km
///   Q=20 → a 1.4794, b 1.4981   a wins
///   Q=80 → a 1.4723, b 1.4245   b wins
/// ```
///
/// That behaviour is CORRECT — a cheaper station further away genuinely
/// becomes worth the drive once you are buying enough — but it means Q
/// is a real input to the ranking, not a harmless scale factor. It is
/// why `RefuelProfile.litresIntended` is measured from the user's own
/// median fill (#4150) rather than defaulted, and why #4095 lets them
/// change it.
///
/// What IS invariant, and is tested:
///
///  * at **equal distance** the effective price is proportional to the
///    pump price, so Q never reorders two stations the same distance
///    away;
///  * raising Q moves every effective price monotonically **toward** its
///    pump price, never away.
///
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

/// How fresh a price must be for Best Value to LEAD rather than merely
/// rank (spec §3.1, #4139).
///
/// A day: every source the app uses refreshes at least daily, so a price
/// older than this is one the provider itself has stopped standing
/// behind.
const Duration kConfidentPickMaxPriceAge = Duration(hours: 24);

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
    this.isPhysicalStation = true,
    this.coverageComplete = true,
    this.openState = const DataValue.unknown(
      reason: DataUnknownReason.notPublishedForThisItem,
    ),
    this.priceAge = const DataValue.unknown(
      reason: DataUnknownReason.notPublishedForThisItem,
    ),
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

  /// False for a reference price stood in at a synthetic point — LU's
  /// decree at a city centroid, GR's prefecture average (#4348,
  /// `ProviderCapability.coordinates`).
  ///
  /// Such a candidate stays in [RefuelDecision.quotes] (its price is
  /// real) but has no cost — nobody drives to a town square to buy fuel
  /// — and holds no ranking, so no saving can be claimed against it.
  final bool isPhysicalStation;

  /// False when this candidate's source covers only part of its
  /// country's stations (#4348, DK's three brand feeds). A pick drawn
  /// from such a set is the best among the stations listed, and
  /// [RefuelDecision.coverageIncomplete] makes the UI say so.
  final bool coverageComplete;

  /// Whether the station is open right now (#4139), as far as the
  /// country's provider can say (#4156).
  ///
  /// Never used in the ARITHMETIC — it gates whether Best Value may LEAD
  /// (spec §3.1). A confident recommendation at a closed forecourt is the
  /// failure §5 named as costing more trust than the optimisation buys.
  ///
  /// Was a `bool?`, which conflated two different absences and read both
  /// as "closed": eleven of the seventeen registered countries publish no
  /// opening hours for anyone, so the conditional lead could not fire in
  /// any of them and nothing said why.
  /// `ProviderCapability.openState` produces this, and the difference
  /// between the two unknowns is what the gate now reads.
  final DataValue<bool> openState;

  /// How old the price is (#4139), as far as the country's provider can
  /// say (#4156). Gates the lead for the same reason; never enters the
  /// cost.
  ///
  /// [DataUnknownReason.notPublishedByProvider] means the source stamps
  /// no prices at all — the age we could compute would be our own
  /// download clock. See `ProviderCapability.priceAge`.
  final DataValue<Duration> priceAge;

  @override
  bool operator ==(Object other) =>
      other is RefuelCandidate &&
      other.stationId == stationId &&
      other.oneWayKm == oneWayKm &&
      other.pricePerLitre == pricePerLitre &&
      other.isRoadDistance == isRoadDistance &&
      other.isPhysicalStation == isPhysicalStation &&
      other.coverageComplete == coverageComplete &&
      other.openState == openState &&
      other.priceAge == priceAge;

  @override
  int get hashCode =>
      Object.hash(stationId, oneWayKm, pricePerLitre, isRoadDistance,
          isPhysicalStation, coverageComplete, openState, priceAge);
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

  /// The same pair in the app-wide shape (#4160).
  ///
  /// [consumptionLPer100km] and [consumptionIsEstimated] are a value with
  /// a flag beside it, which is exactly the arrangement a `≈` goes
  /// missing from: nothing stops the flag being dropped on the way to a
  /// widget. Both fields stay — the arithmetic below wants a plain
  /// `double?` and always will — but a rendering path takes this getter
  /// instead, and the provenance cannot be left behind.
  ///
  /// A null consumption is [DataUnknownReason.notMeasuredYet]: it means
  /// the user has no fill-up history, and trust rule 1 requires saying
  /// which missing input it is rather than showing an empty figure.
  DataValue<double> get consumption {
    final value = consumptionLPer100km;
    if (value == null) {
      return const DataValue.unknown(
        reason: DataUnknownReason.notMeasuredYet,
      );
    }
    return consumptionIsEstimated
        ? DataValue.estimated(value, basis: DataBasis.fleetAverage)
        : DataValue.measured(value);
  }

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
