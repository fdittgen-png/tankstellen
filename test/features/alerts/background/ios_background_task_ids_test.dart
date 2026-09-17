// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/background/ios_background_task_ids.dart';
import 'package:workmanager/workmanager.dart';

/// Fault-injection [Workmanager]: every call throws, to exercise the
/// never-throws contract (#3169).
class _ThrowingWorkmanager implements Workmanager {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('workmanager backend unavailable');
}

/// #3169 — the iOS BGTask ids and the processing-lane submission, in the
/// file they moved to with #4162.
void main() {
  test('scheduleIosProcessingTask never throws (fault injection)', () async {
    // Never-throws contract: a re-arm failure inside the dispatcher must
    // not fail the scan that triggered it.
    await expectLater(
        scheduleIosProcessingTask(_ThrowingWorkmanager()), completes);
  });

  test('the identifiers are distinct and bundle-derived', () {
    const ids = [
      IosBackgroundTaskIds.appRefresh,
      IosBackgroundTaskIds.processing,
      IosBackgroundTaskIds.slcWake,
      IosBackgroundTaskIds.opportunistic,
    ];
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids, everyElement(startsWith('de.tankstellen.tankstellen.')));
  });
}
