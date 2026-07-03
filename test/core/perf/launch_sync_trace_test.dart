// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/perf/launch_sync_trace.dart';
import 'package:tankstellen/core/perf/startup_timer.dart';
import 'package:tankstellen/core/sync/sync_run_trace.dart';

/// #3445 — the launch-sync span recorder: rides the existing
/// [StartupTimer] span machinery, taps the #3126 [SyncRunTrace] per-table
/// counts, and costs a single null check when disarmed.
void main() {
  setUp(() {
    StartupTimer.instance.reset();
    SyncRunTrace.tableSink = null;
  });
  tearDown(() {
    StartupTimer.instance.reset();
    SyncRunTrace.tableSink = null;
  });

  group('LaunchSyncTrace.maybeArm (#3445)', () {
    test('disabled → null, and spanned() still runs the body', () async {
      StartupTimer.instance.start();
      final trace = LaunchSyncTrace.maybeArm(enabled: false);
      expect(trace, isNull);

      var ran = false;
      await LaunchSyncTrace.spanned(trace, 'tanksync_init', () async {
        ran = true;
      });

      expect(ran, isTrue);
      expect(StartupTimer.instance.spans, isEmpty,
          reason: 'flag off → zero spans recorded');
      expect(SyncRunTrace.tableSink, isNull,
          reason: 'flag off → no counts tap installed');
    });

    test('enabled → records named spans with durations', () async {
      StartupTimer.instance.start();
      final trace = LaunchSyncTrace.maybeArm(enabled: true)!;

      await trace.span('tanksync_init', () async {});
      trace.finish();

      final names = StartupTimer.instance.spans.map((s) => s.name).toList();
      expect(names, ['tanksync_init', 'sync_phase_done']);
      for (final s in StartupTimer.instance.spans) {
        expect(s.endMs, greaterThanOrEqualTo(s.startMs));
      }
    });

    test('span records even when the body throws', () async {
      StartupTimer.instance.start();
      final trace = LaunchSyncTrace.maybeArm(enabled: true)!;

      await expectLater(
        trace.span('trips_merge', () async => throw StateError('boom')),
        throwsStateError,
      );

      expect(StartupTimer.instance.spans.map((s) => s.name),
          contains('trips_merge'));
    });
  });

  group('LaunchSyncTrace SyncRunTrace counts tap (#3445)', () {
    test('per-table counts reported during a span land in its attributes',
        () async {
      StartupTimer.instance.start();
      final trace = LaunchSyncTrace.maybeArm(enabled: true)!;

      await trace.span('vehicles', () async {
        // What EntitySync.merge reports mid-merge (#3126).
        SyncRunTrace.table('vehicles', uploaded: 2, downloaded: 5);
      });

      final span = StartupTimer.instance.spans.single;
      expect(span.attributes['table'], 'vehicles');
      expect(span.attributes['pushed'], 2);
      expect(span.attributes['pulled'], 5);
    });

    test('attributes callback overrides tapped counts on collision',
        () async {
      StartupTimer.instance.start();
      final trace = LaunchSyncTrace.maybeArm(enabled: true)!;

      await trace.span('station_ratings', () async {
        SyncRunTrace.table('station_ratings', downloaded: 1);
      }, attributes: () => {'pulled': 7});

      expect(StartupTimer.instance.spans.single.attributes['pulled'], 7);
    });

    test('counts reported OUTSIDE any span are ignored', () async {
      StartupTimer.instance.start();
      final trace = LaunchSyncTrace.maybeArm(enabled: true)!;

      SyncRunTrace.table('favorites', downloaded: 9);
      await trace.span('alerts', () async {});

      expect(StartupTimer.instance.spans.single.attributes,
          isNot(contains('table')));
    });

    test('finish() restores the previous sink and adds sync_phase_done', () {
      StartupTimer.instance.start();
      void previous(String t, int u, int d, int ts) {}
      SyncRunTrace.tableSink = previous;

      final trace = LaunchSyncTrace.maybeArm(enabled: true)!;
      expect(SyncRunTrace.tableSink, isNot(equals(previous)));

      trace.finish();
      expect(SyncRunTrace.tableSink, same(previous));
      expect(StartupTimer.instance.spans.single.name, 'sync_phase_done');
    });
  });
}
