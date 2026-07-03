// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/providers/gps_sample_diagnostics_recorder.dart';

/// #3253 — the GPS-only pipeline's cadence-diagnostics recorder (#1458
/// parity with the OBD2 path's `TripSampleBuffer`).
void main() {
  final base = DateTime.utc(2026, 6, 1, 8);

  test('records one entry per fix with the injected lifecycle state', () {
    final states = ['resumed', 'paused', 'resumed'];
    var call = 0;
    final recorder =
        GpsSampleDiagnosticsRecorder(lifecycleStateName: () => states[call++]);
    for (var i = 0; i < 3; i++) {
      recorder.record(now: base.add(Duration(seconds: i)));
    }
    final snapshot = recorder.snapshot;
    expect(snapshot, hasLength(3));
    expect(snapshot.map((d) => d.lifecycleState), states);
    expect(snapshot.map((d) => d.timestamp),
        [for (var i = 0; i < 3; i++) base.add(Duration(seconds: i))]);
  });

  test('indices are monotonic and survive clear-free appends', () {
    final recorder =
        GpsSampleDiagnosticsRecorder(lifecycleStateName: () => 'resumed');
    for (var i = 0; i < 5; i++) {
      recorder.record(now: base.add(Duration(seconds: i)));
    }
    expect(recorder.snapshot.map((d) => d.index), [0, 1, 2, 3, 4]);
  });

  test('snapshot is unmodifiable (the buffer cannot be mutated)', () {
    final recorder =
        GpsSampleDiagnosticsRecorder(lifecycleStateName: () => 'resumed');
    recorder.record(now: base);
    expect(() => recorder.snapshot.clear(), throwsUnsupportedError);
  });

  test('clear resets both the buffer and the index for the next trip', () {
    final recorder =
        GpsSampleDiagnosticsRecorder(lifecycleStateName: () => 'resumed');
    recorder.record(now: base);
    recorder.record(now: base.add(const Duration(seconds: 1)));
    recorder.clear();
    expect(recorder.snapshot, isEmpty);
    recorder.record(now: base.add(const Duration(seconds: 2)));
    expect(recorder.snapshot.single.index, 0,
        reason: 'a new trip starts a fresh index sequence');
  });
}
