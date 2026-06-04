// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/background/android_background_price_fetcher.dart';
import 'package:tankstellen/core/background/background_price_fetcher.dart';
import 'package:tankstellen/core/background/background_service.dart';
import 'package:tankstellen/core/background/ios_background_price_fetcher.dart';
import 'package:tankstellen/core/background/noop_background_price_fetcher.dart';

void main() {
  group('BackgroundPriceFetcher interface', () {
    test('AndroidBackgroundPriceFetcher implements BackgroundPriceFetcher', () {
      final fetcher = AndroidBackgroundPriceFetcher();
      expect(fetcher, isA<BackgroundPriceFetcher>());
    });

    test('IosBackgroundPriceFetcher implements BackgroundPriceFetcher', () {
      final fetcher = IosBackgroundPriceFetcher();
      expect(fetcher, isA<BackgroundPriceFetcher>());
    });

    test('NoopBackgroundPriceFetcher implements BackgroundPriceFetcher', () {
      final fetcher = NoopBackgroundPriceFetcher();
      expect(fetcher, isA<BackgroundPriceFetcher>());
    });
  });

  group('NoopBackgroundPriceFetcher', () {
    test('init completes without error', () async {
      final fetcher = NoopBackgroundPriceFetcher();
      await expectLater(fetcher.init(), completes);
    });

    test('cancelAll completes without error', () async {
      final fetcher = NoopBackgroundPriceFetcher();
      await expectLater(fetcher.cancelAll(), completes);
    });
  });

  group('IosBackgroundPriceFetcher', () {
    test('init / cancelAll exist and are callable', () {
      final fetcher = IosBackgroundPriceFetcher();
      expect(fetcher.init, isA<Function>());
      expect(fetcher.cancelAll, isA<Function>());
    });

    test('registers the BGAppRefresh identifier matching Info.plist', () {
      final source = File(
        'lib/core/background/ios_background_price_fetcher.dart',
      ).readAsStringSync();
      expect(
        source.contains('IosBackgroundTaskIds.appRefresh'),
        isTrue,
        reason: 'iOS fetcher must register the shared BGTask identifier',
      );
    });

    test('the iOS BGTask identifier matches Info.plist', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(
        plist.contains('de.tankstellen.tankstellen.background'),
        isTrue,
        reason: 'BGTaskSchedulerPermittedIdentifiers must list the task id',
      );
      expect(
        IosBackgroundTaskIds.appRefresh,
        'de.tankstellen.tankstellen.background',
      );
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

    test('uses the BackgroundService periodic task name constant', () {
      // Verify the Android implementation references the shared task name.
      final source = File(
        'lib/core/background/android_background_price_fetcher.dart',
      ).readAsStringSync();

      expect(
        source.contains('BackgroundService.priceRefreshTask'),
        isTrue,
        reason: 'Must use shared task name constant from BackgroundService',
      );
    });

    test('registers exactly ONE periodic task — the twice-daily scan (#2866)',
        () {
      final source = File(
        'lib/core/background/android_background_price_fetcher.dart',
      ).readAsStringSync();

      // Exactly one registerPeriodicTask: the 30-min charging task was dropped
      // so a multi-country scan can never hit a provider more than twice a day.
      final registerCalls = 'registerPeriodicTask'.allMatches(source).length;
      expect(
        registerCalls,
        equals(1),
        reason: 'Must register exactly one twice-daily periodic task',
      );
    });

    test('uses a battery-aware WorkManager constraint (no charging variant)',
        () {
      final source = File(
        'lib/core/background/android_background_price_fetcher.dart',
      ).readAsStringSync();

      expect(
        source.contains('requiresBatteryNotLow: true'),
        isTrue,
        reason: 'Twice-daily task must skip when battery is low',
      );
      expect(
        source.contains('requiresCharging: true'),
        isFalse,
        reason: 'The charging-only task was removed (#2866)',
      );
    });

    test('uses the twice-daily refresh interval from BackgroundService', () {
      final source = File(
        'lib/core/background/android_background_price_fetcher.dart',
      ).readAsStringSync();

      expect(
        source.contains('BackgroundService.refreshInterval'),
        isTrue,
        reason: 'Must use refresh interval from BackgroundService constants',
      );
      expect(
        source.contains('chargingRefreshInterval'),
        isFalse,
        reason: 'No separate charging interval exists anymore (#2866)',
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

    test('callback dispatcher uses the public task name constant', () {
      final source = File(
        'lib/core/background/background_service.dart',
      ).readAsStringSync();

      expect(
        source.contains('BackgroundService.priceRefreshTask'),
        isTrue,
        reason: 'Callback dispatcher must use public task name constant',
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
        source.contains('ios_background_price_fetcher.dart'),
        isTrue,
        reason: 'Factory must import iOS implementation',
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
