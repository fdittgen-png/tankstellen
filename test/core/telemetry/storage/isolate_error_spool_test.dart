// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/storage/isolate_error_spool.dart';
import 'package:tankstellen/core/telemetry/storage/isolate_error_spool_entry.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';

/// Top-level entry point spawned by [Isolate.spawn]. Runs in a fresh
/// isolate where Hive was never `init`ed — the exact orphaned-completer
/// scenario fixed in #2321: `Hive.openBox` rethrows AND completes its
/// internal `_openingBoxes` completer with an error that has no
/// listener. If the guard in [IsolateErrorSpool._defaultOpenBox]
/// regressed, that rejection would surface as an *unhandled* async
/// error and kill the spawned isolate before it sends `'done'` back —
/// so the parent's `onExit`/timeout would fire instead of `'done'`.
///
/// The isolate sends `'done'` only if [IsolateErrorSpool.enqueue]
/// returned normally with no escaped async error.
Future<void> spawnedEnqueueEntry(SendPort reply) async {
  // Mirror the real background-isolate wake-up: no Hive.init has run.
  await IsolateErrorSpool.enqueue(
    isolateTaskName: 'spawned_price_refresh',
    error: Exception('boom from a real isolate'),
    contextMap: const <String, dynamic>{'attempt': 1},
  );
  // Drain microtasks so an orphaned-completer rejection (if the guard
  // regressed) gets a chance to surface inside this isolate before we
  // report success.
  await Future<void>.delayed(Duration.zero);
  reply.send('done');
}

/// Minimal fake [TraceRecorder] that captures every call to `record`.
///
/// We deliberately don't extend the real recorder via Mocktail — its
/// constructor pulls in TraceStorage / TraceUploader / Ref, none of
/// which are needed for the drain assertion. Implementing the public
/// surface keeps the test focused on the spool contract.
class _FakeTraceRecorder implements TraceRecorder {
  final calls = <Object>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    calls.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('isolate_error_spool_');
    Hive.init(tempDir.path);
    IsolateErrorSpool.resetBoxFactoryForTest();
  });

  tearDown(() async {
    IsolateErrorSpool.resetBoxFactoryForTest();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('IsolateErrorSpool round-trip', () {
    test('writes and reads a single entry', () async {
      await IsolateErrorSpool.enqueue(
        isolateTaskName: 'price_refresh',
        error: Exception('boom'),
        stack: StackTrace.fromString('#0 main (test.dart:1)'),
        contextMap: <String, dynamic>{
          'stationId': 'abc',
          'attempt': 2,
        },
        timestamp: DateTime(2026, 4, 26, 10, 0, 0),
      );

      final entries = await IsolateErrorSpool.peek();
      expect(entries, hasLength(1));
      final e = entries.single;
      expect(e.isolateTaskName, 'price_refresh');
      expect(e.errorMessage, contains('boom'));
      expect(e.stack, contains('main (test.dart:1)'));
      expect(e.contextMap['stationId'], 'abc');
      expect(e.contextMap['attempt'], 2);
      expect(e.timestamp, DateTime(2026, 4, 26, 10, 0, 0));
    });

    test('keeps only the last 50 entries when 60 are written (FIFO)',
        () async {
      for (var i = 0; i < 60; i++) {
        await IsolateErrorSpool.enqueue(
          isolateTaskName: 'price_refresh',
          error: 'error-$i',
          stack: StackTrace.fromString('stack-$i'),
          timestamp: DateTime(2026, 1, 1).add(Duration(seconds: i)),
        );
      }
      final stored = await IsolateErrorSpool.peek();
      expect(stored, hasLength(IsolateErrorSpool.maxEntries));
      // Oldest 10 evicted -> first surviving is error-10.
      expect(stored.first.errorMessage, contains('error-10'));
      expect(stored.last.errorMessage, contains('error-59'));
      expect(await IsolateErrorSpool.length(),
          IsolateErrorSpool.maxEntries);
    });

    test('sanitizes non-Hive-safe context values via toString()',
        () async {
      await IsolateErrorSpool.enqueue(
        isolateTaskName: 'velocity_detector',
        error: 'x',
        contextMap: <String, dynamic>{
          'duration': const Duration(seconds: 5),
          'okString': 'kept',
          'okInt': 42,
        },
      );
      final entry = (await IsolateErrorSpool.peek()).single;
      expect(entry.contextMap['duration'], '0:00:05.000000');
      expect(entry.contextMap['okString'], 'kept');
      expect(entry.contextMap['okInt'], 42);
    });
  });

  group('IsolateErrorSpool.drain', () {
    test('replays N entries through the recorder and clears the box',
        () async {
      for (var i = 0; i < 5; i++) {
        await IsolateErrorSpool.enqueue(
          isolateTaskName: 'task-$i',
          error: 'oops-$i',
          stack: StackTrace.fromString('stack-$i'),
        );
      }
      expect(await IsolateErrorSpool.length(), 5);

      final recorder = _FakeTraceRecorder();
      final replayed = await IsolateErrorSpool.drain(recorder);

      expect(replayed, 5);
      expect(recorder.calls, hasLength(5));
      // Replayed errors carry the original task name and message in
      // their toString representation so the foreground recorder can
      // distinguish background-origin failures.
      expect(recorder.calls.first.toString(), contains('task-0'));
      expect(recorder.calls.first.toString(), contains('oops-0'));
      expect(await IsolateErrorSpool.length(), 0);
    });

    test('drain on empty spool returns 0 and does not call recorder',
        () async {
      final recorder = _FakeTraceRecorder();
      final replayed = await IsolateErrorSpool.drain(recorder);
      expect(replayed, 0);
      expect(recorder.calls, isEmpty);
    });

    test('continues draining when one record throws and still clears',
        () async {
      await IsolateErrorSpool.enqueue(
        isolateTaskName: 'first',
        error: 'a',
      );
      await IsolateErrorSpool.enqueue(
        isolateTaskName: 'second',
        error: 'b',
      );

      final recorder = _ThrowOnceTraceRecorder();
      final replayed = await IsolateErrorSpool.drain(recorder);

      // Only one survived the bad record, but the box must still be
      // cleared so we don't replay the same failure on every cold
      // start.
      expect(replayed, 1);
      expect(await IsolateErrorSpool.length(), 0);
    });
  });

  group('IsolateErrorSpool failure isolation', () {
    test('enqueue does not throw when the Hive box factory throws',
        () async {
      IsolateErrorSpool.boxFactory = () async {
        throw StateError('hive box broken');
      };

      // The whole point of the spool is that observability MUST NOT
      // derail the background task. enqueue must swallow Hive errors.
      await expectLater(
        IsolateErrorSpool.enqueue(
          isolateTaskName: 'price_refresh',
          error: 'never_lands',
        ),
        completes,
      );
    });

    test(
        'enqueue does not leak an unhandled async error when Hive is '
        'uninitialised (default box factory)', () async {
      // Regression for the PR #2321 test(2) failure: when #2307 routed
      // GPS-stream errors through `errorLogger.log`, an uninitialised
      // Hive made `Hive.openBox` complete its internal `_openingBoxes`
      // completer with an error that had no listener — surfacing as an
      // *unhandled* async error that failed otherwise-green tests even
      // though `enqueue` caught the rethrown copy. The fix wraps the
      // open in a guarded zone; this test pins that the default box
      // factory (real `Hive.openBox`) is orphan-error-safe with no Hive
      // directory bound.
      await Hive.close();
      IsolateErrorSpool.resetBoxFactoryForTest();
      await expectLater(
        IsolateErrorSpool.enqueue(
          isolateTaskName: 'gps_stream',
          error: Exception('permission revoked'),
        ),
        completes,
      );
      // Drain pending microtasks; an orphaned completer rejection would
      // surface here and fail the test zone if the guard regressed.
      await Future<void>.delayed(Duration.zero);
    });

    test('peek returns an empty list when the box factory throws',
        () async {
      IsolateErrorSpool.boxFactory = () async {
        throw StateError('hive box broken');
      };
      expect(await IsolateErrorSpool.peek(), isEmpty);
      expect(await IsolateErrorSpool.length(), 0);
    });

    test('drain handles enqueue-empty + factory failure gracefully',
        () async {
      IsolateErrorSpool.boxFactory = () async {
        throw StateError('hive box broken');
      };
      final recorder = _FakeTraceRecorder();
      // Should not throw even though the underlying box is broken.
      final replayed = await IsolateErrorSpool.drain(recorder);
      expect(replayed, 0);
      expect(recorder.calls, isEmpty);
    });
  });

  group('IsolateErrorSpool from a spawned isolate (#2321 orphan leak)', () {
    test(
        'enqueue completes normally in a real Isolate.spawn context with no '
        'Hive.init — no orphaned-completer leak kills the isolate', () async {
      // This is the path the PR #2321 fix was about: the `boxFactory`
      // seam exists, but only a *real* isolate (not a swapped factory)
      // reproduces the `_openingBoxes` orphaned-completer rejection. We
      // spawn a fresh isolate, run the default (real `Hive.openBox`)
      // enqueue inside it, and require it to report `'done'`. A
      // regression of the guarded zone would surface as an unhandled
      // async error that terminates the isolate before `'done'`, so the
      // `onExit` sentinel / timeout trips instead.
      final reply = ReceivePort();
      final exitPort = ReceivePort();
      final errorPort = ReceivePort();

      final isolate = await Isolate.spawn(
        spawnedEnqueueEntry,
        reply.sendPort,
        onExit: exitPort.sendPort,
        onError: errorPort.sendPort,
        errorsAreFatal: true,
      );

      Object? isolateError;
      errorPort.listen((dynamic e) => isolateError = e);

      final completer = Completer<Object?>();
      reply.listen((dynamic msg) {
        if (!completer.isCompleted) completer.complete(msg);
      });
      // If the isolate dies (e.g. an unhandled async error with
      // `errorsAreFatal`) before sending `'done'`, onExit fires with no
      // prior reply — complete with a sentinel so the test fails loudly
      // rather than hanging.
      exitPort.listen((_) {
        if (!completer.isCompleted) {
          completer.complete(#isolateExitedWithoutReply);
        }
      });

      final result = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => #timedOut,
      );

      isolate.kill(priority: Isolate.immediate);
      reply.close();
      exitPort.close();
      errorPort.close();

      expect(isolateError, isNull,
          reason: 'enqueue must not let an error escape the spawned isolate; '
              'an orphaned `_openingBoxes` rejection would land here.');
      expect(result, 'done',
          reason: 'the spawned isolate must reach `reply.send(\'done\')`; a '
              'sentinel means it died (orphan leak) or hung.');
    });
  });

  group('IsolateErrorSpoolEntry round-trip', () {
    test('serialises and deserialises every field', () {
      final populated = IsolateErrorSpoolEntry(
        timestamp: DateTime(2026, 4, 26, 12, 0, 0),
        isolateTaskName: 'radius_alerts',
        errorMessage: 'connection refused',
        stack: '#0 fetcher (svc.dart:42)',
        contextMap: const <String, dynamic>{
          'apiKey': null,
          'count': 3,
          'flag': true,
          'list': <String>['a', 'b'],
        },
      );
      final json = populated.toJson();
      final round = IsolateErrorSpoolEntry.fromJson(json);
      expect(round.timestamp, populated.timestamp);
      expect(round.isolateTaskName, populated.isolateTaskName);
      expect(round.errorMessage, populated.errorMessage);
      expect(round.stack, populated.stack);
      expect(round.contextMap['apiKey'], isNull);
      expect(round.contextMap['count'], 3);
      expect(round.contextMap['flag'], true);
    });
  });
}

/// Recorder that throws on the first call and succeeds afterwards.
class _ThrowOnceTraceRecorder implements TraceRecorder {
  bool _hasThrown = false;
  final calls = <Object>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    if (!_hasThrown) {
      _hasThrown = true;
      throw StateError('first record fails');
    }
    calls.add(error);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
