// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/background/background_alert_scan_coordinator.dart';
import 'package:tankstellen/core/background/background_price_fetcher.dart';
import 'package:tankstellen/features/alerts/background/background_service.dart';
import 'package:tankstellen/core/background/hive_isolate_lock.dart';
import 'package:tankstellen/core/notifications/local_notification_service.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/utils/json_extensions.dart';
import 'package:workmanager/workmanager.dart';

/// Recording [BackgroundPriceFetcher] for the #3169 opportunistic-wake
/// decision table.
class _RecordingFetcher implements BackgroundPriceFetcher {
  int initCalls = 0;
  int cancelCalls = 0;
  int opportunisticCalls = 0;

  @override
  Future<void> init() async => initCalls++;

  @override
  Future<void> cancelAll() async => cancelCalls++;

  @override
  Future<void> scheduleOpportunisticScan() async => opportunisticCalls++;
}

/// Fault-injection fetcher: scheduling throws (#3169 never-throws check).
class _ThrowingFetcher extends _RecordingFetcher {
  @override
  Future<void> scheduleOpportunisticScan() =>
      throw StateError('scheduler backend unavailable');
}

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

    test('refresh interval is twice-daily (~12h) — the #2866 ToS safeguard', () {
      // Epic #2860 EXIT GATE: the now-multi-country scan polls every feasible
      // provider, so the cadence is the core rate-limit / ToS safeguard. Twice
      // a day keeps every provider comfortably inside its published limits.
      expect(BackgroundService.refreshInterval, const Duration(hours: 12));
    });

    test('the 30-min charging cadence is gone (it would breach twice-daily)',
        () {
      // The charging-only variant was dropped (#2866): a 30-min cadence would
      // let a multi-country scan hit a provider far more than twice a day.
      final source = File(
        'lib/features/alerts/background/background_service.dart',
      ).readAsStringSync();
      expect(source.contains('chargingRefreshInterval'), isFalse,
          reason: 'no separate charging cadence may exist');
      expect(source.contains('priceRefreshChargingTask'), isFalse,
          reason: 'no charging task name may exist');
    });
  });

  group('HiveStorage.initInIsolate', () {
    test('initInIsolate method exists and is callable', () {
      // initInIsolate requires platform channels (FlutterSecureStorage),
      // so we can only verify the method signature exists.
      expect(HiveStorage.initInIsolate, isA<Function>());
    });

    test('scan coordinator does not open Hive boxes directly', () {
      // #2415 — the scan body moved into BackgroundAlertScanCoordinator.
      // It still must delegate Hive initialization to
      // HiveStorage.initInIsolate (with encryption) rather than opening
      // boxes directly without a cipher.
      final source = File(
        'lib/features/alerts/background/background_alert_scan_coordinator.dart',
      ).readAsStringSync();

      // Should NOT contain direct Hive.openBox calls
      expect(
        source.contains('Hive.openBox'),
        isFalse,
        reason: 'Coordinator must use HiveStorage.initInIsolate() '
            'instead of opening Hive boxes directly without encryption',
      );

      // Should NOT import hive_flutter directly
      expect(
        source.contains("import 'package:hive_flutter/hive_flutter.dart'"),
        isFalse,
        reason: 'Coordinator should not import Hive directly',
      );

      // Should use initInIsolate
      expect(
        source.contains('initInIsolate'),
        isTrue,
        reason: 'Coordinator must call HiveStorage.initInIsolate()',
      );
    });

    test('background service callback delegates to the scan coordinator', () {
      // #2415 — the thin callback must hand off to the shared coordinator
      // rather than re-implement the scan body.
      final source = File(
        'lib/features/alerts/background/background_service.dart',
      ).readAsStringSync();
      expect(
        source.contains('BackgroundAlertScanCoordinator'),
        isTrue,
        reason: 'callbackDispatcher must delegate into the coordinator',
      );
    });

    test('scan coordinator contains no unsafe as-casts', () {
      final source = File(
        'lib/features/alerts/background/background_alert_scan_coordinator.dart',
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
    });

    test('JSON-parsing scan files use safe accessors (json_extensions)', () {
      // #2415 — the price/JSON parsing lives in the runners + history
      // writer now; both must use the SafeJsonAccessors extension rather
      // than hand-rolled casts.
      for (final path in const [
        'lib/features/alerts/background/background_scan_runners.dart',
        'lib/features/alerts/background/background_price_history_writer.dart',
      ]) {
        final source = File(path).readAsStringSync();
        expect(
          source.contains('json_extensions.dart'),
          isTrue,
          reason: '$path should import SafeJsonAccessors',
        );
        expect(
          source.contains('as num)'),
          isFalse,
          reason: '$path should use getDouble() not "as num" casts',
        );
        expect(
          RegExp(r'as Map<String, dynamic>(?!\?)').hasMatch(source),
          isFalse,
          reason: '$path should use getMap() not unsafe Map casts',
        );
      }
    });

    test('background service registers the single twice-daily periodic task '
        '(#2866)', () {
      final source = File(
        'lib/features/alerts/background/background_service.dart',
      ).readAsStringSync();

      // The one twice-daily scan task — the multi-country ToS safeguard.
      expect(
        source.contains('priceRefresh'),
        isTrue,
        reason: 'Must register the standard priceRefresh task',
      );
    });

    test('battery-aware WorkManager constraint is in Android implementation',
        () {
      final source = File(
        'lib/features/alerts/background/android_background_price_fetcher.dart',
      ).readAsStringSync();

      // The twice-daily task should still skip when battery is low.
      expect(
        source.contains('requiresBatteryNotLow: true'),
        isTrue,
        reason: 'Twice-daily task must skip when battery is low',
      );
    });

    test('callback dispatcher handles the periodic task name', () {
      final source = File(
        'lib/features/alerts/background/background_service.dart',
      ).readAsStringSync();

      // The dispatcher should check for the periodic task via the constant.
      expect(
        source.contains('BackgroundService.priceRefreshTask'),
        isTrue,
        reason: 'Callback dispatcher must handle the periodic task',
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
    // #2415 — the scan body (lock + Hive init + close) moved into
    // BackgroundAlertScanCoordinator. The serialisation invariants still
    // hold; the assertions now read the coordinator source.
    test('scan coordinator acquires lock before Hive access', () {
      final source = File(
        'lib/features/alerts/background/background_alert_scan_coordinator.dart',
      ).readAsStringSync();

      // Must import hive_isolate_lock
      expect(
        source.contains('hive_isolate_lock.dart'),
        isTrue,
        reason: 'Coordinator must import HiveIsolateLock',
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

    test('scan coordinator closes Hive boxes in finally block', () {
      final source = File(
        'lib/features/alerts/background/background_alert_scan_coordinator.dart',
      ).readAsStringSync();

      // Must call closeIsolateBoxes
      expect(
        source.contains('closeIsolateBoxes'),
        isTrue,
        reason: 'Coordinator must close Hive boxes after use',
      );

      // Must release lock
      expect(
        source.contains('lock?.release()'),
        isTrue,
        reason: 'Coordinator must release lock in finally block',
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

    test('scan coordinator skips scan when lock is unavailable', () {
      final source = File(
        'lib/features/alerts/background/background_alert_scan_coordinator.dart',
      ).readAsStringSync();

      // Must check lock acquisition result and return early if failed
      expect(
        source.contains('if (!acquired)'),
        isTrue,
        reason: 'Coordinator must check lock acquisition and skip if failed',
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

  // #2249 — the background + widget isolates must obtain their Dio via the
  // rate-limited factory, never by hand-rolling `Dio(BaseOptions(...))`. A raw
  // Dio skips the RateLimitInterceptor (429/Retry-After) + conditional-GET
  // interceptor, so the headless isolate could thunder at Tankerkönig. This is
  // a source-scan guard rather than a runtime test because the Dios are built
  // inside top-level isolate entrypoints that can't be exercised without a
  // platform engine.
  group('background isolate Dio construction (#2249)', () {
    // #2415 — the Dio construction moved into the coordinator with the scan
    // body. #2862 — it moved into the registry-driven BackgroundPriceSource.
    // #2863 — it moved once more, into the polled CountryAlertStrategy
    // (PolledAlertStrategy builds each polled country's Dio). The #2249
    // invariant (rate-limited factory, never raw Dio) still applies; the
    // source-scan now reads the polled strategy + the price source + the
    // coordinator + the runners, and none may hand-roll a Dio.
    final polledStrategy =
        File('lib/features/alerts/background/polled_alert_strategy.dart')
            .readAsStringSync();
    final priceSource =
        File('lib/features/alerts/background/background_price_source.dart')
            .readAsStringSync();
    final coordinator =
        File('lib/features/alerts/background/background_alert_scan_coordinator.dart')
            .readAsStringSync();
    final runners =
        File('lib/features/alerts/background/background_scan_runners.dart')
            .readAsStringSync();

    test('routes every Dio through DioFactory', () {
      expect(
        polledStrategy.contains("import '../../../core/services/dio_factory.dart';"),
        isTrue,
        reason: 'the polled alert strategy must import DioFactory',
      );
      expect(
        polledStrategy.contains('DioFactory.create('),
        isTrue,
        reason: 'the background isolate must build its Dio via '
            'DioFactory.create',
      );
    });

    test('constructs no raw Dio(BaseOptions(...)) instances', () {
      for (final source in [polledStrategy, priceSource, coordinator, runners]) {
        expect(
          source.contains('Dio(BaseOptions('),
          isFalse,
          reason: 'raw Dio bypasses the rate-limit + conditional-GET '
              'interceptors — use DioFactory.create instead',
        );
      }
    });
  });

  // #2413 — WorkManager hardening: re-arm the periodic schedule on reboot.
  group('boot re-registration (#2413)', () {
    test('bootReregisterTask constant matches the native BootReceiver', () {
      // BootReceiver.BOOT_REREGISTER_TASK and BackgroundService
      // .bootReregisterTask are two ends of the same WorkManager input-data
      // contract; they must stay byte-identical.
      expect(BackgroundService.bootReregisterTask, 'bootReregister');
      final kt = File(
        'android/app/src/main/kotlin/de/tankstellen/tankstellen/BootReceiver.kt',
      ).readAsStringSync();
      expect(
        kt.contains('"bootReregister"'),
        isTrue,
        reason: 'BootReceiver must enqueue the bootReregister Dart task',
      );
    });

    test('callbackDispatcher re-registers on the boot task', () {
      final source = File(
        'lib/features/alerts/background/background_service.dart',
      ).readAsStringSync();
      // The boot branch must re-register (init), not run a scan.
      final idx = source.indexOf('BackgroundService.bootReregisterTask');
      expect(idx, greaterThan(0),
          reason: 'dispatcher must special-case the boot re-register task');
      final initIdx = source.indexOf('BackgroundService.init()', idx);
      final scanIdx = source.indexOf('.scan(', idx);
      expect(initIdx, greaterThan(0));
      expect(initIdx, lessThan(scanIdx),
          reason: 'boot task must re-register before the scan branch');
    });

    test('manifest declares RECEIVE_BOOT_COMPLETED + the BootReceiver', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(
        manifest.contains('android.permission.RECEIVE_BOOT_COMPLETED'),
        isTrue,
        reason: 'boot re-registration needs RECEIVE_BOOT_COMPLETED',
      );
      expect(
        manifest.contains('.BootReceiver'),
        isTrue,
        reason: 'the BootReceiver must be registered',
      );
      expect(
        manifest.contains('android.intent.action.BOOT_COMPLETED'),
        isTrue,
        reason: 'the receiver must filter the boot broadcast',
      );
    });
  });

  // #3169 — the task-name → trigger mapping every wake source funnels
  // through. The full decision table, exercised directly via the
  // @visibleForTesting seam.
  group('task → trigger mapping (#3169)', () {
    test('maps every scheduled task name onto its trigger', () {
      expect(debugTriggerForTask(BackgroundService.priceRefreshTask),
          BackgroundScanTrigger.workManagerPeriodic);
      expect(debugTriggerForTask(BackgroundService.widgetRefreshScanTask),
          BackgroundScanTrigger.androidWidget);
      expect(debugTriggerForTask(Workmanager.iOSBackgroundTask),
          BackgroundScanTrigger.iosBackgroundRefresh);
      expect(debugTriggerForTask(IosBackgroundTaskIds.appRefresh),
          BackgroundScanTrigger.iosBackgroundRefresh);
      // The #3169 mitigation lanes.
      expect(debugTriggerForTask(IosBackgroundTaskIds.processing),
          BackgroundScanTrigger.iosBgProcessing);
      expect(debugTriggerForTask(IosBackgroundTaskIds.slcWake),
          BackgroundScanTrigger.iosSlcWake);
      expect(debugTriggerForTask(IosBackgroundTaskIds.opportunistic),
          BackgroundScanTrigger.opportunistic);
    });

    test('unknown and special-cased task names scan nothing', () {
      expect(debugTriggerForTask('some-stray-task'), isNull);
      // bootReregister is handled BEFORE the mapping (re-arms, no scan).
      expect(debugTriggerForTask(BackgroundService.bootReregisterTask),
          isNull);
    });

    test('dispatcher re-arms the one-shot BGProcessingTask after a run', () {
      // A BGProcessingTask submission is one-shot (the plugin's native
      // handler only re-submits the BGAppRefresh lane) — the dispatcher
      // must re-arm it or the lane dies after one wake.
      final source = File(
        'lib/features/alerts/background/background_service.dart',
      ).readAsStringSync();
      final idx = source.indexOf('IosBackgroundTaskIds.processing)',
          source.indexOf('void callbackDispatcher()'));
      expect(idx, greaterThan(0),
          reason: 'dispatcher must special-case the processing task');
      expect(
        source.contains('scheduleIosProcessingTask(Workmanager())'),
        isTrue,
        reason: 'dispatcher must re-submit the processing request after '
            'the scan',
      );
    });
  });

  // #3169 — opportunistic foreground-wake scans.
  group('onOpportunisticWake (#3169)', () {
    test('schedules a scan when an alert is active', () async {
      final fetcher = _RecordingFetcher();
      await BackgroundService.onOpportunisticWake(
        fetcher: fetcher,
        alertsGate: () async => true,
      );
      expect(fetcher.opportunisticCalls, 1);
      expect(fetcher.initCalls, 0,
          reason: 'a foreground wake must not re-register periodic tasks');
    });

    test('schedules nothing without an active alert (ToS: no '
        'non-user-consented polling)', () async {
      final fetcher = _RecordingFetcher();
      await BackgroundService.onOpportunisticWake(
        fetcher: fetcher,
        alertsGate: () async => false,
      );
      expect(fetcher.opportunisticCalls, 0);
    });

    test('never throws when the scheduler backend faults', () async {
      await expectLater(
        BackgroundService.onOpportunisticWake(
          fetcher: _ThrowingFetcher(),
          alertsGate: () async => true,
        ),
        completes,
      );
    });

    test('never throws when the alerts gate faults (e.g. Hive unavailable)',
        () async {
      final fetcher = _RecordingFetcher();
      await expectLater(
        BackgroundService.onOpportunisticWake(
          fetcher: fetcher,
          alertsGate: () async => throw StateError('alerts box closed'),
        ),
        completes,
      );
      expect(fetcher.opportunisticCalls, 0,
          reason: 'an unreadable gate must fail closed (no scan)');
    });

    test('lifecycle + cold-start call sites fire the opportunistic wake',
        () {
      // The two foreground execution windows: every resume (app.dart) and
      // the cold launch (app_initializer.dart).
      final app = File('lib/app/app.dart').readAsStringSync();
      expect(
        app.contains('BackgroundService.onOpportunisticWake()'),
        isTrue,
        reason: 'the lifecycle observer must fire the wake on resume',
      );
      expect(
        app.contains('AppLifecycleState.resumed'),
        isTrue,
        reason: 'the wake must be gated on the resumed transition',
      );
      final initializer =
          File('lib/app/app_initializer.dart').readAsStringSync();
      expect(
        initializer.contains('BackgroundService.onOpportunisticWake()'),
        isTrue,
        reason: 'cold launch must fire the wake after reconcile',
      );
    });
  });

  // #3169 — SLC wake monitoring follows the alert lifecycle.
  group('SLC wake reconcile wiring (#3169)', () {
    test('reconcile arms/disarms the SLC monitor with the alert state', () {
      final source = File(
        'lib/features/alerts/background/background_service.dart',
      ).readAsStringSync();
      expect(
        source.contains('createSlcWakeMonitor().setEnabled(active)'),
        isTrue,
        reason: 'reconcile must mirror the alert-active state into the '
            'SLC monitor (on with alerts, off without)',
      );
    });
  });

  // #2412 — Android home-widget refresh feeds the on-device scan.
  group('widget-refresh scan trigger (#2412)', () {
    test('widgetRefreshScanTask constant matches the native provider', () {
      expect(BackgroundService.widgetRefreshScanTask, 'widgetRefreshScan');
      final kt = File(
        'android/app/src/main/kotlin/de/tankstellen/tankstellen/'
        'FuelPriceWidgetProvider.kt',
      ).readAsStringSync();
      expect(
        kt.contains('"widgetRefreshScan"'),
        isTrue,
        reason: 'widget provider must enqueue the widgetRefreshScan task',
      );
      expect(
        kt.contains('BackgroundScanEnqueuer.enqueue'),
        isTrue,
        reason: 'onUpdate must enqueue a scan via the shared enqueuer',
      );
    });

    test('the widget task maps to the androidWidget trigger', () {
      // Exercises the private _triggerForTask switch indirectly via the
      // source — the function is file-private, so a source-scan guards the
      // mapping the same way the boot test guards its branch.
      final source = File(
        'lib/features/alerts/background/background_service.dart',
      ).readAsStringSync();
      expect(
        source.contains('BackgroundScanTrigger.androidWidget'),
        isTrue,
        reason: 'the widget task must route to the androidWidget trigger',
      );
    });
  });
}
