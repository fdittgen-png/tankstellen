// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/sync/trips_sync_enabled_provider.dart';

import '../../fakes/fake_hive_storage.dart';

/// Pins `tripsSyncEnabledProvider` (#1665) — the trajet-sync gate
/// `A ∧ B ∧ C`: non-anonymous account ∧ cloudSync consent ∧ syncTrips
/// toggle.
class _FakeSyncState extends SyncState {
  _FakeSyncState(this._config);
  final SyncConfig _config;

  @override
  SyncConfig build() => _config;
}

void main() {
  ProviderContainer makeContainer({
    required bool hasEmail,
    required bool cloudSync,
    required bool syncTrips,
  }) {
    final storage = FakeHiveStorage();
    unawaited(storage.putSetting(StorageKeys.consentCloudSync, cloudSync));
    unawaited(storage.putSetting(StorageKeys.consentSyncTrips, syncTrips));
    final c = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(storage),
      syncStateProvider.overrideWith(
        () => _FakeSyncState(
          SyncConfig(userEmail: hasEmail ? 'driver@example.com' : null),
        ),
      ),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('tripsSyncEnabledProvider — gate A ∧ B ∧ C (#1665)', () {
    test('enabled only when non-anonymous account AND cloudSync AND '
        'syncTrips are all true', () {
      expect(
        makeContainer(hasEmail: true, cloudSync: true, syncTrips: true)
            .read(tripsSyncEnabledProvider),
        isTrue,
      );
    });

    test('an anonymous account (no email) gates off — even with both '
        'consents granted', () {
      expect(
        makeContainer(hasEmail: false, cloudSync: true, syncTrips: true)
            .read(tripsSyncEnabledProvider),
        isFalse,
        reason: 'trajet sync requires an email-backed account',
      );
    });

    test('cloudSync consent off gates off', () {
      expect(
        makeContainer(hasEmail: true, cloudSync: false, syncTrips: true)
            .read(tripsSyncEnabledProvider),
        isFalse,
      );
    });

    test('syncTrips toggle off gates off', () {
      expect(
        makeContainer(hasEmail: true, cloudSync: true, syncTrips: false)
            .read(tripsSyncEnabledProvider),
        isFalse,
      );
    });

    test('all three off gates off', () {
      expect(
        makeContainer(hasEmail: false, cloudSync: false, syncTrips: false)
            .read(tripsSyncEnabledProvider),
        isFalse,
      );
    });
  });
}
