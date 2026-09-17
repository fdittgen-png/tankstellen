// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'next_fill_candidates.dart';
import 'next_fill_decision.dart';
import 'next_fill_request.dart';
import 'tank_blend_engine.dart';
import 'tank_blend_event.dart';
import 'tank_blend_snapshot.dart';

/// Multi-fill convergence toward a [TargetBlend] (#4277).
///
/// The plan assumes a steady refill rhythm: each fill buys [litres] of the
/// target grade, and exactly that much is burned before the next one, so
/// every fill fits. The #4275 engine folds those hypothetical events, which
/// keeps the guaranteed-minimum semantics: an uncertain residual volume
/// slows convergence instead of being assumed away. Without a capacity the
/// residual is unbounded and no minimum share can ever rise — the plan
/// says so rather than extrapolating.
abstract final class NextFillConvergence {
  static ConvergencePlan plan({
    required TankBlendSnapshot tank,
    required TankBlendEngine engine,
    required TargetBlend target,
    required double litres,
    required bool approved,
    required double tolerance,
    required int maxFills,
  }) {
    ConvergencePlan notComputable(DecisionReason why) => ConvergencePlan(
        target: target,
        tolerance: tolerance,
        status: ConvergenceStatus.notComputable,
        minimumShareAfterFill: const [],
        reason: why);
    if (!approved) return notComputable(DecisionReason.gradeNotApproved);
    final goal = target.minimumShare - tolerance;
    if (tank.minimumShare(target.grade) >= goal) {
      return ConvergencePlan(
          target: target,
          tolerance: tolerance,
          status: ConvergenceStatus.alreadyAtTarget,
          minimumShareAfterFill: const [],
          fillsNeeded: 0);
    }
    if (tank.tankCapacityLitres == null) {
      return notComputable(DecisionReason.capacityUnknown);
    }
    var state = tank;
    final shares = <double>[];
    for (var k = 1; k <= maxFills; k++) {
      final at = kHypotheticalFillInstant.add(Duration(microseconds: k));
      if (k > 1) {
        state = engine.apply(
            state,
            TankConsumptionEvent.exact(
                id: 'plan-burn:$k', at: at, litres: litres));
      }
      state = engine.apply(
          state,
          TankFillEvent(
              id: 'plan-fill:$k',
              at: at,
              grade: target.grade,
              litres: litres));
      final share = state.minimumShare(target.grade);
      shares.add(share);
      if (share >= goal) {
        return ConvergencePlan(
            target: target,
            tolerance: tolerance,
            status: ConvergenceStatus.reachable,
            minimumShareAfterFill: shares,
            fillsNeeded: k);
      }
    }
    return ConvergencePlan(
        target: target,
        tolerance: tolerance,
        status: ConvergenceStatus.unreachableWithinHorizon,
        minimumShareAfterFill: shares);
  }
}
