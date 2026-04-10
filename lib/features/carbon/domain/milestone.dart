import '../../consumption/domain/entities/fill_up.dart';
import 'monthly_summary.dart';

/// A gamification milestone that can be unlocked by the user.
///
/// Milestones are pure data — they have no I/O and are cheap to
/// re-compute on every rebuild. Unlocking is derived from the current
/// fill-up list, not persisted separately, so there is no drift risk
/// between "persisted unlocked flag" and "current reality".
class Milestone {
  /// Stable identifier, safe to persist and key widgets on.
  final String id;
  final MilestoneCategory category;
  final double target;
  final String unit;

  const Milestone({
    required this.id,
    required this.category,
    required this.target,
    required this.unit,
  });
}

enum MilestoneCategory {
  firstFillUp,
  fillUpsLogged,
  litersTracked,
  co2Tracked,
  distanceDriven,
  co2SavedVsAvg,
}

/// Progress towards a specific milestone.
class MilestoneProgress {
  final Milestone milestone;
  final double current;
  final bool unlocked;

  const MilestoneProgress({
    required this.milestone,
    required this.current,
    required this.unlocked,
  });

  /// Fraction in [0.0, 1.0]. 0 when target is zero.
  double get fraction {
    if (milestone.target <= 0) return 0;
    final raw = current / milestone.target;
    if (raw.isNaN || raw.isInfinite) return 0;
    if (raw < 0) return 0;
    if (raw > 1) return 1;
    return raw;
  }
}

/// Engine for milestone unlocking.
class MilestoneEngine {
  MilestoneEngine._();

  /// Assumed average CO2 per km for a modern EV (kg/km), grid-average
  /// EU electricity mix. Used for "fuel vs EV" comparison.
  static const double kgCo2PerKmEv = 0.05;

  /// Canonical milestone catalog. Ordered for display.
  static const List<Milestone> catalog = [
    Milestone(
      id: 'first_fill_up',
      category: MilestoneCategory.firstFillUp,
      target: 1,
      unit: 'fillup',
    ),
    Milestone(
      id: 'ten_fill_ups',
      category: MilestoneCategory.fillUpsLogged,
      target: 10,
      unit: 'fillup',
    ),
    Milestone(
      id: 'fifty_fill_ups',
      category: MilestoneCategory.fillUpsLogged,
      target: 50,
      unit: 'fillup',
    ),
    Milestone(
      id: 'hundred_liters',
      category: MilestoneCategory.litersTracked,
      target: 100,
      unit: 'L',
    ),
    Milestone(
      id: 'thousand_liters',
      category: MilestoneCategory.litersTracked,
      target: 1000,
      unit: 'L',
    ),
    Milestone(
      id: 'hundred_kg_co2',
      category: MilestoneCategory.co2Tracked,
      target: 100,
      unit: 'kg',
    ),
    Milestone(
      id: 'one_tonne_co2',
      category: MilestoneCategory.co2Tracked,
      target: 1000,
      unit: 'kg',
    ),
    Milestone(
      id: 'thousand_km',
      category: MilestoneCategory.distanceDriven,
      target: 1000,
      unit: 'km',
    ),
    Milestone(
      id: 'ten_thousand_km',
      category: MilestoneCategory.distanceDriven,
      target: 10000,
      unit: 'km',
    ),
  ];

  /// Computes the distance driven across [fillUps] from odometer
  /// deltas. Returns 0 when fewer than two readings or when all
  /// odometer values are non-positive.
  static double distanceFromOdometer(List<FillUp> fillUps) {
    final valid = fillUps
        .where((f) => f.odometerKm > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (valid.length < 2) return 0;
    final first = valid.first.odometerKm;
    final last = valid.last.odometerKm;
    final delta = last - first;
    return delta > 0 ? delta : 0;
  }

  /// Evaluates [catalog] against the provided fill-up data and returns
  /// a progress entry for each milestone.
  static List<MilestoneProgress> evaluate(List<FillUp> fillUps) {
    final summaries = MonthlyAggregator.byMonth(fillUps);
    final totalLiters = MonthlyAggregator.totalLiters(summaries);
    final totalCo2 = MonthlyAggregator.totalCo2(summaries);
    final distanceKm = distanceFromOdometer(fillUps);
    final count = fillUps.length.toDouble();

    return [
      for (final m in catalog)
        MilestoneProgress(
          milestone: m,
          current: _currentFor(m, count, totalLiters, totalCo2, distanceKm),
          unlocked: _currentFor(m, count, totalLiters, totalCo2, distanceKm) >=
              m.target,
        ),
    ];
  }

  static double _currentFor(
    Milestone m,
    double count,
    double totalLiters,
    double totalCo2,
    double distanceKm,
  ) {
    switch (m.category) {
      case MilestoneCategory.firstFillUp:
      case MilestoneCategory.fillUpsLogged:
        return count;
      case MilestoneCategory.litersTracked:
        return totalLiters;
      case MilestoneCategory.co2Tracked:
        return totalCo2;
      case MilestoneCategory.distanceDriven:
        return distanceKm;
      case MilestoneCategory.co2SavedVsAvg:
        return 0;
    }
  }

  /// CO2 (kg) an EV would have emitted over the same distance,
  /// using [kgCo2PerKmEv].
  static double evEquivalentCo2(double distanceKm) {
    if (distanceKm <= 0) return 0;
    return distanceKm * kgCo2PerKmEv;
  }
}
