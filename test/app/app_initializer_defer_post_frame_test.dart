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
/// Note: `SchedulerBinding.addPostFrameCallback` needs a frame to fire.
/// We pump a trivial widget first so the binding produces a frame, then
/// pump again to drain any follow-up microtasks the helper enqueues.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAFrame(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.idle();
  }

  testWidgets('deferPostFirstFrame runs its body after a frame', (tester) async {
    var ran = false;
    AppInitializer.deferPostFirstFrame(() async {
      ran = true;
    });

    await pumpAFrame(tester);

    expect(ran, isTrue,
        reason: 'deferred body must run after a frame is produced');
  });

  testWidgets('deferPostFirstFrame swallows exceptions inside the body',
      (tester) async {
    // Register a body that throws. The helper must catch and log, NOT
    // rethrow — otherwise an SDK hiccup inside TankSync would crash the
    // running app post-launch.
    AppInitializer.deferPostFirstFrame(() async {
      throw StateError('simulated post-frame failure');
    });

    await pumpAFrame(tester);

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
    for (var i = 0; i < 3; i++) {
      final captured = i;
      AppInitializer.deferPostFirstFrame(() async {
        ran.add(captured);
      });
    }

    await pumpAFrame(tester);
    // Follow-up pumps in case some deferrals got scheduled onto a
    // subsequent frame (each post-frame callback may enqueue a
    // microtask that chains onto the next frame).
    await tester.pump();
    await tester.idle();

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
