// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'fuel_context.dart';
import 'tank_blend_engine.dart';
import 'tank_blend_event.dart';
import 'tank_blend_snapshot.dart';

/// The tank blend as a function of time, for attributing evidence to the
/// blend that was actually burning (#4276).
///
/// "Replay the event log up to the trip's time" is exactly what this
/// answers — but the log is folded ONCE, in the engine's canonical order,
/// and each query is a binary search over the recorded steps. A query at a
/// time `t` sees every event strictly before `t`: the tank as a drive
/// starting at `t` found it. Consumption never changes the shares, so
/// where a trip's own consumption event lands does not move its context.
final class BlendTimeline {
  BlendTimeline._(this._initial, this._steps);

  /// Folds [events] with [engine] (canonical order, duplicates collapsed —
  /// see [TankBlendEngine.canonicalLog]).
  factory BlendTimeline.fold(
      TankBlendEngine engine, Iterable<TankBlendEvent> events) {
    final initial = engine.initial();
    var state = initial;
    final steps = <_Step>[];
    for (final event in TankBlendEngine.canonicalLog(events)) {
      state = engine.apply(state, event);
      steps.add(_Step(event, state));
    }
    return BlendTimeline._(initial, List.unmodifiable(steps));
  }

  final TankBlendSnapshot _initial;
  final List<_Step> _steps;

  /// The blend after every event strictly before [at].
  TankBlendSnapshot snapshotBefore(DateTime at) {
    final i = _countBefore(at);
    return i == 0 ? _initial : _steps[i - 1].after;
  }

  /// The context a drive starting at [at] burned.
  FuelContext contextAt(DateTime at) =>
      FuelContext.classify(snapshotBefore(at));

  /// The context a fill window burned: the tank right after its opening
  /// fill (every event at or before [openedAt]), then after every fill
  /// strictly inside the window, combined with [FuelContext.combine]. The
  /// closing fill is excluded — its fuel is burned in the NEXT window
  /// (ADR 0015 v3).
  FuelContext contextOverWindow(DateTime openedAt, DateTime closedAt) {
    final atOpen = _countBefore(openedAt.add(const Duration(microseconds: 1)));
    final contexts = <FuelContext>[
      FuelContext.classify(atOpen == 0 ? _initial : _steps[atOpen - 1].after),
    ];
    for (var i = atOpen; i < _steps.length; i++) {
      final step = _steps[i];
      if (!step.event.at.isBefore(closedAt)) break;
      if (step.event is TankFillEvent) {
        contexts.add(FuelContext.classify(step.after));
      }
    }
    return FuelContext.combine(contexts);
  }

  int _countBefore(DateTime at) {
    var lo = 0, hi = _steps.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_steps[mid].event.at.isBefore(at)) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

final class _Step {
  const _Step(this.event, this.after);
  final TankBlendEvent event;
  final TankBlendSnapshot after;
}
