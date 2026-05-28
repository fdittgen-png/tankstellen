// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/approach_detector.dart';
import 'approach_simulator_provider.dart';
import 'approach_state_provider.dart';

part 'effective_approach_state_provider.g.dart';

/// The [ApproachState] the UI should render — simulator override
/// wins over the real detector (#2163).
///
/// Returns:
/// - the simulator's value when non-null (debug "Test approach
///   overlay" button is active), or
/// - the latest value from [approachStateProvider], or
/// - `null` when the real stream has not produced a value yet
///   (e.g. no trip recording — the real stream emits [ApproachIdle]
///   in that case, which the PiP treats as "show the default layout").
@Riverpod(keepAlive: true)
ApproachState? effectiveApproachState(Ref ref) {
  final simulated = ref.watch(approachSimulatorProvider);
  if (simulated != null) return simulated;
  return ref.watch(approachStateProvider).value;
}
