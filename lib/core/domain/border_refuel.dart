// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Refuelling around a border crossing (#4361, Epic #4358, work package
/// D).
///
/// The question a driver asks approaching a border is not "which station
/// is cheapest" but "do I buy a little now so I can fill up cheaply over
/// there?". That is a comparison between whole ITINERARIES, and the
/// answer flips on things a per-station ranking cannot see: the reserve
/// on the leg to the far station, the tank's capacity, a fee incurred
/// only by one of the stops, and whether the two prices are even in
/// comparable money.
///
/// Worked example (#4361's acceptance case), 200 km at 10 L/100 km,
/// start 10 L, reserve 5 L, capacity 40 L:
///
/// | itinerary | pump cash | ends |
/// |---|---|---|
/// | 5 L at A (km 40, €2/L), 10 L at B (km 100, €1.50/L) | €25 | 5 L |
/// | 15 L at A | €30 | 5 L |
/// | B only | infeasible — A is 100 km away on 5 usable litres | — |
///
/// Add a €6 charge incurred only by stopping at B and the two-stop
/// itinerary becomes €31, so the single expensive fill wins. A charge
/// both itineraries pay — the crossing's own toll — is counted once in
/// each and changes neither the difference nor the order.
///
/// ## What this library refuses to do
///
///  * invent a rate: an unconvertible pair yields native totals and no
///    combined winner ([ItineraryBlocker.currencyNotComparable]);
///  * invent a delay: an unknown border wait is unknown, never zero, and
///    no itinerary may be called the fastest across the border on it;
///  * query a country the route does not enter, or one the driver has no
///    setup for — [BorderCountryStatus] carries that state instead of the
///    comparison quietly missing half its offers (#4257, #2741).
///
/// Pure Dart.
library;

import 'package:meta/meta.dart';

import 'data_value.dart';
import 'money.dart';
import 'refuel_itinerary.dart';
import 'refuel_ledger.dart';
import 'refuel_quantities.dart';

/// What is known about the offers on one side of a crossing.
///
/// Four different absences that a single "no stations" would collapse —
/// and each has a different next action for the driver.
enum BorderCountryStatus {
  /// A registered, configured country whose source answered.
  ready,

  /// Supported, but the driver has no profile/setup for it yet (#4257).
  setupMissing,

  /// The app has no data source for this country at all.
  unsupported,

  /// A source that lists only part of the country's stations (DK).
  partialCoverage,

  /// A configured source that failed this time — a retry, not an answer.
  providerUnavailable,
}

/// A crossing on the journey, with what is and is not known about it.
@immutable
class BorderCrossing {
  const BorderCrossing({
    required this.alongRouteKm,
    required this.fromCountry,
    required this.toCountry,
    this.charge,
    this.delayMinutes = const DataValue.unknown(
      reason: DataUnknownReason.notPublishedByProvider,
    ),
    this.destinationStatus = BorderCountryStatus.ready,
  });

  final double alongRouteKm;
  final String fromCountry;
  final String toCountry;

  /// A known toll or ferry fare for the crossing itself. Null is
  /// UNKNOWN, not free.
  final Money? charge;

  /// Queue/formalities time. Unknown by default — the app observes no
  /// border queues and must not imply it does.
  final DataValue<double> delayMinutes;

  final BorderCountryStatus destinationStatus;

  /// Whether the destination country's offers can be treated as a
  /// complete answer. False still allows a comparison — it qualifies it.
  bool get destinationEvidenceComplete =>
      destinationStatus == BorderCountryStatus.ready;

  /// True when nobody can say how long the crossing takes, so no
  /// itinerary may be presented as the guaranteed fastest across it.
  bool get delayUnknown => delayMinutes is! Measured<double> &&
      delayMinutes is! Estimated<double>;
}

/// The shape of a cross-border refuelling choice.
enum BorderStrategyKind {
  /// Drive through on the fuel already aboard.
  noStop,

  /// Buy everything before the crossing.
  beforeCrossing,

  /// Buy everything after the crossing.
  afterCrossing,

  /// A small bridge fill before, then the cheaper fill after — the
  /// answer a per-station ranking cannot produce.
  bridgeThenCheaper,
}

/// One candidate itinerary around a crossing, already evaluated.
@immutable
class BorderStrategy {
  const BorderStrategy({
    required this.kind,
    required this.stops,
    required this.outcome,
    required this.crossing,
  });

  final BorderStrategyKind kind;
  final List<ItineraryStop> stops;
  final ItineraryOutcome outcome;
  final BorderCrossing crossing;

  /// True when the itinerary actually buys fuel in the country across
  /// the border — the fact that makes the crossing part of the advice
  /// rather than scenery.
  bool get buysAcrossBorder =>
      stops.any((s) => s.alongRouteKm > crossing.alongRouteKm);

  bool get isFeasible => outcome.isFeasible;
}

/// Build and evaluate the candidate itineraries around [crossing].
///
/// [sites] are every allowed stop, in route order, with their quantities
/// still to be decided — [assignPurchaseQuantities] sets those so every
/// alternative ends at [targetEndLitres] and the totals compare (#4360
/// rule 3). The crossing's own charge and delay are SHARED by every
/// alternative, so they enter [ItineraryInput.sharedCharges] once each
/// and cannot change which alternative wins.
///
/// The enumeration is deliberately small and named: through, each single
/// site, and each before/after pair. The general search over arbitrary
/// stop sets is the planner's job (#4362); this is the shape a border
/// explanation needs, bounded so it can be shown.
List<BorderStrategy> crossBorderStrategies({
  required ItineraryInput baseline,
  required List<ItineraryStop> sites,
  required BorderCrossing crossing,
  required double targetEndLitres,
}) {
  final before = [
    for (final s in sites)
      if (s.alongRouteKm <= crossing.alongRouteKm) s,
  ];
  final after = [
    for (final s in sites)
      if (s.alongRouteKm > crossing.alongRouteKm) s,
  ];

  final sequences = <(BorderStrategyKind, List<ItineraryStop>)>[
    (BorderStrategyKind.noStop, const []),
    for (final s in before) (BorderStrategyKind.beforeCrossing, [s]),
    for (final s in after) (BorderStrategyKind.afterCrossing, [s]),
    for (final a in before)
      for (final b in after) (BorderStrategyKind.bridgeThenCheaper, [a, b]),
  ];

  final shared = <Money>[
    ...baseline.sharedCharges,
    ?crossing.charge,
  ];

  return [
    for (final (kind, sequence) in sequences)
      _evaluate(baseline, shared, kind, sequence, crossing, targetEndLitres),
  ];
}

BorderStrategy _evaluate(
  ItineraryInput baseline,
  List<Money> shared,
  BorderStrategyKind kind,
  List<ItineraryStop> sequence,
  BorderCrossing crossing,
  double targetEndLitres,
) {
  final stops = assignPurchaseQuantities(baseline, sequence,
      targetEndLitres: targetEndLitres);
  final input = ItineraryInput(
    routeKm: baseline.routeKm,
    drivingMinutes: baseline.drivingMinutes,
    consumptionLPer100km: baseline.consumptionLPer100km,
    startLitres: baseline.startLitres,
    capacityL: baseline.capacityL,
    reserveLitres: baseline.reserveLitres,
    stops: stops,
    comparisonCurrency: baseline.comparisonCurrency,
    rates: baseline.rates,
    now: baseline.now,
    sharedCharges: shared,
    limits: baseline.limits,
  );
  return BorderStrategy(
    kind: kind,
    stops: stops,
    outcome: evaluateItinerary(input),
    crossing: crossing,
  );
}
