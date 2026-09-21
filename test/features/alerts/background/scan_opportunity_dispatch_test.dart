// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/constants/field_names.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/notifications/notification_delivery.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/background/background_scan_runners.dart';
import 'package:tankstellen/features/alerts/background/country_alert_strategy_resolver.dart';
import 'package:tankstellen/features/alerts/background/notification_templates.dart';
import 'package:tankstellen/features/alerts/background/opportunity_dispatcher.dart';
import 'package:tankstellen/features/alerts/background/scan_opportunity_dispatch.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/data/opportunity_feed_store.dart';
import 'package:tankstellen/features/alerts/data/repositories/alert_repository.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_budget.dart';

import '../../../fakes/fake_storage_repository.dart';
import '../../../helpers/hive_temp_dir.dart';

/// #4183 — a price observation in, a notification decision out.
///
/// The shape #4164 established, applied to the alert chain: drive the
/// real detector with real prices, through the real budget and the real
/// stores, with the clock injected. What this holds that no unit test
/// could is the sentence the issue was filed about — **three tripped
/// alerts used to be three notifications.**
void main() {
  late Directory tmpDir;
  final now = DateTime.utc(2026, 9, 15, 12);
  final templates = BackgroundNotificationTemplates.resolveForLanguage('en');

  PriceAlert alert(String stationId, {double target = 1.800}) => PriceAlert(
        id: 'a-$stationId',
        stationId: stationId,
        stationName: 'Station $stationId',
        fuelType: FuelType.e5,
        targetPrice: target,
        isActive: true,
        createdAt: DateTime.utc(2026, 9, 1),
      );

  Map<String, Map<String, dynamic>> pricesFor(Map<String, double> byStation) => {
        for (final e in byStation.entries)
          e.key: {
            TankerkoenigFields.status: TankerkoenigFields.statusOpen,
            TankerkoenigFields.e5: e.value,
          },
      };

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('scan_dispatch_');
    Hive.init(tmpDir.path);
    await Hive.openBox<dynamic>(HiveBoxes.alerts);
  });

  tearDown(() async {
    await closeHiveAndDeleteTemp(tmpDir);
  });

  test('three tripped alerts trip three times — detection is unchanged',
      () async {
    final found = await BackgroundScanRunners.detectPerStationAlerts(
      repo: AlertRepository(_FakeAlertStorage()),
      alerts: [alert('de-1'), alert('de-2'), alert('de-3')],
      prices: pricesFor({'de-1': 1.759, 'de-2': 1.749, 'de-3': 1.769}),
      now: now,
      templates: templates,
      fallbackCountryCode: 'DE',
    );

    expect(found, hasLength(3),
        reason: 'the budget throttles ATTENTION; it must not make the '
            'detector blind');
    expect(found.map((c) => c.copy!.body),
        everyElement(contains('€')));
  });

  test('a price above the target does not trip', () async {
    final found = await BackgroundScanRunners.detectPerStationAlerts(
      repo: AlertRepository(_FakeAlertStorage()),
      alerts: [alert('de-1', target: 1.700)],
      prices: pricesFor({'de-1': 1.759}),
      now: now,
      templates: templates,
      fallbackCountryCode: 'DE',
    );
    expect(found, isEmpty);
  });

  test('the detector no longer applies its own 4 h cooldown', () async {
    // #4183 — `BudgetPolicy.perStationQuiet` is 12 h and spans every
    // detector, so the local 4 h check became dead weight in front of a
    // stricter rule. This asserts the removal deliberately: the finding
    // reaches the budget, and the budget is what stays quiet.
    final found = await BackgroundScanRunners.detectPerStationAlerts(
      repo: AlertRepository(_FakeAlertStorage()),
      alerts: [
        PriceAlert(
          id: 'a1',
          stationId: 'de-1',
          stationName: 'S',
          fuelType: FuelType.e5,
          targetPrice: 1.800,
          isActive: true,
          createdAt: DateTime.utc(2026, 9, 1),
          lastTriggeredAt: now.subtract(const Duration(minutes: 10)),
        ),
      ],
      prices: pricesFor({'de-1': 1.759}),
      now: now,
      templates: templates,
      fallbackCountryCode: 'DE',
    );

    expect(found, hasLength(1),
        reason: 'one gate, in one place — the budget. Two overlapping '
            'cooldowns is what #4151 removed');
  });

  test('an inactive alert is not detected at all', () async {
    final found = await BackgroundScanRunners.detectPerStationAlerts(
      repo: AlertRepository(_FakeAlertStorage()),
      alerts: [
        PriceAlert(
          id: 'a1',
          stationId: 'de-1',
          stationName: 'S',
          fuelType: FuelType.e5,
          targetPrice: 1.800,
          isActive: false,
          createdAt: DateTime.utc(2026, 9, 1),
        ),
      ],
      prices: pricesFor({'de-1': 1.759}),
      now: now,
      templates: templates,
      fallbackCountryCode: 'DE',
    );
    expect(found, isEmpty);
  });

  test('a station with no prices is skipped', () async {
    final found = await BackgroundScanRunners.detectPerStationAlerts(
      repo: AlertRepository(_FakeAlertStorage()),
      alerts: [alert('de-1')],
      prices: {
        'de-1': {
          TankerkoenigFields.status: TankerkoenigFields.statusNoPrices,
          TankerkoenigFields.e5: 1.759,
        },
      },
      now: now,
      templates: templates,
      fallbackCountryCode: 'DE',
    );
    expect(found, isEmpty);
  });

  test('every candidate carries the copy its path has always produced',
      () async {
    final found = await BackgroundScanRunners.detectPerStationAlerts(
      repo: AlertRepository(_FakeAlertStorage()),
      alerts: [alert('de-1')],
      prices: pricesFor({'de-1': 1.759}),
      now: now,
      templates: templates,
      fallbackCountryCode: 'DE',
    );

    final copy = found.single.copy!;
    expect(copy.title, contains('Station de-1'));
    expect(copy.body, contains('1.759'));
    expect(copy.body, contains('1.800'),
        reason: 'the target is the reference, and it is the most '
            'checkable one there is — the user set it');
  });

  // #4335 — `lastTriggeredAt` is shown in the alert list as "you were
  // told". A suppressed delivery must not write it.
  group('lastTriggeredAt means the user was told (#4335)', () {
    Future<PriceAlert> run(NotificationService notifier) async {
      final storage = _FakeAlertStorage();
      final repo = AlertRepository(storage);
      final a = alert('de-1');
      await repo.saveAlert(a);
      await detectAndDispatch(
        repo: repo,
        alerts: [a],
        prices: pricesFor({'de-1': 1.759}),
        now: now,
        templates: templates,
        storage: HiveStorage(),
        resolver: CountryAlertStrategyResolver(
            storage: FakeStorageRepository(),
            cache: CacheManager(FakeStorageRepository())),
        activeCountry: 'DE',
        notifier: () async => notifier,
      );
      return repo.getAlerts().single;
    }

    test('posted: written', () async {
      expect((await run(_RecordingNotifier())).lastTriggeredAt, now);
    });

    test('suppressed: not written', () async {
      final notifier = _SilencedNotifier();
      expect((await run(notifier)).lastTriggeredAt, isNull);
      expect(notifier.sent, isEmpty);
    });
  });

  test('THE issue, end to end: three tripped alerts, one notification',
      () async {
    // A price observation in, a notification decision out — the real
    // detector feeding the real budget and the real stores. Before
    // #4183 this produced three notifications, one per tripped alert.
    final found = await BackgroundScanRunners.detectPerStationAlerts(
      repo: AlertRepository(_FakeAlertStorage()),
      alerts: [alert('de-1'), alert('de-2'), alert('de-3')],
      prices: pricesFor({'de-1': 1.759, 'de-2': 1.749, 'de-3': 1.769}),
      now: now,
      templates: templates,
      fallbackCountryCode: 'DE',
    );

    final notifier = _RecordingNotifier();
    final outcome = await const OpportunityDispatcher().dispatch(
      candidates: found,
      now: now,
      notifier: notifier,
      templates: templates,
    );

    expect(notifier.sent, hasLength(1));
    expect(outcome.demotions, hasLength(2));
    expect(outcome.demotions.map((d) => d.reason),
        everyElement(BudgetRefusal.outrankedInWindow),
        reason: 'the budget refused them, and the refusals are ITS enum — '
            'a dispatcher inventing its own reasons would make the feed '
            'and the budget disagree about why');

    final feed = const OpportunityFeedStore().read();
    expect(feed, hasLength(3),
        reason: 'nothing is lost; two of the three are simply not a push');
    expect(feed.where((e) => e.wasNotified), hasLength(1));
  });
}

/// A notifier whose OS has notifications turned off (#4335).
class _SilencedNotifier extends _RecordingNotifier
    implements NotificationDeliveryProbe {
  @override
  Future<NotificationDelivery?> blockedDelivery(
          NotificationChannelKind channel) async =>
      NotificationDelivery.suppressedPermission;

  @override
  Future<bool> openNotificationSettings() async => true;
}

/// Records what was posted instead of touching a platform channel.
class _RecordingNotifier implements NotificationService {
  final List<({int id, String title, String body})> sent = [];

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async =>
      sent.add((id: id, title: title, body: body));

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<void> showServiceReminder({
    required int id,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAll() async {}
}

/// Minimal in-memory storage for [AlertRepository].
class _FakeAlertStorage implements AlertStorage {
  List<Map<String, dynamic>> _alerts = [];

  @override
  List<Map<String, dynamic>> getAlerts() => _alerts;

  @override
  Future<void> saveAlerts(List<Map<String, dynamic>> alerts) async {
    _alerts = alerts;
  }

  @override
  Future<void> clearAlerts() async => _alerts = [];

  @override
  int get alertCount => _alerts.length;
}
