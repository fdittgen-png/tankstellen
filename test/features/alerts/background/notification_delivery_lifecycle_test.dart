// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4162 — the notification subsystem's interruptions, seen from delivery.
///
/// The OS revokes a permission or disables a channel without telling the
/// app, and `show` then returns normally while displaying nothing. A radius
/// alert's notification has to carry its deep link and its per-alert id
/// through the budget. These drive the REAL detector and dispatcher against
/// the real alerts box and pin, as known defects, what they do today.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/background/background_scan_trigger.dart';
import 'package:tankstellen/core/cache/cache_manager.dart';
import 'package:tankstellen/core/domain/search_params.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/notifications/notification_delivery.dart';
import 'package:tankstellen/core/notifications/notification_payload.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/services/station_service.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/background/background_scan_runners.dart';
import 'package:tankstellen/features/alerts/background/country_alert_strategy_resolver.dart';
import 'package:tankstellen/features/alerts/background/notification_templates.dart';
import 'package:tankstellen/features/alerts/background/opportunity_dispatcher.dart';
import 'package:tankstellen/features/alerts/background/polled_alert_strategy.dart';
import 'package:tankstellen/features/alerts/data/budget_state_store.dart';
import 'package:tankstellen/features/alerts/data/opportunity_feed_store.dart';
import 'package:tankstellen/features/alerts/data/radius_alert_store.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';

import '../../../fakes/fake_storage_repository.dart';
import '../../../helpers/hive_temp_dir.dart';
import '../../../helpers/silence_error_logger.dart';
import 'support/delivery_trace.dart';
import 'support/scan_disk_image.dart';
import 'support/scan_session_driver.dart';

/// A notifier that behaves like the OS: with the permission revoked or the
/// channel disabled, `show` returns normally and nothing appears — and,
/// like the platform plugin, it can be asked first (#4335).
class OsGatedNotifier implements NotificationService, NotificationDeliveryProbe {
  bool permissionGranted = true;
  bool channelEnabled = true;

  /// The OS setting changes between the probe and the post.
  bool revokeAfterProbe = false;

  int probes = 0;

  @override
  Future<NotificationDelivery?> blockedDelivery(
      NotificationChannelKind channel) async {
    probes++;
    final answer = !permissionGranted
        ? NotificationDelivery.suppressedPermission
        : !channelEnabled
            ? NotificationDelivery.suppressedChannel
            : null;
    if (revokeAfterProbe) permissionGranted = false;
    return answer;
  }

  @override
  Future<bool> openNotificationSettings() async => true;

  /// What the user could actually see.
  final List<({int id, String? payload})> visible = [];

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!permissionGranted || !channelEnabled) return; // silently nothing
    visible.add((id: id, payload: payload));
  }

  @override
  Future<bool> areNotificationsEnabled() async => permissionGranted;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

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

/// A recorded-shape DE provider answering area searches from fixed rows.
class _Forecourts implements StationService {
  List<Station> stations = [];

  @override
  Future<ServiceResult<List<Station>>> searchStations(SearchParams params,
          {CancelToken? cancelToken}) async =>
      ServiceResult(
          data: stations,
          source: ServiceSource.tankerkoenigApi,
          fetchedAt: kScanT0);

  @override
  Future<ServiceResult<Map<String, StationPrices>>> getPrices(
          List<String> ids) async =>
      ServiceResult(
          data: const {},
          source: ServiceSource.tankerkoenigApi,
          fetchedAt: kScanT0);

  @override
  Future<ServiceResult<StationDetail>> getStationDetail(String id) =>
      throw UnimplementedError();
}

Station forecourt(String id, double e10) => Station(
      id: id,
      name: '$id forecourt',
      brand: 'ARAL',
      street: 'Hauptstr. 1',
      postCode: '10115',
      place: 'Berlin',
      lat: 52.52,
      lng: 13.40,
      e10: e10,
      isOpen: true,
    );

void main() {
  silenceErrorLoggerSpool();

  late Directory dir;
  final templates = BackgroundNotificationTemplates.resolveForLanguage('en');

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('delivery_lifecycle_');
    Hive.init(dir.path);
    await Hive.openBox<dynamic>(HiveBoxes.alerts);
  });

  tearDown(() async {
    await closeHiveAndDeleteTemp(dir);
  });

  group('a revoked permission or a disabled channel (N2, #4335)', () {
    Future<(DispatchOutcome, OsGatedNotifier)> dispatchWith(
        void Function(OsGatedNotifier) os) async {
      final notifier = OsGatedNotifier();
      os(notifier);
      final outcome = await const OpportunityDispatcher().dispatch(
        candidates: [OpportunityCandidate(scanOpportunity(at: kScanT0))],
        now: kScanT0,
        notifier: notifier,
        templates: templates,
      );
      return (outcome, notifier);
    }

    Set<DeliveryMisreport> misreports(
            DispatchOutcome outcome, OsGatedNotifier os, DeliveryMisreport kind) =>
        {
          if (outcome.delivery == NotificationDelivery.posted &&
              os.visible.isEmpty)
            kind,
        };

    test('with both granted, the post is posted and visible', () async {
      final (outcome, os) = await dispatchWith((_) {});
      expect(outcome.delivery, NotificationDelivery.posted);
      expect(os.visible, hasLength(1));
    });

    for (final (label, off, expected) in [
      (
        'permission revoked',
        (OsGatedNotifier n) => n.permissionGranted = false,
        NotificationDelivery.suppressedPermission,
      ),
      (
        'channel disabled',
        (OsGatedNotifier n) => n.channelEnabled = false,
        NotificationDelivery.suppressedChannel,
      ),
    ]) {
      test('$label: reported as suppressed, and nothing is spent or '
          'written as told', () async {
        var detectorRecorded = false;
        final notifier = OsGatedNotifier();
        off(notifier);
        final outcome = await const OpportunityDispatcher().dispatch(
          candidates: [
            OpportunityCandidate(scanOpportunity(at: kScanT0),
                onNotified: () async => detectorRecorded = true),
          ],
          now: kScanT0,
          notifier: notifier,
          templates: templates,
        );

        final found = misreports(outcome, notifier,
            expected == NotificationDelivery.suppressedPermission
                ? DeliveryMisreport.revokedPermissionCountedPosted
                : DeliveryMisreport.disabledChannelCountedPosted);
        expectOnlyKnownMisreports(found);
        expect(outcome.delivery, expected);
        expect(outcome.notified, isFalse);
        expect(const BudgetStateStore().read().recentNotifications, isEmpty,
            reason: 'no budget slot for a notification nobody saw');
        expect(detectorRecorded, isFalse,
            reason: 'no detector cooldown either');
        expect(const OpportunityFeedStore().read(), hasLength(1),
            reason: 'the finding is still real, and still in the feed');
      });
    }

    test('the OS turns notifications off between the probe and the post: '
        'the post is what counts', () async {
      final notifier = OsGatedNotifier()..revokeAfterProbe = true;
      final outcome = await const OpportunityDispatcher().dispatch(
        candidates: [OpportunityCandidate(scanOpportunity(at: kScanT0))],
        now: kScanT0,
        notifier: notifier,
        templates: templates,
      );
      // Pinned residue: the plugin's show() returns normally with nothing
      // on screen, so a revocation inside the probe→post window of one
      // dispatch is still counted — the next dispatch's probe sees it.
      expect(outcome.delivery, NotificationDelivery.posted);
      expect(notifier.probes, 1);
    });

    test('a post that throws is failed, and spends nothing', () async {
      final trace = DeliveryTrace()..throwOnPost = true;
      final outcome = await const OpportunityDispatcher().dispatch(
        candidates: [OpportunityCandidate(scanOpportunity(at: kScanT0))],
        now: kScanT0,
        notifier: trace,
        templates: templates,
      );
      expect(outcome.delivery, NotificationDelivery.failed);
      expect(outcome.notified, isFalse);
      expect(const BudgetStateStore().read().recentNotifications, isEmpty);
    });

    test('nothing attempted: no delivery at all', () async {
      final outcome = await const OpportunityDispatcher().dispatch(
        candidates: const [],
        now: kScanT0,
        notifier: DeliveryTrace(),
        templates: templates,
      );
      expect(outcome.delivery, isNull);
    });
  });

  group('the scan journal records a suppressed delivery (#4335)', () {
    test('the completed row says why nothing was sent', () async {
      await Hive.close();
      final disk = await ScanDisk.open();
      addTearDown(() async {
        await disk.close();
        Hive.init(dir.path);
        await Hive.openBox<dynamic>(HiveBoxes.alerts);
      });
      final notifier = OsGatedNotifier()..permissionGranted = false;

      await disk
          .coordinator(
            body: (_, at) =>
                ScriptedScanBody(at, candidates: [scanOpportunity(at: at)]),
            notifier: notifier,
          )
          .scan(
              trigger: BackgroundScanTrigger.workManagerPeriodic, now: kScanT0);

      expect(disk.journal.single, {
        'at': kScanT0.toIso8601String(),
        'trigger': 'workmanager_periodic',
        'stations': 1,
        'alertsFired': 0,
        'undelivered': 'suppressedPermission',
      });
    });
  });

  group('the radius notification envelope (N1, N3, #4334)', () {
    late _Forecourts provider;
    late CountryAlertStrategyResolver resolver;

    setUp(() async {
      provider = _Forecourts();
      final storage = FakeStorageRepository();
      resolver = CountryAlertStrategyResolver(
        storage: storage,
        cache: CacheManager(storage),
        polledDeps: PolledAlertStrategyDeps(
            serviceBuilder: (_, {String? apiKey}) => provider),
      );
      await RadiusAlertStore().upsert(RadiusAlert(
        id: 'home-e10',
        fuelType: 'e10',
        threshold: 1.799,
        centerLat: 52.52,
        centerLng: 13.40,
        radiusKm: 5,
        label: 'Home',
        createdAt: DateTime.utc(2026, 9, 1),
        frequencyPerDay: 4,
      ));
    });

    Future<DeliveryTrace> scan(DateTime at) async {
      final candidates = await BackgroundScanRunners.detectRadiusAlerts(
          now: at, resolver: resolver, templates: templates);
      expect(candidates, isNotEmpty, reason: 'the fixture must trip');
      final trace = DeliveryTrace();
      await const OpportunityDispatcher().dispatch(
        candidates: candidates,
        now: at,
        notifier: trace,
        templates: templates,
      );
      return trace;
    }

    test('N1 (#4334) — the tap opens the cheapest station: the payload the '
        'radius runner built reaches the post', () async {
      provider.stations = [forecourt('de-b', 1.759), forecourt('de-a', 1.699)];
      final trace = await scan(kScanT0);

      final payload = NotificationPayload.tryDecode(trace.posts.single.payload);
      final defects = {
        if (payload?.stationId != 'de-a') EnvelopeDefect.radiusPayloadDropped,
      };
      expectOnlyKnownEnvelopeDefects(defects);
      expect(payload?.kind, NotificationPayload.kindRadius);
      expect(payload?.stationId, 'de-a', reason: 'the cheapest match');
      expect(payload?.country, 'DE', reason: "the centre's country");
      expect(payload?.toRouterPath(), isNotNull,
          reason: 'the launch listener can route it');
    });

    test('N3 (#4334) — one notification id per alert across scans, even '
        'when the cheapest station changes', () async {
      provider.stations = [forecourt('de-a', 1.699)];
      final first = await scan(kScanT0);
      provider.stations = [forecourt('de-c', 1.649)];
      final second = await scan(kScanT0.add(const Duration(hours: 13)));

      final perAlert = 'radius:home-e10'.hashCode;
      final defects = {
        if (first.posts.single.id != perAlert ||
            second.posts.single.id != perAlert)
          EnvelopeDefect.radiusIdPerStation,
      };
      expectOnlyKnownEnvelopeDefects(defects);
      expect(second.posts.single.id, first.posts.single.id,
          reason: 'the second replaces the first instead of stacking');
    });

    test('N3 — two alerts whose cheapest station is the same keep two ids',
        () async {
      await RadiusAlertStore().upsert(RadiusAlert(
        id: 'work-e10',
        fuelType: 'e10',
        threshold: 1.799,
        centerLat: 52.52,
        centerLng: 13.40,
        radiusKm: 3,
        label: 'Work',
        createdAt: DateTime.utc(2026, 9, 1),
        frequencyPerDay: 4,
      ));
      provider.stations = [forecourt('de-a', 1.699)];
      final candidates = await BackgroundScanRunners.detectRadiusAlerts(
          now: kScanT0, resolver: resolver, templates: templates);

      expect({for (final c in candidates) c.envelope?.id}, {
        'radius:home-e10'.hashCode,
        'radius:work-e10'.hashCode,
      }, reason: 'neither overwrites the other on the shade');
    });
  });
}
