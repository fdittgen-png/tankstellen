// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_events.dart';

/// #3446 — the sync-events bus contract: pull paths emit per-table
/// change counts after persisting; subscribers get only their table;
/// no-op counts are dropped so call sites can emit unconditionally.
void main() {
  group('SyncEvents.emit (#3446)', () {
    test('delivers the event to a stream subscriber', () async {
      final events = <SyncTableChanged>[];
      final sub = SyncEvents.instance.stream.listen(events.add);
      addTearDown(sub.cancel);

      SyncEvents.instance
          .emit(const SyncTableChanged(SyncTables.favorites, 2));
      await _flushMicrotasks();

      expect(events, hasLength(1));
      expect(events.single.table, SyncTables.favorites);
      expect(events.single.changedCount, 2);
    });

    test('drops zero / negative counts (nothing was written)', () async {
      final events = <SyncTableChanged>[];
      final sub = SyncEvents.instance.stream.listen(events.add);
      addTearDown(sub.cancel);

      SyncEvents.instance
          .emit(const SyncTableChanged(SyncTables.favorites, 0));
      SyncEvents.instance
          .emit(const SyncTableChanged(SyncTables.favorites, -1));
      await _flushMicrotasks();

      expect(events, isEmpty);
    });
  });

  group('SyncEvents.forTable (#3446)', () {
    test('filters to the subscribed table only', () async {
      final events = <SyncTableChanged>[];
      final sub = SyncEvents.instance
          .forTable(SyncTables.stationRatings)
          .listen(events.add);
      addTearDown(sub.cancel);

      SyncEvents.instance
          .emit(const SyncTableChanged(SyncTables.favorites, 3));
      SyncEvents.instance
          .emit(const SyncTableChanged(SyncTables.stationRatings, 1));
      await _flushMicrotasks();

      expect(events.map((e) => e.table), [SyncTables.stationRatings]);
    });

    test('broadcast: multiple independent subscribers each get the event',
        () async {
      var a = 0;
      var b = 0;
      final subA =
          SyncEvents.instance.forTable(SyncTables.alerts).listen((_) => a++);
      final subB =
          SyncEvents.instance.forTable(SyncTables.alerts).listen((_) => b++);
      addTearDown(subA.cancel);
      addTearDown(subB.cancel);

      SyncEvents.instance.emit(const SyncTableChanged(SyncTables.alerts, 1));
      await _flushMicrotasks();

      expect(a, 1);
      expect(b, 1);
    });
  });

  group('SyncEvents.emitIdSetDelta (#3446)', () {
    test('emits the symmetric difference (adds + removals)', () async {
      final events = <SyncTableChanged>[];
      final sub = SyncEvents.instance
          .forTable(SyncTables.ignoredStations)
          .listen(events.add);
      addTearDown(sub.cancel);

      SyncEvents.instance.emitIdSetDelta(
        SyncTables.ignoredStations,
        ['a', 'b'],
        ['b', 'c', 'd'], // 'a' removed (tombstone), 'c'+'d' pulled
      );
      await _flushMicrotasks();

      expect(events.single.changedCount, 3);
    });

    test('identical sets → nothing emitted', () async {
      final events = <SyncTableChanged>[];
      final sub = SyncEvents.instance.stream.listen(events.add);
      addTearDown(sub.cancel);

      SyncEvents.instance
          .emitIdSetDelta(SyncTables.favorites, ['a', 'b'], ['b', 'a']);
      await _flushMicrotasks();

      expect(events, isEmpty);
    });
  });
}

Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);
