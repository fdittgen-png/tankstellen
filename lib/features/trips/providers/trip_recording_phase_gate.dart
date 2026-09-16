// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:collection';

import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import 'trip_recording_phase.dart';
import 'trip_recording_state.dart';

/// One phase change [TripRecordingPhaseGate] saw that
/// [kTripRecordingTransitions] does not allow (#4162).
typedef TripPhaseViolation = ({
  TripRecordingPhase from,
  TripRecordingPhase to,
  String cause,
});

/// The single door every recording-state publication walks through
/// (#4162).
///
/// Before this, the recording phase was written from five files and
/// more than twenty sites — the notifier's lifecycle, persistence and
/// snapshot parts, and both pipelines through the host's state setter —
/// and none of them looked at the phase it was leaving. So nothing could
/// say which changes happened, let alone refuse one: a stop that flickers
/// back to `recording` mid-save was indistinguishable from a resume.
///
/// The gate compares each write against [kTripRecordingTransitions].
///
/// * **Observed** — every change the table does not allow is recorded in
///   [debugViolations] (bounded) and left as a breadcrumb, so the next
///   exported error log shows which edge happened and which writer
///   caused it.
/// * **Enforced** — only for the source phases in [enforcedFrom]. An
///   illegal change out of one of those is refused: [admit] returns the
///   current state unchanged.
///
/// Observe-first is deliberate: enforcing an edge nobody has watched
/// happen in the field would turn an unnoticed flicker into a stuck
/// recording, which is worse. An edge is enforced once its writer is
/// fixed and a test pins it.
///
/// Never throws: it is on the path of every state write, and a recording
/// that cannot publish its state is a recording lost.
class TripRecordingPhaseGate {
  TripRecordingPhaseGate({this.enforcedFrom = const {}});

  /// Source phases whose illegal changes are refused, not just observed.
  final Set<TripRecordingPhase> enforcedFrom;

  /// How many violations [debugViolations] keeps (newest win).
  static const int maxViolations = 16;

  final Queue<TripPhaseViolation> _violations = Queue<TripPhaseViolation>();

  /// The most recent illegal changes, oldest first.
  List<TripPhaseViolation> get debugViolations =>
      List<TripPhaseViolation>.unmodifiable(_violations);

  /// The state to publish when [current] is replaced by [next] on behalf
  /// of [cause] — [next] itself, unless the change is illegal AND leaves
  /// an enforced phase, in which case [current].
  TripRecordingState admit(
    TripRecordingState current,
    TripRecordingState next,
    String cause,
  ) {
    final from = current.phase;
    final to = next.phase;
    if (isTripRecordingTransition(from, to)) return next;
    _record((from: from, to: to, cause: cause));
    return enforcedFrom.contains(from) ? current : next;
  }

  void _record(TripPhaseViolation violation) {
    _violations.addLast(violation);
    while (_violations.length > maxViolations) {
      _violations.removeFirst();
    }
    try {
      BreadcrumbCollector.add(
        'trip phase: illegal ${violation.from.name}→${violation.to.name}',
        detail: violation.cause,
      );
    } catch (e, st) {
      // The breadcrumb is a courtesy to the next export; the violation is
      // already in the ring above, and the publication must go on.
      log.warn('TripRecordingPhaseGate: breadcrumb failed',
          error: e, stack: st, layer: ErrorLayer.providers);
    }
  }
}
