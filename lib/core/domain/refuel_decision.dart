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

import 'data_value.dart';
import 'refuel_economics.dart';

/// What the conditional lead could NOT verify (#4156).
///
/// A gate the provider cannot answer is not a gate we may fail — that
/// would have disabled the lead in eleven of seventeen countries because
/// their source publishes no opening hours, which is a fact about the
/// source and not about the forecourt. It is also not a gate we may
/// silently pass: the user is being shown one answer instead of three,
/// and is owed the reason it is only *probably* right.
///
/// So the gate steps aside and records why. The UI states these next to
/// the lead; `docs/specs/refuel-economics.md` trust rule 1 — a missing
/// input is stated, never defaulted.
enum LeadCaveat {
  /// This country's source publishes no opening hours at all, so nobody
  /// checked whether the forecourt is open.
  openingHoursNotPublished,

  /// This country's source stamps no prices, so the age of the number is
  /// our download time, not the provider's price time.
  priceAgeNotPublished,
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

  /// The pick the UI may LEAD with, or null (spec §3.1, #4139).
  ///
  /// Non-null only when every gate holds: a Best Value exists, the
  /// consumption behind it was MEASURED rather than modelled, the station
  /// is not known to be closed, and its price is not known to be stale.
  /// Any gate failing returns the UI to the three-answer header.
  ///
  /// The gates never change the RANKING — they decide whether it is
  /// confident enough to be stated as an answer. That is the difference
  /// between §3.1 and the blended score §5 still refuses: a gate can be
  /// explained in one sentence, a weight cannot.
  ///
  /// #4156 — "not known to be closed" is doing real work in that
  /// sentence. A gate the country's provider cannot answer for anyone
  /// stands down and is reported in [leadCaveats]; a gate it can answer
  /// and left blank for THIS station still blocks.
  RefuelQuote? get confidentPick {
    final pick = bestValue;
    if (pick == null) return null;
    if (profile.consumptionIsEstimated) return null;
    if (_openGateBlocks(pick.candidate.openState)) return null;
    if (_freshnessGateBlocks(pick.candidate.priceAge)) return null;
    return pick;
  }

  /// What [confidentPick] could not verify, so the UI can say so (#4156).
  ///
  /// Empty when every gate was actually checked. Never populated when
  /// there is no lead — a caveat on an answer nobody is being shown is
  /// noise.
  Set<LeadCaveat> get leadCaveats {
    final pick = confidentPick;
    if (pick == null) return const {};
    return {
      if (_notPublishedByProvider(pick.candidate.openState))
        LeadCaveat.openingHoursNotPublished,
      if (_notPublishedByProvider(pick.candidate.priceAge))
        LeadCaveat.priceAgeNotPublished,
    };
  }

  /// True when the provider for this row publishes nothing of the kind —
  /// the one unknown that lets a gate stand down rather than fail.
  static bool _notPublishedByProvider(DataValue<Object?> value) =>
      value is Unknown &&
      value.reason == DataUnknownReason.notPublishedByProvider;

  /// Open now, or nobody could have known.
  ///
  /// Blocks on a station we know is closed, and on a station whose
  /// provider DOES publish hours but published none for this row — that
  /// gap is real and specific to the forecourt we are about to send
  /// someone to. Stands down when the provider publishes no hours for
  /// anyone; [leadCaveats] carries that forward.
  static bool _openGateBlocks(DataValue<bool> openState) =>
      switch (openState) {
        Measured<bool>(:final value) => !value,
        Unknown<bool>(:final reason) =>
          reason != DataUnknownReason.notPublishedByProvider,
        _ => true,
      };

  /// Fresh enough to lead on, or nobody could have known.
  ///
  /// [kConfidentPickMaxPriceAge] is unchanged and still the product
  /// decision it was in #4139. What #4156 adds is the difference between
  /// "this provider stamps no prices" — in which case there is no age to
  /// test and the gate stands down with a caveat — and "this provider
  /// stamps prices and left this one blank", which stays a block.
  static bool _freshnessGateBlocks(DataValue<Duration> priceAge) =>
      switch (priceAge) {
        Measured<Duration>(:final value) => value > kConfidentPickMaxPriceAge,
        Unknown<Duration>(:final reason) =>
          reason != DataUnknownReason.notPublishedByProvider,
        _ => true,
      };

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
