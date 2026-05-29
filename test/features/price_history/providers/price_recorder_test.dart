// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/price_history/data/models/price_record.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/price_history/providers/price_recorder.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// Fake repository that tracks recorded prices and can simulate failures.
class _FakePriceHistoryRepo implements PriceHistoryRepository {
  final List<PriceRecord> recorded = [];
  /// If >= 0, the call at this call-count index throws instead of recording.
  int failAtIndex = -1;
  int _callCount = 0;

  @override
  Future<void> recordPrice(PriceRecord record) async {
    final idx = _callCount++;
    if (idx == failAtIndex) {
      throw Exception('Simulated failure at index $idx');
    }
    recorded.add(record);
  }

  // Stub other methods
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('recordSearchResults', () {
    test('records price for each station', () async {
      final repo = _FakePriceHistoryRepo();
      final stations = [
        _makeStation('1', e5: 1.5, diesel: 1.3),
        _makeStation('2', e5: 1.6, diesel: 1.4),
      ];

      await recordSearchResults(stations, repo);

      expect(repo.recorded.length, 2);
      expect(repo.recorded[0].stationId, '1');
      expect(repo.recorded[0].e5, 1.5);
      expect(repo.recorded[0].diesel, 1.3);
      expect(repo.recorded[1].stationId, '2');
      expect(repo.recorded[1].e5, 1.6);
      expect(repo.recorded[1].diesel, 1.4);
    });

    test('records all fuel types from station', () async {
      final repo = _FakePriceHistoryRepo();
      final stations = [
        _makeStation('1', e5: 1.5, e10: 1.45, diesel: 1.3),
      ];

      await recordSearchResults(stations, repo);

      expect(repo.recorded.length, 1);
      final record = repo.recorded.first;
      expect(record.e5, 1.5);
      expect(record.e10, 1.45);
      expect(record.diesel, 1.3);
      expect(record.e98, isNull);
    });

    test('records all stations sequentially (#2309 — awaited loop)', () async {
      // recordSearchResults now awaits each repo.recordPrice so Hive
      // write failures are caught by the per-record try/catch, not lost
      // to the uncaught-error zone.
      final repo = _FakePriceHistoryRepo();
      final stations = [
        _makeStation('1'),
        _makeStation('2'),
        _makeStation('3'),
      ];

      await recordSearchResults(stations, repo);

      expect(repo.recorded.length, 3);
    });

    test('async write failure is caught per-record, other stations still record (#2309)', () async {
      // failAtIndex=1: the second call (station '2') throws.
      final repo = _FakePriceHistoryRepo()..failAtIndex = 1;
      final stations = [
        _makeStation('1'),
        _makeStation('2'),
        _makeStation('3'),
      ];

      // Must not throw even though station '2' fails.
      await expectLater(recordSearchResults(stations, repo), completes);
      // Station 1 and 3 succeed; station 2 was silently skipped.
      expect(repo.recorded.map((r) => r.stationId), containsAll(['1', '3']));
    });

    test('handles empty station list', () async {
      final repo = _FakePriceHistoryRepo();

      await recordSearchResults([], repo);

      expect(repo.recorded, isEmpty);
    });

    test('records null prices when station has no prices', () async {
      final repo = _FakePriceHistoryRepo();
      final stations = [_makeStation('1')];

      await recordSearchResults(stations, repo);

      expect(repo.recorded.length, 1);
      final record = repo.recorded.first;
      expect(record.e5, isNull);
      expect(record.diesel, isNull);
    });
  });
}

Station _makeStation(String id, {double? e5, double? e10, double? diesel}) {
  return Station(
    id: id,
    name: 'Test',
    brand: 'Test',
    street: 'St',
    postCode: '00000',
    place: 'City',
    lat: 48.0,
    lng: 2.0,
    isOpen: true,
    e5: e5,
    e10: e10,
    diesel: diesel,
  );
}
