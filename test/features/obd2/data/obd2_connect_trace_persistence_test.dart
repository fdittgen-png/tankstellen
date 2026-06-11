// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/telemetry/storage/trace_storage.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_log.dart';
import 'package:tankstellen/features/obd2/data/obd2_connect_trace_persistence.dart';

/// #3184 — the connect-trace ring must survive an app kill. The canonical
/// field flow is "it won't connect" → force-quit → relaunch → export the
/// error log; the pre-#3184 in-memory-only ring shipped EMPTY through that
/// flow. These tests drive the real Hive box (temp dir) end-to-end:
/// persist-on-endTrace, hydrate-at-startup, retention caps, corrupt-entry
/// resilience, and the `obd2ConnectTraces` error-log export section.
void main() {
  late Directory tempDir;

  Obd2ConnectTrace makeTrace({
    required String id,
    required int startedAtMs,
    Obd2ConnectOutcome outcome = Obd2ConnectOutcome.gattTimeout,
  }) =>
      Obd2ConnectTrace(
        attemptId: id,
        startedAtMs: startedAtMs,
        origin: Obd2ConnectOrigin.firstConnect,
        requestedTransport: Obd2ConnectTransport.ble,
        outcome: outcome,
      );

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('obd2_trace_persistence_test_');
    Hive.init(tempDir.path);
    Obd2ConnectTraceLog.clear();
    TraceStorage.extraExportSections.clear();
  });

  tearDown(() async {
    Obd2ConnectTraceLog.clear();
    TraceStorage.extraExportSections.clear();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Obd2ConnectTracePersistence.init (#3184)', () {
    test(
        'a finalised trace is persisted via the endTrace hook and survives '
        'a simulated app restart (hydrate) — RED on master: ring was '
        'in-memory only', () async {
      await Obd2ConnectTracePersistence.init();

      final h = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: 'AA:BB:CC:DD:EE:F1',
        requestedTransport: Obd2ConnectTransport.ble,
      );
      h.setOutcome(Obd2ConnectOutcome.gattTimeout, failureDetail: 'timed out');
      Obd2ConnectTraceLog.endTrace(h);
      // The persist hook is fire-and-forget — drain the microtask queue.
      await pumpEventQueue();

      // Simulated kill + relaunch: drop the in-memory ring, hydrate anew.
      Obd2ConnectTraceLog.clear();
      expect(Obd2ConnectTraceLog.snapshot(), isEmpty);
      await Obd2ConnectTracePersistence.init();

      final revived = Obd2ConnectTraceLog.snapshot();
      expect(revived, hasLength(1),
          reason: 'the pre-kill trace must survive the relaunch');
      expect(revived.single.outcome, Obd2ConnectOutcome.gattTimeout);
      expect(revived.single.failureDetail, 'timed out');
    });

    test(
        'init registers the obd2ConnectTraces export section — the ONE '
        'exportable error log carries the traces, ungated by debugMode',
        () async {
      await Obd2ConnectTracePersistence.init();
      expect(TraceStorage.extraExportSections,
          contains('obd2ConnectTraces'));

      final persistence = Obd2ConnectTracePersistence();
      await persistence
          .append(makeTrace(id: 'a', startedAtMs: _nowMs() - 1000));
      await persistence.append(makeTrace(id: 'b', startedAtMs: _nowMs()));

      final section = TraceStorage.extraExportSections['obd2ConnectTraces']!()
          as List<dynamic>;
      expect(section, hasLength(2));
      // Newest-first, like the export's main trace list.
      expect((section.first as Map<String, dynamic>)['id'], 'b');
      expect((section.last as Map<String, dynamic>)['id'], 'a');
    });
  });

  group('append / load / prune (#3184)', () {
    test('round-trips a trace through the box JSON-string encoding',
        () async {
      await Hive.openBox<dynamic>(Obd2ConnectTracePersistence.boxName);
      final persistence = Obd2ConnectTracePersistence();
      final trace = makeTrace(id: 't1', startedAtMs: _nowMs());

      await persistence.append(trace);

      expect(persistence.load().single, trace);
    });

    test('caps the box at maxPersisted, dropping the OLDEST', () async {
      await Hive.openBox<dynamic>(Obd2ConnectTracePersistence.boxName);
      final persistence = Obd2ConnectTracePersistence();
      final base = _nowMs();
      const extra = 5;
      for (var i = 0;
          i < Obd2ConnectTracePersistence.maxPersisted + extra;
          i++) {
        await persistence.append(makeTrace(id: 't$i', startedAtMs: base + i));
      }

      final loaded = persistence.load();
      expect(loaded, hasLength(Obd2ConnectTracePersistence.maxPersisted));
      // The oldest [extra] were pruned; the survivors are the newest.
      expect(loaded.first.attemptId, 't$extra');
      expect(loaded.last.attemptId,
          't${Obd2ConnectTracePersistence.maxPersisted + extra - 1}');
    });

    test('drops traces older than maxAge on prune AND skips them on load',
        () async {
      await Hive.openBox<dynamic>(Obd2ConnectTracePersistence.boxName);
      final now = DateTime.now();
      final persistence = Obd2ConnectTracePersistence(clock: () => now);
      final aged = now
          .subtract(Obd2ConnectTracePersistence.maxAge +
              const Duration(hours: 1))
          .millisecondsSinceEpoch;

      await persistence.append(
          makeTrace(id: 'old', startedAtMs: aged));
      await persistence.append(
          makeTrace(id: 'fresh', startedAtMs: now.millisecondsSinceEpoch));

      expect(persistence.load().single.attemptId, 'fresh');
      final box = Hive.box<dynamic>(Obd2ConnectTracePersistence.boxName);
      expect(box.get('old'), isNull,
          reason: 'the aged-out entry must be physically pruned');
    });

    test('a corrupt entry is skipped and never poisons the rest', () async {
      final box = await Hive.openBox<dynamic>(Obd2ConnectTracePersistence.boxName);
      final persistence = Obd2ConnectTracePersistence();
      await box.put('corrupt', 'not json at all {');
      await box.put('wrong-type', 42);
      await persistence.append(makeTrace(id: 'good', startedAtMs: _nowMs()));

      expect(persistence.load().single.attemptId, 'good');
    });

    test('load() on a never-opened box degrades to empty, not a throw', () {
      final persistence = Obd2ConnectTracePersistence();
      expect(persistence.load(), isEmpty);
    });
  });

  group('Obd2ConnectTraceLog.hydrateFromPersisted (#3184)', () {
    test('hydrates oldest-first and trims to the ring cap', () {
      final base = _nowMs();
      const overCap = Obd2ConnectTraceLog.maxTraces + 3;
      // Shuffled input: hydrate must sort by startedAtMs itself.
      final traces = [
        for (var i = overCap - 1; i >= 0; i--)
          makeTrace(id: 'p$i', startedAtMs: base + i),
      ];

      Obd2ConnectTraceLog.hydrateFromPersisted(traces);

      final snap = Obd2ConnectTraceLog.snapshot(); // newest-first
      expect(snap, hasLength(Obd2ConnectTraceLog.maxTraces));
      expect(snap.first.attemptId, 'p${overCap - 1}',
          reason: 'newest persisted trace heads the snapshot');
      expect(snap.last.attemptId, 'p3',
          reason: 'the oldest 3 beyond the cap were trimmed');
    });
  });

  group('serialised PII shape (#3184)', () {
    test('the persisted JSON carries only the REDACTED MAC', () async {
      await Hive.openBox<dynamic>(Obd2ConnectTracePersistence.boxName);
      final persistence = Obd2ConnectTracePersistence();

      final h = Obd2ConnectTraceLog.beginTrace(
        origin: Obd2ConnectOrigin.firstConnect,
        mac: 'AA:BB:CC:DD:EE:F1',
        requestedTransport: Obd2ConnectTransport.ble,
      );
      h.setOutcome(Obd2ConnectOutcome.gattTimeout);
      Obd2ConnectTraceLog.endTrace(h);
      await persistence.append(Obd2ConnectTraceLog.snapshot().single);

      final raw =
          Hive.box<dynamic>(Obd2ConnectTracePersistence.boxName).values.single
              as String;
      expect(raw, isNot(contains('AA:BB')),
          reason: 'the raw MAC must never reach disk');
      expect((jsonDecode(raw) as Map<String, dynamic>)['mac'],
          endsWith('E:F1'));
    });
  });
}

int _nowMs() => DateTime.now().millisecondsSinceEpoch;
