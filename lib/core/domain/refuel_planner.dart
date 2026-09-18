// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Which stops a journey needs, and which of them is the minimum of each
/// objective (#4146, rewritten for #4362, Epic #4358).
///
/// ## The problem this solves, exactly
///
/// > Given a journey of known length, a tank with a known capacity,
/// > start level and reserve, and a bounded set of allowed stops each
/// > with a position, a routed access/rejoin cost and a price already
/// > normalised into ONE currency: choose an ordered subset of stops and
/// > a quantity at each so that the reserve holds on every leg, the tank
/// > never overflows, the journey ends at the agreed terminal level, and
/// > one of total money / total time / extra kilometres is minimal.
///
/// Anything outside that sentence is not this layer's answer. In
/// particular it does not decide WHICH stations are allowed — hard
/// exclusions (incompatible fuel, an ignored station, a reference price,
/// a known closure) are applied by the provider before a candidate
/// exists, and a soft display or price filter must never reach here at
/// all, or a necessary expensive bridge stop disappears before
/// feasibility is considered.
///
/// ## How, and what the claim is worth
///
/// Quantities for a FIXED stop sequence have a closed form — the classic
/// gas-station rule in `refuel_quantities.dart`. What is left is the
/// choice of sequence, and that is enumerated: every ordered subset of
/// the bounded candidate pool up to [kPlannerMaxStops], each evaluated
/// against the one ledger in `refuel_ledger.dart`.
///
/// Within the pool and the stop cap this is EXHAUSTIVE, and the claim is
/// exactly that: the minimum over the itineraries searched. When either
/// bound bites, [RefuelPlanSet.searchWasBounded] says so and the result
/// is the best found rather than the best that exists. The previous
/// implementation claimed a greedy optimum it no longer had once
/// detours, stop overheads and quantity-dependent charges entered, and
/// picked "fastest" by a 10 % distance heuristic that never looked at the
/// returned durations at all.
///
/// The three objectives are computed over the SAME journey, vehicle,
/// candidate set, limits and terminal tank state, so their disagreement
/// is a real trade-off rather than an artefact of different inputs.
library;

import 'dart:math' as math;

import 'money.dart';
import 'refuel_itinerary.dart';
import 'refuel_ledger.dart';
import 'refuel_plan.dart';
import 'refuel_quantities.dart';

/// Candidates the search may combine.
///
/// 10 keeps the exhaustive enumeration under a thousand evaluations —
/// milliseconds, and small enough to run on a provider rebuild without
/// blocking a frame. A route with more priced stations keeps the ones a
/// plan could actually use (see `_boundedPool`) and says the search was
/// bounded.
const int kPlannerMaxCandidates = 10;

/// Stops one enumerated itinerary may contain.
///
/// Four covers every European journey a full tank plus three refills can
/// make. A journey that genuinely needs more falls back to the reachable
/// chain and is reported as bounded rather than silently truncated.
const int kPlannerMaxStops = 4;

abstract final class RefuelPlanner {
  /// Plan [request] for each objective. See the library doc for the
  /// problem solved and the strength of the claim.
  ///
  /// Returns an empty set when the inputs cannot support arithmetic —
  /// the caller says what is missing rather than showing a guess — and a
  /// set carrying only a [RefuelPlanGap] when the journey cannot be
  /// driven at all. It never returns a plan that does not reach the
  /// destination.
  static RefuelPlanSet plan(RefuelPlanRequest request) {
    if (!request.isComputable) return const RefuelPlanSet();

    // Candidates beyond the destination and behind the origin cannot
    // create a stop; a position of exactly 0 can — a compatible station
    // at the origin is a valid refuelling action.
    final sorted = [
      for (final c in request.candidates)
        if (c.alongRouteKm >= 0 && c.alongRouteKm <= request.routeKm) c,
    ]..sort((a, b) => a.alongRouteKm != b.alongRouteKm
        ? a.alongRouteKm.compareTo(b.alongRouteKm)
        : a.stationId.compareTo(b.stationId));

    final baseline = _baseline(request);
    final found = <_Itinerary>[];

    // A journey the tank already covers is a first-class answer, and it
    // is available even when no priced station was returned at all.
    final through = evaluateItinerary(baseline);
    if (through.isFeasible) {
      found.add(_Itinerary(const [], through, request));
    }

    final (pool, trimmed) = _boundedPool(request, sorted);
    var bounded = trimmed;
    final currency = baseline.comparisonCurrency;
    for (final sequence in _sequences(pool, kPlannerMaxStops)) {
      final stops = assignPurchaseQuantities(
        baseline,
        [for (final c in sequence) c.asSite(currency)],
        targetEndLitres: request.reserveLitres,
      );
      final outcome = evaluateItinerary(_withStops(baseline, stops));
      if (outcome.isFeasible) found.add(_Itinerary(sequence, outcome, request));
    }
    if (found.isEmpty) {
      // Nothing searched was feasible. Say WHERE the journey breaks — a
      // gap the driver can act on — rather than returning a plan that
      // does not reach the end.
      return RefuelPlanSet(
        gap: _firstGap(request, sorted) ??
            RefuelPlanGap(fromKm: 0, toKm: request.routeKm),
        searchWasBounded: bounded,
      );
    }
    if (pool.length < sorted.length) bounded = true;

    return RefuelPlanSet(
      cheapest: _best(found, (i) => i.cost)?.plan,
      fastest: _best(found, (i) => i.outcome.totalMinutes)?.plan,
      leastDetour: _best(found, (i) => i.outcome.extraKm)?.plan,
      reserveLitres: request.reserveLitres,
      currencyCode: request.currencyCode,
      searchWasBounded: bounded,
      valuationPricePerLitre: sorted.isEmpty
          ? null
          : sorted.map((c) => c.pricePerLitre).reduce(math.min),
    );
  }

  /// The minimum of [key], ties broken deterministically: fewer stops
  /// first, then the stop ids in order. A recommendation that reshuffles
  /// between two equal plans reads as noise.
  static _Itinerary? _best(
    List<_Itinerary> all,
    double? Function(_Itinerary) key,
  ) {
    _Itinerary? winner;
    double? winning;
    for (final candidate in all) {
      final value = key(candidate);
      if (value == null || !value.isFinite) continue;
      if (winning == null ||
          value < winning ||
          (value == winning &&
              candidate.tieBreak.compareTo(winner!.tieBreak) < 0)) {
        winner = candidate;
        winning = value;
      }
    }
    return winner;
  }

  /// Every ordered subset of [pool] of size 1..[maxStops], in route order.
  static Iterable<List<PlanCandidate>> _sequences(
    List<PlanCandidate> pool,
    int maxStops,
  ) sync* {
    final limit = math.min(maxStops, pool.length);
    for (var size = 1; size <= limit; size++) {
      yield* _combinations(pool, size, 0, <PlanCandidate>[]);
    }
  }

  static Iterable<List<PlanCandidate>> _combinations(
    List<PlanCandidate> pool,
    int size,
    int from,
    List<PlanCandidate> acc,
  ) sync* {
    if (acc.length == size) {
      yield List.of(acc);
      return;
    }
    for (var i = from; i <= pool.length - (size - acc.length); i++) {
      acc.add(pool[i]);
      yield* _combinations(pool, size, i + 1, acc);
      acc.removeLast();
    }
  }

  /// At most [kPlannerMaxCandidates] candidates, and whether trimming
  /// happened.
  ///
  /// The pool keeps the stations a plan could actually use: the chain the
  /// reachability walk needs to cross the route at all (drop one and a
  /// feasible journey looks infeasible), then the cheapest of the rest.
  static (List<PlanCandidate>, bool) _boundedPool(
    RefuelPlanRequest r,
    List<PlanCandidate> sorted,
  ) {
    if (sorted.length <= kPlannerMaxCandidates) return (sorted, false);
    final keep = {..._reachableChain(r, sorted).map((c) => c.stationId)};
    final byPrice = [...sorted]
      ..sort((a, b) => a.pricePerLitre != b.pricePerLitre
          ? a.pricePerLitre.compareTo(b.pricePerLitre)
          : a.stationId.compareTo(b.stationId));
    for (final c in byPrice) {
      if (keep.length >= kPlannerMaxCandidates) break;
      keep.add(c.stationId);
    }
    return ([
      for (final c in sorted)
        if (keep.contains(c.stationId)) c,
    ], true);
  }

  /// The stations a maximum-reach walk stops at — the bridge chain.
  static List<PlanCandidate> _reachableChain(
    RefuelPlanRequest r,
    List<PlanCandidate> sorted,
  ) {
    final chain = <PlanCandidate>[];
    var at = 0.0;
    var available = r.startLitres - r.reserveLitres;
    while (r.litresFor(r.routeKm - at) > available + 1e-9) {
      final next = _furthestReach(r, sorted, at, available);
      if (next == null) break;
      chain.add(next);
      at = next.alongRouteKm;
      available = r.tankCapacityL - r.reserveLitres - _half(r, next);
    }
    return chain;
  }

  static PlanCandidate? _furthestReach(
    RefuelPlanRequest r,
    List<PlanCandidate> sorted,
    double at,
    double available,
  ) {
    PlanCandidate? best;
    var bestFrontier = double.negativeInfinity;
    for (final c in sorted) {
      if (c.alongRouteKm <= at) continue;
      if (r.litresFor(c.alongRouteKm - at) + _half(r, c) > available + 1e-9) {
        continue;
      }
      final frontier = c.alongRouteKm +
          r.kmFor(r.tankCapacityL - r.reserveLitres - _half(r, c));
      if (frontier > bestFrontier) {
        best = c;
        bestFrontier = frontier;
      }
    }
    return best;
  }

  /// The first stretch the driver cannot cross, or null.
  ///
  /// Each hop goes to the reachable station whose full tank reaches
  /// furthest, access and rejoin legs included, so a far-off station is
  /// not counted as a bridge its own detour cannot pay for.
  static RefuelPlanGap? _firstGap(
    RefuelPlanRequest r,
    List<PlanCandidate> sorted,
  ) {
    var at = 0.0;
    var available = r.startLitres - r.reserveLitres;
    while (true) {
      if (r.litresFor(r.routeKm - at) <= available + 1e-9) return null;
      final next = _furthestReach(r, sorted, at, available);
      if (next == null) {
        final beyond = sorted.where((c) => c.alongRouteKm > at).firstOrNull;
        return RefuelPlanGap(
          fromKm: at + r.kmFor(math.max(0, available)),
          toKm: beyond?.alongRouteKm ?? r.routeKm,
        );
      }
      at = next.alongRouteKm;
      available = r.tankCapacityL - r.reserveLitres - _half(r, next);
    }
  }

  static double _half(RefuelPlanRequest r, PlanCandidate c) =>
      r.litresFor(c.extraKm / 2);

  static ItineraryInput _baseline(RefuelPlanRequest r) => ItineraryInput(
        routeKm: r.routeKm,
        drivingMinutes: r.drivingMinutes,
        consumptionLPer100km: r.consumptionLPer100km,
        startLitres: r.startLitres,
        capacityL: r.tankCapacityL,
        reserveLitres: r.reserveLitres,
        comparisonCurrency: r.currencyCode ?? _unnamedCurrency,
        limits: r.limits,
        // Every price already carries the request's currency, so the
        // ledger never converts and no rate staleness is ever tested
        // (#4361 normalises before planning). A fixed epoch is therefore
        // the honest value: this layer reads no clock at all.
        now: _noClock,
      );

  static ItineraryInput _withStops(
          ItineraryInput baseline, List<ItineraryStop> stops) =>
      ItineraryInput(
        routeKm: baseline.routeKm,
        drivingMinutes: baseline.drivingMinutes,
        consumptionLPer100km: baseline.consumptionLPer100km,
        startLitres: baseline.startLitres,
        capacityL: baseline.capacityL,
        reserveLitres: baseline.reserveLitres,
        stops: stops,
        comparisonCurrency: baseline.comparisonCurrency,
        limits: baseline.limits,
        now: baseline.now,
      );
}

/// The instant the ledger is handed. It is never used: the planner does
/// no currency conversion, so nothing here asks how old a rate is.
final DateTime _noClock = DateTime.utc(1970);

/// The placeholder denomination for a caller that named none. It is a
/// label, never a real currency: it only has to be the SAME on every
/// amount so the ledger's sums stay well defined.
const String _unnamedCurrency = '::unnamed';

/// One evaluated itinerary, with the [RefuelPlan] it becomes.
class _Itinerary {
  _Itinerary(this.sequence, this.outcome, this.request);

  final List<PlanCandidate> sequence;
  final ItineraryOutcome outcome;
  final RefuelPlanRequest request;

  double? get cost => outcome.total?.amount;

  /// Fewer stops first, then the stop ids — a total order, so two plans
  /// with identical totals always resolve the same way.
  String get tieBreak =>
      '${sequence.length}|${sequence.map((c) => c.stationId).join('>')}';

  late final RefuelPlan plan = _build();

  RefuelPlan _build() {
    var roadMinutes = 0.0;
    var approximateKm = 0.0;
    for (final c in sequence) {
      final routed = c.roadExtraMinutes;
      if (routed == null) {
        approximateKm += c.extraKm;
      } else {
        roadMinutes += routed;
      }
    }
    return RefuelPlan(
      stops: [
        for (var i = 0; i < sequence.length; i++)
          PlannedStop(
            candidate: sequence[i],
            litres: outcome.stops[i].stop.litresToBuy,
            cost: outcome.stops[i].pumpCash.amount,
            arrivalLitres: outcome.stops[i].arrivalLitres,
          ),
      ],
      fuelCost: outcome.pumpCash?.amount ?? 0,
      chargesCost: outcome.charges?.amount ?? 0,
      detourKm: outcome.extraKm,
      roadDetourMinutes: roadMinutes,
      approximateDetourKm: approximateKm,
      routeKm: request.routeKm,
      drivingMinutes: request.drivingMinutes,
      consumptionLPer100km: request.consumptionLPer100km,
      startLitres: request.startLitres,
      consumedLitres: outcome.consumedLitres,
      endLitres: outcome.endLitres,
      currencyCode: request.currencyCode,
    );
  }
}

/// Bridge a [PlanCandidate] into the ledger's stop shape.
extension on PlanCandidate {
  ItineraryStop asSite(String currency) => ItineraryStop(
        stopId: stationId,
        alongRouteKm: alongRouteKm,
        pricePerLitre: Money(pricePerLitre, currency),
        litresToBuy: 0,
        countryCode: countryCode,
        extraKm: extraKm,
        extraMinutes: roadExtraMinutes,
        stopOverheadMinutes: kStopOverheadMinutes,
        incrementalCharge: incrementalCharge == null
            ? null
            : Money(incrementalCharge!, currency),
      );
}
