// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/logging/error_logger.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/trace_recorder.dart';
import 'package:tankstellen/features/consumption/data/obd2/supported_pids_cache.dart';
import 'package:tankstellen/features/consumption/data/obd2/supported_pids_resolver.dart';

/// #2424 (follow-up to #2379) — [SupportedPidsResolver] is best-effort:
/// every catch site (prime, VIN-for-cache-key read, supported-PID scan)
/// already degrades gracefully on a flaky/slow ELM327. A transient there
/// (TimeoutException / concurrent-sendCommand StateError / device-not-
/// connected) flooded a real user's error log mis-tagged `[storage]`.
/// #2379 fixed the analogous floods elsewhere; this file pins the same
/// contract for the resolver: the recovered path produces ZERO traces.

/// Records every [errorLogger] trace so the test can assert on count —
/// mirrors `obd2_service_odometer_logging_test.dart` (#2379).
class _CaptureRecorder implements TraceRecorder {
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
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CaptureRecorder recorder;

  setUp(() {
    errorLogger.resetForTest();
    recorder = _CaptureRecorder();
    errorLogger.testRecorderOverride = recorder;
  });

  tearDown(errorLogger.resetForTest);

  group('SupportedPidsResolver transient → zero error traces (#2424)', () {
    test(
        'discoverSupportedPids: a send TimeoutException returns gracefully '
        'and logs NO error trace', () async {
      final resolver = SupportedPidsResolver(
        // Every supported-PID scan command times out — the flaky-adapter
        // scenario from the user logs.
        send: (_) async =>
            throw TimeoutException('ELM327 did not respond within 2.5s'),
        isConnected: () => true,
      );

      final pids = await resolver.discoverSupportedPids();

      expect(pids, isEmpty,
          reason: 'best-effort: a transient on the first scan command '
              'yields an empty set → caller blind-queries');
      expect(recorder.calls, isEmpty,
          reason: 'a transient supported-PID scan failure is expected/'
              'recoverable — it must not pollute the error log');
    });

    test(
        'discoverSupportedPids: the legacy concurrent-sendCommand '
        'StateError is also silent', () async {
      final resolver = SupportedPidsResolver(
        send: (_) async => throw StateError('A sendCommand is in flight'),
        isConnected: () => true,
      );

      final pids = await resolver.discoverSupportedPids();

      expect(pids, isEmpty);
      expect(recorder.calls, isEmpty,
          reason: 'the legacy concurrent-sendCommand StateError is a '
              'recoverable transient — no trace');
    });
  });

  group('SupportedPidsResolver.prime over a real cache (#2424)', () {
    late Directory tmpDir;
    late Box<String> box;
    late SupportedPidsCache cache;

    setUp(() async {
      tmpDir = Directory.systemTemp
          .createTempSync('supported_pids_resolver_logging_');
      Hive.init(tmpDir.path);
      box = await Hive.openBox<String>('supported_pids_resolver_logging');
      cache = SupportedPidsCache(box);
    });

    tearDown(() async {
      await box.deleteFromDisk();
      await Hive.close();
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test(
        'every send times out → prime returns quietly, _resolveVehicleCacheKey '
        'degrades to the fallback key, and ZERO traces are logged', () async {
      // No cache entry exists, so prime() falls through: fallback-key
      // probe misses → _resolveVehicleCacheKey reads the VIN (0902) which
      // TIMES OUT → it returns the fallback key → cache miss for that key
      // → discoverSupportedPids scans, which also TIMES OUT. Every catch
      // site on the path fires; none of them may log.
      final resolver = SupportedPidsResolver(
        send: (_) async =>
            throw TimeoutException('ELM327 did not respond within 2.5s'),
        isConnected: () => true,
        cache: cache,
        vehicleFallbackKey: 'aa:bb:cc:dd:ee:ff',
      );

      // Should complete without throwing — graceful degradation.
      await resolver.prime();

      expect(resolver.debugSupportedPids, isEmpty,
          reason: 'a fully-timing-out adapter leaves the set empty → '
              'blind query this session');
      expect(recorder.calls, isEmpty,
          reason: 'prime / VIN-read / scan transients are all expected & '
              'recoverable — the recovered path logs zero traces (#2379)');
    });
  });
}
