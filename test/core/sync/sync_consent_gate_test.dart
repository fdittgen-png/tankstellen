// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3866 (Epic #3865) — the Cloud Sync CONSENT gates the whole sync path.
// Before: only trips / trip shares read it; favorites, alerts, vehicles,
// fill-ups, ratings, itineraries and baselines uploaded on `sync_enabled`
// alone, so withdrawing consent in Settings changed nothing.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/sync/sync_provider.dart';
import 'package:tankstellen/core/sync/tanksync_init.dart';

import '../../fakes/fake_hive_storage.dart';
import '../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();
  late FakeHiveStorage storage;
  late ProviderContainer container;

  setUp(() async {
    storage = FakeHiveStorage();
    await storage.putSetting('sync_enabled', true);
    await storage.putSetting('supabase_url', 'https://x.supabase.co');
    container = ProviderContainer(overrides: [
      hiveStorageProvider.overrideWithValue(storage),
    ]);
    addTearDown(container.dispose);
  });

  test('sync_enabled WITHOUT the Cloud Sync consent = not enabled', () {
    expect(container.read(syncStateProvider).enabled, isFalse,
        reason: 'the coordinator, every writer and SyncHelper read this '
            'flag — it must be false until the user consented');
  });

  test('sync_enabled WITH the consent = enabled', () async {
    await storage.putSetting(StorageKeys.consentCloudSync, true);
    container.invalidate(syncStateProvider);
    expect(container.read(syncStateProvider).enabled, isTrue);
  });

  test('TankSyncInit builds no client without the consent', () async {
    final outcome = await TankSyncInit.run(storage);
    expect(outcome, TankSyncInitOutcome.notConfigured,
        reason: 'no consent → no Supabase client, no anonymous sign-in');
  });
}
