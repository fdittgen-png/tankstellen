// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #4162 — KILL: the OS ends the process at any await of a scan.
///
/// WorkManager stops a worker past its window, iOS expires a BGTask, the
/// low-memory killer takes the whole process. Each kill point below is an
/// exact edge of the run — captured through the coordinator's phase sink,
/// or right after the notification was posted — and each is followed by a
/// relaunch: a NEW coordinator on the disk as the kill left it, eleven
/// minutes later (past the cross-trigger cooldown).
///
/// Two promises are checked at every kill point:
///
/// * the user is told about one opportunity at most once per budget
///   window, kill or no kill;
/// * a run that got as far as collecting leaves a journal row — the
///   export's "did scans run?" must not undercount killed runs.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/background/background_scan_trigger.dart';
import 'package:tankstellen/core/background/scan_run_phase.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/data/budget_state_store.dart';

import '../../../helpers/silence_error_logger.dart';
import 'support/delivery_trace.dart';
import 'support/scan_disk_image.dart';
import 'support/scan_phase_trace.dart';
import 'support/scan_session_driver.dart';

/// The reservation marker in the stored budget, read as raw JSON.
Object? pendingReservationOnDisk() {
  final raw =
      Hive.box<dynamic>(HiveBoxes.alerts).get(BudgetStateStore.storageKey);
  return raw is String ? (jsonDecode(raw) as Map)['pending'] : null;
}

/// Where the kill lands: a phase edge, right before the post, or right
/// after it.
typedef KillPoint = ({ScanEdge? edge, bool afterPost, bool beforePost});

/// What a kill at one point, followed by a relaunch, did.
typedef KillResult = ({
  int deliveries,
  List<Map<String, Object?>> journal,
  Set<DeliveryDefect> defects,
  Set<ScanAnomaly> anomalies,
});

/// The run's edges in order, for a scan that notifies.
const List<ScanEdge> kNotifyingPath = [
  (ScanRunPhase.idle, ScanRunPhase.locking),
  (ScanRunPhase.locking, ScanRunPhase.opening),
  (ScanRunPhase.opening, ScanRunPhase.gated),
  (ScanRunPhase.gated, ScanRunPhase.collecting),
  (ScanRunPhase.collecting, ScanRunPhase.dispatching),
  (ScanRunPhase.dispatching, ScanRunPhase.refreshingWidgets),
  (ScanRunPhase.refreshingWidgets, ScanRunPhase.stamping),
  (ScanRunPhase.stamping, ScanRunPhase.idle),
];

/// Kill points past which the run owes the journal a row.
bool owesJournalRow(KillPoint k) =>
    k.afterPost ||
    k.beforePost ||
    const {
      ScanRunPhase.collecting,
      ScanRunPhase.dispatching,
      ScanRunPhase.refreshingWidgets,
      ScanRunPhase.stamping,
    }.contains(k.edge?.$2);

String describe(KillPoint k) => k.afterPost
    ? 'after the post'
    : k.beforePost
        ? 'before the post'
        : '${k.edge!.$1.name}→${k.edge!.$2.name}';

void main() {
  silenceErrorLoggerSpool();

  late ScanDisk disk;

  setUp(() async => disk = await ScanDisk.open());
  tearDown(() async => disk.close());

  Future<KillResult> killThenRelaunch(KillPoint kill) async {
    ScanDiskImage? image;
    var lastSeenPost = -1;
    final first = DeliveryTrace();
    void captureOnce() {
      if (image != null) return;
      image = disk.capture();
      lastSeenPost = first.posts.isEmpty ? -1 : first.posts.last.sequence;
    }

    if (kill.afterPost) first.onPost = (_) => captureOnce();
    if (kill.beforePost) first.onBeforePost = captureOnce;
    final trace = ScanPhaseTrace(onEdge: (e) {
      if (e == kill.edge) captureOnce();
    });

    await disk
        .coordinator(
          body: (_, at) =>
              ScriptedScanBody(at, candidates: [scanOpportunity(at: at)]),
          notifier: first,
          sink: trace,
        )
        .scan(trigger: BackgroundScanTrigger.workManagerPeriodic, now: kScanT0);
    trace.expectLawful();
    expect(image, isNotNull, reason: 'the kill point ${describe(kill)} '
        'was never reached');

    // The process died at the capture: nothing after it happened.
    await disk.restore(image!);
    first.truncateAfter(lastSeenPost);

    final relaunchAt = kScanT0.add(const Duration(minutes: 11));
    final second = DeliveryTrace();
    await disk
        .coordinator(
          body: (_, at) =>
              ScriptedScanBody(at, candidates: [scanOpportunity(at: at)]),
          notifier: second,
        )
        .scan(
            trigger: BackgroundScanTrigger.workManagerPeriodic, now: relaunchAt);

    final deliveries = first.posts.length + second.posts.length;
    final journal = disk.journal;
    final killedRunRows = journal
        .where((r) => r['at'] == kScanT0.toIso8601String())
        .toList();
    return (
      deliveries: deliveries,
      journal: journal,
      defects: {
        if (deliveries > 1) DeliveryDefect.duplicateAfterKill,
      },
      anomalies: {
        if (owesJournalRow(kill) && killedRunRows.isEmpty)
          ScanAnomaly.unjournaledRun,
      },
    );
  }

  final killPoints = <KillPoint>[
    for (final e in kNotifyingPath) (edge: e, afterPost: false, beforePost: false),
    (edge: null, afterPost: false, beforePost: true),
    (edge: null, afterPost: true, beforePost: false),
  ];

  test('without a kill: one notification, one completed row per scan',
      () async {
    final notifier = DeliveryTrace();
    final trace = ScanPhaseTrace();
    final coordinator = disk.coordinator(
      body: (_, at) =>
          ScriptedScanBody(at, candidates: [scanOpportunity(at: at)]),
      notifier: notifier,
      sink: trace,
    );

    expect(
        await coordinator.scan(
            trigger: BackgroundScanTrigger.workManagerPeriodic, now: kScanT0),
        isTrue);
    expect(trace.edges, kNotifyingPath);
    expect(trace.outcomes.single.$1, ScanOutcome.completed);
    trace.expectLawful();
    expect(notifier.posts, hasLength(1));
    expect(disk.journal.single, {
      'at': kScanT0.toIso8601String(),
      'trigger': 'workmanager_periodic',
      'stations': 1,
      'alertsFired': 1,
    });

    // The same opportunity eleven minutes later is inside the budget's
    // quiet window: recorded, not posted again.
    await coordinator.scan(
        trigger: BackgroundScanTrigger.workManagerPeriodic,
        now: kScanT0.add(const Duration(minutes: 11)));
    expect(notifier.posts, hasLength(1));
    expect(disk.journal.last['alertsFired'], 0);
  });

  for (final kill in killPoints) {
    test('killed ${describe(kill)}: relaunch keeps the delivery and journal '
        'promises', () async {
      final result = await killThenRelaunch(kill);
      expectOnlyKnownDeliveryDefects(result.defects);
      expectOnlyKnownAnomalies(result.anomalies);
      expect(result.defects, isEmpty);
      expect(result.anomalies, isEmpty);

      if (kill.beforePost) {
        // The reservation was on disk, the post never happened. The
        // budget cannot tell "about to show" from "shown" once the process
        // is gone, and it chooses at most once: no notification inside
        // this window — the next one after it tells the user.
        expect(result.deliveries, 0);
      } else {
        expect(result.deliveries, 1,
            reason: 'told exactly once, kill or no kill');
      }

      final killedRun = result.journal
          .where((r) => r['at'] == kScanT0.toIso8601String())
          .toList();
      if (owesJournalRow(kill) &&
          kill.edge != (ScanRunPhase.stamping, ScanRunPhase.idle)) {
        expect(killedRun.single, {
          'at': kScanT0.toIso8601String(),
          'trigger': 'workmanager_periodic',
          'interrupted': true,
        }, reason: 'the in-flight marker, resolved by the relaunch');
      }
      expect(result.journal.where((r) => r['inFlight'] == true), isEmpty,
          reason: 'no marker survives a completed relaunch');
    });
  }

  test('killed before the post: the reservation is resolved, and the '
      'opportunity is told once the quiet window has passed', () async {
    await killThenRelaunch((edge: null, afterPost: false, beforePost: true));
    expect(pendingReservationOnDisk(), isNull,
        reason: 'the relaunch resolved the reservation it found');

    final late = DeliveryTrace();
    await disk
        .coordinator(
          body: (_, at) =>
              ScriptedScanBody(at, candidates: [scanOpportunity(at: at)]),
          notifier: late,
        )
        .scan(
            trigger: BackgroundScanTrigger.workManagerPeriodic,
            now: kScanT0.add(const Duration(hours: 13)));
    expect(late.posts, hasLength(1));
  });

  test('every known-defect set is empty — B4 is fixed', () {
    expect(kKnownDeliveryDefects, isEmpty);
    expect(kKnownDeliveryDefectsCeiling, 0);
    expect(kKnownScanAnomalies, isEmpty);
    expect(kKnownScanAnomaliesCeiling, 0);
  });
}
