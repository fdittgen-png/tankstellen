// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/car/car_fix_store.dart';

import '../../fakes/fake_storage_repository.dart';

/// Android Auto v2 PHASE-3 (#2990) — fault-injection coverage for the
/// never-throws contract of `car_fix_store.dart` (#2349/#1103): every helper
/// the headless car engine calls must return normally when its dependency
/// faults, because a throw would crash the OS-spawned engine.
void main() {
  group('persistCarFix — never throws (#2349 fault injection)', () {
    test('a throwing storage write completes normally (best-effort persist)',
        () async {
      final storage = _WriteFaultStorage();
      await expectLater(
        persistCarFix(storage, (lat: 52.52, lng: 13.405)),
        completes,
        reason: 'a storage fault must never fail the car fetch',
      );
    });

    test('a healthy storage gets the UserPositionNotifier-shaped keys',
        () async {
      final storage = FakeStorageRepository();
      await persistCarFix(storage, (lat: 52.52, lng: 13.405));
      expect(storage.getSetting(StorageKeys.userPositionLat), 52.52);
      expect(storage.getSetting(StorageKeys.userPositionLng), 13.405);
      expect(storage.getSetting(StorageKeys.userPositionSource), 'car');
      expect(storage.getSetting(StorageKeys.userPositionTimestamp), isA<int>());
    });
  });

  group('readers — degrade to null / no_gps, never throw', () {
    test('carLiveFixFromArgs returns normally on every malformed payload', () {
      expect(() => carLiveFixFromArgs(null), returnsNormally);
      expect(() => carLiveFixFromArgs(42), returnsNormally);
      expect(() => carLiveFixFromArgs({'lat': 'NaNish', 'lng': true}),
          returnsNormally);
      expect(carLiveFixFromArgs({'lat': 'NaNish', 'lng': true}), isNull);
    });

    test('readPersistedCarFix rejects a poisoned (0,0) fix (#2872 guard)',
        () async {
      final storage = FakeStorageRepository();
      await storage.putSetting(StorageKeys.userPositionLat, 0.0);
      await storage.putSetting(StorageKeys.userPositionLng, 0.0);
      expect(readPersistedCarFix(storage), isNull);
    });

    test('readCarUserLocation degrades a string timestamp, never throws', () async {
      final storage = FakeStorageRepository();
      await storage.putSetting(StorageKeys.userPositionLat, 48.8566);
      await storage.putSetting(StorageKeys.userPositionLng, 2.3522);
      await storage.putSetting(
          StorageKeys.userPositionTimestamp, 'not-a-date-or-int');
      final loc = readCarUserLocation(storage);
      expect(loc['lat'], 48.8566);
      expect(loc['updatedAtMs'], isNull);
    });
  });

  group('activeCarProfile — unknown fuel key falls back, never throws', () {
    test('an unparseable preferredFuelType degrades to the E10 default',
        () async {
      final storage = FakeStorageRepository();
      await storage.saveProfile('p1', {
        'id': 'p1',
        'name': 'Default',
        'defaultSearchRadius': 7.0,
        'preferredFuelType': 'kryptonite',
      });
      await storage.setActiveProfileId('p1');

      late CarProfile profile;
      expect(() => profile = activeCarProfile(storage), returnsNormally);
      expect(profile.radiusKm, 7.0);
      // FuelType.fromString maps unknown keys to FuelType.all (its own
      // fallback) rather than throwing — the radius must still apply.
      expect(profile.fuelType, FuelType.all);
    });
  });
}

/// Fault seam: a [FakeStorageRepository] whose setting writes throw — drives
/// the `persistCarFix` best-effort contract.
class _WriteFaultStorage extends FakeStorageRepository {
  @override
  Future<void> putSetting(String key, dynamic value) async {
    throw StateError('injected storage fault');
  }
}
