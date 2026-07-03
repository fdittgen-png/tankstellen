// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/perf/startup_timer.dart';

/// #3445 — spans on the startup timeline. Unlike milestones (which
/// `mark()` drops once the stopwatch stopped), spans must keep recording
/// AFTER `finish()`: the launch-sync phase runs post-first-frame.
void main() {
  setUp(StartupTimer.instance.reset);
  tearDown(StartupTimer.instance.reset);

  group('StartupTimer.addSpan (#3445)', () {
    test('records a span with attributes', () {
      final timer = StartupTimer.instance..start();

      timer.addSpan(
        'trips_merge',
        startMs: 10,
        endMs: 42,
        attributes: {'table': 'trip_summaries', 'pulled': 3},
      );

      expect(timer.spans, hasLength(1));
      final span = timer.spans.single;
      expect(span.name, 'trips_merge');
      expect(span.startMs, 10);
      expect(span.endMs, 42);
      expect(span.durationMs, 32);
      expect(span.attributes, {'table': 'trip_summaries', 'pulled': 3});
    });

    test('keeps recording AFTER finish() ran (post-first-frame phase)', () {
      final timer = StartupTimer.instance
        ..start()
        ..mark('first_frame')
        ..finish();

      // mark() is dead now — the pre-#3445 behaviour this decouples from.
      timer.mark('too_late');
      expect(timer.milestones.map((m) => m.name), isNot(contains('too_late')));

      timer.addSpan('tanksync_init', startMs: 100, endMs: 180);
      expect(timer.spans.map((s) => s.name), contains('tanksync_init'));
    });

    test('elapsedMsNow keeps advancing on the wall clock after finish()',
        () async {
      final timer = StartupTimer.instance..start();
      timer.finish();
      final frozen = timer.totalMs!;

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(timer.elapsedMsNow(), greaterThan(frozen),
          reason: 'post-finish spans must land on the same timeline, '
              'not at a frozen stopwatch reading');
    });

    test('no-op before start() — nothing to anchor the timeline to', () {
      final timer = StartupTimer.instance;
      timer.addSpan('orphan', startMs: 0, endMs: 5);
      expect(timer.spans, isEmpty);
      expect(timer.elapsedMsNow(), 0);
    });

    test('start() and reset() clear previously recorded spans', () {
      final timer = StartupTimer.instance..start();
      timer.addSpan('a', startMs: 0, endMs: 1);

      timer.start();
      expect(timer.spans, isEmpty, reason: 'start() begins a fresh trace');

      timer.addSpan('b', startMs: 0, endMs: 1);
      timer.reset();
      expect(timer.spans, isEmpty, reason: 'reset() clears everything');
    });
  });
}
