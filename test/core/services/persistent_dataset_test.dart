// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/services/persistent_dataset.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

/// #3154 — [PersistentDataset.write] / [PersistentDataset.readAsync] run the
/// (de)serialize closures through `compute()` so a whole-country dataset
/// (~11k `Station.fromJson` calls) never blocks the UI isolate. These tests
/// pin the OUTPUT contract: the isolate round-trip is byte-identical to the
/// old inline path, and the synchronous [PersistentDataset.read] (kept for
/// the small per-province ES payloads) still reads what [write] persisted.

/// Minimal in-memory [CacheStrategy] (no Hive).
class _MemCache implements CacheStrategy {
  final Map<String, CacheEntry> entries = {};

  @override
  Future<void> put(
    String key,
    Map<String, dynamic> data, {
    required Duration ttl,
    required ServiceSource source,
  }) async {
    entries[key] = CacheEntry(
      payload: data,
      storedAt: DateTime.now(),
      originalSource: source,
      ttl: ttl,
    );
  }

  @override
  CacheEntry? get(String key) => entries[key];

  @override
  CacheEntry? getFresh(String key) {
    final e = entries[key];
    if (e == null || e.isExpired) return null;
    return e;
  }
}

/// The same codec shape the FR flux / DK services wire in (capture-free
/// closures over Station JSON).
PersistentDataset<List<Station>> _stationDataset(CacheStrategy cache) =>
    PersistentDataset<List<Station>>(
      cache: cache,
      countryCode: 'FR',
      datasetName: 'stations',
      source: ServiceSource.prixCarburantsApi,
      serialize: (stations) =>
          {'stations': stations.map((s) => s.toJson()).toList()},
      deserialize: (json) {
        final list = json['stations'] as List<dynamic>?;
        if (list == null) return null;
        return list
            .map((j) => Station.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
      },
    );

/// A recorded-shape national payload slice: full-field stations as the FR
/// flux parser produces them.
final List<Station> _recorded = [
  const Station(
    id: 'fr-34200002',
    name: '120 RUE LECLERC',
    brand: 'Independent',
    street: '120 RUE LECLERC',
    postCode: '34290',
    place: 'CASTELNAU',
    lat: 43.45,
    lng: 3.52,
    dist: 0,
    e5: 1.879,
    e10: 1.799,
    e98: 1.929,
    diesel: 1.659,
    e85: 0.899,
    lpg: 0.999,
    isOpen: true,
    updatedAt: '29/05 08:00',
    stationType: 'R',
    is24h: false,
    openingHoursText: 'Lundi 07:00-18:30',
  ),
  const Station(
    id: 'fr-75001001',
    name: 'AIRE DE PARIS',
    brand: 'Autoroute',
    street: 'AIRE DE PARIS',
    postCode: '75001',
    place: 'PARIS',
    lat: 48.85,
    lng: 2.35,
    dist: 0,
    diesel: 1.749,
    isOpen: true,
    is24h: true,
  ),
];

void main() {
  group('PersistentDataset off-isolate (de)serialization (#3154)', () {
    test('write → readAsync round-trips the recorded payload identically',
        () async {
      final cache = _MemCache();
      final dataset = _stationDataset(cache);

      await dataset.write(_recorded, hardTtl: const Duration(hours: 6));
      final hit = await dataset.readAsync();

      expect(hit, isNotNull);
      // Freezed value equality — every field survived the isolate
      // round-trip byte-identically.
      expect(hit!.value, _recorded);
      expect(hit.age, lessThan(const Duration(seconds: 5)));
      // The persisted envelope is the same JSON the inline path produced.
      final payload =
          cache.entries[PersistentDataset.datasetKey('FR', 'stations')]!
              .payload;
      expect(payload['stations'], hasLength(2));
      expect((payload['stations'] as List).first['id'], 'fr-34200002');
    });

    test('readAsync returns null when nothing is persisted', () async {
      final dataset = _stationDataset(_MemCache());
      expect(await dataset.readAsync(), isNull);
    });

    test('readAsync returns null when the payload fails to deserialize',
        () async {
      final cache = _MemCache();
      cache.entries[PersistentDataset.datasetKey('FR', 'stations')] =
          CacheEntry(
        payload: const {'unexpected': 'shape'},
        storedAt: DateTime.now(),
        originalSource: ServiceSource.prixCarburantsApi,
        ttl: const Duration(hours: 6),
      );
      final dataset = _stationDataset(cache);
      expect(await dataset.readAsync(), isNull);
    });

    test('synchronous read() (ES per-province contract) still reads what '
        'the off-isolate write persisted', () async {
      final cache = _MemCache();
      final dataset = _stationDataset(cache);

      await dataset.write(_recorded, hardTtl: const Duration(hours: 6));
      final hit = dataset.read();

      expect(hit, isNotNull);
      expect(hit!.value, _recorded);
    });

    test('readWithin honours maxAge against the stored copy', () async {
      final cache = _MemCache();
      final dataset = _stationDataset(cache);

      await dataset.write(_recorded, hardTtl: const Duration(hours: 6));
      expect(dataset.readWithin(const Duration(minutes: 1)), _recorded);
      expect(dataset.readWithin(Duration.zero), isNull);
    });
  });
}
