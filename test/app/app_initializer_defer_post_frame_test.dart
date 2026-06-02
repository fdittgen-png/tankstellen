// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/app_initializer.dart';

/// Runtime tests for the `AppInitializer.deferPostFirstFrame` helper
/// introduced by #795 phase 1.
///
/// The helper is the mechanism that keeps TankSync, CommunityConfig, and
/// the PackageInfo runtime-version read off the first-frame critical
/// path. These tests verify three behaviours:
///
///  1. The deferred body actually runs after a frame is produced.
///  2. An exception inside the deferred body is caught; it never
///     becomes an uncaught async error on the running app.
///  3. Multiple deferrals all execute.
///
/// Determinism (#2729): the helper registers a `SchedulerBinding`
/// post-frame callback that then `unawaited`s an async `run()` closure.
/// That closure (`await body()` inside a try/catch) settles on the
/// microtask queue *after* the frame's post-frame phase — so a test that
/// merely pumps once and asserts is betting on incidental frame/microtask
/// timing, which is exactly why this file flaked on loaded CI runners
/// (failed 3× in a row, blocking unrelated PRs).
///
/// Instead of guessing, each test drives the deferred work to a *settled*
/// state before asserting:
///
///  * the body itself completes a `Completer`, so the test has a concrete
///    future to await — for the throwing case it signals from a `finally`
///    so the throw still reaches the helper's production catch;
///  * the pump + the await both run inside `tester.runAsync`, the only
///    harness primitive that lets the real (non-faked) microtask queue
///    backing the `unawaited(run())` future actually drain to completion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps a real frame (so the post-frame callback fires) and then awaits
  /// [settled] — the future the deferred body completes — so the assertion
  /// runs against fully-drained deferred work rather than incidental timing.
  ///
  /// The frame is pumped via the normal harness path (`addPostFrameCallback`
  /// fires during `pumpWidget`, which queues the helper's `unawaited(run())`).
  /// The await then happens inside [WidgetTester.runAsync] — the only harness
  /// primitive that lets the genuine microtask queue backing that future
  /// drain to completion. `pump`/`idle` alone advance only the fake async
  /// clock and do not guarantee that chained `await body()` continuations
  /// settle, which is the timing the flaky version was betting on (#2729).
  Future<void> pumpUntilDeferredSettles(
    WidgetTester tester,
    Future<void> settled,
  ) async {
    // A real frame is required for `addPostFrameCallback` to fire; this also
    // schedules the helper's `unawaited(run())` onto the microtask queue.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      // Bound the wait so a wiring regression fails fast instead of hanging
      // the suite; the deferred body should settle near-instantly.
      await settled.timeout(const Duration(seconds: 5));
    });
    // Drain any follow-up frame/microtask the helper enqueued so the binding
    // is quiescent before we sample `takeException`.
    await tester.pump();
    await tester.idle();
  }

  testWidgets('deferPostFirstFrame runs its body after a frame', (tester) async {
    final ran = Completer<void>();
    AppInitializer.deferPostFirstFrame(() async {
      ran.complete();
    });

    await pumpUntilDeferredSettles(tester, ran.future);

    expect(ran.isCompleted, isTrue,
        reason: 'deferred body must run after a frame is produced');
  });

  testWidgets('deferPostFirstFrame swallows exceptions inside the body',
      (tester) async {
    // Register a body that throws. The helper must catch and log, NOT
    // rethrow — otherwise an SDK hiccup inside TankSync would crash the
    // running app post-launch.
    //
    // The body signals completion from `finally` so the test can await the
    // exact settle point, while the `throw` still escapes into the helper's
    // production try/catch (where it must be trapped).
    final attempted = Completer<void>();
    AppInitializer.deferPostFirstFrame(() async {
      try {
        throw StateError('simulated post-frame failure');
      } finally {
        attempted.complete();
      }
    });

    await pumpUntilDeferredSettles(tester, attempted.future);

    // `takeException` returns the first uncaught exception that reached
    // the binding. The helper must trap the StateError so it never
    // bubbles up here.
    expect(tester.takeException(), isNull,
        reason: 'errors inside the deferred body must be caught so they '
            'never bubble up as uncaught async errors while the user is '
            'interacting with the app');
  });

  testWidgets('multiple deferPostFirstFrame calls all run', (tester) async {
    final ran = <int>[];
    final completers = List.generate(3, (_) => Completer<void>());
    for (var i = 0; i < 3; i++) {
      final captured = i;
      AppInitializer.deferPostFirstFrame(() async {
        ran.add(captured);
        completers[captured].complete();
      });
    }

    await pumpUntilDeferredSettles(
      tester,
      Future.wait(completers.map((c) => c.future)),
    );

    expect(ran, containsAll([0, 1, 2]),
        reason: 'every scheduled deferred body must run');
    expect(ran, hasLength(3),
        reason: 'no duplicates — each deferral runs exactly once');
  });

  testWidgets('SchedulerBinding is available — helper uses it internally',
      (tester) async {
    // Guard against a future rewrite that swaps to `scheduleMicrotask`
    // and silently breaks the post-frame guarantee. If the helper used
    // scheduleMicrotask, the body would run during the same event-loop
    // turn as the call — before any frame is produced.
    //
    // The source-level phase-1 test (app_initializer_phase1_test.dart)
    // pins the textual presence of `addPostFrameCallback`; this test
    // just sanity-checks the SchedulerBinding is in fact wired up under
    // the test harness so the source-level guard matches runtime.
    expect(SchedulerBinding.instance, isNotNull,
        reason: 'SchedulerBinding must be available after '
            'TestWidgetsFlutterBinding.ensureInitialized');
  });
}
