// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/perf/jank_frame_recorder.dart';

/// #4546 — the bounded worst-frame ring behind the startup trace's
/// `jankFrames`. Driven with an injected clock and synthetic timings —
/// no engine frames needed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var nowMs = 0;
  JankFrameRecorder make({int capacity = 3}) => JankFrameRecorder(
        elapsedMs: () => nowMs,
        capacity: capacity,
        window: const Duration(seconds: 10),
      );

  setUp(() => nowMs = 0);

  test('is bounded and keeps the worst frames, worst first', () {
    final rec = make();
    for (final ms in [20, 900, 16, 300, 1500, 40, 700]) {
      nowMs += 100;
      rec.record(totalMs: ms, buildMs: ms - 5, rasterMs: 5);
    }
    expect(rec.frames.map((f) => f.totalMs), [1500, 900, 700]);
    final worst = rec.frames.first;
    expect(worst.buildMs, 1495);
    expect(worst.rasterMs, 5);
    expect(worst.atMs, 500, reason: 'stamped on the launch clock');
  });

  test('stops recording and unregisters once the window has elapsed', () {
    final binding = SchedulerBinding.instance;
    final rec = make()..arm(binding);
    addTearDown(rec.reset);
    expect(rec.isListening, isTrue);

    nowMs = 9000;
    rec.record(totalMs: 200, buildMs: 190, rasterMs: 10);
    expect(rec.frames, hasLength(1));

    nowMs = 10000;
    rec.record(totalMs: 5000, buildMs: 4990, rasterMs: 10);
    expect(rec.frames.map((f) => f.totalMs), [200],
        reason: 'a frame after the window is not recorded');
    expect(rec.isListening, isFalse);

    rec.arm(binding);
    expect(rec.isListening, isFalse,
        reason: 'a closed window never re-arms');
  });

  test('arm is idempotent and export rows mirror the ring', () {
    final rec = make()
      ..arm(SchedulerBinding.instance)
      ..arm(SchedulerBinding.instance);
    addTearDown(rec.reset);
    nowMs = 1234;
    rec.record(totalMs: 80, buildMs: 60, rasterMs: 20);
    expect(rec.exportRows(), [
      {'totalMs': 80, 'buildMs': 60, 'rasterMs': 20, 'atMs': 1234},
    ]);
  });
}
