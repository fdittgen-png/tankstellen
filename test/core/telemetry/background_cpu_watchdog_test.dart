// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3641 — the background CPU watchdog: /proc stat parsing, the
// two-hot-windows report flow with per-thread attribution, the report
// rate limit, and the fail-open (disarm, never throw) contract.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/telemetry/background_cpu_watchdog.dart';

import '../../helpers/silence_error_logger.dart';

/// A minimal but realistic `/proc/<pid>/stat` line. [comm] deliberately
/// exercises the parens-and-spaces trap ("(Signal Catcher)").
String _statLine({required String comm, required int utime, int stime = 0}) =>
    '12345 ($comm) S 1 12345 0 0 -1 1077936448 2500 0 1 0 '
    '$utime $stime 33 44 20 0 42 0 12345678 999424 12345 '
    '18446744073709551615 1 1 0 0 0 0 0 4096 0 0 0 0 17 3 0 0 0 0 0';

void main() {
  silenceErrorLoggerSpool();

  group('proc stat parsing', () {
    test('utime+stime extracted; comm with spaces and parens survives', () {
      final line = _statLine(comm: 'Signal (Catcher)', utime: 120, stime: 30);
      expect(parseProcStatCpuJiffies(line), 150);
      expect(parseProcStatComm(line), 'Signal (Catcher)');
    });

    test('malformed input → null, never a throw', () {
      expect(parseProcStatCpuJiffies(''), isNull);
      expect(parseProcStatCpuJiffies('no parens at all'), isNull);
      expect(parseProcStatCpuJiffies('1 (x) S 2'), isNull);
      expect(parseProcStatComm(''), isNull);
    });
  });

  group('watchdog windows', () {
    late DateTime now;
    late Map<String, String> files;
    late List<String> reports;

    BackgroundCpuWatchdog build({Duration gap = const Duration(minutes: 10)}) =>
        BackgroundCpuWatchdog(
          readFile: (path) => files[path],
          listThreadStatPaths: () => files.keys
              .where((p) => p.startsWith('/proc/self/task/'))
              .toList(),
          now: () => now,
          minReportGap: gap,
          platformSupported: true,
          onReport: reports.add,
        );

    setUp(() {
      now = DateTime(2026, 7, 29, 23, 0);
      reports = [];
      files = {
        '/proc/self/stat': _statLine(comm: 'main', utime: 1000),
        '/proc/self/task/101/stat': _statLine(comm: 'main', utime: 500),
        '/proc/self/task/202/stat': _statLine(comm: 'spinner', utime: 500),
      };
    });

    void tickAfter(BackgroundCpuWatchdog dog, Duration wall,
        {required int processJiffies, int spinnerJiffies = 500}) {
      now = now.add(wall);
      files['/proc/self/stat'] =
          _statLine(comm: 'main', utime: processJiffies);
      files['/proc/self/task/202/stat'] =
          _statLine(comm: 'spinner', utime: spinnerJiffies);
      dog.tick();
    }

    test('a cool window reports nothing', () {
      final dog = build()..start();
      // 60 s window, 600 ms CPU = 1%.
      tickAfter(dog, const Duration(seconds: 60), processJiffies: 1060);
      expect(reports, isEmpty);
      dog.stop();
    });

    test('two hot windows → one report naming the burning thread', () {
      final dog = build()..start();
      // Window 1: 3000 jiffies = 30 s CPU over 60 s = 50% — arms the
      // per-thread baseline, no report yet.
      tickAfter(dog, const Duration(seconds: 60), processJiffies: 4000);
      expect(reports, isEmpty, reason: 'first hot window only arms');
      // Window 2: still hot; the spinner thread ate the delta.
      tickAfter(dog, const Duration(seconds: 60),
          processJiffies: 7000, spinnerJiffies: 3400);
      expect(reports, hasLength(1));
      expect(reports.single, contains('50%'));
      expect(reports.single, contains('spinner#202:+29000ms'),
          reason: 'the per-thread delta names the culprit');
    });

    test('reports are rate-limited; a cool window disarms the baseline', () {
      final dog = build()..start();
      tickAfter(dog, const Duration(seconds: 60), processJiffies: 4000);
      tickAfter(dog, const Duration(seconds: 60),
          processJiffies: 7000, spinnerJiffies: 3400);
      expect(reports, hasLength(1));
      // Still hot immediately after: inside the gap — no second report.
      tickAfter(dog, const Duration(seconds: 60),
          processJiffies: 10000, spinnerJiffies: 6400);
      expect(reports, hasLength(1));
      // Cool window: baseline disarmed…
      tickAfter(dog, const Duration(seconds: 60), processJiffies: 10060);
      // …so a single hot window after the gap still only ARMS. (The
      // silent 10-min jump stretches the wall window to 11 min, so the
      // CPU delta must be ≥25% of 660 s to read hot.)
      now = now.add(const Duration(minutes: 10));
      tickAfter(dog, const Duration(seconds: 60), processJiffies: 27100);
      expect(reports, hasLength(1),
          reason: 're-armed, not yet re-reported');
    });

    test('a degenerate wall window (deep sleep) proves nothing', () {
      final dog = build()..start();
      tickAfter(dog, const Duration(seconds: 5), processJiffies: 4000);
      expect(reports, isEmpty,
          reason: 'a 5 s wall window under a 60 s cadence is discarded');
    });

    test('fault injection: a throwing proc read disarms without throwing',
        () {
      var boom = false;
      final dog = BackgroundCpuWatchdog(
        readFile: (path) {
          if (boom) throw StateError('proc read failed');
          return files[path];
        },
        listThreadStatPaths: () => const [],
        now: () => now,
        platformSupported: true,
        onReport: reports.add,
      )..start();
      expect(dog.isRunning, isTrue);
      boom = true;
      now = now.add(const Duration(seconds: 60));
      expect(dog.tick, returnsNormally);
      expect(dog.isRunning, isFalse,
          reason: 'forensics must never hurt the app: fail open, disarm');
    });

    test('unsupported platform: start is a no-op', () {
      final dog = BackgroundCpuWatchdog(
        readFile: (path) => files[path],
        listThreadStatPaths: () => const [],
        now: () => now,
        platformSupported: false,
      )..start();
      expect(dog.isRunning, isFalse);
    });
  });
}
