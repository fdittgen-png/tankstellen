// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// One contextual travel estimate per selected station (#4359, Epic
/// #4358, work package A).
///
/// Before this, a station's "distance" was whatever the caller had lying
/// around: the crow-flies figure on a search result, a radar-only
/// station-id → km map with no idea which origin or direction it was
/// measured from, or a route projection onto the nearest sampled vertex
/// — none of them a drive to the correct entrance and back. A station
/// 1 km from the motorway on the map can be a 20 km loop from the
/// opposite carriageway.
///
/// This contract carries what a decision needs to trust a travel figure:
///
///  * **three quantities, never one** — to the station, the whole
///    itinerary, and the EXTRA relative to a named baseline. For a stop on
///    a 100 km / 80 min journey whose itinerary via the station is
///    112 km / 98 min, the extra is 12 km / 18 min, and 112 km is never
///    presented as the detour;
///  * **both legs, separately** — a 3 km outbound and 7 km return errand
///    is 10 km, not 6 km: one-way streets and the opposite carriageway
///    make the two legs genuinely different;
///  * **provenance and status** — road-routed or approximate, unreachable,
///    constraints the router could not honour, or a baseline inconsistent
///    with its itinerary (a negative detour is a routing mismatch to
///    revalidate, never a free saving);
///  * **its own context** — origin, destination, heading, purpose,
///    constraints and route revision — so a quote computed for one
///    journey can never be served as current for another;
///  * **stop overhead and charges separately** — a default stop overhead
///    is an estimate, not a live queue; an absent toll answer is unknown,
///    never "free".
///
/// Units are kilometres and minutes throughout; the routing adapter
/// converts from the router's metres and seconds, each from its own
/// field (a duration can never stand in for a missing distance).
///
/// Pure Dart: the router, the provider and the economics all share it.
library;

import 'package:meta/meta.dart';

/// Minutes a stop costs beyond the driving — pulling off, queueing,
/// paying, rejoining. An ESTIMATE, carried separately from road duration
/// so it can never be mistaken for a measured queue.
const double kDefaultStopOverheadMinutes = 10;

/// A negative extra below this is a routing mismatch, not rounding.
///
/// Routers snap the same coordinate slightly differently per request; a
/// few hundred metres of "negative detour" is that noise and reads as
/// zero. Beyond it the baseline and the itinerary were not computed on
/// the same terms, and the estimate is flagged for revalidation.
const double kTravelBaselineToleranceKm = 0.3;

/// How long a road estimate stays current for the SAME context.
///
/// Traffic-free routing changes slowly, but a quote is a recommendation
/// input: past this age it is re-asked rather than promoted.
const Duration kTravelEstimateMaxAge = Duration(minutes: 15);

/// Origin/destination quantum for the cache key, in degrees (≈ 250 m).
///
/// Part of the documented request budget: GPS jitter inside one cell
/// reuses the quote instead of re-asking the router on every fix, while
/// a real move to another cell is a new context.
const double kTravelPointQuantumDegrees = 0.0025;

/// Heading bucket for the cache key, in degrees.
const int kTravelHeadingBucketDegrees = 30;

/// Stations per `/table` request — the documented request budget
/// (#4359).
///
/// With a journey context that is 26 coordinates and a 676-cell matrix:
/// small enough for the free public OSRM server (the app adopts no paid
/// routing API), large enough that every station a decision can
/// realistically present — the picks plus a page of results, not just
/// the radar's top eight — is quoted in ONE request. A caller with more
/// candidates keeps the nearest by crow-flies and leaves the rest
/// approximate, stated as such.
const int kTravelQuoteMaxStations = 24;

/// A station reduced to what routing needs.
typedef TravelStop = ({String id, double lat, double lng});

/// What the driver is doing with the station.
enum TravelPurpose {
  /// A dedicated refuelling errand: origin → station → origin. The
  /// default for a nearby search.
  errandReturn,

  /// An errand the driver does not return from (explicit choice).
  errandOneWay,

  /// A stop on a journey: origin → station → destination, compared with
  /// origin → destination under the same constraints.
  stopOnJourney,
}

/// Routing exclusions a comparison must apply to BOTH sides.
enum TravelConstraint { avoidFerries, avoidTolls, avoidMotorways }

/// How far a [StationTravelEstimate] may be trusted.
enum TravelEstimateStatus {
  /// Both legs routed on roads, under the requested constraints.
  roadVerified,

  /// No road answer: a crow-flies preview, explicitly approximate. May
  /// be browsed, never ranked as fastest (it carries no duration).
  approximate,

  /// The router could not reach the station from this context.
  unreachable,

  /// The router refused a requested exclusion. The estimate is NOT
  /// silently recomputed without it — a ferry-avoiding baseline must not
  /// be compared with an itinerary that takes one.
  constraintsUnsupported,

  /// The itinerary came out shorter than its own baseline by more than
  /// [kTravelBaselineToleranceKm] — revalidate, never show as a saving.
  inconsistentBaseline,
}

@immutable
class TravelPoint {
  const TravelPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  String get _quantised =>
      '${(lat / kTravelPointQuantumDegrees).round()}:'
      '${(lng / kTravelPointQuantumDegrees).round()}';

  @override
  bool operator ==(Object other) =>
      other is TravelPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'TravelPoint($lat, $lng)';
}

/// Everything a travel quote depends on — and therefore its identity.
@immutable
class TravelContext {
  const TravelContext({
    required this.origin,
    required this.purpose,
    this.destination,
    this.headingDegrees,
    this.constraints = const {},
    this.routeRevision = 0,
  }) : assert(purpose != TravelPurpose.stopOnJourney || destination != null,
            'a stop on a journey needs the journey destination');

  final TravelPoint origin;

  /// The journey's end; required for [TravelPurpose.stopOnJourney] and
  /// ignored for errands.
  final TravelPoint? destination;

  /// Direction of travel at [origin] (0–360°), so the router starts on
  /// the carriageway the driver is actually on. Null at standstill.
  final double? headingDegrees;

  final TravelPurpose purpose;
  final Set<TravelConstraint> constraints;

  /// Bumped by the route layer whenever the journey itself is recomputed,
  /// so a quote for the previous route can never read as current.
  final int routeRevision;

  /// The request/cache key: quantised points, heading bucket, purpose,
  /// sorted constraints, route revision.
  String get cacheKey {
    final heading = headingDegrees;
    final bucket = heading == null || !heading.isFinite
        ? '-'
        : '${((heading % 360) / kTravelHeadingBucketDegrees).round() % (360 ~/ kTravelHeadingBucketDegrees)}';
    final constraintKey = (constraints.map((c) => c.name).toList()..sort())
        .join(',');
    final dest = purpose == TravelPurpose.stopOnJourney
        ? destination?._quantised ?? '-'
        : '-';
    return '${purpose.name}|${origin._quantised}|$dest|h$bucket|'
        '$constraintKey|r$routeRevision';
  }

  @override
  bool operator ==(Object other) =>
      other is TravelContext && other.cacheKey == cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;
}

/// One stretch of driving. Either figure may be absent on its own.
@immutable
class TravelLeg {
  const TravelLeg({this.distanceKm, this.durationMinutes});

  static const zero = TravelLeg(distanceKm: 0, durationMinutes: 0);

  final double? distanceKm;
  final double? durationMinutes;

  TravelLeg operator +(TravelLeg other) => TravelLeg(
        distanceKm: distanceKm == null || other.distanceKm == null
            ? null
            : distanceKm! + other.distanceKm!,
        durationMinutes:
            durationMinutes == null || other.durationMinutes == null
                ? null
                : durationMinutes! + other.durationMinutes!,
      );

  @override
  bool operator ==(Object other) =>
      other is TravelLeg &&
      other.distanceKm == distanceKm &&
      other.durationMinutes == durationMinutes;

  @override
  int get hashCode => Object.hash(distanceKm, durationMinutes);

  @override
  String toString() => 'TravelLeg(${distanceKm}km, ${durationMinutes}min)';
}

/// Tolls, ferries and other charges of the itinerary.
///
/// The free public router the app uses answers no fee questions, so the
/// default is [TravelCharges.unknown] — which is NOT zero. A known
/// amount arrives only from a source that actually priced it.
@immutable
class TravelCharges {
  const TravelCharges.unknown()
      : amount = null,
        currencyCode = null;
  const TravelCharges.known({required double this.amount,
      required String this.currencyCode});

  final double? amount;
  final String? currencyCode;

  bool get isKnown => amount != null;
}

/// The travel quote for one station in one [TravelContext].
@immutable
class StationTravelEstimate {
  const StationTravelEstimate({
    required this.stationId,
    required this.context,
    required this.status,
    required this.calculatedAt,
    this.toStation = const TravelLeg(),
    this.fromStation = const TravelLeg(),
    this.baseline = TravelLeg.zero,
    this.stopOverheadMinutes = kDefaultStopOverheadMinutes,
    this.charges = const TravelCharges.unknown(),
  });

  /// Build a road-routed estimate, deriving the status from the numbers:
  /// a missing leg is [TravelEstimateStatus.unreachable]; a negative
  /// extra beyond tolerance is [TravelEstimateStatus.inconsistentBaseline].
  factory StationTravelEstimate.routed({
    required String stationId,
    required TravelContext context,
    required TravelLeg toStation,
    required TravelLeg fromStation,
    required TravelLeg baseline,
    required DateTime calculatedAt,
  }) {
    final draft = StationTravelEstimate(
      stationId: stationId,
      context: context,
      status: TravelEstimateStatus.roadVerified,
      calculatedAt: calculatedAt,
      toStation: toStation,
      fromStation: fromStation,
      baseline: baseline,
    );
    final itineraryKm = draft.itinerary.distanceKm;
    final status = itineraryKm == null || baseline.distanceKm == null
        ? TravelEstimateStatus.unreachable
        : itineraryKm - baseline.distanceKm! < -kTravelBaselineToleranceKm
            ? TravelEstimateStatus.inconsistentBaseline
            : TravelEstimateStatus.roadVerified;
    return draft._withStatus(status);
  }

  /// Every station in a request gets the same non-road status (the
  /// router refused the constraints, or answered nothing at all).
  const StationTravelEstimate.withoutRoute({
    required this.stationId,
    required this.context,
    required this.status,
    required this.calculatedAt,
  })  : toStation = const TravelLeg(),
        fromStation = const TravelLeg(),
        baseline = TravelLeg.zero,
        stopOverheadMinutes = kDefaultStopOverheadMinutes,
        charges = const TravelCharges.unknown();

  final String stationId;
  final TravelContext context;
  final TravelEstimateStatus status;
  final DateTime calculatedAt;

  /// Origin → station.
  final TravelLeg toStation;

  /// Station → origin (errand) or station → destination (journey).
  /// Unused for [TravelPurpose.errandOneWay].
  final TravelLeg fromStation;

  /// What the driver would drive anyway: nothing for an errand, origin →
  /// destination for a journey stop.
  final TravelLeg baseline;

  /// An estimate, never a live observation — kept out of [itinerary].
  final double stopOverheadMinutes;

  final TravelCharges charges;

  /// The whole drive this choice implies.
  TravelLeg get itinerary => context.purpose == TravelPurpose.errandOneWay
      ? toStation
      : toStation + fromStation;

  /// Kilometres this station adds over [baseline]. Null when unknown.
  double? get extraKm {
    final a = itinerary.distanceKm, b = baseline.distanceKm;
    return a == null || b == null ? null : a - b;
  }

  /// Driving minutes this station adds over [baseline], stop overhead
  /// excluded. Null when either duration is unknown — a station with an
  /// unknown duration is never "fastest".
  double? get extraDrivingMinutes {
    final a = itinerary.durationMinutes, b = baseline.durationMinutes;
    return a == null || b == null ? null : a - b;
  }

  /// Whether a decision may act on this quote.
  bool get isActionable => status == TravelEstimateStatus.roadVerified;

  /// Current for [other] at [now]: the same context, and young enough.
  bool isCurrentFor(TravelContext other, DateTime now) =>
      other.cacheKey == context.cacheKey &&
      !now.isBefore(calculatedAt) &&
      now.difference(calculatedAt) <= kTravelEstimateMaxAge;

  StationTravelEstimate _withStatus(TravelEstimateStatus next) =>
      StationTravelEstimate(
        stationId: stationId,
        context: context,
        status: next,
        calculatedAt: calculatedAt,
        toStation: toStation,
        fromStation: fromStation,
        baseline: baseline,
        stopOverheadMinutes: stopOverheadMinutes,
        charges: charges,
      );
}
