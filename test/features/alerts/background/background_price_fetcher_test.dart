// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/background/android_background_price_fetcher.dart';
import 'package:tankstellen/core/background/background_price_fetcher.dart';
import 'package:tankstellen/features/alerts/background/background_service.dart';
import 'package:tankstellen/features/alerts/background/ios_background_price_fetcher.dart';
import 'package:tankstellen/features/alerts/background/noop_background_price_fetcher.dart';
import 'package:workmanager/workmanager.dart';

/// Recording [Workmanager] fake — captures every scheduling call so the
/// #3169 scheduling decision table is testable without platform channels.
class _RecordingWorkmanager implements Workmanager {
  final List<Invocation> calls = [];

  Iterable<Invocation> named(Symbol member) =>
      calls.where((c) => c.memberName == member);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation);
    if (invocation.memberName == #printScheduledTasks) {
      return Future<String>.value('');
    }
    return Future<void>.value();
  }
}

/// Fault-injection [Workmanager]: every call throws, to exercise the
/// never-throws contracts (#3169).
class _ThrowingWorkmanager implements Workmanager {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('workmanager backend unavailable');
}

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
        'lib/features/alerts/background/ios_background_price_fetcher.dart',
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

    // #3169 — the BGProcessingTask lane: Info.plist permitted-identifier +
    // AppDelegate handler registration + Dart submission all share one id.
    test('the BGProcessingTask identifier matches Info.plist + AppDelegate',
        () {
      expect(
        IosBackgroundTaskIds.processing,
        'de.tankstellen.tankstellen.processing',
      );
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(
        plist.contains('de.tankstellen.tankstellen.processing'),
        isTrue,
        reason: 'BGTaskSchedulerPermittedIdentifiers must list the '
            'processing task id (#3169)',
      );
      final appDelegate =
          File('ios/Runner/AppDelegate.swift').readAsStringSync();
      expect(
        appDelegate.contains('registerBGProcessingTask'),
        isTrue,
        reason: 'AppDelegate must install the BGProcessingTask launch '
            'handler (#3169)',
      );
      expect(
        appDelegate.contains('de.tankstellen.tankstellen.processing'),
        isTrue,
        reason: 'AppDelegate must register the same identifier the Dart '
            'side submits',
      );
    });

    test('the SLC one-off identifier matches the native SlcWakeBridge', () {
      // The slcWake task is enqueued NATIVELY (startOneOffTask) so the
      // Swift literal and the Dart constant are two ends of one contract.
      expect(
        IosBackgroundTaskIds.slcWake,
        'de.tankstellen.tankstellen.slcWake',
      );
      final appDelegate =
          File('ios/Runner/AppDelegate.swift').readAsStringSync();
      expect(
        appDelegate.contains('"de.tankstellen.tankstellen.slcWake"'),
        isTrue,
        reason: 'SlcWakeBridge must enqueue the slcWake one-off task id',
      );
      expect(
        appDelegate.contains('startOneOffTask'),
        isTrue,
        reason: 'the SLC wake must ride the workmanager one-off path so it '
            'runs the shared coordinator scan',
      );
    });

    test('the SLC bridge never prompts for location permission', () {
      // HARD requirement (#3169): SLC piggybacks an EXISTING Always grant;
      // alerts must never escalate the location permission. Comments are
      // stripped so the bridge's own "never calls request…" dartdoc cannot
      // mask (or trip) the code scan.
      final appDelegate = File('ios/Runner/AppDelegate.swift')
          .readAsLinesSync()
          .where((line) => !line.trimLeft().startsWith('//'))
          .map((line) {
            final comment = line.indexOf('// ');
            return comment < 0 ? line : line.substring(0, comment);
          })
          .join('\n');
      expect(
        appDelegate.contains('requestAlwaysAuthorization'),
        isFalse,
        reason: 'SlcWakeBridge must never request Always authorization',
      );
      expect(
        appDelegate.contains('requestWhenInUseAuthorization'),
        isFalse,
        reason: 'SlcWakeBridge must never request any location permission',
      );
      expect(
        appDelegate.contains('.authorizedAlways'),
        isTrue,
        reason: 'SLC monitoring must gate on an existing Always grant',
      );
    });
  });

  // #3169 — the scheduling decision table, driven through a recording
  // Workmanager fake (no platform channels needed).
  group('iOS scheduling decision table (#3169)', () {
    test('init registers the BGAppRefresh periodic task AND arms the '
        'BGProcessingTask lane', () async {
      final wm = _RecordingWorkmanager();
      await IosBackgroundPriceFetcher(workmanager: wm).init();

      expect(wm.named(#initialize), hasLength(1));

      final periodic = wm.named(#registerPeriodicTask).single;
      expect(periodic.positionalArguments,
          [IosBackgroundTaskIds.appRefresh, IosBackgroundTaskIds.appRefresh]);

      final processing = wm.named(#registerProcessingTask).single;
      expect(
          processing.positionalArguments,
          [IosBackgroundTaskIds.processing, IosBackgroundTaskIds.processing]);
      expect(processing.namedArguments[#initialDelay],
          IosBackgroundTaskIds.processingEarliestDelay);
      final constraints =
          processing.namedArguments[#constraints] as Constraints?;
      expect(constraints?.networkType, NetworkType.connected,
          reason: 'a scan without network is a dead wake');
      expect(constraints?.requiresCharging, isNot(isTrue),
          reason: 'requiring external power would forfeit most run chances');
    });

    test('the processing earliest-begin delay sits between the foreground '
        'cooldown and the periodic cadence', () {
      expect(IosBackgroundTaskIds.processingEarliestDelay,
          greaterThan(const Duration(minutes: 10)),
          reason: 'must not duplicate a just-completed scan');
      expect(IosBackgroundTaskIds.processingEarliestDelay,
          lessThan(BackgroundService.refreshInterval),
          reason: 'the lane must be able to add wakes between periodic runs');
    });

    test('scheduleOpportunisticScan enqueues exactly one immediate one-off '
        'task in the opportunistic lane', () async {
      final wm = _RecordingWorkmanager();
      await IosBackgroundPriceFetcher(workmanager: wm)
          .scheduleOpportunisticScan();

      final oneOff = wm.named(#registerOneOffTask).single;
      expect(oneOff.positionalArguments, [
        IosBackgroundTaskIds.opportunistic,
        IosBackgroundTaskIds.opportunistic,
      ]);
      expect(wm.named(#registerPeriodicTask), isEmpty,
          reason: 'a foreground wake must not touch the periodic schedule');
      expect(wm.named(#registerProcessingTask), isEmpty);
    });

    test('cancelAll cancels everything (alerts went inactive)', () async {
      final wm = _RecordingWorkmanager();
      await IosBackgroundPriceFetcher(workmanager: wm).cancelAll();
      expect(wm.named(#cancelAll), hasLength(1));
    });

    test('scheduleIosProcessingTask never throws (fault injection)',
        () async {
      // Never-throws contract: a re-arm failure inside the dispatcher must
      // not fail the scan that triggered it.
      final wm = _ThrowingWorkmanager();
      await expectLater(scheduleIosProcessingTask(wm), completes);
    });

    test('Android scheduleOpportunisticScan is a deliberate no-op '
        '(SLA already met, provider budget protected)', () async {
      final wm = _RecordingWorkmanager();
      await AndroidBackgroundPriceFetcher(workmanager: wm)
          .scheduleOpportunisticScan();
      expect(wm.calls, isEmpty);
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
        'lib/features/alerts/background/android_background_price_fetcher.dart',
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
        'lib/features/alerts/background/android_background_price_fetcher.dart',
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
        'lib/features/alerts/background/android_background_price_fetcher.dart',
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
        'lib/features/alerts/background/android_background_price_fetcher.dart',
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
        'lib/features/alerts/background/background_service.dart',
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
        'lib/features/alerts/background/background_service.dart',
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
        'lib/features/alerts/background/background_service.dart',
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
        'lib/features/alerts/background/background_price_fetcher_provider.dart',
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
        'lib/features/alerts/background/background_price_fetcher_provider.dart',
      ).readAsStringSync();

      expect(
        source.contains('Platform.isAndroid'),
        isTrue,
        reason: 'Factory must check Platform.isAndroid',
      );
    });
  });
}
