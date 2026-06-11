// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/telemetry/storage/startup_failure_store.dart';

/// #3149 — when the storage phase bricks, Hive (and with it the trace
/// store + isolate spool) is dead, so the cause must persist through a
/// plain file the next successful launch can replay. These tests pin the
/// round-trip, the read-once semantics, and the best-effort fault paths
/// on both sides.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('startup_failure_');
    StartupFailureStore.directoryProvider = () async => tempDir;
  });

  tearDown(() {
    StartupFailureStore.resetForTest();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('persist → drain round-trips error type, message and stack', () async {
    final error = StateError('keychain unavailable');
    final stack = StackTrace.current;
    await StartupFailureStore.persist(error, stack);

    final record = await StartupFailureStore.drain();
    expect(record, isNotNull);
    expect(record!['errorType'], 'StateError');
    expect(record['error'], contains('keychain unavailable'));
    expect(record['stack'], contains('startup_failure_store_test'));
    expect(DateTime.tryParse(record['at'] as String), isNotNull);
  });

  test('drain deletes the record — a poisoned record reports at most once',
      () async {
    await StartupFailureStore.persist(Exception('boom'), StackTrace.current);
    expect(await StartupFailureStore.drain(), isNotNull);
    expect(await StartupFailureStore.drain(), isNull,
        reason: 'second drain must find nothing');
    expect(
        File('${tempDir.path}/${StartupFailureStore.fileName}').existsSync(),
        isFalse);
  });

  test('drain returns null when no failure was ever persisted', () async {
    expect(await StartupFailureStore.drain(), isNull);
  });

  test('a later persist overwrites the earlier record', () async {
    await StartupFailureStore.persist(Exception('first'), StackTrace.current);
    await StartupFailureStore.persist(Exception('second'), StackTrace.current);
    final record = await StartupFailureStore.drain();
    expect(record!['error'], contains('second'));
  });

  test('persist swallows a directory-provider fault (fault injection)',
      () async {
    StartupFailureStore.directoryProvider =
        () async => throw const FileSystemException('disk gone');
    await expectLater(
      StartupFailureStore.persist(Exception('boom'), StackTrace.current),
      completes,
      reason: 'observability must never make a bricked startup worse',
    );
  });

  test('drain swallows a corrupt record and returns null (fault injection)',
      () async {
    final file = File('${tempDir.path}/${StartupFailureStore.fileName}');
    file.writeAsStringSync('{not json');
    expect(await StartupFailureStore.drain(), isNull,
        reason: 'a corrupt record must never brick the healthy launch');
  });

  test('the record is plain JSON a maintainer can read off-device', () async {
    await StartupFailureStore.persist(Exception('boom'), StackTrace.current);
    final raw = File('${tempDir.path}/${StartupFailureStore.fileName}')
        .readAsStringSync();
    expect(() => jsonDecode(raw), returnsNormally);
  });
}
