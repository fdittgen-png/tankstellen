// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/app/startup/launch_critical_path.dart';
import 'package:tankstellen/app/startup/storage_failure_gate.dart';
import 'package:tankstellen/app/widgets/storage_recovery_screen.dart';
import 'package:tankstellen/core/telemetry/storage/startup_failure_store.dart';

void main() {
  test(
    'storage failure escapes while a telemetry sibling remains pending',
    () async {
      final sibling = Completer<void>();
      final failure = StateError('profile write failed');
      Object? surfaced;
      final phase =
          LaunchCriticalPath.storagePhase(
            openBoxes: () async {},
            loadApiKeys: () async {},
            seedDefaultProfile: () async => throw failure,
            telemetry: {'trace_storage': () => sibling.future},
          ).catchError((Object error) {
            surfaced = error;
          });
      await pumpEventQueue();
      final failedBeforeSibling = identical(surfaced, failure);
      sibling.completeError(StateError('late telemetry failure'));
      await phase;
      expect(failedBeforeSibling, isTrue);
      expect(surfaced, same(failure));
    },
  );

  testWidgets('recovery mounts before diagnostic directory lookup finishes', (
    tester,
  ) async {
    final directory = Completer<Directory>();
    StartupFailureStore.directoryProvider = () => directory.future;
    addTearDown(StartupFailureStore.resetForTest);
    final result = runStoragePhaseGuarded(
      () async => throw StateError('storage failed'),
    );
    await tester.pump();
    final mountedBeforeDiagnostics = find
        .byType(StorageRecoveryHost)
        .evaluate()
        .isNotEmpty;
    directory.completeError(
      const FileSystemException('diagnostics unavailable'),
    );
    await result;
    await tester.pumpWidget(const SizedBox.shrink());
    expect(mountedBeforeDiagnostics, isTrue);
  });

  testWidgets('diagnostic persistence cannot keep the failed launch pending', (
    tester,
  ) async {
    final directory = Completer<Directory>();
    StartupFailureStore.directoryProvider = () => directory.future;
    addTearDown(StartupFailureStore.resetForTest);
    var stopped = false;
    final result =
        runStoragePhaseGuarded(
          () async => throw StateError('storage failed'),
        ).then((ok) {
          stopped = !ok;
        });
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    final stoppedBeforeDiagnostics = stopped;
    directory.completeError(
      const FileSystemException('late diagnostic failure'),
    );
    await result;
    await tester.pumpWidget(const SizedBox.shrink());
    expect(stoppedBeforeDiagnostics, isTrue);
  });

  testWidgets('slow successful storage remains a valid launch', (tester) async {
    final storage = Completer<void>();
    bool? ready;
    final launch = runStoragePhaseGuarded(
      () => storage.future,
    ).then((value) => ready = value);
    await tester.pump(const Duration(minutes: 1));
    expect(ready, isNull);
    expect(find.byType(StorageRecoveryHost), findsNothing);
    storage.complete();
    await launch;
    expect(ready, isTrue);
  });
}
