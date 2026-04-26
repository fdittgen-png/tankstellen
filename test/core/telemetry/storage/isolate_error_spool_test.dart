import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/storage/isolate_error_spool.dart';
import 'package:tankstellen/core/telemetry/storage/isolate_error_spool_entry.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';

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
