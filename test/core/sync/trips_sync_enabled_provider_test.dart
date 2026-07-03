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

/// Pins `tripsSyncEnabledProvider` (#1665, re-cut by #3448) — the
/// trajet-sync gate is `B ∧ C`: cloudSync consent ∧ syncTrips toggle.
/// The former email requirement (**A**) was dropped: an anonymous UUID is
/// a full RLS-scoped identity, so consent alone decides.
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

  group('tripsSyncEnabledProvider — consent-only gate B ∧ C (#3448)', () {
    test('enabled when cloudSync AND syncTrips are true (email account)',
        () {
      expect(
        makeContainer(hasEmail: true, cloudSync: true, syncTrips: true)
            .read(tripsSyncEnabledProvider),
        isTrue,
      );
    });

    test('an ANONYMOUS account with both consents granted is enabled — '
        'the #3448 acceptance criterion', () {
      expect(
        makeContainer(hasEmail: false, cloudSync: true, syncTrips: true)
            .read(tripsSyncEnabledProvider),
        isTrue,
        reason: 'an anonymous UUID is a full identity; email only makes it '
            'portable across devices (#3448 dropped the email gate)',
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

    test('everything off gates off', () {
      expect(
        makeContainer(hasEmail: false, cloudSync: false, syncTrips: false)
            .read(tripsSyncEnabledProvider),
        isFalse,
      );
    });
  });
}
