// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_phase.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_phase_gate.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_state.dart';

import '../../../helpers/silence_error_logger.dart';

/// #4162 — the one door every recording-state write walks through.
void main() {
  silenceErrorLoggerSpool();

  setUp(BreadcrumbCollector.clear);
  tearDown(() => BreadcrumbCollector.onAdd = null);

  TripRecordingState s(TripRecordingPhase p) => TripRecordingState(phase: p);

  test('a documented transition passes through untouched and unrecorded',
      () {
    final gate = TripRecordingPhaseGate();
    final next = s(TripRecordingPhase.saving);
    expect(gate.admit(s(TripRecordingPhase.recording), next, 'stop'),
        same(next));
    expect(gate.debugViolations, isEmpty);
    expect(BreadcrumbCollector.snapshot(), isEmpty);
  });

  test('observe mode: an illegal change is published AND recorded, with '
      'its cause', () {
    final gate = TripRecordingPhaseGate();
    final next = s(TripRecordingPhase.recording);
    expect(gate.admit(s(TripRecordingPhase.saving), next, 'pipeline'),
        same(next));
    expect(gate.debugViolations.single,
        (from: TripRecordingPhase.saving, to: TripRecordingPhase.recording,
            cause: 'pipeline'));
    final crumb = BreadcrumbCollector.snapshot().single;
    expect(crumb.action, 'trip phase: illegal saving→recording');
    expect(crumb.detail, 'pipeline');
  });

  test('enforced source phase: an illegal change is refused', () {
    final gate =
        TripRecordingPhaseGate(enforcedFrom: {TripRecordingPhase.saving});
    final current = s(TripRecordingPhase.saving);
    expect(gate.admit(current, s(TripRecordingPhase.recording), 'late tick'),
        same(current));
    expect(gate.debugViolations, hasLength(1));
    // A legal change out of the enforced phase still passes.
    final done = s(TripRecordingPhase.finished);
    expect(gate.admit(current, done, 'saved'), same(done));
  });

  test('the violation ring is bounded, newest kept', () {
    final gate = TripRecordingPhaseGate();
    for (var i = 0; i < TripRecordingPhaseGate.maxViolations + 5; i++) {
      gate.admit(s(TripRecordingPhase.saving), s(TripRecordingPhase.paused),
          'tick $i');
    }
    expect(gate.debugViolations, hasLength(TripRecordingPhaseGate.maxViolations));
    expect(gate.debugViolations.last.cause,
        'tick ${TripRecordingPhaseGate.maxViolations + 4}');
  });

  test('never throws — not even when the breadcrumb sink does', () {
    BreadcrumbCollector.onAdd = () => throw StateError('persistence down');
    final gate = TripRecordingPhaseGate();
    for (final from in TripRecordingPhase.values) {
      for (final to in TripRecordingPhase.values) {
        expect(() => gate.admit(s(from), s(to), 'every pair'), returnsNormally,
            reason: '${from.name}→${to.name}');
      }
    }
  });
}
