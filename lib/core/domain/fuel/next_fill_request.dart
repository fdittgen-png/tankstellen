// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:meta/meta.dart';

import '../refuel_economics.dart';
import 'fuel_context.dart';
import 'fuel_grade.dart';

/// What the driver wants the next fill to optimise (#4277). Each is one
/// metric (or, for [balancedCostCo2e], two reported side by side) — never
/// a weighted score (refuel-economics spec §5).
enum FillObjective {
  /// Money per kilometre at today's prices, detour included.
  lowestCostPerKm,

  /// Litres per 100 km.
  lowestConsumption,

  /// kg CO2e per km — only with a versioned factor.
  lowestCo2ePerKm,

  /// A candidate at least as good on cost AND on CO2e, and better on one.
  /// When cost and CO2e disagree the decision is a stated trade-off.
  balancedCostCo2e,

  /// Kilometres per tank — only with a known capacity.
  maxRange,
}

/// One compatible fuel on offer: its pump price and, when a station is
/// involved, the station reduced for [RefuelEconomics] so the detour
/// counts.
@immutable
final class FuelOffer {
  FuelOffer({required this.grade, required this.pricePerLitre, this.station}) {
    if (!pricePerLitre.isFinite || pricePerLitre <= 0) {
      throw ArgumentError.value(pricePerLitre, 'pricePerLitre');
    }
  }

  final FuelGrade grade;
  final double pricePerLitre;
  final RefuelCandidate? station;

  @override
  bool operator ==(Object other) =>
      other is FuelOffer &&
      other.grade == grade &&
      other.pricePerLitre == pricePerLitre &&
      other.station == station;

  @override
  int get hashCode => Object.hash(grade, pricePerLitre, station);
}

/// A blend to converge on: at least [minimumShare] of [grade].
@immutable
final class TargetBlend {
  TargetBlend({required this.grade, this.minimumShare = kPureGradeMinShare}) {
    if (!grade.isLiquid) throw ArgumentError.value(grade, 'grade');
    if (!minimumShare.isFinite || minimumShare <= 0 || minimumShare > 1) {
      throw ArgumentError.value(minimumShare, 'minimumShare');
    }
  }

  final FuelGrade grade;
  final double minimumShare;

  @override
  bool operator ==(Object other) =>
      other is TargetBlend &&
      other.grade == grade &&
      other.minimumShare == minimumShare;

  @override
  int get hashCode => Object.hash(grade, minimumShare);
}

/// Minimum relative advantage worth a recommendation: 2 %. Below it a
/// difference is real arithmetic but not a reason to change fuel — the
/// same order as the ±2 % a pump display and an odometer each carry.
const double kMinMaterialAdvantage = 0.02;

/// A target share counts as reached within this tolerance (5 points): the
/// blend engine's shares are guaranteed minimums, and chasing the last
/// few points costs more fills than it changes behaviour.
const double kTargetShareTolerance = 0.05;

/// Fills a convergence plan looks ahead. Five half-tank refills leave
/// 0.5⁵ ≈ 3 % of today's content — inside [kTargetShareTolerance] of any
/// target; a target still out of reach after that is reported unreachable
/// rather than extrapolated.
const int kMaxConvergenceFills = 5;

/// Everything the next-fill decision needs beyond the tank and the
/// profile (#4277). Value-equal, so it can key a provider family.
@immutable
final class NextFillRequest {
  NextFillRequest({
    required this.objective,
    required this.capability,
    required Iterable<FuelOffer> offers,
    this.expectedFillLitres,
    this.target,
    this.minMaterialAdvantage = kMinMaterialAdvantage,
    this.targetTolerance = kTargetShareTolerance,
    this.maxConvergenceFills = kMaxConvergenceFills,
  }) : offers = List.unmodifiable(offers) {
    final q = expectedFillLitres;
    if (q != null && (!q.isFinite || q <= 0)) {
      throw ArgumentError.value(q, 'expectedFillLitres');
    }
    if (maxConvergenceFills < 1) {
      throw ArgumentError.value(maxConvergenceFills, 'maxConvergenceFills');
    }
  }

  final FillObjective objective;

  /// What the manufacturer approves (#4274). An unknown capability
  /// approves nothing: no fuel is ever recommended on a guess, and the
  /// decision says the capability is unknown.
  final VehicleFuelCapability capability;
  final List<FuelOffer> offers;

  /// Litres the fill is expected to buy; null derives the most that is
  /// guaranteed to fit (capacity − the tank's maximum volume).
  final double? expectedFillLitres;
  final TargetBlend? target;
  final double minMaterialAdvantage;
  final double targetTolerance;
  final int maxConvergenceFills;

  @override
  bool operator ==(Object other) =>
      other is NextFillRequest &&
      other.objective == objective &&
      _sameGrades(other.capability, capability) &&
      other.capability.provenance == capability.provenance &&
      _sameList(other.offers, offers) &&
      other.expectedFillLitres == expectedFillLitres &&
      other.target == target &&
      other.minMaterialAdvantage == minMaterialAdvantage &&
      other.targetTolerance == targetTolerance &&
      other.maxConvergenceFills == maxConvergenceFills;

  @override
  int get hashCode => Object.hash(
        objective,
        Object.hashAllUnordered(capability.approvedGrades),
        capability.provenance,
        Object.hashAll(offers),
        expectedFillLitres,
        target,
        minMaterialAdvantage,
        targetTolerance,
        maxConvergenceFills,
      );
}

bool _sameGrades(VehicleFuelCapability a, VehicleFuelCapability b) =>
    a.approvedGrades.length == b.approvedGrades.length &&
    a.approvedGrades.containsAll(b.approvedGrades);

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
