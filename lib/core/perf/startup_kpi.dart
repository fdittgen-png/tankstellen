// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The one startup number this app defends: **time to useful map** —
/// launch → the first frame on which the user can read a fuel price
/// (#4140, Epic #4132).
///
/// ## Why not `first_frame`
///
/// `StartupTimer` already marks `first_frame`, and that mark is not the
/// product. The first frame is the shell: a bottom bar, an app bar, and
/// whatever the search surface shows while it has nothing. For "I am
/// driving and want to know where to stop", the launch is over when a
/// PRICE is on screen, and every millisecond between the two is a
/// millisecond the user spends looking at furniture. The 2026-09-12
/// field export that started #4110 reported 8,891 ms to `first_frame`
/// and said nothing at all about the number the user actually felt.
///
/// ## Why it is not a milestone
///
/// [StartupTimer.mark] is a no-op once `finish()` has stopped the
/// stopwatch, and `finish()` runs AT `first_frame` — by construction
/// before any price can be on screen. So the KPI is recorded the way the
/// post-first-frame launch-sync phase records its work: against
/// [StartupTimer.elapsedMsNow], the wall-clock continuation of the same
/// timeline, and published as a [StartupSpan] so the trace waterfall
/// shows it beside the phases that produced it.
///
/// ## Why [DataValue] rather than an `int?`
///
/// A launch in which the user never sees a price — no network, empty
/// cache, a search that returned nothing — has no KPI. Not zero, and not
/// "slow": absent. Reporting `0` would read as instant and reporting the
/// last known number would read as measured, so the absence is stated
/// with its reason like every other unknown in this app (#4160).
///
/// ## The budget
///
/// [kColdStartBudget] — 2,500 ms, "cold start to usable map". It is the
/// same surface, measured on a mid-range Samsung with a cold cache after
/// #4110 moved the national datasets off the first-frame path. This
/// library does not restate the number; there is one place it lives.
library;

import 'package:flutter/widgets.dart';

import '../domain/data_value.dart';
import 'perf_budgets.dart';
import 'startup_timer.dart';

/// Records and reports the time-to-useful-map KPI.
abstract final class StartupKpi {
  /// The span name under which the KPI lands on the startup timeline.
  static const String spanName = 'time_to_useful_map';

  /// What the KPI measures, in one sentence, carried into the export so
  /// a reader of a field trace never has to come back here to find out.
  static const String definition =
      'launch to the first painted frame on which a station price is '
      'readable';

  static Duration? _reached;
  static bool _pending = false;

  /// Bumped by [reset]. A post-frame callback scheduled before a reset
  /// must not land after it — without this, one suite's pending frame
  /// records a KPI into the next test's freshly-started launch.
  static int _generation = 0;

  /// The KPI, or why it is not known.
  ///
  /// [Measured] once a price-bearing frame has painted; [Unknown] with
  /// [DataUnknownReason.notMeasuredYet] before that — including for a
  /// launch that never reaches one.
  static DataValue<Duration> get value => switch (_reached) {
        final Duration d => DataValue<Duration>.measured(d),
        null => const DataValue<Duration>.unknown(
            reason: DataUnknownReason.notMeasuredYet),
      };

  /// Whether the KPI, once known, is inside [kColdStartBudget]. Unknown
  /// while the KPI is — a launch with no price on screen has not met the
  /// budget and has not missed it either. `map` is what keeps that
  /// honest: an unknown cannot be laundered into a `false`.
  static DataValue<bool> get isWithinBudget => value.map(withinBudget);

  /// The budget predicate, separately so the boundary is testable
  /// without a clock seam. Inclusive: a launch landing exactly ON the
  /// ceiling met it — a budget is the worst acceptable number, not the
  /// first unacceptable one.
  static bool withinBudget(Duration d) =>
      d.inMilliseconds <= kColdStartBudget.limit!;

  /// Called from every surface that can be the first to put a price in
  /// front of the user. Idempotent and cheap after the first hit, so a
  /// call from a `build` that runs on every rebuild is fine.
  ///
  /// The reading is taken in a post-frame callback rather than here: the
  /// caller is building the frame, and the KPI is about the frame being
  /// ON SCREEN. That costs one frame of honesty and buys the right
  /// definition.
  static void markUsefulMap() {
    if (_reached != null || _pending) return;
    // Nothing to anchor to — a widget test, or any binding that did not
    // come up through AppInitializer. Recording against a timer that
    // never started would report a launch that never happened.
    if (!StartupTimer.instance.hasStarted) return;
    _pending = true;
    final generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (generation != _generation) return;
      _pending = false;
      if (_reached != null) return;
      final ms = StartupTimer.instance.elapsedMsNow();
      _reached = Duration(milliseconds: ms);
      StartupTimer.instance.addSpan(spanName, startMs: 0, endMs: ms);
    });
  }

  /// Forget the recorded KPI — test isolation only.
  @visibleForTesting
  static void reset() {
    _reached = null;
    _pending = false;
    _generation++;
  }

  /// The KPI as an export row, reported beside the phases and budgets.
  ///
  /// `ms` is absent rather than null when the KPI was never reached, for
  /// the reason `slowestBoxOpen` is absent rather than null-filled: a
  /// `{"ms": null}` row invites a reader to conclude something.
  static Map<String, Object?> exportRow() => {
        'name': spanName,
        'definition': definition,
        'budgetMs': kColdStartBudget.limit,
        if (value case Measured<Duration>(:final value))
          'ms': value.inMilliseconds
        else
          'unknownReason': DataUnknownReason.notMeasuredYet.name,
        if (isWithinBudget case Measured<bool>(:final value))
          'withinBudget': value,
      };
}
