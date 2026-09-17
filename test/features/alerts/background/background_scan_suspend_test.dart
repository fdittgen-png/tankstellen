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
import 'package:tankstellen/core/background/background_price_fetcher.dart';
import 'package:tankstellen/core/background/background_scan_trigger.dart';
import 'package:tankstellen/core/background/hive_isolate_lock.dart';
import 'package:tankstellen/core/background/scan_run_phase.dart';
import 'package:tankstellen/features/alerts/background/alert_schedule_reconciler.dart';
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
          body: (_, at) => ScriptedScanBody(at, parkCollect: park.future),
          notifier: DeliveryTrace(),
          sink: firstTrace,
        )
        .scan(trigger: BackgroundScanTrigger.workManagerPeriodic, now: kScanT0);
    await pumpEventQueue();
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
    expect(disk.journal.single,
        {'at': kScanT0.toIso8601String(), 'trigger': 'android_widget',
          'skipped': 'hive_lock'});

    park.release();
    expect(await first, isTrue);
    firstTrace.expectLawful();
  });

  test('a second trigger in ANOTHER isolate of the process must be refused '
      'too — or reproduce only the filed B3 defect', () async {
    final park = Park();
    final running = disk
        .coordinator(
          body: (_, at) => ScriptedScanBody(at, parkCollect: park.future),
          notifier: DeliveryTrace(),
        )
        .scan(trigger: BackgroundScanTrigger.workManagerPeriodic, now: kScanT0);
    await pumpEventQueue();

    final acquired = await acquiredBySpawnedIsolate(disk.lockFile);
    final anomalies = {if (acquired) ScanAnomaly.concurrentScan};
    expectOnlyKnownAnomalies(anomalies);
    expect(anomalies, contains(ScanAnomaly.concurrentScan),
        reason: 'B3 still reproduces: the per-isolate claim cannot see the '
            'other isolate, and fcntl locks are per process — delete the '
            'known entry with the fix');

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
              parkCollect: park.future,
              candidates: [scanOpportunity(at: at)]),
          notifier: DeliveryTrace(),
          sink: trace,
        )
        .scan(
            trigger: BackgroundScanTrigger.iosBackgroundRefresh, now: kScanT0));
    await pumpEventQueue();
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
  });

  group('schedule', () {
    test('B2 — an arm suspended on its register while a later cancel lands '
        'ends ARMED: reproduces only the filed defect', () async {
      final fetcher = GatedFetcher();
      final slc = RecordingSlc();
      var active = true;
      final reconciler = AlertScheduleReconciler(
        gate: () async => active,
        fetcher: () => fetcher,
        slc: () => slc,
        persistTemplates: () async {},
      );

      fetcher.holdInit = Completer<void>();
      final arm = reconciler.reconcile(); // reads true, parks in init()
      await pumpEventQueue();
      active = false; // the last alert is deleted meanwhile
      await reconciler.reconcile(); // reads false, cancels
      fetcher.holdInit!.complete();
      await arm;

      expect(fetcher.calls, ['init', 'cancelAll']);
      final violations = [for (final v in reconciler.debugViolations) v.$1];
      expectOnlyKnownScheduleViolations(violations);
      expect(violations, contains(ScheduleViolation.staleArmAfterCancel),
          reason: 'B2 still reproduces — delete the known entry with the fix');
      expect(slc.calls.last, isTrue,
          reason: 'the stale arm also re-armed the iOS SLC wake');
    });
  });
}
