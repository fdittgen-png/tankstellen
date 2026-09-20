// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4212 — fleet sharing consent is gated on the master cloud-sync
// consent exactly like `consentSyncTrips` (#1479): fleet data leaves the
// device over TankSync or not at all.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/fleet/api.dart';

import '../../fakes/fake_hive_storage.dart';

void main() {
  late FakeHiveStorage storage;

  setUp(() => storage = FakeHiveStorage());

  ProviderContainer containerFor({
    required bool cloudSync,
    bool? fleetSharing,
  }) {
    unawaited(storage.putSetting(StorageKeys.consentCloudSync, cloudSync));
    if (fleetSharing != null) {
      unawaited(
          storage.putSetting(StorageKeys.consentFleetSharing, fleetSharing));
    }
    final container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('defaults to false — sharing with an employer is opt-in', () {
    expect(
      containerFor(cloudSync: true).read(fleetSharingConsentProvider),
      isFalse,
    );
  });

  test('reads back the stored opt-in once cloud sync is consented', () {
    expect(
      containerFor(cloudSync: true, fleetSharing: true)
          .read(fleetSharingConsentProvider),
      isTrue,
    );
  });

  test('a stored true CANNOT ride past a withdrawn cloud-sync consent', () {
    expect(
      containerFor(cloudSync: false, fleetSharing: true)
          .read(fleetSharingConsentProvider),
      isFalse,
      reason: 'without the master consent there is no backend to share '
          'with — the read itself forces false, as GdprConsent.save does '
          'for consentSyncTrips',
    );
  });

  test('setting it while cloud sync is off persists false, so it cannot '
      'take effect silently when sync comes back', () async {
    final container = containerFor(cloudSync: false);
    await container.read(fleetSharingConsentProvider.notifier).set(true);

    expect(container.read(fleetSharingConsentProvider), isFalse);
    expect(storage.getSetting(StorageKeys.consentFleetSharing), isFalse);
  });

  test('setting it with cloud sync on persists and exposes true', () async {
    final container = containerFor(cloudSync: true);
    await container.read(fleetSharingConsentProvider.notifier).set(true);

    expect(container.read(fleetSharingConsentProvider), isTrue);
    expect(storage.getSetting(StorageKeys.consentFleetSharing), isTrue);

    await container.read(fleetSharingConsentProvider.notifier).set(false);
    expect(container.read(fleetSharingConsentProvider), isFalse);
  });
}
