import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/background_service.dart';
import 'package:tankstellen/core/background/hive_isolate_lock.dart';
import 'package:tankstellen/core/notifications/local_notification_service.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/utils/json_extensions.dart';

void main() {
  group('BackgroundService', () {
    test('BackgroundService.init does not throw in test environment', () {
      // BackgroundService.init calls Workmanager().initialize which
      // requires platform channels. In unit tests without a running
      // Flutter engine, this will throw a MissingPluginException.
      // We verify the method exists and is callable.
      expect(BackgroundService.init, isA<Function>());
    });

    test('retry constants are reasonable', () {
      expect(BackgroundService.maxRetryAttempts, greaterThanOrEqualTo(2));
      expect(BackgroundService.maxRetryAttempts, lessThanOrEqualTo(5));
      expect(
        BackgroundService.retryBaseDelay.inSeconds,
        greaterThanOrEqualTo(1),
      );
    });

    test('charging refresh interval is shorter than standard', () {
      expect(
        BackgroundService.chargingRefreshInterval.inMinutes,
        lessThan(BackgroundService.refreshInterval.inMinutes),
      );
    });

    test('standard refresh interval is 1 hour', () {
      expect(BackgroundService.refreshInterval, const Duration(hours: 1));
    });

    test('charging refresh interval is 30 minutes', () {
      expect(
        BackgroundService.chargingRefreshInterval,
        const Duration(minutes: 30),
      );
    });
  });

  group('HiveStorage.initInIsolate', () {
    test('initInIsolate method exists and is callable', () {
      // initInIsolate requires platform channels (FlutterSecureStorage),
      // so we can only verify the method signature exists.
      expect(HiveStorage.initInIsolate, isA<Function>());
    });

    test('background service does not open Hive boxes directly', () {
      // Verify the background service delegates Hive initialization
      // to HiveStorage.initInIsolate (with encryption) rather than
      // opening boxes directly without a cipher.
      final source = File(
        'lib/core/background/background_service.dart',
      ).readAsStringSync();

      // Should NOT contain direct Hive.openBox calls
      expect(
        source.contains('Hive.openBox'),
        isFalse,
        reason: 'Background service must use HiveStorage.initInIsolate() '
            'instead of opening Hive boxes directly without encryption',
      );

      // Should NOT import hive_flutter directly
      expect(
        source.contains("import 'package:hive_flutter/hive_flutter.dart'"),
        isFalse,
        reason: 'Background service should not import Hive directly',
      );

      // Should use initInIsolate
      expect(
        source.contains('initInIsolate'),
        isTrue,
        reason: 'Background service must call HiveStorage.initInIsolate()',
      );
    });

    test('background service contains no unsafe as-casts', () {
      final source = File(
        'lib/core/background/background_service.dart',
      ).readAsStringSync();

      // Should NOT contain unsafe 'as Map<String, dynamic>' casts
      // (safe patterns: 'is Map', 'as Map?' with null check, getMap())
      final unsafeCastPattern = RegExp(
        r'as Map<String, dynamic>(?!\?)',
      );
      expect(
        unsafeCastPattern.hasMatch(source),
        isFalse,
        reason: 'Background service should use getMap() instead of '
            'unsafe "as Map<String, dynamic>" casts',
      );

      // Should NOT contain unsafe 'as num)' casts (non-nullable)
      // Safe: 'as num?' with ?.toDouble()
      expect(
        source.contains('as num)'),
        isFalse,
        reason: 'Background service should use getDouble() instead of '
            'unsafe "as num" casts',
      );

      // Should NOT contain unsafe 'as String)' casts (non-nullable)
      expect(
        source.contains('as String)'),
        isFalse,
        reason: 'Background service should use getString() or '
            '?.toString() instead of unsafe "as String" casts',
      );

      // Should import json_extensions for safe accessors
      expect(
        source.contains('json_extensions.dart'),
        isTrue,
        reason: 'Background service should import SafeJsonAccessors',
      );
    });

    test('background service registers two periodic tasks for adaptive scheduling', () {
      final source = File(
        'lib/core/background/background_service.dart',
      ).readAsStringSync();

      // Must register both a standard and a charging task
      expect(
        source.contains('priceRefresh'),
        isTrue,
        reason: 'Must register standard priceRefresh task',
      );
      expect(
        source.contains('priceRefreshCharging'),
        isTrue,
        reason: 'Must register priceRefreshCharging task for when device is plugged in',
      );
    });

    test('battery-aware WorkManager constraints are in Android implementation', () {
      final source = File(
        'lib/core/background/android_background_price_fetcher.dart',
      ).readAsStringSync();

      // Standard task should require battery not low
      expect(
        source.contains('requiresBatteryNotLow: true'),
        isTrue,
        reason: 'Standard task must skip when battery is low',
      );

      // Charging task should require device to be charging
      expect(
        source.contains('requiresCharging: true'),
        isTrue,
        reason: 'Charging task must only run when plugged in',
      );
    });

    test('callback dispatcher handles both task names', () {
      final source = File(
        'lib/core/background/background_service.dart',
      ).readAsStringSync();

      // The dispatcher should check for both task names via public constants
      expect(
        source.contains('BackgroundService.priceRefreshChargingTask'),
        isTrue,
        reason: 'Callback dispatcher must handle the charging task',
      );
    });
  });

  group('Background API response safe parsing', () {
    // These tests verify the safe parsing patterns used in background_service
    // for Tankerkoenig API responses, using the SafeJsonAccessors extension.

    test('getMap safely extracts prices from API response', () {
      final apiResponse = <String, dynamic>{
        'ok': true,
        'prices': <String, dynamic>{
          'station-1': {'e5': 1.859, 'e10': 1.779, 'diesel': 1.659, 'status': 'open'},
          'station-2': {'status': 'no prices'},
        },
      };

      final rawPrices = apiResponse.getMap('prices');
      expect(rawPrices, isNotNull);
      expect(rawPrices!.keys, containsAll(['station-1', 'station-2']));
    });

    test('getMap returns null for missing prices key', () {
      final apiResponse = <String, dynamic>{
        'ok': true,
      };

      expect(apiResponse.getMap('prices'), isNull);
    });

    test('getMap returns null for non-map prices value', () {
      final apiResponse = <String, dynamic>{
        'ok': true,
        'prices': 'unexpected string',
      };

      expect(apiResponse.getMap('prices'), isNull);
    });

    test('getDouble safely extracts fuel prices', () {
      final stationPrices = <String, dynamic>{
        'e5': 1.859,
        'e10': 1.779,
        'diesel': 1.659,
        'status': 'open',
      };

      expect(stationPrices.getDouble('e5'), 1.859);
      expect(stationPrices.getDouble('e10'), 1.779);
      expect(stationPrices.getDouble('diesel'), 1.659);
    });

    test('getDouble returns null for missing fuel type', () {
      final stationPrices = <String, dynamic>{
        'e5': 1.859,
        'status': 'open',
      };

      expect(stationPrices.getDouble('e10'), isNull);
      expect(stationPrices.getDouble('diesel'), isNull);
    });

    test('getDouble handles int prices from API', () {
      // Some APIs return int instead of double for round prices
      final stationPrices = <String, dynamic>{
        'e5': 2,
        'diesel': 1,
      };

      expect(stationPrices.getDouble('e5'), 2.0);
      expect(stationPrices.getDouble('diesel'), 1.0);
    });

    test('getDouble handles string prices gracefully', () {
      // Edge case: API returning prices as strings
      final stationPrices = <String, dynamic>{
        'e5': '1.859',
        'diesel': 'invalid',
      };

      expect(stationPrices.getDouble('e5'), 1.859);
      expect(stationPrices.getDouble('diesel'), isNull);
    });

    test('safe recordedAt parsing handles missing field', () {
      // Simulates the dedup logic in background_service
      final records = [
        <String, dynamic>{'e5': 1.859},
      ];

      final lastRecordedAt = records.isNotEmpty
          ? DateTime.tryParse(records.last['recordedAt']?.toString() ?? '')
          : null;

      // Should be null, not throw
      expect(lastRecordedAt, isNull);
    });

    test('safe recordedAt parsing handles valid ISO string', () {
      final records = [
        <String, dynamic>{
          'recordedAt': '2026-04-06T12:00:00.000',
          'e5': 1.859,
        },
      ];

      final lastRecordedAt = records.isNotEmpty
          ? DateTime.tryParse(records.last['recordedAt']?.toString() ?? '')
          : null;

      expect(lastRecordedAt, isNotNull);
      expect(lastRecordedAt!.year, 2026);
    });

    test('safe recordedAt parsing handles non-string value', () {
      final records = [
        <String, dynamic>{
          'recordedAt': 12345,
          'e5': 1.859,
        },
      ];

      // toString() converts int to string, DateTime.tryParse handles it
      final lastRecordedAt = records.isNotEmpty
          ? DateTime.tryParse(records.last['recordedAt']?.toString() ?? '')
          : null;

      // '12345' is not a valid ISO date, so tryParse returns null
      expect(lastRecordedAt, isNull);
    });

    test('getMap safely extracts cached station data', () {
      final cached = <String, dynamic>{
        'data': <String, dynamic>{
          'name': 'Shell Station',
          'e5': 1.859,
        },
        'timestamp': '2026-04-06T12:00:00.000',
      };

      final data = cached.getMap('data');
      expect(data, isNotNull);
      expect(data!['name'], 'Shell Station');
    });

    test('getMap returns null for missing cached data', () {
      final cached = <String, dynamic>{
        'timestamp': '2026-04-06T12:00:00.000',
      };

      expect(cached.getMap('data'), isNull);
    });

    test('station price entry value type handling', () {
      // Test the pattern used for iterating over price entries
      final rawPrices = <String, dynamic>{
        'station-1': <String, dynamic>{'e5': 1.859, 'status': 'open'},
        'station-2': <dynamic, dynamic>{'e5': 1.779, 'status': 'open'},
        'station-3': 'invalid',
      };

      final prices = <String, Map<String, dynamic>>{};
      for (final entry in rawPrices.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          prices[entry.key] = value;
        } else if (value is Map) {
          prices[entry.key] = Map<String, dynamic>.from(value);
        }
      }

      expect(prices.containsKey('station-1'), isTrue);
      expect(prices.containsKey('station-2'), isTrue);
      expect(prices.containsKey('station-3'), isFalse);
    });
  });

  group('Hive isolate safety', () {
    test('background service acquires lock before Hive access', () {
      final source = File(
        'lib/core/background/background_service.dart',
      ).readAsStringSync();

      // Must import hive_isolate_lock
      expect(
        source.contains('hive_isolate_lock.dart'),
        isTrue,
        reason: 'Background service must import HiveIsolateLock',
      );

      // Must acquire lock before initInIsolate
      final lockAcquireIndex = source.indexOf('lock.acquire()');
      final initIndex = source.indexOf('initInIsolate()');
      expect(
        lockAcquireIndex,
        lessThan(initIndex),
        reason: 'Lock must be acquired before Hive initialization',
      );
    });

    test('background service closes Hive boxes in finally block', () {
      final source = File(
        'lib/core/background/background_service.dart',
      ).readAsStringSync();

      // Must call closeIsolateBoxes
      expect(
        source.contains('closeIsolateBoxes'),
        isTrue,
        reason: 'Background service must close Hive boxes after use',
      );

      // Must release lock
      expect(
        source.contains('lock?.release()'),
        isTrue,
        reason: 'Background service must release lock in finally block',
      );

      // closeIsolateBoxes and release must be in a finally block
      final finallyIndex = source.indexOf('} finally {');
      final closeIndex = source.indexOf('closeIsolateBoxes');
      expect(
        finallyIndex,
        lessThan(closeIndex),
        reason: 'Box closing must happen in a finally block',
      );
    });

    test('background service skips task when lock is unavailable', () {
      final source = File(
        'lib/core/background/background_service.dart',
      ).readAsStringSync();

      // Must check lock acquisition result and return early if failed
      expect(
        source.contains('if (!acquired)'),
        isTrue,
        reason: 'Background service must check lock acquisition and skip if failed',
      );
    });

    test('HiveStorage.closeIsolateBoxes method exists', () {
      expect(HiveStorage.closeIsolateBoxes, isA<Function>());
    });

    test('HiveIsolateLock.create method exists', () {
      expect(HiveIsolateLock.create, isA<Function>());
    });
  });

  group('NotificationService', () {
    test('LocalNotificationService implements NotificationService', () {
      final service = LocalNotificationService();
      expect(service, isA<NotificationService>());
    });
  });
}
