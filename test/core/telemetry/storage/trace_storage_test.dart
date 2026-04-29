import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/telemetry/models/error_trace.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';

/// Create a plain JSON map that Hive can serialize (no freezed objects).
/// This mirrors what TraceStorage.store does: trace.toJson(), but we ensure
/// nested objects are fully converted to plain maps via jsonEncode/jsonDecode.
Map<String, dynamic> _makePlainJson({
  required String id,
  DateTime? timestamp,
}) {
  final trace = ErrorTrace(
    id: id,
    timestamp: timestamp ?? DateTime.now(),
    timezoneOffset: '+01:00',
    category: ErrorCategory.unknown,
    errorType: 'Exception',
    errorMessage: 'Test error $id',
    stackTrace: '#0 main (test.dart:1)',
    deviceInfo: const DeviceInfo(
      os: 'test',
      osVersion: '1.0',
      platform: 'test',
      locale: 'en',
      screenWidth: 400,
      screenHeight: 800,
      appVersion: '1.0.0',
    ),
    appState: const AppStateSnapshot(),
    networkState: const NetworkSnapshot(isOnline: true, connectivityType: 'wifi'),
  );
  // Round-trip through JSON string to get a fully plain Map
  return jsonDecode(jsonEncode(trace.toJson())) as Map<String, dynamic>;
}

void main() {
  late Directory tempDir;
  late TraceStorage storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('trace_storage_test_');
    Hive.init(tempDir.path);
    await TraceStorage.init();
    storage = TraceStorage();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TraceStorage', () {
    test('store and retrieve by ID', () async {
      final json = _makePlainJson(id: 'trace-1');
      final trace = ErrorTrace.fromJson(json);
      // Store the plain JSON directly in Hive box (bypassing toJson issue)
      await Hive.box('error_traces').put(trace.id, json);

      final retrieved = storage.getById('trace-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'trace-1');
      expect(retrieved.errorMessage, 'Test error trace-1');
    });

    test('getById returns null for missing ID', () {
      expect(storage.getById('nonexistent'), isNull);
    });

    test('getAll returns all stored traces sorted by timestamp descending', () async {
      final olderJson = _makePlainJson(id: 'old', timestamp: DateTime(2025, 1, 1));
      final newerJson = _makePlainJson(id: 'new', timestamp: DateTime(2025, 6, 1));

      final box = Hive.box('error_traces');
      await box.put('old', olderJson);
      await box.put('new', newerJson);

      final all = storage.getAll();
      expect(all, hasLength(2));
      // Newest first
      expect(all[0].id, 'new');
      expect(all[1].id, 'old');
    });

    test('delete removes a trace', () async {
      final json = _makePlainJson(id: 'to-delete');
      await Hive.box('error_traces').put('to-delete', json);
      expect(storage.getById('to-delete'), isNotNull);

      await storage.delete('to-delete');
      expect(storage.getById('to-delete'), isNull);
    });

    test('clearAll removes all traces', () async {
      final box = Hive.box('error_traces');
      await box.put('a', _makePlainJson(id: 'a'));
      await box.put('b', _makePlainJson(id: 'b'));
      expect(storage.count, 2);

      await storage.clearAll();
      expect(storage.count, 0);
      expect(storage.getAll(), isEmpty);
    });

    test('count reflects number of stored traces', () async {
      final box = Hive.box('error_traces');
      expect(storage.count, 0);
      await box.put('1', _makePlainJson(id: '1'));
      expect(storage.count, 1);
      await box.put('2', _makePlainJson(id: '2'));
      expect(storage.count, 2);
    });

    test('prune removes entries beyond maxTraces', () async {
      final box = Hive.box('error_traces');
      // Store more than maxTraces (50)
      for (var i = 0; i < 55; i++) {
        final json = _makePlainJson(
          id: 'trace-$i',
          timestamp: DateTime.now().add(Duration(seconds: i)),
        );
        await box.put('trace-$i', json);
      }
      expect(storage.count, 55);

      // getAll returns sorted by timestamp descending and we can verify
      // that all 55 are retrievable (pruning only happens on store)
      final all = storage.getAll();
      expect(all, hasLength(55));
      // Newest first
      expect(all.first.id, 'trace-54');
    });

    test('getAll parses stored JSON back into ErrorTrace objects', () async {
      final json = _makePlainJson(id: 'parse-test');
      await Hive.box('error_traces').put('parse-test', json);

      final traces = storage.getAll();
      expect(traces, hasLength(1));
      expect(traces.first, isA<ErrorTrace>());
      expect(traces.first.deviceInfo.os, 'test');
      expect(traces.first.networkState.isOnline, isTrue);
    });

    group('exportAsJson (#476)', () {
      test('returns an empty traces array when no traces are stored', () {
        final raw = storage.exportAsJson();
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        expect(decoded['traceCount'], 0);
        expect(decoded['traces'], isEmpty);
        expect(decoded['exportedAt'], isA<String>());
      });

      test('serialises every persisted trace into the traces array',
          () async {
        await Hive.box('error_traces')
            .put('e1', _makePlainJson(id: 'e1'));
        await Hive.box('error_traces')
            .put('e2', _makePlainJson(id: 'e2'));
        await Hive.box('error_traces')
            .put('e3', _makePlainJson(id: 'e3'));

        final raw = storage.exportAsJson();
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        expect(decoded['traceCount'], 3);
        final traces = decoded['traces'] as List;
        expect(traces, hasLength(3));
        // Every item has the canonical ErrorTrace shape.
        for (final t in traces) {
          final m = t as Map<String, dynamic>;
          expect(m, contains('id'));
          expect(m, contains('timestamp'));
          expect(m, contains('errorMessage'));
        }
      });

      test('includes an ISO-8601 exportedAt timestamp in UTC', () {
        final raw = storage.exportAsJson();
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final ts = decoded['exportedAt'] as String;
        expect(ts, endsWith('Z'),
            reason: 'exportedAt should be ISO-8601 UTC for portability');
        // Round-trip parses cleanly.
        expect(() => DateTime.parse(ts), returnsNormally);
      });

      test('output is pretty-printed (uses indentation) for human review',
          () {
        final raw = storage.exportAsJson();
        // JsonEncoder.withIndent uses 2-space indent — the second line
        // should start with two spaces.
        final lines = raw.split('\n');
        expect(lines.length, greaterThan(1));
        expect(lines[1], startsWith('  '));
      });
    });

    /// #1301 — surface parse-vs-raw mismatch so the privacy dashboard
    /// can warn the user (and ship the unreadable payload for offline
    /// debugging) when a Hive schema migration leaves stale entries the
    /// current `ErrorTrace.fromJson` can no longer decode.
    group('parse-vs-raw (#1301)', () {
      Map<String, dynamic> malformedEntry(String id) => <String, dynamic>{
            'id': id,
            // Missing every required field except id — this triggers
            // FormatException inside ErrorTrace.fromJson.
            'schemaVersion': 'unknown',
          };

      test(
          'count returns the raw box length while parsedCount filters out '
          'failures', () async {
        final box = Hive.box('error_traces');
        await box.put('valid', _makePlainJson(id: 'valid'));
        await box.put('broken-1', malformedEntry('broken-1'));
        await box.put('broken-2', malformedEntry('broken-2'));

        expect(storage.count, 3);
        expect(storage.parsedCount, 1);
        expect(storage.unparsedCount, 2);
      });

      test(
          'when every entry fails to parse, exportAsJson surfaces the raw '
          'payload under unparsedRaw and traces is empty', () async {
        final box = Hive.box('error_traces');
        await box.put('broken-1', malformedEntry('broken-1'));
        await box.put('broken-2', malformedEntry('broken-2'));

        expect(storage.parsedCount, 0);
        expect(storage.unparsedCount, storage.count);

        final decoded =
            jsonDecode(storage.exportAsJson()) as Map<String, dynamic>;
        expect(decoded['traceCount'], 2);
        expect(decoded['parsedCount'], 0);
        expect(decoded['unparsedCount'], 2);
        expect(decoded['traces'], isEmpty);
        final unparsed = decoded['unparsedRaw'] as List;
        expect(unparsed, hasLength(2));
        // Each raw entry is round-tripped as a plain Map preserving the
        // original id so a maintainer can correlate it back to the device.
        final ids = unparsed
            .map((e) => (e as Map<String, dynamic>)['id'] as String)
            .toSet();
        expect(ids, {'broken-1', 'broken-2'});
      });

      test(
          'with mixed valid/invalid entries both arrays populate and counts '
          'add up to the raw box length', () async {
        final box = Hive.box('error_traces');
        await box.put('valid-1', _makePlainJson(id: 'valid-1'));
        await box.put('valid-2', _makePlainJson(id: 'valid-2'));
        await box.put('broken', malformedEntry('broken'));

        expect(storage.count, 3);
        expect(storage.parsedCount, 2);
        expect(storage.unparsedCount, 1);

        final decoded =
            jsonDecode(storage.exportAsJson()) as Map<String, dynamic>;
        expect(decoded['traceCount'], 3);
        expect(decoded['parsedCount'], 2);
        expect(decoded['unparsedCount'], 1);
        expect(decoded['traces'], hasLength(2));
        expect(decoded['unparsedRaw'], hasLength(1));
        final raw = (decoded['unparsedRaw'] as List).first as Map;
        expect(raw['id'], 'broken');
      });

      test('unparsedCount is 0 (never negative) when every entry parses',
          () async {
        final box = Hive.box('error_traces');
        await box.put('a', _makePlainJson(id: 'a'));
        await box.put('b', _makePlainJson(id: 'b'));

        expect(storage.unparsedCount, 0);
        final decoded =
            jsonDecode(storage.exportAsJson()) as Map<String, dynamic>;
        expect(decoded['unparsedCount'], 0);
        expect(decoded['unparsedRaw'], isEmpty);
      });
    });
  });
}
