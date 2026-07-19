// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_persistence.dart';
import 'package:tankstellen/core/telemetry/crash_forensics_harvester.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';

/// #3580/#3581 — crash forensics + the sync episode gate.
class _CapturingRecorder implements TraceRecorder {
  final List<Object> errors = [];
  final List<StackTrace> stacks = [];

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    errors.add(error);
    stacks.add(stackTrace);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CrashForensicsHarvester (#3580)', () {
    late _CapturingRecorder recorder;

    setUp(() {
      recorder = _CapturingRecorder();
      errorLogger.testRecorderOverride = recorder;
    });

    tearDown(() {
      errorLogger.resetForTest();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('tankstellen/crash_forensics'), null);
    });

    void mockHarvest(Object payload) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('tankstellen/crash_forensics'),
        (call) async => jsonEncode(payload),
      );
    }

    test('an uncaught JVM crash + an OOM exit each become a logged trace '
        'with the journaled stack surfaced as the stack trace', () async {
      mockHarvest({
        'uncaught': [
          {
            'timestampMs': 1783990000000,
            'thread': 'main',
            'error': 'java.lang.NullPointerException: boom',
            'stack': 'java.lang.NullPointerException: boom\n'
                '\tat de.tankstellen.Obd2ClassicPlugin.read(Obd2ClassicPlugin.kt:42)',
          },
        ],
        'exits': [
          {
            'timestampMs': 1783990100000,
            'reason': 'low_memory_kill',
            'importance': 'background',
            'description': '',
            'pssKb': 250000,
            'rssKb': 300000,
            'trace': '',
          },
        ],
      });

      await CrashForensicsHarvester.harvestAndLog();
      // The logs are fire-and-forget; drain the microtask queue.
      await Future<void>.delayed(Duration.zero);

      expect(recorder.errors, hasLength(2));
      expect(recorder.errors[0].toString(),
          contains('uncaught java.lang.NullPointerException'));
      expect(recorder.stacks[0].toString(),
          contains('Obd2ClassicPlugin.kt:42'),
          reason: 'the journaled JVM stack IS the trace stack');
      expect(recorder.errors[1].toString(), contains('low_memory_kill'));
      expect(recorder.errors[1].toString(), contains('background'));
    });

    test('routine freezer exits are skipped; a missing channel is a no-op',
        () async {
      mockHarvest({
        'uncaught': <Map<String, Object?>>[],
        'exits': [
          {'timestampMs': 1, 'reason': 'freezer', 'importance': 'background'},
        ],
      });
      await CrashForensicsHarvester.harvestAndLog();
      await Future<void>.delayed(Duration.zero);
      expect(recorder.errors, isEmpty,
          reason: 'OS freezer reclaims are normal lifecycle, not errors');

      // No handler at all (iOS / tests): silently does nothing.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('tankstellen/crash_forensics'), null);
      await CrashForensicsHarvester.harvestAndLog();
      expect(recorder.errors, isEmpty);
    });

    test('never throws: a faulting channel or garbage payload returns '
        'normally (#2349 contract)', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('tankstellen/crash_forensics'),
        (call) async => throw PlatformException(code: 'boom'),
      );
      await expectLater(CrashForensicsHarvester.harvestAndLog(), completes);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('tankstellen/crash_forensics'),
        (call) async => 'not json at all {',
      );
      await expectLater(CrashForensicsHarvester.harvestAndLog(), completes);
      expect(recorder.errors, isEmpty,
          reason: 'forensics faults are debugPrint-only, never traces');
    });
  });

  group('BreadcrumbPersistence (#3580)', () {
    tearDown(BreadcrumbPersistence.resetForTest);

    test('the ring survives a simulated process death and feeds lastRun',
        () async {
      final dir = Directory.systemTemp.createTempSync('crumbs_');
      addTearDown(() => dir.deleteSync(recursive: true));

      BreadcrumbCollector.clear();
      await BreadcrumbPersistence.init(dir.path);
      BreadcrumbCollector.add('trip:start', detail: 'gpsOnly');
      BreadcrumbCollector.add('obd2-link: connecting');
      // Wait past the debounce so the mirror flushes.
      await Future<void>.delayed(
          BreadcrumbPersistence.flushInterval + const Duration(seconds: 1));

      // Simulated crash + relaunch: fresh statics, same directory.
      BreadcrumbPersistence.resetForTest();
      BreadcrumbCollector.clear();
      await BreadcrumbPersistence.init(dir.path);

      expect(BreadcrumbPersistence.lastRun, hasLength(2));
      final summary = BreadcrumbPersistence.lastRunSummary();
      expect(summary, contains('trip:start'));
      expect(summary, contains('gpsOnly'));
      expect(summary, contains('obd2-link: connecting'));
    });
  });

  group('sync episode gate (#3581)', () {
    late _CapturingRecorder recorder;

    setUp(() {
      recorder = _CapturingRecorder();
      errorLogger.testRecorderOverride = recorder;
      errorLogger.resetSyncEpisodeForTest();
    });

    tearDown(errorLogger.resetForTest);

    test('identical sync failures collapse into one trace; the next '
        'different signature carries the suppressed count', () async {
      final handshake = Exception('HandshakeException: Handshake error');
      for (var i = 0; i < 40; i++) {
        await errorLogger.log(ErrorLayer.sync, handshake, StackTrace.current);
      }
      expect(recorder.errors, hasLength(1),
          reason: 'one trace per outage episode, not one per retry');

      await errorLogger.log(
          ErrorLayer.sync, Exception('different failure'), StackTrace.current);
      expect(recorder.errors, hasLength(2));
      expect(recorder.errors.last.toString(),
          contains('previousSyncEpisodeSuppressed: 39'),
          reason: 'the episode summary must carry the suppressed count');
    });

    test('non-sync layers are never gated', () async {
      final same = Exception('same error');
      await errorLogger.log(ErrorLayer.ui, same, StackTrace.current);
      await errorLogger.log(ErrorLayer.ui, same, StackTrace.current);
      expect(recorder.errors, hasLength(2));
    });
  });
}
