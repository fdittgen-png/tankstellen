import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/error_tracing/models/error_trace.dart';
import 'package:tankstellen/core/error_tracing/trace_recorder.dart';
import 'package:tankstellen/core/logging/error_logger.dart';

/// Captures every `record` call without standing up a real
/// TraceStorage / TraceUploader / Riverpod stack. Mirrors the fake
/// used by `test/core/error_tracing/storage/isolate_error_spool_test.dart`.
class _FakeTraceRecorder implements TraceRecorder {
  final calls = <_RecordedCall>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    calls.add(_RecordedCall(error, stackTrace, serviceChainState));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _RecordedCall {
  final Object error;
  final StackTrace stackTrace;
  final ServiceChainSnapshot? snapshot;
  _RecordedCall(this.error, this.stackTrace, this.snapshot);
}

class _SpoolCall {
  final String isolateTaskName;
  final Object error;
  final StackTrace? stack;
  final Map<String, dynamic>? contextMap;
  _SpoolCall(this.isolateTaskName, this.error, this.stack, this.contextMap);
}

void main() {
  group('ErrorLogger foreground path (TraceRecorder)', () {
    late _FakeTraceRecorder recorder;

    setUp(() {
      errorLogger.resetForTest();
      recorder = _FakeTraceRecorder();
      errorLogger.testRecorderOverride = recorder;
    });

    tearDown(() {
      errorLogger.resetForTest();
    });

    test('delegates a basic error + stack to the recorder', () async {
      final stack = StackTrace.fromString('#0 unit_test (file.dart:1)');
      await errorLogger.log(
        ErrorLayer.services,
        Exception('api boom'),
        stack,
      );

      expect(recorder.calls, hasLength(1));
      final call = recorder.calls.single;
      expect(call.stackTrace, same(stack));
      // Wrapped error renders the layer prefix so log triage can grep
      // by layer in the recorder's `errorMessage` field.
      expect(call.error.toString(), contains('[services]'));
      expect(call.error.toString(), contains('api boom'));
    });

    test('captures StackTrace.current when stack is null', () async {
      await errorLogger.log(
        ErrorLayer.providers,
        StateError('unbound provider'),
        null,
      );

      expect(recorder.calls, hasLength(1));
      // We can't compare to a synthesised stack, but it must not be
      // empty and must not be the literal "null" string.
      expect(recorder.calls.single.stackTrace.toString(), isNotEmpty);
    });

    test('layer prefix is part of the toString for grep targets',
        () async {
      for (final layer in ErrorLayer.values) {
        recorder.calls.clear();
        await errorLogger.log(layer, 'boom', StackTrace.empty);
        expect(
          recorder.calls.single.error.toString(),
          contains('[${layer.name}]'),
          reason: 'layer ${layer.name} must surface in errorMessage',
        );
      }
    });

    test('context map is rendered into the wrapper error toString',
        () async {
      await errorLogger.log(
        ErrorLayer.services,
        Exception('rate limit'),
        StackTrace.empty,
        context: <String, Object?>{
          'station_id': 'abc-123',
          'country': 'fr',
          'attempt': 2,
        },
      );

      final rendered = recorder.calls.single.error.toString();
      expect(rendered, contains('station_id'));
      expect(rendered, contains('abc-123'));
      expect(rendered, contains('country'));
      expect(rendered, contains('attempt'));
    });

    test('null context renders without a context= clause', () async {
      await errorLogger.log(
        ErrorLayer.ui,
        Exception('layout failure'),
        StackTrace.empty,
      );
      expect(
        recorder.calls.single.error.toString(),
        isNot(contains('context=')),
      );
    });

    test('log never throws when the recorder throws', () async {
      errorLogger.testRecorderOverride = _ThrowingRecorder();
      // Must complete without re-raising.
      await expectLater(
        errorLogger.log(
          ErrorLayer.other,
          Exception('inner'),
          StackTrace.empty,
        ),
        completes,
      );
    });
  });

  group('ErrorLogger background-isolate path (spool)', () {
    final spoolCalls = <_SpoolCall>[];

    setUp(() {
      errorLogger.resetForTest();
      spoolCalls.clear();
      errorLogger.spoolEnqueueOverride = ({
        required String isolateTaskName,
        required Object error,
        StackTrace? stack,
        Map<String, dynamic>? contextMap,
        DateTime? timestamp,
      }) async {
        spoolCalls
            .add(_SpoolCall(isolateTaskName, error, stack, contextMap));
      };
    });

    tearDown(() {
      errorLogger.resetForTest();
    });

    test('writes to the spool when no container is bound', () async {
      await errorLogger.log(
        ErrorLayer.isolate,
        Exception('bg task crashed'),
        StackTrace.fromString('bg-stack'),
        context: <String, Object?>{
          'task': 'price_refresh',
          'attempt': 1,
        },
      );

      expect(spoolCalls, hasLength(1));
      final call = spoolCalls.single;
      // Layer name is propagated as the isolate task name so spool
      // entries are filterable by layer through replay.
      expect(call.isolateTaskName, 'isolate');
      expect(call.error, isA<Exception>());
      expect(call.stack.toString(), contains('bg-stack'));
      // Context map carries the layer + caller-supplied keys.
      expect(call.contextMap?['errorLayer'], 'isolate');
      expect(call.contextMap?['task'], 'price_refresh');
      expect(call.contextMap?['attempt'], 1);
    });

    test('passes original error object through to spool unchanged',
        () async {
      final original = StateError('original');
      await errorLogger.log(
        ErrorLayer.background,
        original,
        StackTrace.empty,
      );
      expect(spoolCalls.single.error, same(original));
    });

    test('captures StackTrace.current when stack is null in spool path',
        () async {
      await errorLogger.log(
        ErrorLayer.background,
        Exception('boom'),
        null,
      );
      expect(spoolCalls.single.stack, isNotNull);
      expect(spoolCalls.single.stack.toString(), isNotEmpty);
    });

    test('log never throws when the spool throws', () async {
      errorLogger.spoolEnqueueOverride = ({
        required String isolateTaskName,
        required Object error,
        StackTrace? stack,
        Map<String, dynamic>? contextMap,
        DateTime? timestamp,
      }) async {
        throw StateError('spool unavailable');
      };

      await expectLater(
        errorLogger.log(
          ErrorLayer.isolate,
          Exception('inner'),
          StackTrace.empty,
        ),
        completes,
      );
    });

    test('isForegroundBound is false without a recorder or container',
        () {
      expect(errorLogger.isForegroundBound, isFalse);
    });
  });

  group('ErrorLogger isForegroundBound flag', () {
    setUp(() => errorLogger.resetForTest());
    tearDown(() => errorLogger.resetForTest());

    test('flips to true once a test recorder is set', () {
      expect(errorLogger.isForegroundBound, isFalse);
      errorLogger.testRecorderOverride = _FakeTraceRecorder();
      expect(errorLogger.isForegroundBound, isTrue);
    });
  });
}

class _ThrowingRecorder implements TraceRecorder {
  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    throw StateError('recorder broken');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
