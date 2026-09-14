// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The RESULT of a refuel decision: the three rankings, and whether one
/// of them is confident enough to lead (#4089, #4139).
///
/// Split from `refuel_economics.dart` when §3.1's conditional lead took
/// that file past the 400-line cap. A real seam rather than a length
/// dodge: the arithmetic (what a refuel costs) and the verdict (which
/// answers that produces, and how firmly) are different concerns, and
/// the UI consumes only this half.
library;

import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'refuel_economics.dart';

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

  /// The pick the UI may LEAD with, or null (spec §3.1, #4139).
  ///
  /// Non-null only when every gate holds: a Best Value exists, the
  /// consumption behind it was MEASURED rather than modelled, the station
  /// is open now, and its price is fresh. Any gate failing returns the UI
  /// to the three-answer header.
  ///
  /// The gates never change the RANKING — they decide whether it is
  /// confident enough to be stated as an answer. That is the difference
  /// between §3.1 and the blended score §5 still refuses: a gate can be
  /// explained in one sentence, a weight cannot.
  RefuelQuote? get confidentPick {
    final pick = bestValue;
    if (pick == null) return null;
    if (profile.consumptionIsEstimated) return null;
    if (pick.candidate.isOpenNow != true) return null;
    final age = pick.candidate.priceAge;
    if (age == null || age > kConfidentPickMaxPriceAge) return null;
    return pick;
  }

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
