// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/data/opportunity_watch_store.dart';
import 'package:tankstellen/features/alerts/data/usual_station_store.dart';
import 'package:tankstellen/features/alerts/domain/opportunity.dart';

/// #4154 — the two settings behind "what may interrupt me".
///
/// Against a real Hive box, for #4116's reason: the closed-box branch is
/// the one that fires in a background isolate, and a fake that always
/// has a box proves nothing about it.
void main() {
  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('opportunity_watch_');
    Hive.init(tmpDir.path);
    await Hive.openBox<dynamic>(HiveBoxes.alerts);
  });

  tearDown(() async {
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  group('OpportunityWatchStore', () {
    const store = OpportunityWatchStore();

    test('an absent row means EVERY kind is watched', () {
      expect(store.read(), OpportunityKind.values.toSet(),
          reason: '#4149 — an upgrade that silently stopped alerting is '
              'worse than the model it replaced. No row is a fresh '
              'install, not a user who switched everything off.');
    });

    test('switching one kind off leaves the others watched', () async {
      final after = await store.toggle(OpportunityKind.localMovement,
          watched: false);
      expect(after, isNot(contains(OpportunityKind.localMovement)));
      expect(after, hasLength(OpportunityKind.values.length - 1));
      expect(store.read(), after, reason: 'the write round-trips');
    });

    test('switching it back on restores it, and the set stays a set',
        () async {
      await store.toggle(OpportunityKind.refuelSoon, watched: false);
      await store.toggle(OpportunityKind.refuelSoon, watched: true);
      await store.toggle(OpportunityKind.refuelSoon, watched: true);
      expect(store.read(), OpportunityKind.values.toSet());
    });

    test('every kind off is a real state, not read back as the default',
        () async {
      for (final kind in OpportunityKind.values) {
        await store.toggle(kind, watched: false);
      }
      expect(store.read(), isEmpty,
          reason: 'an empty ROW is "nothing interrupts me"; only an '
              'ABSENT row means everything does');
    });

    test('a closed box degrades to every kind rather than throwing',
        () async {
      await Hive.close();
      expect(store.read(), OpportunityKind.values.toSet());
    });
  });

  group('UsualStationStore', () {
    const store = UsualStationStore();

    test('nothing set reads as null', () {
      expect(store.read(), isNull);
    });

    test('a written station round-trips with its name', () async {
      await store.write(
          const UsualStation(stationId: 'de-aral-1', stationName: 'ARAL'));
      expect(store.read()?.stationId, 'de-aral-1');
      expect(store.read()?.stationName, 'ARAL');
    });

    test('clear removes it', () async {
      await store.write(const UsualStation(stationId: 'de-x'));
      await store.clear();
      expect(store.read(), isNull);
    });

    test('a malformed row reads as null instead of throwing', () async {
      await Hive.box<dynamic>(HiveBoxes.alerts)
          .put(UsualStationStore.storageKey, 'not json');
      expect(store.read(), isNull);
    });

    test('a row without a station id is not a usual station', () async {
      await Hive.box<dynamic>(HiveBoxes.alerts)
          .put(UsualStationStore.storageKey, '{"stationName":"ARAL"}');
      expect(store.read(), isNull);
    });

    test('a closed box reads null and drops the write', () async {
      await Hive.close();
      expect(store.read(), isNull);
      await store.write(const UsualStation(stationId: 'de-y'));
      expect(store.read(), isNull);
    });
  });
}
