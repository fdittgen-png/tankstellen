// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The fleet company's own constraints on where an employee may refuel
/// (#4214, Epic #4211), applied as a **pure pre-filter** in front of the
/// existing refuel economics.
///
/// ## Why a pre-filter and not another input to the calculator
///
/// `RefuelEconomics.decide` answers three economic questions and #4139
/// owns the product decision about which of them may lead. A fleet
/// policy answers a different kind of question — *may this employee buy
/// here at all* — and folding it into the calculator would put a
/// company rule inside an arithmetic that the personal app shares. It
/// would also make the ranking depend on who is asking, which is exactly
/// the failure mode #4214 names: "policy restriction excludes
/// incompatible stations **without corrupting the general station
/// ranking**".
///
/// So this layer only ever *removes* candidates, never rewrites one and
/// never reorders the survivors. `decide` is then called unchanged on
/// [FleetPolicyOutcome.eligible], which makes the property testable and
/// tested: the filtered ranking equals the unfiltered ranking restricted
/// to the eligible subset.
///
/// ## What "detour" means here
///
/// With a road-verified [StationTravelEstimate] (#4359) the detour is
/// that contract's own `extraKm` / `extraDrivingMinutes` — the extra
/// over a named baseline, both legs, from the driver's own origin.
/// Without one there is no routed answer, so the cap falls back to the
/// crow-flies distance corrected by [kCrowFliesRoadFactor] and the
/// exclusion is marked [PolicyExclusion.approximate]. That fallback is a
/// **lower bound** on a return errand (it counts one leg), so it errs
/// toward keeping a station the policy cannot prove non-compliant — the
/// right direction for a rule that costs an employee a fuel card.
///
/// A minutes cap has no such fallback: a duration cannot be invented
/// from a distance without assuming a speed, and trust rule 1 of
/// `docs/specs/refuel-economics.md` forbids defaulting a missing input.
/// An unevaluable minutes cap therefore excludes nothing.
///
/// Pure Dart over primitives, like the economics it guards: the brand of
/// a station lives in a feature, so it arrives as an injected
/// [FleetPolicyBrandLookup] rather than an import (core → feature is
/// pinned at zero, #3129).
library;

import 'package:meta/meta.dart';

import '../refuel_economics.dart';

/// Why a candidate was removed before the economics ran (#4214).
///
/// Each reason is a company rule the employee can be told about; none of
/// them is an opinion about the station's economics.
enum PolicyExclusionReason {
  /// The vehicle's fuel is not on the policy's approved list. Produced by
  /// the vehicle comparison, which is where a fuel key exists — a station
  /// row carries the price of the *selected* fuel, not a fuel of its own.
  fuelNotApproved,

  /// The station's brand is not among [FleetRefuelPolicy.allowedNetworks].
  networkNotAllowed,

  /// The policy restricts networks and nothing could say which brand this
  /// station is. Stated rather than guessed either way: silently allowing
  /// it sends the employee to a forecourt the card may refuse, and
  /// silently dropping it hides a station for a reason nobody can read.
  networkUnknown,

  /// The brand is allowed but does not take the fleet's fuel card.
  fuelCardNotAccepted,

  /// The detour exceeds [FleetRefuelPolicy.maxDetourKm].
  detourTooLong,

  /// The detour exceeds [FleetRefuelPolicy.maxDetourMinutes].
  detourTooSlow,
}

/// One removal, with the number that caused it.
///
/// [observed] and [limit] are in the unit of [reason] — kilometres for
/// [PolicyExclusionReason.detourTooLong], minutes for
/// [PolicyExclusionReason.detourTooSlow] — and are null for the network
/// reasons, which are not about a quantity.
@immutable
final class PolicyExclusion {
  const PolicyExclusion({
    required this.reason,
    this.approximate = false,
    this.observed,
    this.limit,
  });

  final PolicyExclusionReason reason;

  /// True when the figure the cap was judged on was not road-verified —
  /// a crow-flies distance corrected by [kCrowFliesRoadFactor]. The UI
  /// qualifies such an exclusion; a fleet manager reviewing it is
  /// looking at an approximation, not a routed drive.
  final bool approximate;

  /// What was measured (km or minutes), or null for a network reason.
  final double? observed;

  /// The policy cap it was judged against.
  final double? limit;

  @override
  bool operator ==(Object other) =>
      other is PolicyExclusion &&
      other.reason == reason &&
      other.approximate == approximate &&
      other.observed == observed &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(reason, approximate, observed, limit);

  @override
  String toString() => 'PolicyExclusion(${reason.name}, '
      'approximate=$approximate, $observed/$limit)';
}

/// The station's brand, or null when it is not known.
///
/// Injected because brand resolution lives in a feature and core may not
/// import one. The string is matched case- and whitespace-insensitively
/// against the policy's network sets.
typedef FleetPolicyBrandLookup = String? Function(String stationId);

/// What the pre-filter produced: the candidates the economics may see,
/// in input order, and why each of the others was removed (keyed by
/// station id).
typedef FleetPolicyOutcome = ({
  List<RefuelCandidate> eligible,
  Map<String, PolicyExclusion> excluded,
});

/// The company's refuelling rules, as data (#4214).
///
/// Every set is empty by default, and an empty set means **no
/// restriction of that kind** — a policy nobody has configured must not
/// silently forbid everything. Both caps are nullable for the same
/// reason: absent is "not capped", never zero.
@immutable
final class FleetRefuelPolicy {
  const FleetRefuelPolicy({
    this.allowedNetworks = const {},
    this.fuelCardNetworks = const {},
    this.maxDetourKm,
    this.maxDetourMinutes,
    this.approvedFuelKeys = const {},
  });

  /// Brands the employee may buy from at all. Empty: any brand.
  final Set<String> allowedNetworks;

  /// Brands that accept the fleet's fuel card. Empty: the card is not a
  /// constraint (cash or a universal card).
  final Set<String> fuelCardNetworks;

  /// Maximum extra kilometres a refuelling stop may cost. Null: uncapped.
  final double? maxDetourKm;

  /// Maximum extra driving minutes a stop may cost. Null: uncapped.
  final double? maxDetourMinutes;

  /// Fuel keys (`FuelType.apiValue`) the fleet approves. Empty: any fuel.
  final Set<String> approvedFuelKeys;

  /// Whether any network rule applies at all.
  bool get restrictsNetworks =>
      allowedNetworks.isNotEmpty || fuelCardNetworks.isNotEmpty;

  /// Whether [fuelKey] is approved. A null key under a configured list is
  /// **not** approved: an unidentified fuel cannot be shown to be one of
  /// the approved ones.
  bool permitsFuel(String? fuelKey) {
    if (approvedFuelKeys.isEmpty) return true;
    if (fuelKey == null) return false;
    return _contains(approvedFuelKeys, fuelKey);
  }

  /// Trim + lowercase, so `'  Shell '` and `'SHELL'` are one network.
  static String normalizeKey(String raw) => raw.trim().toLowerCase();

  static bool _contains(Set<String> set, String raw) {
    final key = normalizeKey(raw);
    for (final entry in set) {
      if (normalizeKey(entry) == key) return true;
    }
    return false;
  }
}

/// Split [candidates] into the ones [policy] allows and the ones it does
/// not, **without touching either the candidates or their order**.
///
/// The survivors are the same objects in the same sequence, so
/// `RefuelEconomics.decide(outcome.eligible, profile)` produces exactly
/// the costs and picks the unfiltered call would have produced for that
/// subset.
///
/// Reasons are evaluated in a fixed order — network, then card, then the
/// distance cap, then the time cap — so the reason an employee is shown
/// for a given station never depends on iteration luck. A station id that
/// appears twice keeps the last exclusion, as a map does.
FleetPolicyOutcome applyFleetPolicy(
  Iterable<RefuelCandidate> candidates,
  FleetRefuelPolicy policy, {
  FleetPolicyBrandLookup? brandOf,
}) {
  final eligible = <RefuelCandidate>[];
  final excluded = <String, PolicyExclusion>{};
  for (final candidate in candidates) {
    final exclusion = _exclusionFor(candidate, policy, brandOf);
    if (exclusion == null) {
      eligible.add(candidate);
    } else {
      excluded[candidate.stationId] = exclusion;
    }
  }
  return (eligible: eligible, excluded: excluded);
}

PolicyExclusion? _exclusionFor(
  RefuelCandidate candidate,
  FleetRefuelPolicy policy,
  FleetPolicyBrandLookup? brandOf,
) {
  if (policy.restrictsNetworks) {
    final brand = brandOf?.call(candidate.stationId);
    if (brand == null || brand.trim().isEmpty) {
      return const PolicyExclusion(
          reason: PolicyExclusionReason.networkUnknown);
    }
    if (policy.allowedNetworks.isNotEmpty &&
        !FleetRefuelPolicy._contains(policy.allowedNetworks, brand)) {
      return const PolicyExclusion(
          reason: PolicyExclusionReason.networkNotAllowed);
    }
    if (policy.fuelCardNetworks.isNotEmpty &&
        !FleetRefuelPolicy._contains(policy.fuelCardNetworks, brand)) {
      return const PolicyExclusion(
          reason: PolicyExclusionReason.fuelCardNotAccepted);
    }
  }

  final maxKm = policy.maxDetourKm;
  if (maxKm != null) {
    final (km, approximate) = detourKmOf(candidate);
    if (km != null && km > maxKm) {
      return PolicyExclusion(
        reason: PolicyExclusionReason.detourTooLong,
        approximate: approximate,
        observed: km,
        limit: maxKm,
      );
    }
  }

  final maxMinutes = policy.maxDetourMinutes;
  if (maxMinutes != null) {
    final minutes = detourMinutesOf(candidate);
    if (minutes != null && minutes > maxMinutes) {
      return PolicyExclusion(
        reason: PolicyExclusionReason.detourTooSlow,
        observed: minutes,
        limit: maxMinutes,
      );
    }
  }

  return null;
}

/// The kilometres a stop at [candidate] adds, and whether that figure is
/// approximate.
///
/// Road-verified when the candidate carries an actionable
/// `StationTravelEstimate` with a known `extraKm`; otherwise the
/// one-way distance corrected by [kCrowFliesRoadFactor] (omitted when the
/// caller already supplied a road distance), flagged approximate.
///
/// The actionability test is the one `RefuelEconomics.travelKm` uses, so
/// the policy and the economics can never disagree about which travel
/// figure is real.
(double?, bool) detourKmOf(RefuelCandidate candidate) {
  final road = candidate.roadTravel;
  if (road != null && road.isActionable) {
    final extra = road.extraKm;
    if (extra != null) return (extra, false);
  }
  return (
    candidate.oneWayKm * (candidate.isRoadDistance ? 1 : kCrowFliesRoadFactor),
    true,
  );
}

/// The driving minutes a stop at [candidate] adds, or null when no road
/// estimate can say. Stop overhead is deliberately excluded: it is the
/// travel contract's own estimate, not a measured queue.
double? detourMinutesOf(RefuelCandidate candidate) {
  final road = candidate.roadTravel;
  if (road == null || !road.isActionable) return null;
  return road.extraDrivingMinutes;
}
