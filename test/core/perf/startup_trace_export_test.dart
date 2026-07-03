// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/perf/startup_timer.dart';
import 'package:tankstellen/core/perf/startup_trace_export.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';

/// #3383 — the startup-init trace export turns the absolute [StartupTimer]
/// milestones into per-phase spans + a canonical JSON document.
void main() {
  group('StartupTraceExport.phases (#3383)', () {
    test('turns absolute milestones into leading-segment durations', () {
      final spans = StartupTraceExport.phases(const [
        StartupMilestone(name: 'binding', elapsedMs: 10),
        StartupMilestone(name: 'hive_init', elapsedMs: 250),
        StartupMilestone(name: 'first_frame', elapsedMs: 300),
      ]);

      expect(spans, [
        {'name': 'binding', 'atMs': 10, 'durationMs': 10},
        {'name': 'hive_init', 'atMs': 250, 'durationMs': 240},
        {'name': 'first_frame', 'atMs': 300, 'durationMs': 50},
      ]);
    });

    test('empty milestones → empty phases', () {
      expect(StartupTraceExport.phases(const []), isEmpty);
    });
  });

  group('StartupTraceExport.buildDocument (#3383)', () {
    test('carries schema, metadata, total + phases', () {
      final at = DateTime.utc(2026, 6, 20, 12, 0, 0);
      final doc = StartupTraceExport.buildDocument(
        milestones: const [
          StartupMilestone(name: 'binding', elapsedMs: 10),
          StartupMilestone(name: 'storage_ready', elapsedMs: 200),
        ],
        totalMs: 300,
        exportedAt: at,
        appVersion: '6.0.0+2026062001',
      );

      expect(doc['schema'], StartupTraceExport.schemaVersion);
      expect(doc['kind'], 'startupTrace');
      expect(doc['exportedAt'], at.toIso8601String());
      expect(doc['appVersion'], '6.0.0+2026062001');
      expect(doc['totalMs'], 300);
      expect((doc['phases'] as List), hasLength(2));
    });

    test('carries the launch-sync spans with counts (#3445)', () {
      final doc = StartupTraceExport.buildDocument(
        milestones: const [],
        totalMs: 300,
        exportedAt: DateTime.utc(2026, 7, 3),
        appVersion: '6.0.0',
        spans: const [
          StartupSpan(name: 'tanksync_init', startMs: 310, endMs: 900),
          StartupSpan(
            name: 'trips_merge',
            startMs: 900,
            endMs: 1400,
            attributes: {'table': 'trip_summaries', 'pulled': 4},
          ),
        ],
      );

      final spans = doc['spans'] as List;
      expect(spans, hasLength(2));
      expect(spans.first, {
        'name': 'tanksync_init',
        'startMs': 310,
        'endMs': 900,
        'durationMs': 590,
      });
      final trips = spans.last as Map<String, Object?>;
      expect(trips['durationMs'], 500);
      expect(trips['attributes'], {'table': 'trip_summaries', 'pulled': 4});
    });
  });

  group('StartupTraceExport.currentJson (#3383)', () {
    setUp(StartupTimer.instance.reset);
    tearDown(StartupTimer.instance.reset);

    test('serializes the live StartupTimer trace as valid JSON', () {
      StartupTimer.instance
        ..start()
        ..mark('binding')
        ..mark('storage_ready')
        ..finish();

      final decoded =
          jsonDecode(StartupTraceExport.currentJson()) as Map<String, Object?>;
      expect(decoded['kind'], 'startupTrace');
      final phases = decoded['phases'] as List;
      expect(phases.map((p) => (p as Map)['name']),
          containsAllInOrder(['binding', 'storage_ready']));
    });
  });

  group('StartupTraceExport.ensureExtraExportSectionRegistered (#3383)', () {
    tearDown(() {
      TraceStorage.extraExportSections.remove(StartupTraceExport.exportSectionKey);
      StartupTimer.instance.reset();
    });

    test('registers a supplier that rides the error-log export', () {
      StartupTimer.instance
        ..start()
        ..mark('binding')
        ..finish();
      StartupTraceExport.ensureExtraExportSectionRegistered();

      final supplier =
          TraceStorage.extraExportSections[StartupTraceExport.exportSectionKey];
      expect(supplier, isNotNull);
      final section = supplier!() as Map<String, Object?>;
      expect(section['phases'], isA<List<Object?>>());
      expect((section['phases'] as List), isNotEmpty);
    });

    test('section carries post-finish launch-sync spans (#3445)', () {
      StartupTimer.instance
        ..start()
        ..finish()
        ..addSpan('tanksync_init', startMs: 300, endMs: 700, attributes: {
          'table': 'vehicles',
          'pulled': 2,
        });
      StartupTraceExport.ensureExtraExportSectionRegistered();

      final section = TraceStorage
          .extraExportSections[StartupTraceExport.exportSectionKey]!() as Map;
      final spans = section['spans'] as List;
      expect((spans.single as Map)['name'], 'tanksync_init');
      expect(((spans.single as Map)['attributes'] as Map)['pulled'], 2);
    });
  });
}
