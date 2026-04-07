import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/android_background_price_fetcher.dart';
import 'package:tankstellen/core/background/background_price_fetcher.dart';
import 'package:tankstellen/core/background/background_service.dart';
import 'package:tankstellen/core/background/ios_background_price_fetcher_stub.dart';

void main() {
  group('BackgroundPriceFetcher interface', () {
    test('AndroidBackgroundPriceFetcher implements BackgroundPriceFetcher', () {
      final fetcher = AndroidBackgroundPriceFetcher();
      expect(fetcher, isA<BackgroundPriceFetcher>());
    });

    test('IosBackgroundPriceFetcherStub implements BackgroundPriceFetcher', () {
      final fetcher = IosBackgroundPriceFetcherStub();
      expect(fetcher, isA<BackgroundPriceFetcher>());
    });
  });

  group('IosBackgroundPriceFetcherStub', () {
    test('init completes without error', () async {
      final fetcher = IosBackgroundPriceFetcherStub();
      // Should complete without throwing
      await expectLater(fetcher.init(), completes);
    });

    test('cancelAll completes without error', () async {
      final fetcher = IosBackgroundPriceFetcherStub();
      await expectLater(fetcher.cancelAll(), completes);
    });
  });

  group('AndroidBackgroundPriceFetcher', () {
    test('init method exists and is callable', () {
      final fetcher = AndroidBackgroundPriceFetcher();
      expect(fetcher.init, isA<Function>());
    });

    test('cancelAll method exists and is callable', () {
      final fetcher = AndroidBackgroundPriceFetcher();
      expect(fetcher.cancelAll, isA<Function>());
    });

    test('uses BackgroundService task name constants', () {
      // Verify the Android implementation references the shared task names
      final source = File(
        'lib/core/background/android_background_price_fetcher.dart',
      ).readAsStringSync();

      expect(
        source.contains('BackgroundService.priceRefreshTask'),
        isTrue,
        reason: 'Must use shared task name constant from BackgroundService',
      );
      expect(
        source.contains('BackgroundService.priceRefreshChargingTask'),
        isTrue,
        reason: 'Must use shared charging task name constant from BackgroundService',
      );
    });

    test('registers both standard and charging tasks', () {
      final source = File(
        'lib/core/background/android_background_price_fetcher.dart',
      ).readAsStringSync();

      // Must call registerPeriodicTask twice
      final registerCalls = 'registerPeriodicTask'.allMatches(source).length;
      expect(
        registerCalls,
        equals(2),
        reason: 'Must register both standard and charging periodic tasks',
      );
    });

    test('uses battery-aware WorkManager constraints', () {
      final source = File(
        'lib/core/background/android_background_price_fetcher.dart',
      ).readAsStringSync();

      expect(
        source.contains('requiresBatteryNotLow: true'),
        isTrue,
        reason: 'Standard task must skip when battery is low',
      );
      expect(
        source.contains('requiresCharging: true'),
        isTrue,
        reason: 'Charging task must only run when plugged in',
      );
    });

    test('uses correct refresh intervals from BackgroundService', () {
      final source = File(
        'lib/core/background/android_background_price_fetcher.dart',
      ).readAsStringSync();

      expect(
        source.contains('BackgroundService.refreshInterval'),
        isTrue,
        reason: 'Must use refresh interval from BackgroundService constants',
      );
      expect(
        source.contains('BackgroundService.chargingRefreshInterval'),
        isTrue,
        reason: 'Must use charging refresh interval from BackgroundService constants',
      );
    });
  });

  group('BackgroundService.init delegates to platform fetcher', () {
    test('BackgroundService.init method exists', () {
      expect(BackgroundService.init, isA<Function>());
    });

    test('BackgroundService uses createBackgroundPriceFetcher', () {
      final source = File(
        'lib/core/background/background_service.dart',
      ).readAsStringSync();

      expect(
        source.contains('createBackgroundPriceFetcher'),
        isTrue,
        reason: 'BackgroundService.init must delegate to the platform factory',
      );
    });

    test('BackgroundService no longer imports workmanager directly for init', () {
      // The Workmanager import is still needed for the callbackDispatcher,
      // but init() should not call Workmanager() directly.
      final source = File(
        'lib/core/background/background_service.dart',
      ).readAsStringSync();

      // init() should not contain Workmanager().initialize or registerPeriodicTask
      final initMethod = source.substring(
        source.indexOf('static Future<void> init()'),
        source.indexOf('}', source.indexOf('static Future<void> init()')) + 1,
      );

      expect(
        initMethod.contains('Workmanager()'),
        isFalse,
        reason: 'init() must not call Workmanager() directly — '
            'that is now in AndroidBackgroundPriceFetcher',
      );
    });
  });

  group('BackgroundService task name constants', () {
    test('priceRefreshTask is the expected value', () {
      expect(BackgroundService.priceRefreshTask, 'priceRefresh');
    });

    test('priceRefreshChargingTask is the expected value', () {
      expect(BackgroundService.priceRefreshChargingTask, 'priceRefreshCharging');
    });

    test('callback dispatcher uses public task name constants', () {
      final source = File(
        'lib/core/background/background_service.dart',
      ).readAsStringSync();

      expect(
        source.contains('BackgroundService.priceRefreshTask'),
        isTrue,
        reason: 'Callback dispatcher must use public task name constant',
      );
      expect(
        source.contains('BackgroundService.priceRefreshChargingTask'),
        isTrue,
        reason: 'Callback dispatcher must use public charging task name constant',
      );
    });
  });

  group('Platform factory', () {
    test('factory file imports both implementations', () {
      final source = File(
        'lib/core/background/background_price_fetcher_provider.dart',
      ).readAsStringSync();

      expect(
        source.contains('android_background_price_fetcher.dart'),
        isTrue,
        reason: 'Factory must import Android implementation',
      );
      expect(
        source.contains('ios_background_price_fetcher_stub.dart'),
        isTrue,
        reason: 'Factory must import iOS stub',
      );
    });

    test('factory uses Platform.isAndroid for detection', () {
      final source = File(
        'lib/core/background/background_price_fetcher_provider.dart',
      ).readAsStringSync();

      expect(
        source.contains('Platform.isAndroid'),
        isTrue,
        reason: 'Factory must check Platform.isAndroid',
      );
    });
  });
}
