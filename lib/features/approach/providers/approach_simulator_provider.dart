// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/approach_detector.dart';
import '../../search/domain/entities/station.dart';

part 'approach_simulator_provider.g.dart';

/// In-app simulator that injects a synthetic [ApproachState] (#2163).
///
/// Exists so the maintainer can verify the PiP price-layout flip on a
/// desk, without driving to a station. The debug button on the
/// trip-recording screen drives this notifier; the real-data
/// [approachStateProvider] is unaffected.
///
/// Flow:
/// 1. `simulate(station)` → emits [ApproachInRadius] for `duration`.
/// 2. After `duration` → emits [ApproachLeaving] for
///    [ApproachDetector.exitGrace] (matches the real detector).
/// 3. After grace → clears (`null`).
///
/// `clear()` aborts at any phase and returns to `null` immediately.
@Riverpod(keepAlive: true)
class ApproachSimulator extends _$ApproachSimulator {
  Timer? _phaseTimer;
  bool _disposed = false;

  @override
  ApproachState? build() {
    ref.onDispose(() {
      _disposed = true;
      _phaseTimer?.cancel();
      _phaseTimer = null;
    });
    return null;
  }

  /// Default duration the [ApproachInRadius] phase stays on screen
  /// before the simulator transitions to [ApproachLeaving]. 30 s is
  /// long enough to read the price layout, short enough not to leave
  /// the override stuck after a forgotten test.
  static const Duration defaultDuration = Duration(seconds: 30);

  /// Push a synthetic in-radius state for [station] for [duration],
  /// then auto-advance through `Leaving` → null. Replaces any prior
  /// simulation.
  void simulate(Station station, {Duration duration = defaultDuration}) {
    _phaseTimer?.cancel();
    state = ApproachInRadius(station: station, distanceMeters: 250);
    _phaseTimer = Timer(duration, () {
      if (_disposed) return;
      state = ApproachLeaving(lastStation: station);
      _phaseTimer = Timer(ApproachDetector.exitGrace, () {
        if (_disposed) return;
        state = null;
        _phaseTimer = null;
      });
    });
  }

  /// Abort any in-flight simulation and clear the override.
  void clear() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    state = null;
  }
}
