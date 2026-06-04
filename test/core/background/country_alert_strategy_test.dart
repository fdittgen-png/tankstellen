// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/bulk_dataset_alert_strategy.dart';
import 'package:tankstellen/core/background/country_alert_strategy.dart';
import 'package:tankstellen/core/background/polled_alert_strategy.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';

import '../../fakes/fake_storage_repository.dart';

void main() {
  final storage = FakeStorageRepository();
  final cache = CacheManager(storage);

  group('strategy selection branches on policy.model (#2863)', () {
    test('polled-API countries resolve to PolledAlertStrategy', () {
      for (final code in ['DE', 'AT', 'PT', 'LU', 'SI', 'GR', 'RO', 'MX',
        'KR', 'CL']) {
        final strategy = CountryAlertStrategy.forCountry(code,
            storage: storage, cache: cache, apiKey: 'k');
        expect(strategy, isA<PolledAlertStrategy>(),
            reason: '$code is polledApi → PolledAlertStrategy');
      }
    });

    test('bulk-file countries resolve to BulkDatasetAlertStrategy', () {
      for (final code in ['ES', 'IT', 'AR', 'DK']) {
        final strategy = CountryAlertStrategy.forCountry(code,
            storage: storage, cache: cache);
        expect(strategy, isA<BulkDatasetAlertStrategy>(),
            reason: '$code is bulkFile → BulkDatasetAlertStrategy');
      }
    });

    test('the AU throwing stub (#804) resolves to NO strategy', () {
      expect(
        CountryAlertStrategy.forCountry('AU', storage: storage, cache: cache),
        isNull,
      );
    });

    test('an unregistered country resolves to NO strategy', () {
      expect(
        CountryAlertStrategy.forCountry('ZZ', storage: storage, cache: cache),
        isNull,
      );
    });

    test('GB/FR follow their resolved policy.model (BulkMigrationFlags), NOT '
        'their country code — a flag flip moves them between strategies', () {
      // The selection reads policy.model (the resolved truth that
      // BulkMigrationFlags.ukCmaBulk / .frFluxBulk decide), NOT the country
      // code. So whichever way the flag is set, the resolved strategy class
      // tracks policy.model: a bulkFile model resolves to
      // BulkDatasetAlertStrategy, a polledApi model to PolledAlertStrategy
      // (when the country is in the BG-scanned polled set). Flipping the flag
      // moves the country between the two with no code change here — exactly
      // the contract this test pins.
      for (final code in ['GB', 'FR']) {
        final strategy = CountryAlertStrategy.forCountry(code,
            storage: storage, cache: cache, apiKey: 'k');
        if (BulkDatasetAlertStrategy.isBulk(code)) {
          expect(strategy, isA<BulkDatasetAlertStrategy>(),
              reason: '$code policy.model == bulkFile (flag on) → bulk strategy');
        } else if (PolledAlertStrategy.isPolled(code)) {
          // Legacy polledApi AND in the BG-scanned polled set (GB).
          expect(strategy, isA<PolledAlertStrategy>(),
              reason: '$code polled + scanned → PolledAlertStrategy');
        } else {
          // Legacy polledApi but NOT in the BG-scanned set (FR): not scanned
          // today, so no strategy. Flipping frFluxBulk moves it to the bulk
          // branch above.
          expect(strategy, isNull,
              reason: '$code is polled but not in the BG-scanned set');
        }
      }
    });
  });

  group('PolledAlertStrategy selection parity (#2862/#2863)', () {
    test('isPolled recognises the 11 providers, not bulk / stub', () {
      for (final code in ['DE', 'AT', 'PT', 'GB', 'LU', 'SI', 'GR', 'RO',
        'MX', 'KR', 'CL']) {
        expect(PolledAlertStrategy.isPolled(code), isTrue);
      }
      for (final code in ['ES', 'IT', 'AR', 'DK', 'AU', 'ZZ']) {
        expect(PolledAlertStrategy.isPolled(code), isFalse);
      }
    });

    test('forCountry returns null for a non-polled (bulk) country', () {
      expect(
        PolledAlertStrategy.forCountry('ES', storage: storage, cache: cache),
        isNull,
      );
    });
  });
}
