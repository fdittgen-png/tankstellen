// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/diagnostics/data_access_event.dart';
import 'package:tankstellen/core/services/diagnostics/data_access_recorder.dart';
import 'package:tankstellen/core/services/diagnostics/data_access_trace.dart';
import 'package:tankstellen/core/services/service_result.dart';

/// Builds a [DataAccessEvent] with a monotonic stamp in SECONDS (×1e6) so the
/// interval math reads in plain seconds.
DataAccessEvent _event({
  required String country,
  required ServiceSource source,
  required DataAccessHit hit,
  required double atSec,
  DataAccessEndpoint endpoint = DataAccessEndpoint.searchGeo,
  int? count,
}) =>
    DataAccessEvent(
      at: DateTime.utc(2026, 1, 1),
      monotonicMicros: (atSec * 1e6).round(),
      country: country,
      source: source.name,
      endpoint: endpoint,
      hit: hit,
      resultCount: count,
    );

void main() {
  group('DataAccessTrace.aggregates — cache-hit ratio', () {
    test('ratio is 1 - network/total per country|source group', () {
      final trace = DataAccessTrace(
        capturedAt: DateTime.utc(2026, 1, 1),
        events: [
          _event(
              country: 'FR',
              source: ServiceSource.prixCarburantsApi,
              hit: DataAccessHit.networkApi,
              atSec: 0),
          _event(
              country: 'FR',
              source: ServiceSource.prixCarburantsApi,
              hit: DataAccessHit.hiveFresh,
              atSec: 1),
          _event(
              country: 'FR',
              source: ServiceSource.prixCarburantsApi,
              hit: DataAccessHit.hiveFresh,
              atSec: 2),
          _event(
              country: 'FR',
              source: ServiceSource.prixCarburantsApi,
              hit: DataAccessHit.coalesced,
              atSec: 3),
        ],
      );

      final agg = trace.aggregates().single;
      expect(agg.requestCount, 4);
      expect(agg.networkCount, 1);
      // 1 network out of 4 → 0.75 cache-hit ratio.
      expect(agg.cacheHitRatio, 0.75);
    });
  });

  group('DataAccessTrace.aggregates — grouping by country|source', () {
    test('separates same source across countries and same country across '
        'sources', () {
      final trace = DataAccessTrace(
        capturedAt: DateTime.utc(2026, 1, 1),
        events: [
          _event(
              country: 'FR',
              source: ServiceSource.prixCarburantsApi,
              hit: DataAccessHit.networkApi,
              atSec: 0),
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 0),
          // Same FR country, different (cache) source → its own group.
          _event(
              country: 'FR',
              source: ServiceSource.cache,
              hit: DataAccessHit.hiveStale,
              atSec: 1),
        ],
      );

      final aggs = trace.aggregates();
      expect(aggs.length, 3);
      // First-seen order is preserved.
      expect(aggs[0].country, 'FR');
      expect(aggs[0].source, ServiceSource.prixCarburantsApi.name);
      expect(aggs[1].country, 'DE');
      expect(aggs[2].source, ServiceSource.cache.name);
    });
  });

  group('DataAccessTrace.aggregates — intervals from NETWORK events only', () {
    test('min/median computed from consecutive network monotonic deltas, '
        'ignoring cache events in between', () {
      final trace = DataAccessTrace(
        capturedAt: DateTime.utc(2026, 1, 1),
        events: [
          // Network at 0s.
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 0),
          // A cache hit at 30s must NOT count as a network interval boundary.
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.hiveFresh,
              atSec: 30),
          // Network at 100s → gap from previous network = 100s.
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 100),
          // Network at 160s → gap = 60s.
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 160),
          // Network at 240s → gap = 80s.
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 240),
        ],
      );

      final agg = trace.aggregates().single;
      expect(agg.networkCount, 4);
      // Gaps between consecutive network events: 100, 60, 80.
      expect(agg.networkIntervalsSec, [100, 60, 80]);
      expect(agg.minNetworkIntervalSec, 60);
      // Median of [60, 80, 100] = 80.
      expect(agg.medianNetworkIntervalSec, 80);
    });

    test('median of an even gap count averages the two middle values', () {
      final trace = DataAccessTrace(
        capturedAt: DateTime.utc(2026, 1, 1),
        events: [
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 0),
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 10), // gap 10
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 30), // gap 20
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 70), // gap 40
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 150), // gap 80
        ],
      );
      // Four gaps [10, 20, 40, 80] → even count → median = (20 + 40) / 2 = 30.
      final agg = trace.aggregates().single;
      expect(agg.networkIntervalsSec, [10, 20, 40, 80]);
      expect(agg.medianNetworkIntervalSec, 30);
    });

    test('fewer than two network events → null intervals (nothing to space)',
        () {
      final trace = DataAccessTrace(
        capturedAt: DateTime.utc(2026, 1, 1),
        events: [
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 0),
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.hiveFresh,
              atSec: 50),
        ],
      );
      final agg = trace.aggregates().single;
      expect(agg.networkCount, 1);
      expect(agg.networkIntervalsSec, isEmpty);
      expect(agg.minNetworkIntervalSec, isNull);
      expect(agg.medianNetworkIntervalSec, isNull);
    });
  });

  group('DataAccessTrace.aggregates — compliance', () {
    test('compliant=true when min interval >= configured', () {
      final trace = DataAccessTrace(
        capturedAt: DateTime.utc(2026, 1, 1),
        configuredMinIntervalSec: const {'DE': 60},
        events: [
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 0),
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 90), // gap 90 >= 60
        ],
      );
      final agg = trace.aggregates().single;
      expect(agg.configuredMinIntervalSec, 60);
      expect(agg.minNetworkIntervalSec, 90);
      expect(agg.compliant, isTrue);
    });

    test('compliant=false when min interval < configured', () {
      final trace = DataAccessTrace(
        capturedAt: DateTime.utc(2026, 1, 1),
        configuredMinIntervalSec: const {'DE': 60},
        events: [
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 0),
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 5), // gap 5 < 60 → violation
        ],
      );
      final agg = trace.aggregates().single;
      expect(agg.compliant, isFalse);
    });

    test('compliant=null when no policy was configured for the country', () {
      final trace = DataAccessTrace(
        capturedAt: DateTime.utc(2026, 1, 1),
        events: [
          _event(
              country: 'XX',
              source: ServiceSource.cache,
              hit: DataAccessHit.networkApi,
              atSec: 0),
          _event(
              country: 'XX',
              source: ServiceSource.cache,
              hit: DataAccessHit.networkApi,
              atSec: 5),
        ],
      );
      final agg = trace.aggregates().single;
      expect(agg.configuredMinIntervalSec, isNull);
      expect(agg.compliant, isNull);
    });

    test('compliant=null when there is a policy but no measurable interval', () {
      final trace = DataAccessTrace(
        capturedAt: DateTime.utc(2026, 1, 1),
        configuredMinIntervalSec: const {'DE': 60},
        events: [
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 0),
        ],
      );
      final agg = trace.aggregates().single;
      expect(agg.minNetworkIntervalSec, isNull);
      expect(agg.compliant, isNull);
    });
  });

  group('DataAccessRecorder ring-buffer eviction', () {
    test('caps at maxEvents, evicting oldest-first', () {
      final recorder = DataAccessRecorder();
      // Push maxEvents + 5; the first 5 should be evicted.
      for (var i = 0; i < DataAccessRecorder.maxEvents + 5; i++) {
        recorder.add(DataAccessEvent(
          at: DateTime.utc(2026, 1, 1),
          monotonicMicros: i,
          country: 'DE',
          source: ServiceSource.tankerkoenigApi.name,
          endpoint: DataAccessEndpoint.searchGeo,
          hit: DataAccessHit.networkApi,
        ));
      }
      final events = recorder.events;
      expect(events.length, DataAccessRecorder.maxEvents);
      // Oldest surviving event is index 5 (0..4 evicted).
      expect(events.first.monotonicMicros, 5);
      expect(events.last.monotonicMicros, DataAccessRecorder.maxEvents + 4);
    });

    test('notePolicy ignores null minInterval, records non-null in seconds',
        () {
      final recorder = DataAccessRecorder();
      recorder.notePolicy('DE', const Duration(seconds: 60));
      recorder.notePolicy('XX', null);
      expect(recorder.configuredMinIntervalSec['DE'], 60);
      expect(recorder.configuredMinIntervalSec.containsKey('XX'), isFalse);
    });

    test('clear drops events and noted policies', () {
      final recorder = DataAccessRecorder()
        ..add(DataAccessEvent(
          at: DateTime.utc(2026, 1, 1),
          monotonicMicros: 0,
          country: 'DE',
          source: ServiceSource.tankerkoenigApi.name,
          endpoint: DataAccessEndpoint.searchGeo,
          hit: DataAccessHit.networkApi,
        ))
        ..notePolicy('DE', const Duration(seconds: 60))
        ..clear();
      expect(recorder.events, isEmpty);
      expect(recorder.configuredMinIntervalSec, isEmpty);
    });
  });

  group('serializer', () {
    test('toJson emits schema, dataAccess kind, aggregates and events', () {
      final trace = DataAccessTrace(
        capturedAt: DateTime.utc(2026, 1, 1, 12),
        comment: 'cold start',
        configuredMinIntervalSec: const {'DE': 60},
        events: [
          _event(
              country: 'DE',
              source: ServiceSource.tankerkoenigApi,
              hit: DataAccessHit.networkApi,
              atSec: 0,
              count: 7),
        ],
      );
      final json = trace.toJson();
      expect(json['schema'], DataAccessTrace.schema);
      expect(json['kind'], 'dataAccess');
      expect(json['comment'], 'cold start');
      expect((json['events'] as List).single['resultCount'], 7);
      expect((json['aggregates'] as List).single['networkCount'], 1);
      // Round-trips through the indented formatter.
      expect(formatDataAccessTraceJson(trace), contains('"kind": "dataAccess"'));
    });
  });
}
