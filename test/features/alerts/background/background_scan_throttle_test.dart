// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4162 — THROTTLE: the OS spaces scans out, or crowds them together.
///
/// Doze and the app-standby buckets turn a 12 h cadence into gaps of a day
/// or more; a widget refresh lands seconds after the periodic wake; the
/// lock is contended. None of that may lose the journal's account of what
/// ran, and none of it may make the budget forget what it sent.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/background/background_scan_trigger.dart';
import 'package:tankstellen/core/background/scan_run_phase.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/data/opportunity_feed_store.dart';

import '../../../helpers/silence_error_logger.dart';
import 'support/delivery_trace.dart';
import 'support/scan_disk_image.dart';
import 'support/scan_phase_trace.dart';
import 'support/scan_session_driver.dart';

void main() {
  silenceErrorLoggerSpool();

  late ScanDisk disk;
  late DeliveryTrace notifier;

  setUp(() async {
    disk = await ScanDisk.open();
    notifier = DeliveryTrace();
  });
  tearDown(() async => disk.close());

  Future<(bool, ScanPhaseTrace)> scanAt(
    DateTime at, {
    String station = 'de-aral-1',
    BackgroundScanTrigger trigger = BackgroundScanTrigger.workManagerPeriodic,
  }) async {
    final trace = ScanPhaseTrace();
    final ran = await disk
        .coordinator(
          body: (_, t) => ScriptedScanBody(t,
              candidates: [scanOpportunity(at: t, stationId: station)]),
          notifier: notifier,
          sink: trace,
        )
        .scan(trigger: trigger, now: at);
    trace.expectLawful();
    return (ran, trace);
  }

  test('a burst inside the cooldown is skipped with a journal row, and '
      'posts nothing', () async {
    await scanAt(kScanT0);
    final (ran, trace) = await scanAt(
      kScanT0.add(const Duration(seconds: 40)),
      trigger: BackgroundScanTrigger.androidWidget,
    );

    expect(ran, isFalse);
    expect(trace.outcomes.single,
        (ScanOutcome.skippedCooldown, ScanRunPhase.gated));
    expect(notifier.posts, hasLength(1));
    expect(disk.journal.last['skipped'], 'cooldown');
    expect(disk.journal.last['trigger'], 'android_widget');
  });

  test('doze gaps: the per-station quiet window survives a 6 h gap and '
      'ends by the next day', () async {
    await scanAt(kScanT0);
    await scanAt(kScanT0.add(const Duration(hours: 6)));
    expect(notifier.posts, hasLength(1),
        reason: 'same station inside BudgetPolicy.perStationQuiet (12 h)');
    expect(const OpportunityFeedStore().read(), isNotEmpty,
        reason: 'the refused finding is still recorded');

    await scanAt(kScanT0.add(const Duration(hours: 26)));
    expect(notifier.posts, hasLength(2),
        reason: 'a stand-by bucket that delays the scan by a day must not '
            'silence the alert for good');
    expect([for (final r in disk.journal) r['alertsFired']], [1, 0, 1]);
  });

  test('the daily cap spans every scan of the day', () async {
    for (var i = 0; i < 4; i++) {
      await scanAt(kScanT0.add(Duration(hours: 3 * i)), station: 'de-$i');
    }
    expect(notifier.posts, hasLength(3),
        reason: 'BudgetPolicy.maxPerDay — a day spans many isolate lives');
  });

  test('lock contention journals the skip while the alerts box is open, '
      'and is a silent no-op while it is not (pinned)', () async {
    // Hold the lock in this isolate, as a running scan would.
    final park = Park();
    final holder = disk
        .coordinator(
            body: (_, t) => ScriptedScanBody(t, park: park),
            notifier: notifier)
        .scan(trigger: BackgroundScanTrigger.workManagerPeriodic, now: kScanT0);
    await park.reached;

    var t = DateTime.utc(2026, 9, 16);
    DateTime fast() => t = t.add(const Duration(seconds: 20));
    final contended = disk.coordinator(
      body: (_, at) => ScriptedScanBody(at),
      notifier: notifier,
      lockClock: fast,
    );
    expect(
        await contended.scan(
            trigger: BackgroundScanTrigger.androidWidget, now: kScanT0),
        isFalse);
    expect(disk.journal.last['skipped'], 'hive_lock');

    // A background isolate that does not own the boxes cannot journal a
    // skip — the holder journals its own row. Pinned, not endorsed.
    await Hive.box<dynamic>(HiveBoxes.alerts).close();
    expect(
        await contended.scan(
            trigger: BackgroundScanTrigger.androidWidget, now: kScanT0),
        isFalse);
    await Hive.openBox<dynamic>(HiveBoxes.alerts);
    expect(disk.journal.where((r) => r['skipped'] == 'hive_lock'), hasLength(1));

    park.release();
    await holder;
  });

  test('a failed stage ends the run failed from that phase, journals the '
      'error type, and leaves the cooldown open', () async {
    for (final (stage, phase) in const [
      ('collect', ScanRunPhase.collecting),
      ('dispatch', ScanRunPhase.dispatching),
      ('widgets', ScanRunPhase.refreshingWidgets),
    ]) {
      final trace = ScanPhaseTrace();
      final ran = await disk
          .coordinator(
            body: (_, t) => ScriptedScanBody(t, throwIn: stage),
            notifier: notifier,
            sink: trace,
          )
          .scan(
              trigger: BackgroundScanTrigger.workManagerPeriodic, now: kScanT0);
      expect(ran, isFalse);
      expect(trace.outcomes.single, (ScanOutcome.failed, phase));
      expect(trace.path.last, ScanRunPhase.idle);
      trace.expectLawful();
      expect(disk.journal.last['error'], 'StateError');
    }
    final (ran, _) = await scanAt(kScanT0);
    expect(ran, isTrue, reason: 'no failed run stamped the cooldown');
  });

  test('an empty station set skips dispatch but still refreshes widgets '
      '(#609)', () async {
    final trace = ScanPhaseTrace();
    final body = ScriptedScanBody(kScanT0, stations: 0);
    await disk
        .coordinator(body: (_, _) => body, notifier: notifier, sink: trace)
        .scan(trigger: BackgroundScanTrigger.workManagerPeriodic, now: kScanT0);
    expect(body.stages, ['collect', 'widgets']);
    expect(trace.edges, contains(
        (ScanRunPhase.collecting, ScanRunPhase.refreshingWidgets)));
    expect(disk.journal.single['stations'], 0);
  });
}
