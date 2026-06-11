// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/app_log.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';

/// Captures every `record` call without standing up a real
/// TraceStorage / TraceUploader / Riverpod stack. Mirrors the fake in
/// `test/core/logging/error_logger_test.dart`.
class _FakeTraceRecorder implements TraceRecorder {
  final calls = <(Object, StackTrace)>[];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    calls.add((error, stackTrace));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  late _FakeTraceRecorder recorder;
  late List<String> console;

  setUp(() {
    errorLogger.resetForTest();
    recorder = _FakeTraceRecorder();
    errorLogger.testRecorderOverride = recorder;
    BreadcrumbCollector.clear();
    console = <String>[];
    log.resetForTest();
    log.debugConsoleOverride = true;
    log.consoleSinkOverride = console.add;
  });

  tearDown(() {
    errorLogger.resetForTest();
    log.resetForTest();
    BreadcrumbCollector.clear();
  });

  group('level routing (#3144)', () {
    test('debug: console only — no breadcrumb, no trace', () async {
      log.debug('chatter', tag: 'unit');
      await Future<void>.delayed(Duration.zero);

      expect(console, ['[unit] chatter']);
      expect(BreadcrumbCollector.snapshot(), isEmpty);
      expect(recorder.calls, isEmpty);
    });

    test('debug: fully silent when the console gate is off (release)', () {
      log.debugConsoleOverride = false;
      log.debug('chatter');

      expect(console, isEmpty);
    });

    test('info: console + breadcrumb, but never a trace-ring slot',
        () async {
      log.info('sync ready', tag: 'TankSync');
      await Future<void>.delayed(Duration.zero);

      expect(console, ['[TankSync] sync ready']);
      final crumbs = BreadcrumbCollector.snapshot();
      expect(crumbs, hasLength(1));
      expect(crumbs.single.action, 'TankSync');
      expect(crumbs.single.detail, 'sync ready');
      expect(recorder.calls, isEmpty,
          reason: 'info must not consume a slot in the bounded trace ring');
    });

    test('info: breadcrumb survives with the console gate off (release '
        'visibility)', () {
      log.debugConsoleOverride = false;
      log.info('migrated 3 profiles');

      expect(console, isEmpty);
      expect(BreadcrumbCollector.snapshot(), hasLength(1));
    });

    test('warn: routes to the errorLogger pipeline tagged level=warn',
        () async {
      log.warn('soft 429 from provider',
          tag: 'api', layer: ErrorLayer.services, context: {'country': 'es'});
      await Future<void>.delayed(Duration.zero);

      expect(recorder.calls, hasLength(1));
      final rendered = recorder.calls.single.$1.toString();
      expect(rendered, contains('[services]'));
      expect(rendered, contains('soft 429 from provider'));
      expect(rendered, contains('level: warn'));
      expect(rendered, contains('country: es'));
    });

    test('warn: forwards a caught error object + keeps the message',
        () async {
      final boom = StateError('boom');
      log.warn('scrub failed', error: boom, stack: StackTrace.current);
      await Future<void>.delayed(Duration.zero);

      final rendered = recorder.calls.single.$1.toString();
      expect(rendered, contains('boom'));
      expect(rendered, contains('scrub failed'));
    });

    test('error: delegates to errorLogger unchanged', () async {
      final stack = StackTrace.fromString('#0 unit (file.dart:1)');
      log.error(Exception('hard fail'), stack,
          layer: ErrorLayer.sync, context: {'where': 'unit'});
      await Future<void>.delayed(Duration.zero);

      expect(recorder.calls, hasLength(1));
      expect(recorder.calls.single.$2, same(stack));
      final rendered = recorder.calls.single.$1.toString();
      expect(rendered, contains('[sync]'));
      expect(rendered, contains('hard fail'));
    });
  });

  group('never-throws contract (fault injection)', () {
    test('debug/info return normally when the console sink throws', () {
      log.consoleSinkOverride = (_) => throw StateError('sink fault');

      expect(() => log.debug('x'), returnsNormally);
      expect(() => log.info('x'), returnsNormally);
    });

    test('warn returns normally when the console sink throws', () {
      log.consoleSinkOverride = (_) => throw StateError('sink fault');

      expect(() => log.warn('x'), returnsNormally);
    });

    test('warn/error return normally when the recorder throws', () async {
      // ErrorLogger.log's own never-throws contract absorbs a throwing
      // recorder; the facade must not re-surface it either.
      errorLogger.testRecorderOverride = _ThrowingRecorder();

      expect(() => log.warn('x'), returnsNormally);
      expect(() => log.error(Exception('x'), null), returnsNormally);
      await Future<void>.delayed(Duration.zero);
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
    throw StateError('recorder fault');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
