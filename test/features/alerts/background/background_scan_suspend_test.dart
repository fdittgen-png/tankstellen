// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — SUSPEND: a scan stops mid-await and something else runs.
///
/// An iOS BGTask is suspended at its ~30 s expiry and may never resume; a
/// WorkManager periodic run and a widget-refresh one-off overlap under
/// different unique names; an alert mutation reconciles while the
/// post-frame startup reconcile is still awaiting its gate. Each case
/// parks one side on a completer and drives the other through.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/startup/runtime_services_phase.dart';
import 'package:tankstellen/core/background/alert_scan_journal.dart';
import 'package:tankstellen/core/background/background_price_fetcher.dart';
import 'package:tankstellen/core/background/background_scan_trigger.dart';
import 'package:tankstellen/core/background/hive_isolate_lock.dart';
import 'package:tankstellen/core/background/scan_run_phase.dart';
import 'package:tankstellen/features/alerts/background/alert_schedule_reconciler.dart';
import 'package:tankstellen/features/alerts/background/background_service.dart';
import 'package:tankstellen/features/alerts/background/slc_wake_monitor.dart';

import '../../../helpers/silence_error_logger.dart';
import 'support/delivery_trace.dart';
import 'support/scan_disk_image.dart';
import 'support/scan_phase_trace.dart';
import 'support/scan_session_driver.dart';

/// A lock clock that runs 20 s per reading — a contended acquire gives up
/// after two attempts instead of the real 30 s.
DateTime Function() fastLockClock() {
  var t = DateTime.utc(2026, 9, 16);
  return () => t = t.add(const Duration(seconds: 20));
}

/// Runs in a spawned isolate of THIS process: try the scan's lock file and
/// report whether it was acquired. Deliberately never releases — a release
/// would delete the file under the other holder.
Future<void> acquireInSpawnedIsolate((SendPort, String) message) async {
  final (reply, path) = message;
  final lock = HiveIsolateLock.fromFile(File(path), clock: fastLockClock());
  reply.send(await lock.acquire());
}

Future<bool> acquiredBySpawnedIsolate(File lockFile) async {
  final port = ReceivePort();
  await Isolate.spawn(acquireInSpawnedIsolate, (port.sendPort, lockFile.path));
  final acquired = await port.first as bool;
  port.close();
  return acquired;
}

/// A fetcher whose calls a test can hold open.
class GatedFetcher implements BackgroundPriceFetcher {
  final List<String> calls = [];
  Completer<void>? holdInit;

  @override
  Future<void> init() async {
    calls.add('init');
    await holdInit?.future;
  }

  @override
  Future<void> cancelAll() async => calls.add('cancelAll');

  @override
  Future<void> scheduleOpportunisticScan() async {}
}

class RecordingSlc implements SlcWakeMonitor {
  final List<bool> calls = [];
  @override
  Future<void> setEnabled(bool enabled) async => calls.add(enabled);
}

void main() {
  silenceErrorLoggerSpool();

  late ScanDisk disk;

  setUp(() async => disk = await ScanDisk.open());
  tearDown(() async => disk.close());

  test('a second trigger in the SAME isolate is refused while a scan holds '
      'the lock, and journals why', () async {
    final park = Park();
    final firstTrace = ScanPhaseTrace();
    final first = disk
        .coordinator(
          body: (_, at) => ScriptedScanBody(at, park: park),
          notifier: DeliveryTrace(),
          sink: firstTrace,
        )
        .scan(trigger: BackgroundScanTrigger.workManagerPeriodic, now: kScanT0);
    await park.reached;
    expect(firstTrace.path.last, ScanRunPhase.collecting);

    final secondTrace = ScanPhaseTrace();
    final ran = await disk
        .coordinator(
          body: (_, at) => ScriptedScanBody(at),
          notifier: DeliveryTrace(),
          sink: secondTrace,
          lockClock: fastLockClock(),
        )
        .scan(trigger: BackgroundScanTrigger.androidWidget, now: kScanT0);

    expect(ran, isFalse);
    expect(secondTrace.outcomes.single,
        (ScanOutcome.skippedLock, ScanRunPhase.locking));
    secondTrace.expectLawful();
    expect(disk.journal.last,
        {'at': kScanT0.toIso8601String(), 'trigger': 'android_widget',
          'skipped': 'hive_lock'});
    expect(disk.journal.first[AlertScanJournal.inFlightKey], isTrue,
        reason: 'the holder is mid-body: its marker is on disk (#4333)');

    park.release();
    expect(await first, isTrue);
    firstTrace.expectLawful();
  });

  test('a second trigger in ANOTHER isolate of the process is refused too '
      '(#4333)', () async {
    final park = Park();
    final running = disk
        .coordinator(
          body: (_, at) => ScriptedScanBody(at, park: park),
          notifier: DeliveryTrace(),
        )
        .scan(trigger: BackgroundScanTrigger.workManagerPeriodic, now: kScanT0);
    await park.reached;

    final acquired = await acquiredBySpawnedIsolate(disk.lockFile);
    final anomalies = {if (acquired) ScanAnomaly.concurrentScan};
    expectOnlyKnownAnomalies(anomalies);
    expect(acquired, isFalse,
        reason: 'B3 (#4333): the claim is visible to every isolate');

    park.release();
    expect(await running, isTrue);
  });

  test('an iOS expiry mid-collect: the run never resumes; the next wake '
      'still tells the user once', () async {
    final park = Park(); // never released: the BGTask expired
    ScanDiskImage? image;
    final trace = ScanPhaseTrace(onEdge: (e) {
      if (e.$2 == ScanRunPhase.collecting) image = disk.capture();
    });
    unawaited(disk
        .coordinator(
          body: (_, at) => ScriptedScanBody(at,
              park: park,
              candidates: [scanOpportunity(at: at)]),
          notifier: DeliveryTrace(),
          sink: trace,
        )
        .scan(
            trigger: BackgroundScanTrigger.iosBackgroundRefresh, now: kScanT0));
    await park.reached;
    expect(image, isNotNull);

    // The process was suspended and later killed: relaunch on its disk as
    // a new process, which holds none of the dead one's lock state.
    await disk.restore(image!);
    final notifier = DeliveryTrace();
    final wake = kScanT0.add(const Duration(hours: 3));
    await disk
        .coordinator(
          body: (_, at) =>
              ScriptedScanBody(at, candidates: [scanOpportunity(at: at)]),
          notifier: notifier,
          lock: File('${disk.dir.path}/relaunched_process.lock'),
        )
        .scan(trigger: BackgroundScanTrigger.iosBackgroundRefresh, now: wake);

    expect(notifier.posts, hasLength(1));
    final expiredRunRows = disk.journal
        .where((r) => r['at'] == kScanT0.toIso8601String())
        .toList();
    final anomalies = {
      if (expiredRunRows.isEmpty) ScanAnomaly.unjournaledRun,
    };
    expectOnlyKnownAnomalies(anomalies);
    expect(expiredRunRows.single['interrupted'], isTrue,
        reason: 'B4 (#4333): the expired run is in the export');
  });

  group('schedule', () {
    late GatedFetcher fetcher;
    late RecordingSlc slc;
    late bool active;
    late int gateReads;
    late AlertScheduleReconciler reconciler;

    setUp(() {
      fetcher = GatedFetcher();
      slc = RecordingSlc();
      active = true;
      gateReads = 0;
      reconciler = AlertScheduleReconciler(
        gate: () async {
          gateReads++;
          return active;
        },
        fetcher: () => fetcher,
        slc: () => slc,
        persistTemplates: () async {},
      );
    });

    test('B2 (#4332) — an arm suspended on its register while the last alert '
        'is deleted ends CANCELLED', () async {
      fetcher.holdInit = Completer<void>();
      final arm = reconciler.reconcile(); // reads true, parks in init()
      await pumpEventQueue();
      active = false; // the last alert is deleted meanwhile
      final cancel = reconciler.reconcile();
      await pumpEventQueue();
      fetcher.holdInit!.complete();
      await Future.wait([arm, cancel]);

      expect(fetcher.calls, ['init', 'cancelAll'],
          reason: 'the cancel waits for the arm, then re-reads the gate');
      expect(reconciler.phase, AlertSchedulePhase.cancelled);
      expect(slc.calls.last, isFalse,
          reason: 'the iOS SLC wake follows the final reading too');
      final violations = [for (final v in reconciler.debugViolations) v.$1];
      expectOnlyKnownScheduleViolations(violations);
      expect(violations, isEmpty);
    });

    test('a burst of reconciles applies once, with the final gate (#4332)',
        () async {
      final calls = [
        for (var i = 0; i < 5; i++) reconciler.reconcile(),
      ];
      active = false; // decided before any of them got to read
      await Future.wait(calls);

      expect(gateReads, 1);
      expect(fetcher.calls, ['cancelAll']);
      expect(reconciler.debugApplies, hasLength(1));
    });

    test('calls during an apply coalesce into ONE re-read (#4332)', () async {
      fetcher.holdInit = Completer<void>();
      final first = reconciler.reconcile();
      await pumpEventQueue();
      final followers = [
        for (var i = 0; i < 4; i++) reconciler.reconcile(),
      ];
      active = false;
      fetcher.holdInit!.complete();
      await Future.wait([first, ...followers]);

      expect(gateReads, 2);
      expect(fetcher.calls, ['init', 'cancelAll']);
    });

    test('startup post-frame reconcile racing delete-last-alert, through the '
        'integrated RuntimeServicesPhase and BackgroundService.reconcile, '
        'ends cancelled (#4332, #4317)', () async {
      final original = BackgroundService.schedule;
      addTearDown(() => BackgroundService.schedule = original);
      BackgroundService.schedule = reconciler;
      fetcher.holdInit = Completer<void>();

      final startup = RuntimeServicesPhase.run(RuntimeServices(
        initNotifications: () async {},
        reconcileBackground: BackgroundService.reconcile,
        opportunisticWake: () async {},
        homeWidgetSetup: () async {},
      ));
      await pumpEventQueue();
      expect(fetcher.calls, ['init'], reason: 'startup read an active alert');

      // The user deletes the last alert while startup is still registering:
      // the provider's reconcile.
      active = false;
      final delete = BackgroundService.reconcile();
      await pumpEventQueue();
      fetcher.holdInit!.complete();
      await Future.wait([startup, delete]);

      expect(fetcher.calls, ['init', 'cancelAll']);
      expect(reconciler.phase, AlertSchedulePhase.cancelled);
      expect(reconciler.debugViolations, isEmpty);
    });
  });
}
