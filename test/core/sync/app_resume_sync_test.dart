// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/app_resume_sync.dart';
import 'package:tankstellen/core/sync/sync_pull_coordinator.dart';
import 'package:tankstellen/core/sync/tanksync_init.dart';
import 'package:tankstellen/core/sync/tanksync_init_retry.dart';

import '../../helpers/silence_error_logger.dart';

/// #3447 — the app-resume sync trigger: debounced (≥15 min since the
/// last completed pass), never while a trip is recording, and it fires a
/// pending #3450 init retry first.
void main() {
  silenceErrorLoggerSpool();

  final resume = AppResumeSync.instance;
  final coordinator = SyncPullCoordinator.instance;
  final retry = TankSyncInitRetry.instance;

  var recording = false;
  var pulls = 0;

  void registerCountingPull() {
    coordinator.register(enabled: () => true, entries: [
      SyncPullEntry(
        tables: const ['a'],
        pull: () async {
          pulls++;
          return 1;
        },
      ),
    ]);
  }

  setUp(() {
    recording = false;
    pulls = 0;
    coordinator.resetForTest();
    retry.disarm();
    registerCountingPull();
    resume.configure(recordingActive: () => recording);
  });
  tearDown(() {
    resume.resetForTest();
    coordinator.resetForTest();
    retry.disarm();
  });

  test('first resume (no completed pass yet) pulls', () async {
    await resume.onAppResumed();
    expect(pulls, 1);
  });

  test('debounce — a resume < 15 min after the last completed pass is a '
      'no-op; ≥ 15 min pulls again', () async {
    final t0 = DateTime(2026, 7, 3, 8);
    await resume.onAppResumed(now: () => t0);
    expect(pulls, 1);

    await resume.onAppResumed(
        now: () => t0.add(const Duration(minutes: 14, seconds: 59)));
    expect(pulls, 1, reason: 'inside the 15 min window — debounced');

    await resume.onAppResumed(
        now: () => t0.add(const Duration(minutes: 15, seconds: 1)));
    expect(pulls, 2, reason: 'window elapsed — pull again');
  });

  test('never while a trip is recording', () async {
    recording = true;
    await resume.onAppResumed();
    expect(pulls, 0);

    recording = false;
    await resume.onAppResumed();
    expect(pulls, 1);
  });

  test('unconfigured instance is inert (nothing wired at cold start yet)',
      () async {
    resume.resetForTest();
    await resume.onAppResumed();
    expect(pulls, 0);
  });

  test('FAULT INJECTION — a throwing recording guard never escapes the '
      'lifecycle hook (the never-throws contract)', () async {
    resume.configure(
        recordingActive: () => throw StateError('provider torn down'));
    await expectLater(resume.onAppResumed(), completes);
    expect(pulls, 0, reason: 'the fault is logged and the pass skipped');
  });

  test('#3450 — a pending init retry fires first on resume; its late '
      'success replays the pulls via onReady', () async {
    var initAttempts = 0;
    var lateLaunches = 0;
    retry.arm(
      attempt: () async {
        initAttempts++;
        return TankSyncInitOutcome.ready;
      },
      onReady: () async => lateLaunches++,
    );

    await resume.onAppResumed();

    expect(initAttempts, 1,
        reason: 'the resume window must fast-path the pending retry '
            'instead of waiting out the backoff');
    expect(lateLaunches, 1);
    expect(retry.pending, isFalse,
        reason: 'a ready outcome is terminal — the ladder disarms');
  });
}
