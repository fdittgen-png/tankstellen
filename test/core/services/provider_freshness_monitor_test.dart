// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/core/services/provider_freshness_monitor.dart';
import 'package:tankstellen/core/time/app_clock.dart';

import '../../fakes/fake_storage_repository.dart';

/// #4171 — `ProviderCapability.freshnessViolatedBy` had no caller. These
/// tests drive the one that now exists.
///
/// Every case runs against a real in-memory store
/// ([FakeStorageRepository], not the deprecated mocktail mock) because the
/// monitor's whole job is a write-then-read streak: a stubbed reader that
/// never sees its own writes would pass while observing nothing.
void main() {
  // A mid-month Wednesday, per the AppClock seam's own guidance.
  final now = DateTime(2026, 3, 11, 14, 30);

  /// 24-hour promise, per-row stamps — the shape of AR / GR.
  const daily = ProviderCapability(
    stationIdentity: false,
    price: true,
    priceTimestamp: true,
    expectedFreshness: Duration(hours: 24),
    coverage: ProviderCoverage.national,
  );

  /// Same freshness, but the provider publishes no stamp for anyone.
  const stampless = ProviderCapability(
    stationIdentity: true,
    price: true,
    expectedFreshness: Duration(hours: 24),
    coverage: ProviderCoverage.national,
  );

  Station stationAged(Duration age, {String id = 's1'}) => Station(
        id: id,
        name: 'Station $id',
        brand: 'Brand',
        street: 'Street',
        postCode: '1000',
        place: 'Town',
        lat: 0,
        lng: 0,
        priceUpdatedAt: now.subtract(age),
      );

  Station stationNoStamp({String id = 'n1'}) => Station(
        id: id,
        name: 'No stamp',
        brand: 'Brand',
        street: 'Street',
        postCode: '1000',
        place: 'Town',
        lat: 0,
        lng: 0,
      );

  ProviderFreshnessMonitor monitorFor(
    FakeStorageRepository storage, {
    ProviderCapability? capability = daily,
  }) =>
      ProviderFreshnessMonitor(
        storage,
        clock: FixedClock(now),
        capabilityFor: (_) => capability,
      );

  /// The monitor's write is fire-and-forget by design (the network success
  /// path must not wait on storage), so let the microtask land.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('a provider that is publishing', () {
    test('a fresh response leaves the streak at zero', () async {
      final storage = FakeStorageRepository();
      final monitor = monitorFor(storage);

      monitor.recordResponse('AR', [stationAged(const Duration(hours: 2))]);
      await settle();

      expect(monitor.staleStreak('AR'), 0);
      expect(monitor.looksUnpublished('AR'), isFalse);
    });

    test('an age inside 3x the promise is late, not dead', () async {
      final storage = FakeStorageRepository();
      final monitor = monitorFor(storage);

      // 48 h against a 24 h promise: twice the promise, under the x3
      // violation factor. A provider having a bad day.
      monitor.recordResponse('AR', [stationAged(const Duration(hours: 48))]);
      await settle();

      expect(monitor.staleStreak('AR'), 0,
          reason: 'kFreshnessViolationFactor is 3 — 48 h is not a breach');
    });

    test('the FRESHEST stamp decides, not the oldest', () async {
      final storage = FakeStorageRepository();
      final monitor = monitorFor(storage);

      // A national dataset keeps forecourts that stopped reporting years
      // ago. One ancient row proves nothing about the feed.
      monitor.recordResponse('AR', [
        stationAged(const Duration(days: 900), id: 'ancient'),
        stationAged(const Duration(hours: 1), id: 'fresh'),
      ]);
      await settle();

      expect(monitor.staleStreak('AR'), 0);
    });
  });

  group('a provider that has stopped', () {
    test('one breach counts once and is NOT yet a conclusion', () async {
      final storage = FakeStorageRepository();
      final monitor = monitorFor(storage);

      monitor.recordResponse('AR', [stationAged(const Duration(days: 4))]);
      await settle();

      expect(monitor.staleStreak('AR'), 1);
      expect(monitor.looksUnpublished('AR'), isFalse,
          reason: 'one observation is never death — #4171 is explicit that '
              'a capability changes only on sustained evidence');
    });

    test('three consecutive breaches look unpublished', () async {
      final storage = FakeStorageRepository();
      final monitor = monitorFor(storage);

      for (var i = 0; i < ProviderFreshnessMonitor.deadStreakThreshold; i++) {
        monitor.recordResponse('AR', [stationAged(const Duration(days: 4))]);
        await settle();
      }

      expect(monitor.staleStreak('AR'), 3);
      expect(monitor.looksUnpublished('AR'), isTrue);
    });

    test('a fresh response mid-streak resets it to zero', () async {
      final storage = FakeStorageRepository();
      final monitor = monitorFor(storage);

      monitor.recordResponse('AR', [stationAged(const Duration(days: 4))]);
      await settle();
      monitor.recordResponse('AR', [stationAged(const Duration(days: 4))]);
      await settle();
      expect(monitor.staleStreak('AR'), 2);

      monitor.recordResponse('AR', [stationAged(const Duration(hours: 1))]);
      await settle();

      expect(monitor.staleStreak('AR'), 0,
          reason: 'a provider that came back is not a provider that stopped');
    });

    test('streaks are per country', () async {
      final storage = FakeStorageRepository();
      final monitor = monitorFor(storage);

      monitor.recordResponse('AR', [stationAged(const Duration(days: 4))]);
      await settle();

      expect(monitor.staleStreak('AR'), 1);
      expect(monitor.staleStreak('GR'), 0);
    });
  });

  group('responses that are not evidence either way', () {
    test('a provider that publishes no stamps is skipped', () async {
      final storage = FakeStorageRepository();
      final monitor = monitorFor(storage, capability: stampless);

      // The station carries a stamp, but the CAPABILITY says this source
      // does not publish them — so the stamp is not the provider's promise
      // to keep, and ageing it would invent a violation.
      monitor.recordResponse('IT', [stationAged(const Duration(days: 900))]);
      await settle();

      expect(monitor.staleStreak('IT'), 0);
    });

    test('a response whose stations carry no stamp records nothing',
        () async {
      final storage = FakeStorageRepository();
      final monitor = monitorFor(storage);

      monitor.recordResponse('AR', [stationNoStamp(), stationNoStamp(id: 'n2')]);
      await settle();

      expect(monitor.staleStreak('AR'), 0);
    });

    test('an unregistered country is skipped', () async {
      final storage = FakeStorageRepository();
      final monitor = monitorFor(storage, capability: null);

      monitor.recordResponse('XX', [stationAged(const Duration(days: 900))]);
      await settle();

      expect(monitor.staleStreak('XX'), 0);
    });

    test('an empty response records nothing', () async {
      final storage = FakeStorageRepository();
      final monitor = monitorFor(storage);

      monitor.recordResponse('AR', const []);
      await settle();

      expect(monitor.staleStreak('AR'), 0);
    });

    test('a stamp in the future is a provider clock problem, not staleness',
        () async {
      final storage = FakeStorageRepository();
      final monitor = monitorFor(storage);

      monitor.recordResponse(
          'AR', [stationAged(const Duration(days: -2))]); // 2 days ahead
      await settle();

      expect(monitor.staleStreak('AR'), 0,
          reason: 'a negative age must clamp to zero, never wrap into a '
              'breach');
    });
  });

  group('persistence', () {
    test('a streak survives a new monitor over the same storage', () async {
      final storage = FakeStorageRepository();

      final first = monitorFor(storage);
      first.recordResponse('AR', [stationAged(const Duration(days: 4))]);
      await settle();
      first.recordResponse('AR', [stationAged(const Duration(days: 4))]);
      await settle();

      // A fresh monitor — the app restarted; the evidence must not.
      final second = monitorFor(storage);
      expect(second.staleStreak('AR'), 2);
    });

    test('an unparseable stored value reads as no streak', () async {
      final storage = FakeStorageRepository();
      await storage.putSetting(
          '${ProviderFreshnessMonitor.keyPrefix}AR', 'not-an-int');

      expect(monitorFor(storage).staleStreak('AR'), 0);
    });
  });
}
