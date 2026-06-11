// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/app_initializer.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';

/// #3143 — startup catch handlers must be release-visible. `_bootstrap()`
/// no-ops `debugPrint` in release builds, so a catch whose only action was
/// `debugPrint` swallowed the failure in production. This test pins the
/// runtime behaviour for the shared deferral helper: a failing deferred
/// body is routed through `errorLogger` (→ TraceRecorder / Sentry), not
/// just printed. The static sweep over lib/app + the background-scan dirs is
/// enforced by `test/lint/no_debugprint_only_catch_test.dart`.
class _CapturingRecorder implements TraceRecorder {
  final captured = <Object>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    captured.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'a failing deferred body records via errorLogger with the '
      'deferPostFirstFrame context (#3143)', (tester) async {
    final recorder = _CapturingRecorder();
    errorLogger.testRecorderOverride = recorder;
    addTearDown(errorLogger.resetForTest);

    final attempted = Completer<void>();
    AppInitializer.deferPostFirstFrame(() async {
      try {
        throw StateError('simulated deferred-init failure');
      } finally {
        attempted.complete();
      }
    });

    // A real frame fires the post-frame callback; runAsync drains the
    // genuine microtask queue so the helper's catch (and its errorLogger
    // call) settles before the assertion (same pattern as #2729).
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await attempted.future.timeout(const Duration(seconds: 5));
      // Let the helper's catch block + errorLogger.log continuation run.
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    await tester.idle();

    expect(recorder.captured, hasLength(1),
        reason: 'the deferred failure must reach the TraceRecorder pipeline');
    final logged = recorder.captured.single;
    expect(logged, isA<ContextualError>());
    final contextual = logged as ContextualError;
    expect(contextual.layer, ErrorLayer.background);
    expect(contextual.context?['where'], 'deferPostFirstFrame');
    expect(contextual.inner, isA<StateError>());
    expect(tester.takeException(), isNull,
        reason: 'the failure must be logged, never rethrown');
  });
}
