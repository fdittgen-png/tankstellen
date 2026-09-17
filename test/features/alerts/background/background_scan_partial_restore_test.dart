// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — PARTIAL RESTORE: some of the app's state comes back, some not.
///
/// A reboot re-runs the boot receiver with only the native side ready; an
/// Android backup restores what `data_extraction_rules.xml` does not
/// exclude; a box that fails to open leaves the gate unreadable. The
/// schedule and the scan must each land in a state the user consented to.
///
/// Device-only residue, documented rather than tested here: the backup
/// rules exclude Hive and FlutterSharedPreferences but NOT the WorkManager
/// database or the workmanager callback-handle prefs, so a restored
/// periodic task can fire with a handle from another install before the
/// first launch (#3688's leak family). No Dart test can stand that up.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/background/background_price_fetcher.dart';
import 'package:tankstellen/core/background/background_scan_trigger.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/background/alert_schedule_reconciler.dart';
import 'package:tankstellen/features/alerts/background/background_service.dart';
import 'package:tankstellen/features/alerts/background/slc_wake_monitor.dart';

import '../../../helpers/silence_error_logger.dart';
import 'support/delivery_trace.dart';
import 'support/scan_disk_image.dart';
import 'support/scan_phase_trace.dart';
import 'support/scan_session_driver.dart';

class _Fetcher implements BackgroundPriceFetcher {
  final List<String> calls = [];
  @override
  Future<void> init() async => calls.add('init');
  @override
  Future<void> cancelAll() async => calls.add('cancelAll');
  @override
  Future<void> scheduleOpportunisticScan() async => calls.add('oneOff');
}

class _Slc implements SlcWakeMonitor {
  final List<bool> calls = [];
  @override
  Future<void> setEnabled(bool enabled) async => calls.add(enabled);
}

void main() {
  silenceErrorLoggerSpool();

  late ScanDisk disk;
  late _Fetcher fetcher;
  late _Slc slc;

  setUp(() async {
    disk = await ScanDisk.open();
    fetcher = _Fetcher();
    slc = _Slc();
  });
  tearDown(() async => disk.close());

  AlertScheduleReconciler reconciler() => AlertScheduleReconciler(
        // The production gate, reading the real boxes.
        gate: BackgroundService.hasActiveAlerts,
        fetcher: () => fetcher,
        slc: () => slc,
        persistTemplates: () async {},
      );

  group('schedule', () {
    test('an unreadable alerts gate leaves the schedule exactly as it was',
        () async {
      await Hive.box<dynamic>(HiveBoxes.alerts).close();
      final schedule = reconciler();

      await expectLater(schedule.reconcile(), completes);

      expect(fetcher.calls, isEmpty, reason: 'neither arm nor cancel');
      expect(slc.calls, isEmpty);
      expect(schedule.phase, AlertSchedulePhase.unknown);
      expect(schedule.debugApplies.single.gate,
          ScheduleGateReading.unreadable);
    });

    test('no alerts restored: reconcile cancels and disarms', () async {
      final schedule = reconciler();
      await schedule.reconcile();
      expect(fetcher.calls, ['cancelAll']);
      expect(slc.calls, [false]);
      expect(schedule.phase, AlertSchedulePhase.cancelled);
      expect(schedule.debugViolations, isEmpty);
    });

    test('B1 — a boot re-arm with no alerts registers anyway: reproduces '
        'only the filed defect', () async {
      final schedule = reconciler();

      expect(await runBackgroundTask(BackgroundService.bootReregisterTask,
              schedule: schedule),
          isTrue);

      final violations = [for (final v in schedule.debugViolations) v.$1];
      expectOnlyKnownScheduleViolations(violations);
      expect(violations, contains(ScheduleViolation.bootRearmWithoutGate),
          reason: 'B1 still reproduces — delete the known entry with the fix');
      expect(fetcher.calls, ['init'],
          reason: 'pinned: the boot path registers the 12 h scan with no '
              'alert to consent to it');
    });
  });

  group('scan', () {
    test('a restore without the alerts box: the scan runs on empty stores '
        'and tells the user once', () async {
      final notifier = DeliveryTrace();
      await disk
          .coordinator(
            body: (_, t) =>
                ScriptedScanBody(t, candidates: [scanOpportunity(at: t)]),
            notifier: notifier,
          )
          .scan(
              trigger: BackgroundScanTrigger.workManagerPeriodic, now: kScanT0);

      // The next device: Hive excluded from the backup.
      await disk.restore(disk.capture().without(HiveBoxes.alerts));
      await disk
          .coordinator(
            body: (_, t) =>
                ScriptedScanBody(t, candidates: [scanOpportunity(at: t)]),
            notifier: notifier,
          )
          .scan(
              trigger: BackgroundScanTrigger.workManagerPeriodic,
              now: kScanT0.add(const Duration(minutes: 1)));

      expect(notifier.posts, hasLength(2),
          reason: 'pinned: a restored install has no budget memory, so the '
              'first scan on it may repeat a notification the old device '
              'already showed');
      expect(disk.journal, hasLength(1),
          reason: 'the journal restarts with the box');
    });
  });
}
