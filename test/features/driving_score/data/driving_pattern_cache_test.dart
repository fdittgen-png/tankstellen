// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// #4366 acceptance 8 — a cached per-trip total must go stale for the
// right reasons: a trip edit, a deletion, a vehicle reassignment or a
// changed model version. Nothing here knows about the selected vehicles
// or the active one, which is exactly why neither can be disturbed.
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving_score/data/driving_pattern_cache.dart';
import 'package:tankstellen/features/driving_score/domain/driving_pattern_comparison.dart';
import 'package:tankstellen/features/trips/api.dart';

TripHistoryEntry _trip(
  String id, {
  String? vehicleId = 'a',
  double km = 42,
  int samples = 600,
  bool cold = false,
}) =>
    TripHistoryEntry(
      id: id,
      vehicleId: vehicleId,
      sampleCount: samples,
      summary: TripSummary(
        distanceKm: km,
        maxRpm: 3000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        coldStartSurcharge: cold,
        startedAt: DateTime.utc(2026, 9, 5, 8),
        endedAt: DateTime.utc(2026, 9, 5, 9),
      ),
    );

final _totals = DrivingPatternTotals(
    events: const {DrivingEventCounter.hardAccelEvents: 3},
    exposure: const {DrivingExposureBasis.movingDistanceKm: 42});

void main() {
  test('a hit is returned only while the fingerprint holds', () {
    final cache = DrivingPatternCache();
    cache.write(_trip('t1'), _totals);
    expect(cache.read(_trip('t1')), isNotNull);
  });

  test('an edited trip misses', () {
    final cache = DrivingPatternCache()..write(_trip('t1'), _totals);
    expect(cache.read(_trip('t1', km: 43)), isNull,
        reason: 'a changed distance is a changed trip');
    expect(cache.read(_trip('t1', samples: 601)), isNull,
        reason: 'a re-finalised sample set is a changed trip');
  });

  test('a reassigned trip misses', () {
    final cache = DrivingPatternCache()..write(_trip('t1'), _totals);
    expect(cache.read(_trip('t1', vehicleId: 'b')), isNull);
  });

  test('a changed model version misses every entry', () {
    final a = fingerprintOf(_trip('t1'));
    expect(a.startsWith('$kDrivingPatternModelVersion|'), isTrue,
        reason: 'the version leads the fingerprint, so a bump invalidates '
            'the whole cache at once');
  });

  test('a deleted trip is evicted', () {
    final cache = DrivingPatternCache()
      ..write(_trip('t1'), _totals)
      ..write(_trip('t2'), _totals);
    cache.evictMissing({'t1'});
    expect(cache.length, 1);
    expect(cache.read(_trip('t2')), isNull);
    expect(cache.read(_trip('t1')), isNotNull);
  });

  test('the cache is bounded and evicts the least recently used', () {
    final cache = DrivingPatternCache(capacity: 2)
      ..write(_trip('t1'), _totals)
      ..write(_trip('t2'), _totals);
    cache.read(_trip('t1'));
    cache.write(_trip('t3'), _totals);
    expect(cache.length, 2);
    expect(cache.read(_trip('t2')), isNull, reason: 't2 was the oldest touch');
    expect(cache.read(_trip('t1')), isNotNull);
  });
}
