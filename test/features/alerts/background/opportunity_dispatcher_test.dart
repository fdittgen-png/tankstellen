// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/domain/data_value.dart';
import 'package:tankstellen/core/notifications/notification_service.dart';
import 'package:tankstellen/core/services/provider_capability.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/alerts/background/notification_templates.dart';
import 'package:tankstellen/features/alerts/background/opportunity_dispatcher.dart';
import 'package:tankstellen/features/alerts/data/budget_state_store.dart';
import 'package:tankstellen/features/alerts/data/opportunity_feed_store.dart';
import 'package:tankstellen/features/alerts/domain/opportunity.dart';
import 'package:tankstellen/features/alerts/domain/opportunity_budget.dart';

/// #4183 — the whole chain, driven end to end.
///
/// A price observation in, a notification decision out, with the clock
/// injected — the shape #4164 established. What this holds that no unit
/// test of the budget could: that the budget's promises survive the
/// plumbing. "Suppressed means not a push, never discarded" is a claim
/// about a STORE, and only a test that writes and reads one can check it.
void main() {
  late Directory tmpDir;
  late _RecordingNotifier notifier;
  final now = DateTime.utc(2026, 9, 15, 12);

  const dispatcher = OpportunityDispatcher();

  Opportunity opportunity({
    String stationId = 'de-a',
    String? stationName = 'ARAL Berlin',
    OpportunityKind kind = OpportunityKind.favouriteStation,
    double currentPrice = 1.649,
    double? referencePrice = 1.729,
    double? net = 3.8,
    DataConfidence confidence = DataConfidence.high,
    DateTime? detectedAt,
  }) {
    final at = detectedAt ?? now;
    return Opportunity(
      kind: kind,
      stationId: stationId,
      stationName: stationName,
      fuelType: 'e10',
      currentPrice: currentPrice,
      reference: OpportunityReference.thresholdYouSet,
      referencePrice: referencePrice,
      grossSaving: net == null ? null : net + 0.4,
      detourCost: net == null ? null : 0.4,
      netSaving: net,
      distanceKm: 3.2,
      priceAge: const DataValue.measured(Duration(minutes: 12)),
      confidence: confidence,
      detectedAt: at,
      expiresAt: at.add(const Duration(hours: 6)),
    );
  }

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('opportunity_dispatch_');
    Hive.init(tmpDir.path);
    await Hive.openBox<dynamic>(HiveBoxes.alerts);
    notifier = _RecordingNotifier();
  });

  tearDown(() async {
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  final templates = BackgroundNotificationTemplates.resolveForLanguage('en');

  Future<DispatchOutcome> dispatch(List<Opportunity> candidates,
          {DateTime? at}) =>
      dispatcher.dispatch(
        candidates: candidates,
        now: at ?? now,
        notifier: notifier,
        templates: templates,
      );

  group('the chain', () {
    test('one candidate becomes one notification and one feed entry',
        () async {
      final outcome = await dispatch([opportunity()]);

      expect(outcome.notified, isTrue);
      expect(notifier.sent, hasLength(1));
      expect(notifier.sent.single.title, contains('ARAL Berlin'));

      final feed = const OpportunityFeedStore().read();
      expect(feed, hasLength(1));
      expect(feed.single.wasNotified, isTrue);
    });

    test('three candidates produce ONE notification and three feed entries',
        () async {
      // The change this issue exists to make. Before it, the per-station
      // runner fired once per tripped alert, so three alerts crossing in
      // one scan produced three notifications.
      final outcome = await dispatch([
        opportunity(stationId: 'de-a', net: 1.5),
        opportunity(stationId: 'de-b', net: 4.0),
        opportunity(stationId: 'de-c', net: 2.5),
      ]);

      expect(notifier.sent, hasLength(1));
      expect(outcome.demotions, hasLength(2));
      expect(
          outcome.demotions.map((d) => d.reason),
          everyElement(BudgetRefusal.outrankedInWindow));

      final feed = const OpportunityFeedStore().read();
      expect(feed, hasLength(3),
          reason: 'the other two are demoted, not discarded — that is the '
              'promise #4151 made and this store is where it becomes real');
      expect(feed.where((e) => e.wasNotified), hasLength(1));
    });

    test('the best one wins, not the first one', () async {
      await dispatch([
        opportunity(stationId: 'de-cheap-find', net: 1.0),
        opportunity(stationId: 'de-best', net: 9.0),
      ]);
      expect(notifier.sent.single.id, 'de-best'.hashCode);
    });

    test('a scan that finds nothing writes nothing and sends nothing',
        () async {
      final outcome = await dispatch([]);
      expect(outcome.notified, isFalse);
      expect(outcome.recorded, 0);
      expect(notifier.sent, isEmpty);
      expect(const OpportunityFeedStore().read(), isEmpty);
    });
  });

  group('the budget spans scans — the whole point of persisting it', () {
    test('a second scan minutes later is refused, and says why', () async {
      await dispatch([opportunity(stationId: 'de-a')]);
      expect(notifier.sent, hasLength(1));

      final second = await dispatch(
        [opportunity(stationId: 'de-b', detectedAt: now.add(const Duration(minutes: 30)))],
        at: now.add(const Duration(minutes: 30)),
      );

      expect(notifier.sent, hasLength(1),
          reason: 'minInterval is 2 h across ALL kinds; a budget that '
              'forgot the first scan would be a per-scan filter with a '
              'cap of one');
      expect(second.demotions.single.reason, BudgetRefusal.tooSoonAfterLast);

      final feed = const OpportunityFeedStore().read();
      expect(feed, hasLength(2));
      expect(feed.first.refusal, BudgetRefusal.tooSoonAfterLast,
          reason: '"why didn\'t I get an alert" has an answer the user '
              'can open');
    });

    test('the same station stays quiet for perStationQuiet', () async {
      await dispatch([opportunity(stationId: 'de-a')]);

      final later = now.add(const Duration(hours: 3));
      final second = await dispatch(
        [opportunity(stationId: 'de-a', detectedAt: later)],
        at: later,
      );

      expect(second.demotions.single.reason,
          BudgetRefusal.alreadyToldRecently);
      expect(notifier.sent, hasLength(1));
    });

    test('a different station after the interval DOES get through',
        () async {
      await dispatch([opportunity(stationId: 'de-a')]);

      final later = now.add(const Duration(hours: 3));
      await dispatch(
        [opportunity(stationId: 'de-b', detectedAt: later)],
        at: later,
      );

      expect(notifier.sent, hasLength(2),
          reason: 'the budget throttles attention, it does not switch '
              'alerts off');
    });

    test('the daily cap holds across scans', () async {
      var at = now;
      for (var i = 0; i < 6; i++) {
        await dispatch(
          [opportunity(stationId: 'de-$i', detectedAt: at)],
          at: at,
        );
        at = at.add(const Duration(hours: 3));
      }
      expect(notifier.sent, hasLength(const BudgetPolicy().maxPerDay),
          reason: 'alert_delivery_sla caps the day at 3, and six scans '
              'three hours apart all clear minInterval');
    });
  });

  group('refusals are recorded, not swallowed', () {
    test('a saving below the floor never competes', () async {
      final outcome = await dispatch([opportunity(net: 0.10)]);
      expect(outcome.notified, isFalse);
      expect(
          outcome.demotions.single.reason, BudgetRefusal.savingBelowFloor);
      expect(const OpportunityFeedStore().read().single.refusal,
          BudgetRefusal.savingBelowFloor);
    });

    test('a provider with no confidence cannot arrive uninvited', () async {
      final outcome =
          await dispatch([opportunity(confidence: DataConfidence.none)]);
      expect(outcome.notified, isFalse);
      expect(const OpportunityFeedStore().read(), hasLength(1),
          reason: 'a weak signal is still worth having when the user goes '
              'looking for it');
    });

    test('an unrenderable winner is recorded and does NOT spend the slot',
        () async {
      // A station-shaped kind with no station name: nothing honest to
      // put in the copy. It must not become a notification naming an id,
      // and it must not consume the day's budget either.
      await dispatch([opportunity(stationName: null)]);
      expect(notifier.sent, isEmpty);
      expect(const OpportunityFeedStore().read(), hasLength(1));
      expect(const BudgetStateStore().read().recentNotifications, isEmpty,
          reason: 'nothing was sent, so nothing was spent');
    });

    test('a notification channel that throws does not take the scan down',
        () async {
      notifier.throwOnSend = true;
      final outcome = await dispatch([opportunity()]);

      expect(outcome.notified, isFalse);
      expect(const OpportunityFeedStore().read(), hasLength(1),
          reason: 'the finding is real whether or not the channel took it');
      expect(const BudgetStateStore().read().recentNotifications, isEmpty);
    });
  });

  test('a closed alerts box degrades to a no-op, not a crash', () async {
    await Hive.box<dynamic>(HiveBoxes.alerts).close();
    await expectLater(dispatch([opportunity()]), completes);
    expect(notifier.sent, hasLength(1),
        reason: 'the notification still goes out; only the record is lost');
  });
}

/// Records what was posted instead of touching a platform channel.
class _RecordingNotifier implements NotificationService {
  final List<({int id, String title, String body})> sent = [];
  bool throwOnSend = false;

  @override
  Future<void> showPriceAlert({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (throwOnSend) throw StateError('channel unavailable');
    sent.add((id: id, title: title, body: body));
  }

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
